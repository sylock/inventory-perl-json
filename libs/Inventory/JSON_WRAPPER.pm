#! /usr/bin/env perl

package Inventory::JSON_WRAPPER;

eval
{
     require JSON;
     push @ISA, 'JSON';
     1;
}
or do
{
    require PP;
    push @ISA, 'JSON::PP';
};

1;
