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

  __PACKAGE__->register('chairs', '_chairs');
}

1;
