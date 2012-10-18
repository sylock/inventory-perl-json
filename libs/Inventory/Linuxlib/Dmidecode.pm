use strict;
use warnings;

package Inventory::Linuxlib::Dmidecode;

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
    if (! $self->parser() )
    {
        return;
    }
    $self->HardwareVendor();
    $self->HardwareModel();
    $self->HardwareSerial();
    $self->HardwareProductNumber();
}

sub parser
{
    my $self = shift;
    my $from = (caller(0))[3];

    my $valsInHashRef = $self->Sudo("dmidecode");
    if (! $valsInHashRef->{status})
    {
        $self->{INVOBJ}->log({
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                    });

        # don't remove the return since ->run need to know the status of the parser
        return 0;
    }

    my %dmiData;
    my @oneBlock;
    foreach (@{ $valsInHashRef->{data} })
    {
        if ($_ =~ m/Handle/)
        {
            my $blockType = "none";
            foreach my $blockLine (@oneBlock)
            {
                if ($blockLine =~ m/^Handle/) { next;}
                if ($blockType eq "system")
                {
                    if ($blockLine =~ m/:/)
                    {
                        my ($left, $right) = split(":", $blockLine);
                        $self->{dmidecode}->{$self->Strip($left)} = $self->Strip($right);
                    }
                }             
                if ($blockLine =~ m/System Information/) { $blockType = "system"; }
            }
            @oneBlock = ();
        }
        else
        {
            push(@oneBlock, $_);
        }
    }
    # don't remove the return since ->run need to know the status of the parser
    return 1;
}

sub HardwareVendor
{
    my $self = shift;
    my $from = (caller(0))[3];
    
    if ($self->{dmidecode}->{Manufacturer})
    {
        $self->{INVOBJ}->StoreValue("C_HWVENDOR"
                                    , $self->{dmidecode}->{Manufacturer}
                                    , $from);

    }
    else
    {
        $self->{INVOBJ}->log({
                        tag=>"C_HWVENDOR"
                        , msg=>"Although dmidecode is available Manufacturer can't be found."
                        , from=>$from
                        , status=>0
                    });
    }
}

sub HardwareModel
{
    my $self = shift;
    my $from = (caller(0))[3];

    
    
    if ($self->{dmidecode}->{"Product Name"})
    {
        $self->{INVOBJ}->StoreValue("C_HWMODEL"
                                    , $self->{dmidecode}->{"Product Name"}
                                    , $from);
    }
    else
    {
        $self->{INVOBJ}->log({
                        tag=>"C_HWMODEL"
                        , msg=>"Although dmidecode is available \"Product Name\" can't be found."
                        , from=>$from
                        , status=>0
                    });
    }
}

sub HardwareSerial
{
    my $self = shift;
    my $from = (caller(0))[3];
    
    if ($self->{dmidecode}->{"Serial Number"})
    {
        $self->{INVOBJ}->StoreValue("C_HWSERIAL"
                                    , $self->{dmidecode}->{"Serial Number"}
                                    , $from);
    }
    else
    {
        $self->{INVOBJ}->log({
                        tag=>"C_HWSERIAL"
                        , msg=>"Although dmidecode is available \"Serial Number\" can't be found."
                        , from=>$from
                        , status=>0
                    });
    }
}

sub HardwareProductNumber
{
    my $self = shift;
    my $from = (caller(0))[3];

    if (    $self->{dmidecode}->{"SKU Number"} 
        and 
            ($self->{dmidecode}->{"SKU Number"} ne "Not Specified")
        )
    {
        $self->{INVOBJ}->StoreValue("C_HWPRODUCTNUMBER"
                                    , $self->{dmidecode}->{"SKU Number"}
                                    , $from);
    }
    else
    {
        $self->{INVOBJ}->log({
                        tag=>"C_HWPRODUCTNUMBER"
                        , msg=>"Although dmidecode is available \"Product Number\" can't be found."
                        , from=>$from
                        , status=>0
                    });
    }
}

1;
