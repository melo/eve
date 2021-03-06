package Eve;

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
    require Eve::Driver::SQLite;
    return Eve::Driver::SQLite->_build($class, $dsn, @options);
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

    $ops = _calc_ops_from_caller($ops, (caller())[0]) unless ref($ops);

    my $r_ops = $registry{$class}{$type} ||= {};
    $registry{$class}{$type} = {
      marshal   => sub { return encode_json($_[0]) },
      unmarshal => sub { return decode_json($_[0]) },
      %$r_ops, %$ops,
    };

    return;
  }

  sub _calc_ops_from_caller {
    my ($prefix, $class) = @_;
    my %ops;

    for my $m (qw( id before after deploy marshal unmarshal )) {
      my $op = $class->can("${prefix}_$m");
      next unless $op;

      $ops{$m} = $op;
    }

    return \%ops;
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
