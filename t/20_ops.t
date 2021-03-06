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
my $id = $st->create('chairs', { my => 'chair', legs => 4, material => 'wood' }, { user => 'me' });
ok($id, "created with ID $id");


### Fetch it
$obj = $st->fetch('chairs', $id);
ok($obj, "fetch($id) worked now");
cmp_deeply($obj, { my => 'chair', legs => 4, material => 'wood' });


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


### Make sure denorm is up-to-date
cmp_deeply($st->sql_first('SELECT * FROM chairs'), { entity_id => $id, legs => 4, material => 'wood' }, 'denorm ok');


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


### Update with lock fail
my ($new_version, $error) = $st->update('chairs', $id, { legs => 3, material => 'metal' }, { user => 'other' }, 99);
ok($error, 'got error, as expected');
is($error, 'optimistic_lock_failed', '... expected error');
is($new_version, 1, '... current version as expected');


### Update without fail
($new_version, $error) = $st->update('chairs', $id, { legs => 3, material => 'metal' }, { user => 'other' });
ok(!$error, 'no error');
is($new_version, 2, '... new version as expected, 2');


### Make sure denorm is up-to-date
cmp_deeply($st->sql_first('SELECT * FROM chairs'), { entity_id => $id, legs => 3, material => 'metal' }, 'denorm ok');


### List all events, again
$events = $st->events('chairs', $id);
is(scalar(@$events), 2, 'got correct number of events, again');
cmp_deeply(
  $events,
  [ { entity_type => 'chairs',
      created_at  => ignore(),
      event_meta  => { user => 'me' },
      entity_id   => '1',
      event_type  => 'c',
      version     => 1
    },
    { entity_type => 'chairs',
      created_at  => ignore(),
      event_meta  => { user => 'other' },
      entity_id   => '1',
      event_type  => 'u',
      version     => 2
    },
  ],
  'events looks good'
);


## And we are done...
done_testing();
