#include "mop.h"

static void
mop_update_method_map(pTHX_ SV *const self, SV *const class_name, HV *const stash, HV *const map)
{
    const char *const class_name_pv = HvNAME(stash); /* must be HvNAME(stash), not SvPV_nolen_const(class_name) */
    SV   *method_metaclass_name;
    char *method_name;
    I32   method_name_len;
    SV   *coderef;
    HV   *symbols;
    dSP;

    symbols = mop_get_all_package_symbols(stash, TYPE_FILTER_CODE);
    sv_2mortal((SV*)symbols);
    (void)hv_iterinit(symbols);
    while ( (coderef = hv_iternextsv(symbols, &method_name, &method_name_len)) ) {
        CV *cv = (CV *)SvRV(coderef);
        char *cvpkg_name;
        char *cv_name;
        SV *method_slot;
        SV *method_object;

        if (!mop_get_code_info(coderef, &cvpkg_name, &cv_name)) {
            continue;
        }

        /* this checks to see that the subroutine is actually from our package  */
        if ( !(strEQ(cvpkg_name, "constant") && strEQ(cv_name, "__ANON__")) ) {
            if ( strNE(cvpkg_name, class_name_pv) ) {
                continue;
            }
        }

        method_slot = *hv_fetch(map, method_name, method_name_len, TRUE);
        if ( SvOK(method_slot) ) {
            SV *const body = mop_call0(aTHX_ method_slot, KEY_FOR(body)); /* $method_object->body() */
            if ( SvROK(body) && ((CV *) SvRV(body)) == cv ) {
                continue;
            }
        }

        method_metaclass_name = mop_call0(aTHX_ self, mop_method_metaclass); /* $self->method_metaclass() */

        /*
            $method_object = $method_metaclass->wrap(
                $cv,
                associated_metaclass => $self,
                package_name         => $class_name,
                name                 => $method_name
            );
        */
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 8);
        PUSHs(method_metaclass_name); /* invocant */
        mPUSHs(newRV_inc((SV *)cv));
        PUSHs(mop_associated_metaclass);
        PUSHs(self);
        PUSHs(KEY_FOR(package_name));
        PUSHs(class_name);
        PUSHs(KEY_FOR(name));
        mPUSHs(newSVpv(method_name, method_name_len));
        PUTBACK;

        call_sv(mop_wrap, G_SCALAR | G_METHOD);
        SPAGAIN;
        method_object = POPs;
        PUTBACK;
        /* $map->{$method_name} = $method_object */
        sv_setsv(method_slot, method_object);

        FREETMPS;
        LEAVE;
    }
}

MODULE = Class::MOP::Package   PACKAGE = Class::MOP::Package

PROTOTYPES: DISABLE

void
get_all_package_symbols(self, filter=TYPE_FILTER_NONE)
    SV *self
    type_filter_t filter
    PREINIT:
        HV *stash = NULL;
        HV *symbols = NULL;
        register HE *he;
    PPCODE:
        if ( ! SvROK(self) ) {
            die("Cannot call get_all_package_symbols as a class method");
        }

        if (GIMME_V == G_VOID) {
            XSRETURN_EMPTY;
        }

        PUTBACK;

        if ( (he = hv_fetch_ent((HV *)SvRV(self), KEY_FOR(package), 0, HASH_FOR(package))) ) {
            stash = gv_stashsv(HeVAL(he), 0);
        }


        if (!stash) {
            XSRETURN_UNDEF;
        }

        symbols = mop_get_all_package_symbols(stash, filter);
        PUSHs(sv_2mortal(newRV_noinc((SV *)symbols)));

void
get_method_map(self)
    SV *self
    PREINIT:
        HV *const obj        = (HV *)SvRV(self);
        SV *const class_name = HeVAL( hv_fetch_ent(obj, KEY_FOR(package), 0, HASH_FOR(package)) );
        HV *const stash      = gv_stashsv(class_name, 0);
        UV current;
        SV *cache_flag;
        SV *map_ref;
    PPCODE:
        if (!stash) {
             mXPUSHs(newRV_noinc((SV *)newHV()));
             return;
        }

        current    = mop_check_package_cache_flag(aTHX_ stash);
        cache_flag = HeVAL( hv_fetch_ent(obj, KEY_FOR(package_cache_flag), TRUE, HASH_FOR(package_cache_flag)));
        map_ref    = HeVAL( hv_fetch_ent(obj, KEY_FOR(methods), TRUE, HASH_FOR(methods)));

        /* $self->{methods} does not yet exist (or got deleted) */
        if ( !SvROK(map_ref) || SvTYPE(SvRV(map_ref)) != SVt_PVHV ) {
            SV *new_map_ref = newRV_noinc((SV *)newHV());
            sv_2mortal(new_map_ref);
            sv_setsv(map_ref, new_map_ref);
        }

        if ( !SvOK(cache_flag) || SvUV(cache_flag) != current ) {
            mop_update_method_map(aTHX_ self, class_name, stash, (HV *)SvRV(map_ref));
            sv_setuv(cache_flag, mop_check_package_cache_flag(aTHX_ stash)); /* update_cache_flag() */
        }

        XPUSHs(map_ref);

BOOT:
    INSTALL_SIMPLE_READER_WITH_KEY(Package, name, package);
