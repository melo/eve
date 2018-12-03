package X::Storage::Driver::SQLite;

use strict;
use warnings;
use parent 'X::Storage::Driver::DBI';
use DBI qw(:sql_types);

sub _do_create {
  my ($self, $type, $id, $blob, $meta) = @_;
  my $db = $self->{db};

  $db->transaction(
    sub {
      my $sth = $db->prepare('
      INSERT INTO ent_current
             (entity_id, entity_type, version, entity_blob, state)
      VALUES (?,         ?,           1,       ?,           "a")
    ');
      $sth->bind_param(1, $id,   SQL_BLOB);
      $sth->bind_param(2, $type, SQL_BLOB);
      $sth->bind_param(3, $blob, SQL_BLOB);
      $sth->execute();

      $sth = $db->prepare('
      INSERT INTO ent_events
             (entity_id, entity_type, version, event_blob, event_meta, event_type)
      VALUES (?,         ?,           1,       ?,          ?,          "c")
    ');
      $sth->bind_param(1, $id,   SQL_BLOB);
      $sth->bind_param(2, $type, SQL_BLOB);
      $sth->bind_param(3, $blob, SQL_BLOB);
      $sth->bind_param(4, $meta, SQL_BLOB);
      $sth->execute();
    }
  );

  return 1;    ## the version
}

sub _do_fetch {
  my ($self, $type, $id) = @_;

  my $db  = $self->{db};
  my $row = $db->selectrow_arrayref('
    SELECT c.version, c.entity_blob, c.state,
           e.event_meta, e.created_at, e.event_type
      FROM ent_current AS c
           JOIN ent_events AS e ON (
                  e.entity_id   = c.entity_id   AND
                  e.entity_type = c.entity_type AND
                  e.version     = c.version     AND
                  e.event_type  != "a"
                )
     WHERE c.entity_id   = CAST(? AS BLOB)
       AND c.entity_type = CAST(? AS BLOB)
  ', undef, $id, $type);

  return unless defined $row;

  my ($v, $b, $s, $m, $c, $t) = @$row;
  return ($b, $m, { version => $v, created_at => $c, state => $s, event_type => $t });
}

sub _do_events {
  my ($self, $type, $id) = @_;
  my $db = $self->{db};

  return $db->selectall_arrayref('
    SELECT entity_id, version, entity_type, event_type, event_meta, created_at
      FROM ent_events
     WHERE entity_type = CAST(? AS BLOB)
       AND entity_id   = CAST(? AS BLOB)
  ', { Slice => {} }, $type, $id);
}


###
# Deploy logic

sub _do_deploy {
  my ($self) = @_;
  my $db = $self->{db};

  $db->do(
    q{
    CREATE TABLE IF NOT EXISTS ent_events (
        entity_id     BLOB(16)         NOT NULL,
        version       INTEGER UNSIGNED NOT NULL,
        entity_type   BLOB(32)         NOT NULL,
        event_type    TEXT(1)          NOT NULL,

        event_blob    BLOB NOT NULL,
        event_meta    BLOB NOT NULL,

        created_at    DATETIME NOT NULL DEFAULT(STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
        
        CONSTRAINT  ent_events_pk PRIMARY KEY (entity_id, entity_type, version, event_type)
    )
  }
  );

  $db->do(
    q{
    CREATE TABLE IF NOT EXISTS ent_current (
        entity_id     BINARY(16)       NOT NULL,
        entity_type   BINARY(32)       NOT NULL,
        version       INTEGER UNSIGNED NOT NULL,
    
        entity_blob   BLOB NOT NULL,
    
        state         TEXT(1) NOT NULL,

        CONSTRAINT ent_current_pk PRIMARY KEY (entity_id, entity_type)
    )
  }
  );

  return;
}

1;
