package Class::MOP::Class::Immutable::Trait;

use strict;
use warnings;

use MRO::Compat;

use Carp 'confess';
use Scalar::Util 'blessed', 'weaken';

# the original class of the metaclass instance
sub get_mutable_metaclass_name { $_[0]{__immutable}{original_class} }

sub immutable_options { %{ $_[0]{__immutable}{options} } }

sub is_mutable   {0}
sub is_immutable {1}

sub superclasses {
    confess "This method is read-only" if @_ > 1;
    $_[0]->next::method;
}

sub _immutable_cannot_call {
    Carp::confess "This method cannot be called on an immutable instance";
}

sub add_method            { shift->_immutable_cannot_call }
sub alias_method          { shift->_immutable_cannot_call }
sub remove_method         { shift->_immutable_cannot_call }
sub add_attribute         { shift->_immutable_cannot_call }
sub remove_attribute      { shift->_immutable_cannot_call }
sub remove_package_symbol { shift->_immutable_cannot_call }

sub class_precedence_list {
    @{ $_[0]{__immutable}{class_precedence_list}
            ||= [ shift->next::method ] };
}

sub linearized_isa {
    @{ $_[0]{__immutable}{linearized_isa} ||= [ shift->next::method ] };
}

sub get_all_methods {
    @{ $_[0]{__immutable}{get_all_methods} ||= [ shift->next::method ] };
}

sub get_all_method_names {
    @{ $_[0]{__immutable}{get_all_method_names} ||= [ shift->next::method ] };
}

sub get_all_attributes {
    @{ $_[0]{__immutable}{get_all_attributes} ||= [ shift->next::method ] };
}

sub get_meta_instance {
    $_[0]{__immutable}{get_meta_instance} ||= shift->next::method;
}

sub get_method_map {
    $_[0]{__immutable}{get_method_map} ||= shift->next::method;
}

sub add_package_symbol {
    confess "Cannot add package symbols to an immutable metaclass"
        unless ( caller(1) )[3] eq 'Class::MOP::Package::get_package_symbol';

    shift->next::method(@_);
}

1;
