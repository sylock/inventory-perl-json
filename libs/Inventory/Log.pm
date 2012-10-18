use strict;
use warnings;

package Inventory::Log;

# Get the time
use POSIX qw(strftime);

sub log
{
    my $self = shift;
    my $options = shift;

    if (! defined($self->{logs}) )
    {
        $self->{logs} = {};
    }

    my $message = $options->{msg};


    if (! (defined($options->{target}) or defined($options->{tag})) )
    {
        $self->storeGeneralLog($options);
        return;
    }

    if (! defined($options->{target}) )
    {
        $options->{target} = $self->CompletePathReturnString($options->{tag}
                                                        , $options->{tagcomplement});
    }

    $self->storeTargetLog($options);
    
}

sub storeGeneralLog
{
    my $self = shift;
    my $options = shift;

    my $currentTime = strftime "%Y-%m-%dT%H:%M:%S%z", localtime;

    if (! defined($self->{logs}->{general}) )
    {
        $self->{logs}->{general} = [];
    }

    my $msgHashRef = {   msg=>$options->{msg},
                         timestamp=>$currentTime};

    if ( defined($options->{from}) )
    {
        $msgHashRef->{from} = $options->{from};
    }

    push(@{ $self->{logs}->{general} }, $msgHashRef);
}

sub storeTargetLog
{
    my $self = shift;
    my $options = shift;

    my $currentTime = strftime "%Y-%m-%dT%H:%M:%S%z", localtime;
    my $target = $options->{target};

    if (! defined($self->{logs}->{$target}) )
    {
        $self->{logs}->{$target} = {msgs=>[],status=>\0};
    }

    my $status;
    if ($options->{status})
    {
        $self->{logs}->{$target}->{status} = \1;
        $status = \1;
    }
    else
    {
        $status = \0;
    }

    my $loghash = {
            msg=>$options->{msg},
            function=>$options->{from},
            status=>$status,
            timestamp=>$currentTime,
        };

    push(@{ $self->{logs}->{$target}->{msgs} }, $loghash);
}

1;