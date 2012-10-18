use strict;
use warnings;

package Inventory::Linuxlib::HBA;

# Inheritance
use vars qw/@ISA/;

use Inventory::Tools;

our @ISA = qw/Inventory::Tools/;

use File::Basename qw(basename);
use File::Spec::Functions qw(rel2abs catfile);

sub run
{
    my $class   = shift;
    my $INVOBJ  = shift;

    my $self    = {};

    $self->{INVOBJ} = $INVOBJ;

    bless($self, $class);

    # We start populating and grabbing the information
    $self->parser();
    foreach (keys(%{ $self->{hba} }))
    {
      $self->getPortState($_);
      $self->getSpeed($_);           
      $self->getWWN($_);
      $self->getHbaDescription($_);
      $self->getDevs($_);
    }
}

sub parser
{
  my $self = shift;
  my $from = (caller(0))[3];

  # There is no HBA on the server
  if ( ! -e "/sys/class/fc_host")
  {
    return;
  }

  foreach (</sys/class/fc_host/*>)
  {
    $self->{hba}->{basename($_)} = $_;

  }
}

sub getPortState
{
  my ($self, $device) = @_;
  my $from = (caller(0))[3];

  my $valsInHashRef = $self->ReadFile(catfile($self->{hba}->{$device}
                                              , "port_state"));
  if (! $valsInHashRef->{status})
  {
    $self->{INVOBJ}->log({
                      tag=>"C_STOR_HBA_PORTSTATE",
                      tagcomplement=>[$device],
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                      });
    return;
  }
  my $state = $self->Strip($valsInHashRef->{data}->[0]);
  if ($state)
  {
    if ($state eq "Linkdown")
    {
      $state = \0;
    }
    else
    {
      $state = \1; 
    }
    $self->{INVOBJ}->StoreValue("C_STOR_HBA_PORTSTATE", $state, $from, [$device]); 
  }
}

sub getSpeed
{
  my ($self, $device) = @_;
  my $from = (caller(0))[3];

  my $dev_port_state = $self->{INVOBJ}->GetTarget("C_STOR_HBA_PORTSTATE",[$device]);

  # If link is down we won't try to get its speed!
  if ( (! $dev_port_state) or $$dev_port_state == 0 )
  {
    return;
  }

  my $valsInHashRef = $self->ReadFile(catfile($self->{hba}->{$device}
                                              , "speed"));
  if (! $valsInHashRef->{status})
  {
    $self->{INVOBJ}->log({
                      tag=>"C_STOR_HBA_PORTSPEED",
                      tagcomplement=>[$device],
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                      });
    return;
  }
  my $speed = $self->Strip($valsInHashRef->{data}->[0]);
  if ($speed) { $self->{INVOBJ}->StoreValue("C_STOR_HBA_PORTSPEED", $speed, $from, [$device]) };
}

sub getWWN
{
  my ($self, $device) = @_;
  my $from = (caller(0))[3];

  my $valsInHashRef = $self->ReadFile(catfile($self->{hba}->{$device}
                                              , "port_name"));
  if (! $valsInHashRef->{status})
  {
    $self->{INVOBJ}->log({
                      tag=>"C_STOR_HBA_WWN",
                      tagcomplement=>[$device],
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                      });
    return;
  }
  my $wwn = $self->Strip($valsInHashRef->{data}->[0]);
  if ($wwn)
  {
    $wwn =~ s/0x//;
    $self->{INVOBJ}->StoreValue("C_STOR_HBA_WWN", $wwn, $from, [$device]);
  }
}

sub getHbaDescription
{
  my ($self, $device) = @_;
  my $from = (caller(0))[3];

  my $path = "/sys/class/scsi_host/$device/modeldesc";
  my $valsInHashRef = $self->ReadFile($path);
  if (! $valsInHashRef->{status})
  {
    $self->{INVOBJ}->log({
                      tag=>"C_STOR_HBA_DESCR",
                      tagcomplement=>[$device],
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                      });
    return;
  }
  my $name = $self->Strip($valsInHashRef->{data}->[0]);
  if ($name) { $self->{INVOBJ}->StoreValue("C_STOR_HBA_DESCR", $name, $from, [$device]) };
}

sub getDevs
{
  my ($self, $device) = @_;
  my $from = (caller(0))[3];

  # cd $path/device ; find rport* -regex ".*block" -exec ls {} \;
  my $path = catfile($self->{hba}->{$device}, "device");
  my $cmd = "cd "
            . $path
            . ' ; find rport* -regex ".*block" -exec ls {} \;|';

  my $valsInHashRef = $self->ReadFile($cmd);

  if (! $valsInHashRef->{status})
  {
    $self->{INVOBJ}->log({
                      tag=>"C_STOR_HBA_DEVPROVIDED",
                      tagcomplement=>[$device],
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                      });
    return;
  }

  my @devs;
  foreach (@{ $valsInHashRef->{data} })
  {
    push(@devs, $self->Strip($_));
  }
  if ($#devs > 0)
  {
    $self->{INVOBJ}->StoreValue("C_STOR_HBA_DEVPROVIDED", \@devs, $from, [$device]);
  }

}