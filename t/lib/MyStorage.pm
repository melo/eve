package    ## Hide from PAUSE
  MyStorage;

use strict;
use warnings;
use parent 'X::Storage';


#### Chairs type

{
  our $master_id_gen = 1;

  sub _chairs_id {
    my ($type, @rest) = @_;
    return ($master_id_gen++, @rest);
  }

  sub _chairs_before {
    my ($driver, $op, $blob, $meta) = @_;

    if ($op eq 'create') {
      $driver->sql_insert('chairs', { entity_id => $meta->{id}, legs => $blob->{legs}, material => $blob->{material} });
    }
    elsif ($op eq 'update') {
      $driver->sql_update(
        'chairs',
        { legs      => $blob->{legs}, material => $blob->{material} },
        { entity_id => $meta->{id} }
      );
    }

    return;
  }

  sub _chairs_deploy {
    my ($driver) = @_;

    $driver->sql_do('
      CREATE TABLE IF NOT EXISTS chairs (
          entity_id     BINARY(16)       NOT NULL,
          legs          INTEGER          NOT NULL,
          material      TEXT(200)        NOT NULL,
  
          CONSTRAINT chairs_pk PRIMARY KEY (entity_id)
      )
    ');
  }
  __PACKAGE__->register('chairs', '_chairs');
}

1;
