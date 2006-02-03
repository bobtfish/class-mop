
package Perl6Attribute;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Class::MOP::Attribute';

sub new {
    my ($class, $attribute_name, %options) = @_;
    
    # extract the sigil and accessor name
    my ($sigil, $accessor_name) = ($attribute_name =~ /^([\$\@\%])\.(.*)$/);
    
    # pass the accessor name
    $options{accessor} = $accessor_name;
    
    # create a default value based on the sigil
    $options{default} = sub { [] } if ($sigil eq '@');
    $options{default} = sub { {} } if ($sigil eq '%');        
    
    $class->SUPER::new($attribute_name, %options);
}

1;

__END__

=pod

=head1 NAME

Perl6Attribute - An attribute metaclass for Perl 6 style attributes

=head1 SYNOPSIS

  package Foo;
  
  use Class::MOP 'meta';
  
  Foo->meta->add_attribute(Perl6Attribute->new('$.foo'));
  Foo->meta->add_attribute(Perl6Attribute->new('@.bar'));    
  Foo->meta->add_attribute(Perl6Attribute->new('%.baz'));    
  
  sub new  {
      my $class = shift;
      bless $class->meta->construct_instance() => $class;
  }

=head1 DESCRIPTION

This is an attribute metaclass which implements Perl 6 style 
attributes, including the auto-generating accessors. 

This code is very simple, we only need to subclass 
C<Class::MOP::Attribute> and override C<&new>. Then we just 
pre-process the attribute name, and create the accessor name 
and default value based on it. 

More advanced features like the C<handles> trait (see 
L<Perl6::Bible/A12>) can be accomplished as well doing the 
same pre-processing approach. This is left as an exercise to 
the reader though (if you do it, please send me a patch 
though, and will update this).

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut