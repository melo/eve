#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib';
use MyStorage;


## Only core types declared
my @types = MyStorage->types();
is(scalar(@types), 1, 'One type defined for now');
cmp_deeply(\@types, ['chairs'], '... the one defined in the MyStorage class declaration');


## No operations for a new type
my $ops = MyStorage->ops_for_type('test');
ok($ops, 'we always get operations');
is(scalar(%$ops), 0, '... but no operations for a brand new type');


## Register a new type
MyStorage->register(
  test => {
    id => sub { return time() },    ## a lousy ID... :)
  }
);


## Operations for the new type are a go
$ops = MyStorage->ops_for_type('test');
is(scalar(keys %$ops), 3, 'Got one operations for the new type');
ok($ops->{id},        '... has a `id` operation');
ok($ops->{marshal},   '... has a default `marshal` operation');
ok($ops->{unmarshal}, '... has a default `unmarshal` operation');


## No types at all
@types = MyStorage->types();
ok(scalar(@types), 'We have types now');
cmp_deeply(\@types, ['chairs', 'test'], '... the test type was created');


## And we are done...
done_testing();
