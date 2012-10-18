use strict;
use warnings;

package Inventory::Linuxlib::CPU;

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

    my $valsInHashRef = $self->ReadFile("/proc/cpuinfo");
    if (! $valsInHashRef->{status})
    {
        $self->{INVOBJ}->log({
                      tag=>"C_CPU",
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                    });
        return;
    }

    my %oneProcessor;

    foreach (@{ $valsInHashRef->{data} })
    {
        if ($_ =~ /^$/)
        {
            if (keys(%oneProcessor) > 0)
            {
                my $cpuname;

                if (defined($oneProcessor{"physical id"}))
                {
                    $cpuname = "cpu" . $oneProcessor{"physical id"};
                }
                else
                {
                    $cpuname = "cpu0";
                }
                if (! $self->{INVOBJ}->GetTarget("C_CPU_THIS", [$cpuname]))
                {
                    if (defined($oneProcessor{"model name"}))
                    {
                        my $model_string = $oneProcessor{"model name"};
                        $model_string =~ s/\s+/ /g;

                        $self->{INVOBJ}->StoreValue("C_CPU_MODEL"
                                            , $model_string
                                            , $from
                                            , [$cpuname]);
                    }
                    if (defined($oneProcessor{"cpu cores"}))
                    {
                        $self->{INVOBJ}->StoreValue("C_CPU_PHYSCORENUMBER"
                                            , $oneProcessor{"cpu cores"}
                                            , $from
                                            , [$cpuname]);
                    }
                    if (defined($oneProcessor{siblings}))
                    {
                        $self->{INVOBJ}->StoreValue("C_CPU_VIRTCORENUMBER"
                                            , $oneProcessor{siblings}
                                            , $from
                                            , [$cpuname]);
                    }
                    if (defined($oneProcessor{"cpu MHz"}))
                    {
                        $self->{INVOBJ}->StoreValue("C_CPU_CLOCK"
                                            , $oneProcessor{"cpu MHz"}
                                            , $from
                                            , [$cpuname]);
                    }
                    %oneProcessor = ();
                }
            }
        }
        else
        {
            (my $left, my $right) = split(":", $_);
            $oneProcessor{$self->Strip($left)} = $self->Strip($right);
        }
    }
}