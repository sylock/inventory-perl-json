use strict;
use warnings;

package Inventory::Mecanism;

# Inheritance
use vars qw/@ISA/;

use Inventory::Tools;
use Inventory::Log;

our @ISA = qw/Inventory::Log              
              Inventory::Tools
              /;

use Module::Load;

sub RunModules
{
  my $self = shift;

  foreach (@{ $self->{modulesMap} }) 
  {
    my $module      = $_->[0];
    my $privileged  = $_->[1];

    # Skip if asked without any privileged method
    if ( ($self->{params}->{disablePrivilegedMethods}) && ($privileged eq "Privileged") )
    {
      next;
    }

    # Try to load the module and log if we cannot
    # If the environement variable "MAKEITCRASH" is set to whatever value
    # then disable the eval to make it crash. It's then easier and faster to see problems
    if ( $ENV{MAKEITCRASH} )
    {
      load $module;
      $module->run($self);
    }
    else
    {
      eval
      {
        load $module;
        $module->run($self);
        1;
      } 
      or do 
      {
        $self->log({msg=>"Refuse to load $module because: $@."});
      };
    }
  }
}

sub CompletePath
{
  my ($self, $path, $items) = @_;
  # Insert the given @$items to replace any undef with them.
  # Using map and ternary to be concise.
  return map {defined $_ ? $_ : shift(@$items) } @$path;
}

sub CompletePathReturnString
{
  my ($self, $tag, $items) = @_;

  my $path = $self->{targetsMap}->{$tag};
  # Insert the given @$items to replace any undef with them.
  # Using map and ternary to be concise.
  return join("->", map {defined $_ ? $_ : shift(@$items) } @$path);
}

sub StoreValue
{

  my $self = shift;
  my ($tag, $value, $from, $optionnal_path_items_list) = @_;

  my $path = $self->{targetsMap}->{$tag};

  if (! defined($path))
  {
    $self->log({from=>$from,
                msg=>"$tag is unknown in our map.",
              });
    return;
  }
  my $leaf = $path->[-1];
  
  my @updated_path = $self->CompletePath($path, $optionnal_path_items_list);

  # Now we create the tree is not already defined and store the value
  # but only if the value is not already set
  my $storeLocation = $self->GetOrCreateTree(\@updated_path);
  if (! defined($storeLocation->{$leaf}))
  {
    $storeLocation->{$leaf} = $value;
    $self->log({target=>join("->", @updated_path),
                status=>1,
                from=>$from,
                msg=>"Stored the value.",
              });
  }
  else
  {
    $self->log({target=>join("->", @updated_path),
                status=>0,
                from=>$from,
                msg=>"Refuse to store the value: it is already set.",
              });  
  }
}

sub GetTarget
{
    my($self, $constant_name, $optionnal_path_items_list) = @_;

    my $rhash = $self->{inventory};
    my @levels = $self->CompletePath( $self->{targetsMap}->{$constant_name}
                                      ,$optionnal_path_items_list);
    foreach my $level (@levels)
    {
       if ( ! defined($rhash->{$level}) )
       {
          return undef;
       }
       # get the ref of the nested hash
       $rhash = $rhash->{$level};
    }
    return $rhash;
}

sub GetOrCreateTree
{
    # The tree is a nested hash ref which is build against the array ref
    # named $levels minus the last element which is the leaf
    my($self, $levels, $rhash) = @_;

    if (! defined($rhash) ) { $rhash = $self->{inventory}; }

    my $index = 0;
    foreach my $level (@{ $levels })
    {
       if ($index == $#{ $levels }) { last; }
       if ( ! defined($rhash->{$level}) )
       {
           # create the nested hash
           $rhash->{$level} = {};
       }
       # get the ref of the nested hash
       $rhash = $rhash->{$level};
       $index +=1;
    }
    return $rhash;
}

sub GetOrCreateTarget
{
    # The tree is a nested hash ref which is build against the array ref
    # named $levels minus the last element which is the leaf
    my($self, $constant_name, $value, $from, $optionnal_path_items_list) = @_;

    my $rhash = $self->{inventory};
    my @levels = $self->CompletePath( $self->{targetsMap}->{$constant_name}
                                      ,$optionnal_path_items_list);
    push(@levels, $value);
    foreach my $level (@levels)
    {
       if ( ! defined($rhash->{$level}) )
       {
           # create the nested hash
           $rhash->{$level} = {};
       }
       # get the ref of the nested hash
       $rhash = $rhash->{$level};
    }
    return $rhash;
}

sub ReturnCustomedCleanInventory
{
  my $self = shift;

  if ($self->{params}->{enableDebug})
    {
        return
        {  
          inventory=>$self->{inventory},
          logs=>$self->{logs}
        };
    }
    else
    {
        my $logs = {};
        # We're not in debug mode so we only give the logs when the general status is "failed".
        # and we always give the "general" logs
        foreach (keys(%{ $self->{logs} }))
        {
            if ( $_ eq "general" or ${ $self->{logs}->{$_}->{status} } == 0 )
            {
                $logs->{$_} = $self->{logs}->{$_};
            }
        }

        return
        {  
          inventory=>$self->{inventory},
          logs=>$logs
        };   
    }
}

1;