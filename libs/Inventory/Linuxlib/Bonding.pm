use strict;
use warnings;

package Inventory::Linuxlib::Bonding;

# Inheritance
use vars qw/@ISA/;

use Inventory::Tools;

our @ISA = qw/Inventory::Tools/;

use File::Basename qw(basename);

sub run
{
  my $class   = shift;
  my $INVOBJ  = shift;

  my $self    = {};

  $self->{INVOBJ} = $INVOBJ;
    
  bless($self, $class);

  foreach (</proc/net/bonding/*>)
  {
    my $current_dev = basename($_);
    my $deviceDriver = $self->{INVOBJ}->GetTarget("C_NET_DEVICEDRIVER", [$current_dev]);
    if( $deviceDriver )
    {
      if ( $deviceDriver eq "bonding")
      {
        $self->parser($current_dev);
      }
    }
  }
}

sub parser
{
  my $self = shift;
  my $current_dev = shift;
  my $from = (caller(0))[3];


  my $valsInHashRef = $self->ReadFile("/proc/net/bonding/" . $current_dev);
  if ($valsInHashRef->{status})
  {
    my $smartValsInHashRef = $self->SmartReader($valsInHashRef->{data}, ":");
    # Get the bonding mode
    if ($smartValsInHashRef->{keyval}->{"Bonding Mode"})
    {
      $self->{INVOBJ}->StoreValue("C_NET_DEVICEBONDINGMODE"
                ,$smartValsInHashRef->{keyval}->{"Bonding Mode"}
                ,$from
                ,[$current_dev]);
    }
    else
    {
      $self->{INVOBJ}->log({
                      tag=>"C_NET_DEVICEBONDINGMODE",
                      tagcomplement=>[$current_dev],
                      msg=>"Althouth $current_dev is a bonding interface we didn't found its bonding mode",
                      from=>$from,
                      status=>0,
                    });
    }

    # Get the bonding status
    if ($smartValsInHashRef->{keyval}->{"MII Status"})
    {
      my $bonding_status = undef;
      if ($smartValsInHashRef->{keyval}->{"MII Status"} eq "up")
      {
        $bonding_status = \1;
      }
      elsif ($smartValsInHashRef->{keyval}->{"MII Status"} eq "down")
      {
        $bonding_status = \0;
      }

      $self->{INVOBJ}->StoreValue("C_NET_LINKSTATUS"
                ,$bonding_status
                ,$from
                ,[$current_dev]);
    }
    else
    {
      $self->{INVOBJ}->log({
                      tag=>"C_NET_LINKSTATUS",
                      tagcomplement=>[$current_dev],
                      msg=>"Althouth $current_dev is a bonding interface we didn't found its bonding status",
                      from=>$from,
                      status=>0,
                    });
    }
  }
  # Unable to read the PROC file to grab information
  else
  {
    $self->{INVOBJ}->log({
                      tag=>"C_NET_DEVICEBONDINGMODE",
                      tagcomplement=>[$current_dev],
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                    });
  }  
}