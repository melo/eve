package X::Storage::Driver;

use strict;
use warnings;
use Carp;

### Instance and connection setup

sub _build {
  my ($class, $registry, @rest) = @_;
  my $self = bless { registry => $registry }, $class;

  return $self->connect(@rest);
}

sub connect {
  croak "FATAL: class $_[0] must implement connect() method,";
}


### DB Deploy

sub deploy {
  my ($self) = @_;

  $self->_do_deploy();

  my $r = $self->{registry};
  for my $type ($r->types) {
    my $ops = $r->ops_for_type($type);
    next unless exists $ops->{deploy};

    $ops->{deploy}->($self);
  }

  return;
}


### CRUD
sub create {
  my ($self, $type, $blob, $meta) = @_;
  my $ops  = $self->{registry}->ops_for_type($type);
  my $mrsh = $ops->{marshal};

  croak "Type '$type' is missing a ID operation" unless exists $ops->{id};

  my $id;
  ($id, $blob, $meta) = $ops->{id}->($type, $blob || {}, $meta || {});
  $self->_do_create($type, $id, $mrsh->($blob), $mrsh->($meta));

  return $id;
}

sub fetch {
  my ($self, $type, $id) = @_;
  my $ops  = $self->{registry}->ops_for_type($type);
  my $mrsh = $ops->{unmarshal};

  my ($blob, $user_meta, $meta) = $self->_do_fetch($type, $id);
  return unless defined $meta;

  $blob = $mrsh->($blob);
  return $blob unless wantarray;

  $meta->{meta} = $mrsh->($user_meta);
  $meta->{type} = $type;
  $meta->{id}   = $id;

  return ($blob, $meta);
}


### Events
sub events {
  my ($self, $type, $id) = @_;
  my $ops  = $self->{registry}->ops_for_type($type);
  my $mrsh = $ops->{unmarshal};

  my $events = $self->_do_events($type, $id);
  for my $e (@$events) {
    $e->{event_meta} = $mrsh->($e->{event_meta});
  }

  return $events;
}

1;

=head1 SCHEMA

The DBI version of this drivers use the following schema (using the MySQL
version as reference):

    CREATE TABLE IF NOT EXISTS ent_events (
        entity_id     BINARY(16)   NOT NULL,
        version       INTEGER UNSIGNED NOT NULL,
        entity_type   BINARY(32)    NOT NULL,
        event_type    BINARY(1)    NOT NULL,

        event_blob    BLOB NOT NULL,
        event_meta    BLOB NOT NULL,

        created_at    DATETIME(6) NOT NULL,
        
        PRIMARY KEY ent_events_pk (entity_id. version, entity_type, event_type)
    ) ENGINE=InnoDB DEFAULT CHARSET=binary;

The C<event_id> is a simple sequence/auto_increment field to be used as the
table primary key.

=cut
