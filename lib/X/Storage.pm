package X::Storage;

use strict;
use warnings;
use Scalar::Util 'blessed';
use Carp;
use JSON::MaybeXS;


###
# Returns the object that will be used for all object

sub connect {
  my ($class, $dsn, @options) = @_;

  if ($dsn =~ m/^dbi:SQLite:/) {
    require X::Storage::Driver::SQLite;
    return X::Storage::Driver::SQLite->_build($class, $dsn, @options);
  }

  croak "DSN not recognized '$dsn'";
}


###
# Type registry

{
  our %registry;

  sub register {
    my ($class, $type, $ops) = @_;
    $class = blessed($class) if blessed($class);

    my $r_ops = $registry{$class}{$type} ||= {};
    $registry{$class}{$type} = {
      marshal   => sub { return encode_json($_[0]) },
      unmarshal => sub { return decode_json($_[0]) },
      %$r_ops, %$ops,
    };

    return;
  }

  sub types {
    my ($class) = @_;
    $class = blessed($class) if blessed($class);

    return () unless exists $registry{$class};
    return sort keys %{ $registry{$class} };
  }

  sub ops_for_type {
    my ($class, $type) = @_;
    $class = blessed($class) if blessed($class);

    return {} unless exists $registry{$class} and exists $registry{$class}{$type};
    return $registry{$class}{$type};
  }
}
1;
