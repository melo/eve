#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib';
use MyStorage;

### Setup test scenarios
my $st = MyStorage->connect('dbi:SQLite:dbname=:memory:');
$st->deploy;


### Fetch non-existing ID's
my $obj = $st->fetch('chairs', 'noid');
ok(!$obj, 'no chairs found with ID `noid`');


### Create a new entity
my $id = $st->create('chairs', { my => 'chair' }, { user => 'me' });
ok($id, "created with ID $id");


### Fetch it
$obj = $st->fetch('chairs', $id);
ok($obj, "fetch($id) worked now");
cmp_deeply($obj, { my => 'chair' });


### Fetch it with Meta
my $meta;
($obj, $meta) = $st->fetch('chairs', $id);
ok($obj,  "fetch($id) worked again");
ok($meta, '... and we got meta information');
cmp_deeply(
  $meta,
  { id         => $id,
    type       => 'chairs',
    version    => 1,
    created_at => ignore(),
    event_type => 'c',
    meta       => { user => 'me' },
    state      => 'a',
  }
);


### List all events
my $events = $st->events('chairs', $id);
is(scalar(@$events), 1, 'got correct number of events');
cmp_deeply(
  $events->[0],
  { entity_type => 'chairs',
    created_at  => ignore(),
    event_meta  => { user => 'me' },
    entity_id   => '1',
    event_type  => 'c',
    version     => 1
  },
  'event looks good'
);


## And we are done...
done_testing();
