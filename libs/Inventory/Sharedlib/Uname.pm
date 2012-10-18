use strict;
use warnings;

package Inventory::Sharedlib::Uname;

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

    bless($self, $class);

    $self->kernel_version();
    $self->kernel_arch();
}

sub kernel_version
{
    my $self = shift;
    my $from = (caller(0))[3];
    
    my $valsInHashRef = $self->Execute("uname -r");
    if ($valsInHashRef->{status})
    {
        my $kernel_version = $self->Strip($valsInHashRef->{data}->[0]);
        $self->{INVOBJ}->StoreValue("C_KERNEL_VER", $kernel_version, $from);
    }
    else
    {
        $self->{INVOBJ}->log({
                        tag=>"C_KERNEL_VER",
                        msg=>$valsInHashRef->{errmsg},
                        from=>$from,
                        status=>0,
                    });
    }
}

sub kernel_arch
{
    my $self = shift;
    my $from = (caller(0))[3];

    my $valsInHashRef = $self->Execute("uname -m");
    if ($valsInHashRef->{status})
    {
        my $kernel_arch = $self->Strip($valsInHashRef->{data}->[0]);
        $self->{INVOBJ}->StoreValue("C_KERNEL_ARCH", $kernel_arch, $from);
    }
    else
    {
        $self->{INVOBJ}->log({
                        tag=>"C_KERNEL_ARCH",
                        msg=>$valsInHashRef->{errmsg},
                        from=>$from,
                        status=>0,
                    });
    }
}

1;