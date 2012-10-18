use strict;
use warnings;

package Inventory::Linuxlib::OsEtc;

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
    $self->parser();
}

sub parser
{
    my $self = shift;
    my $from = (caller(0))[3];
    
    my $os = "Linux";
    my $distrib;
    my $majorVersion;
    my $minorVersion;

    if ( -e "/etc/SuSE-release")
    {
        my $valsInHashRef = $self->ReadFile("/etc/SuSE-release");
        $valsInHashRef = $self->SmartReader($valsInHashRef->{data}, "=");

        if ( $valsInHashRef->{strings}->[0] =~ /^SUSE/ ) { $distrib = "SLES"; }
        elsif ( $valsInHashRef->{strings}->[0] =~ /^openSUSE/ ) { $distrib = "openSUSE"; }

        $majorVersion = $valsInHashRef->{keyval}->{VERSION};
        $minorVersion = $valsInHashRef->{keyval}->{PATCHLEVEL};
    }
    elsif ( -e "/etc/redhat-release" )
    {
        $distrib = "RHEL";
        my $valsInHashRef = $self->ReadFile("/etc/redhat-release");
        $valsInHashRef = $self->SmartReader($valsInHashRef->{data}, "=");

        $valsInHashRef->{strings}->[0] =~ /release\s(\d+)[\.\s]/;
        $majorVersion = $1;

        if ($majorVersion < 5)
        {
            $valsInHashRef->{strings}->[0] =~ /Update\s(\d+)/;
            $minorVersion = $1;
        }
        else
        {
            $valsInHashRef->{strings}->[0] =~ /release\s\d+\.(\d+)/;
            $minorVersion = $1;
        }
    }
    elsif ( -e "/etc/lsb-release" )
    {
        my $valsInHashRef = $self->ReadFile("/etc/lsb-release");
        $valsInHashRef = $self->SmartReader($valsInHashRef->{data}, "=");

        $distrib = $valsInHashRef->{keyval}->{DISTRIB_ID};
        $valsInHashRef->{keyval}->{DISTRIB_RELEASE} =~ /^([0-9]*)\.([0-9]*)$/;
        $majorVersion = $1;
        $minorVersion = $2;
    }
    elsif ( -e "/etc/arch-release")
    {
        $distrib = "ArchLinux";
    }

    if (defined($distrib))
    {
        $self->{INVOBJ}->StoreValue("C_OS_FAMILY", $os, $from);
        $self->{INVOBJ}->StoreValue("C_OS_DISTRIB", $distrib, $from);
        
        if (defined($majorVersion)) { $self->{INVOBJ}->StoreValue("C_OS_MAJVER", $majorVersion, $from); }
        if (defined($minorVersion)) { $self->{INVOBJ}->StoreValue("C_OS_MINVER", $minorVersion, $from); }
    }
    else
    {
        $self->{INVOBJ}->StoreValue("C_OS_FAMILY", $os, $from);
        $self->{INVOBJ}->log({
                      tag=>"C_OS_DISTRIB",
                      msg=>"Unknown Distribution!",
                      from=>$from,
                      status=>0,
                    });
    }
}