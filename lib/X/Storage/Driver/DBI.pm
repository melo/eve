package X::Storage::Driver::DBI;

use strict;
use warnings;
use parent 'X::Storage::Driver';
use DBIx::Transaction;


####################
# Connection control

sub connect {
  my ($self, $dsn, $user, $pass, $opts) = @_;
  $opts               = {} unless $opts;
  $opts->{RaiseError} = 1  unless exists $opts->{RaiseError};
  $opts->{AutoCommit} = 1  unless exists $opts->{AutoCommit};

  $self->{db} = DBIx::Transaction->connect($dsn, "", "", $opts);

  return $self;
}


#############
# SQL helpers

sub sql_select {
  my ($self, $sql, @bind) = @_;
  my $dbh = $self->{db};

  return $dbh->selectall_arrayref($sql, { Slice => {} }, @bind);
}

sub sql_insert {
  my ($self, $table, $spec) = @_;
  my $db = $self->{db};

  my ($fields, $bind_spec, $bind_vals) = _extract_insert_spec($spec);
  my $sql = "INSERT INTO $table (" . $fields . ') VALUES (' . $bind_spec . ')';
  $db->do($sql, undef, @$bind_vals);

  return $db->last_insert_id(undef, undef, undef, undef);
}

sub sql_update {
  my ($self, $table, $set, $where) = @_;
  my $db = $self->{db};

  my ($set_sql,  $set_bind)  = _extract_fields($set);
  my ($cond_sql, $cond_bind) = _extract_conditions($where);

  my $sql = "UPDATE $table SET $set_sql";
  $sql .= " WHERE $cond_sql" if $cond_sql;

  return $db->do($sql, undef, @$set_bind, @$cond_bind);
}

sub sql_do {
  my ($self, $sql, @bind) = @_;
  return $self->{db}->do($sql, undef, @bind);
}


##############
# SQL builders

sub _extract_insert_spec {
  my ($fields) = @_;

  my @bind_spec;
  my @bind_vals;
  my @fields;

  while (my ($f, $v) = each %$fields) {
    push @fields, $f;
    if (ref($v)) {
      push @bind_spec, $$v;
    }
    else {
      push @bind_spec, '?';
      push @bind_vals, $v;
    }
  }

  return (join(', ', @fields), join(', ', @bind_spec), \@bind_vals);
}

sub _extract_fields {
  my ($fields) = @_;

  my (@fields, @binds);
  while (my ($f, $v) = each %$fields) {
    if (ref($v)) {
      push @fields, "$f = $$v";
    }
    else {
      push @fields, "$f = ?";
      push @binds,  $v;
    }
  }

  return (join(', ', @fields), \@binds);
}

sub _extract_conditions {
  my ($spec) = @_;
  $spec = {} unless $spec;

  my (@conds, @binds);
  while (my ($f, $v) = each %$spec) {
    if (ref($v)) {
      push @conds, "$f = $$v";
    }
    else {
      push @conds, "$f = ?";
      push @binds, $v;
    }
  }

  return (join(' AND ', map {"$_"} @conds), \@binds);
}


1;
