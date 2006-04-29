#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Scalar::Util qw/isweak reftype/;

BEGIN {
    use_ok('Class::MOP::Instance');    
}

can_ok( "Class::MOP::Instance", $_ ) for qw/
    new 
    
	create_instance
	bless_instance_structure

    get_all_slots

	get_slot_value
	set_slot_value
	initialize_slot
	initialize_all_slots
	is_slot_initialized	
/;

{
	package Foo;
	use metaclass;
	
	Foo->meta->add_attribute('moosen');

	package Bar;
	use metaclass;
	use base qw/Foo/;

	Bar->meta->add_attribute('elken');
}

my $mi_foo = Foo->meta->get_meta_instance;
isa_ok($mi_foo, "Class::MOP::Instance");

is_deeply(
    [ $mi_foo->get_all_slots ], 
    [ "moosen" ], 
    '... get all slots for Foo');

my $mi_bar = Bar->meta->get_meta_instance;
isa_ok($mi_bar, "Class::MOP::Instance");

isnt($mi_foo, $mi_bar, '... they are not the same instance');

is_deeply(
    [ sort $mi_bar->get_all_slots ], 
    [ "elken", "moosen" ], 
    '... get all slots for Bar');

my $i_foo = $mi_foo->create_instance;
isa_ok($i_foo, "Foo");

{
    my $i_foo_2 = $mi_foo->create_instance;
    isa_ok($i_foo_2, "Foo");    
    isnt($i_foo_2, $i_foo, '... not the same instance');
    is_deeply($i_foo, $i_foo_2, '... but the same structure');
}

ok(!defined($mi_foo->get_slot_value( $i_foo, "moosen" )), "... no value for slot");

$mi_foo->set_slot_value( $i_foo, "moosen", "the value" );

is($mi_foo->get_slot_value( $i_foo, "moosen" ), "the value", "... get slot value");

ok(!$i_foo->can('moosen'), '... Foo cant moosen');

can_ok( $mi_foo, "set_slot_value_weak" );

my $ref = [];
$mi_foo->set_slot_value_weak( $i_foo, "moosen", $ref );

is( $mi_foo->get_slot_value( $i_foo, "moosen" ), $ref, "weak value is fetchable" );

ok( !isweak($mi_foo->get_slot_value( $i_foo, "moosen" )), "return value not weak" );

undef $ref;

is( $mi_foo->get_slot_value( $i_foo, "moosen" ), undef, "weak value destroyed" );

$ref = [];

$mi_foo->set_slot_value( $i_foo, "moosen", $ref );

undef $ref;

is( reftype( $mi_foo->get_slot_value( $i_foo, "moosen" ) ), "ARRAY", "value not weak yet" );

$mi_foo->weaken_slot_value( $i_foo, "moosen" );

is( $mi_foo->get_slot_value( $i_foo, "moosen" ), undef, "weak value destroyed" );


$ref = [];

$mi_foo->set_slot_value( $i_foo, "moosen", $ref );


$mi_foo->weaken_slot_value( $i_foo, "moosen" );

$mi_foo->strengthen_slot_value( $i_foo, "moosen" );

undef $ref;

is( reftype( $mi_foo->get_slot_value( $i_foo, "moosen" ) ), "ARRAY", "weak value can be strengthened" );


