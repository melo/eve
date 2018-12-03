package X::Storage::Driver::DBI;

use strict;
use warnings;
use parent 'X::Storage::Driver';
use DBIx::Transaction;


sub connect {
  my ($self, $dsn, $user, $pass, $opts) = @_;
  $opts = {} unless $opts;
  $opts->{RaiseError} = 1 unless exists $opts->{RaiseError};
  $opts->{AutoCommit} = 1 unless exists $opts->{AutoCommit};

  $self->{db} = DBIx::Transaction->connect($dsn, "", "", $opts);

  return $self;
}

1;
