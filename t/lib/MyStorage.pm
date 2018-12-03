package    ## Hide from PAUSE
  MyStorage;

use strict;
use warnings;
use parent 'X::Storage';

our $master_id_gen = 1;

__PACKAGE__->register(
  'chairs',
  { id => sub { shift; return ($master_id_gen++, @_) }
  }
);

1;
