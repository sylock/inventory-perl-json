use strict;
use warnings;

package Inventory::Linuxlib::Ethtool;

# Inheritance
use vars qw/@ISA/;

use Inventory::Tools;

our @ISA = qw/Inventory::Tools/;

sub run
{
    my $class   = shift;
    my $INVOBJ  = shift;

    my $self    = {};

    $self->{INVOBJ} = $INVOBJ;
    my @net_devs = keys(%{ $self->{INVOBJ}->GetTarget("C_NET_DEVS") } ) ;
    foreach (@net_devs)
    {
        $self->{netdevs}->{$_} = {};
    }
    
    bless($self, $class);

    $self->parser();
    
    foreach my $current_dev (keys(%{ $self->{netdevs} }) )
    {
        $self->DeviceDriver($current_dev);
        $self->NetLinkStatus($current_dev);

        # Only grab these data if the device have a link UP!
        if ($self->{INVOBJ}->GetTarget("C_NET_LINKSTATUS", [$current_dev]) )
        {
            if (${ $self->{INVOBJ}->GetTarget("C_NET_LINKSTATUS", [$current_dev]) } == 1)
            {
                $self->NetLinkSpeed($current_dev);
                $self->NetLinkMode($current_dev);
            }
        }
    }
    
}

sub parser
{
    my $self = shift;
    my $from = (caller(0))[3];

    my $generalEthtoolValsInHashRef = {};
    my $driverEthtoolValsInHashRef = {};
    $generalEthtoolValsInHashRef->{keyval} = {};
    $driverEthtoolValsInHashRef->{keyval} = {};

    foreach my $current_dev (keys(%{ $self->{netdevs} }) )
    {
        my $valsInHashRef1 = $self->Sudo("ethtool " . $current_dev);
        my $valsInHashRef2 = $self->Sudo("ethtool -i $current_dev");

        # Check if everything is OK. If not we return and basta.
        if ($valsInHashRef1->{status})
        {
            $generalEthtoolValsInHashRef = $self->SmartReader($valsInHashRef1->{data}, ":");
        }
        else
        {
            $self->{INVOBJ}->log({
                      tag=>"C_NET_LINKSTATUS",
                      tagcomplement=>[$current_dev],
                      msg=>$valsInHashRef1->{errmsg},
                      from=>$from,
                      status=>0,
                    });
            $self->{INVOBJ}->log({
                      tag=>"C_NET_LINKSPEED",
                      tagcomplement=>[$current_dev],
                      msg=>$valsInHashRef1->{errmsg},
                      from=>$from,
                      status=>0,
                    });
            $self->{INVOBJ}->log({
                      tag=>"C_NET_LINKMODE",
                      tagcomplement=>[$current_dev],
                      msg=>$valsInHashRef1->{errmsg},
                      from=>$from,
                      status=>0,
                    });
        }

        if ($valsInHashRef2->{status})
        {
            $driverEthtoolValsInHashRef = $self->SmartReader($valsInHashRef2->{data}, ":");
        }
        else
        {
            $self->{INVOBJ}->log({
                      tag=>"C_NET_DEVICEDRIVER",
                      tagcomplement=>[$current_dev],
                      msg=>$valsInHashRef2->{errmsg},
                      from=>$from,
                      status=>0,
                    });
        }

        # Store the union of the  two ethtool commands
        $self->{netdevs}->{$current_dev} = {
                            %{ $generalEthtoolValsInHashRef->{keyval} }
                            ,%{ $driverEthtoolValsInHashRef->{keyval} }
                        };
    }
}

sub NetLinkStatus
{
    my ($self, $current_dev) = @_;
    my $from = (caller(0))[3];
    
    if (defined($self->{netdevs}->{$current_dev}->{"Link detected"}) )
    {
        my $linkstatus = $self->{netdevs}->{$current_dev}->{"Link detected"};

        if ($linkstatus eq "yes")
        {
            $linkstatus = \1;
        }
        else
        {
            $linkstatus = \0;
        }
        $self->{INVOBJ}->StoreValue("C_NET_LINKSTATUS", $linkstatus, $from, [$current_dev]);
    }
    else
    {
        $self->{INVOBJ}->log({
                      tag=>"C_NET_LINKSTATUS",
                      tagcomplement=>[$current_dev],
                      msg=>"Althouth ethtool is available the link status was not found",
                      from=>$from,
                      status=>0,
                    });
    }
}

sub NetLinkSpeed
{
    my ($self, $current_dev) = @_;
    my $from = (caller(0))[3];
    
    if (defined($self->{netdevs}->{$current_dev}->{Speed}) )
    {
        my $linkSpeed = $self->{netdevs}->{$current_dev}->{Speed};
        if ($linkSpeed =~ m/(\d+)/)
        {
            $self->{INVOBJ}->StoreValue("C_NET_LINKSPEED", $1, $from, [$current_dev]);
        }
        else
        {
            $self->{INVOBJ}->log({
                      tag=>"C_NET_LINKSTATUS",
                      tagcomplement=>[$current_dev],
                      msg=>"Althouth ethtool is available the link speed value is unrecognized: \"$linkSpeed\"",
                      from=>$from,
                      status=>0,
                    });
        }
    }
    else
    {
        $self->{INVOBJ}->log({
                      tag=>"C_NET_LINKSPEED",
                      tagcomplement=>[$current_dev],
                      msg=>"Althouth ethtool is available the link speed was not found",
                      from=>$from,
                      status=>0,
                    });
    }
}

sub NetLinkMode
{
    my ($self, $current_dev) = @_;
    my $from = (caller(0))[3];
    
    if (defined($self->{netdevs}->{$current_dev}->{Duplex}) )
    {
        my $linkMode = $self->{netdevs}->{$current_dev}->{Duplex};        
        $self->{INVOBJ}->StoreValue("C_NET_LINKMODE", $linkMode, $from, [$current_dev]);
    }
    else
    {
        $self->{INVOBJ}->log({
                      tag=>"C_NET_LINKMODE",
                      tagcomplement=>[$current_dev],
                      msg=>"Althouth ethtool is available the link mode was not found",
                      from=>$from,
                      status=>0,
                    });
    }
}

sub DeviceDriver
{
    my ($self, $current_dev) = @_;
    my $from = (caller(0))[3];
    
    if (defined($self->{netdevs}->{$current_dev}->{driver}) )
    {
        my $devDriver = $self->{netdevs}->{$current_dev}->{driver};        
        $self->{INVOBJ}->StoreValue("C_NET_DEVICEDRIVER", $devDriver, $from, [$current_dev]);
    }
    else
    {
        $self->{INVOBJ}->log({
                      tag=>"C_NET_DEVICEDRIVER",
                      tagcomplement=>[$current_dev],
                      msg=>"Althouth ethtool is available the driver name was not found",
                      from=>$from,
                      status=>0,
                    });
    }
}

1;