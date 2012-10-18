use strict;
use warnings;

package Inventory::Tools;

use IPC::Open3;
use POSIX ':sys_wait_h';
use File::Spec;

sub ReadFile
{
    my ($self, $file) = @_;
    if (open(my $fh, $file))
    {
        chomp(my @content = <$fh>);
        # get the return code of the close (get the exit code of the command
        # if we opened a command instead of a file
        if (close $fh)
        {
            return {status=>1, data=>\@content};
        }
        else
        {
            return {status=>0, errmsg=>$! . " when trying to open $file in " . (caller(0))[3]};
        }
    }
    else
    {
        return {status=>0, errmsg=>$! . " when trying to open $file in " . (caller(0))[3]};
    }
}

sub Execute
{
    # Execute is a safe way to execute a command and give back its output. It is safe because if has a timeout
    # so even if the command is hanging or is waiting for a user input, the all perl script won't be blocked.
    # That command will just fail after the timeout and the workflow can continue.
    # It also checks the availability of the command before launching it.
    my ($self, $full_cmd) = @_;

    my $timeout = 10; # default timeout of 10 seconds. The longer execution is the local package listing
    my $elapsed_time;
    my $return_code;
    my $kid;
    my $error_message;

    my @split_cmd = split(" ", $full_cmd);
    my $full_path = $self->Which($split_cmd[0]);
    
    if (! $full_path)
    { return {  status=>0
                , errmsg=>"$split_cmd[0] not found in \$PATH in " 
                . (caller(0))[3]};
    }
    if (! -x $full_path)
    { return {  status=>0
                , errmsg=>"Don't have the rights to execute $full_path in "
                . (caller(0))[3]};}   

    # Launch the command
    my $pid = open3(undef, my $f_out, undef, $full_cmd);

    # Here is the loop to wait for the execution to be done or exit after the timeout
    my $start = time();
    do
    {
        $elapsed_time = time() - $start;
        $kid = waitpid($pid, WNOHANG);
        $return_code = $?;
        $error_message = $!;
    }
    until ( (time() - $start) > $timeout or $kid > 0 );

    # Check if we reached the timeout so we have to kill the process
    if ( (kill(0, $pid)) > 0)
    {
        kill(9, $pid);
        return {    status=>0
                    , errmsg=>"Reached timeout of $timeout sec when executing $full_cmd in "
                    . (caller(0))[3] };
    }

    # The execution is successfull and faster than the timeout
    if ($return_code == 0)
    {
        chomp(my @content = <$f_out>);
        return {status=>1, data=>\@content};
    }
    else
    {
        my $message = "Error when executing \"$full_cmd\" in " . (caller(0))[3] . " - Exit code: " .
                      $return_code . " - Error message: " .  $error_message;
        return {status=>0, errmsg=>$message};
    }
}

sub Strip
{
    my ($self, $given_string) = @_;
    if ($given_string)
    {
        $given_string =~ s/^\s+//;
        $given_string =~ s/\s+$//;
        return $given_string;
    }
}

sub Which
{
    # Search in PATH if the command exist and returns its absolute path
    my ($self, $cmd) = @_;
    my @path = split(":", $ENV{PATH});
    my $full_path;
    foreach (@path)
    {
        $full_path = File::Spec->catfile($_, $cmd);
        if ( -e $full_path ) {return $full_path;}
    }
    return 0;
}

sub Sudo
{
    my ($self, $given_cmd) = @_;
    my $sudo_cmd;

    if (! defined($self->{params}->{sudo}))
    {
        $sudo_cmd = "echo ' ' | sudo -S";
        my $valsInHashRef = $self->Execute("sudo -h");
        if ($valsInHashRef->{status})
        {
            foreach (@{ $valsInHashRef->{data} })
            {
                if ( ($_ =~ m/\s+-n/) || ($_ =~ m/\[-\w*n\w*\]/) )
                {
                    $sudo_cmd = "sudo -n";
                    last;
                }
            }
            $self->{params}->{sudo} = $sudo_cmd;
        }
        else
        {
            return {status=>0, errmsg=>$valsInHashRef->{errmsg} . " in " . (caller(0))[3]};
        }
    }
    my $full_cmd = $self->{params}->{sudo} . " " . $given_cmd;

    # Little hack since dmidecode hang when executed with
    # "open3". Don't hang with "open" so use our ReadFile sub
    my $valsInHashRef;
    if ($full_cmd =~ m/dmidecode/) { $valsInHashRef = $self->ReadFile($full_cmd . "|"); }
    else { $valsInHashRef = $self->Execute($full_cmd);}

    if ($valsInHashRef->{status}) { return {status=>1, data=>$valsInHashRef->{data}}; }
    else { return {status=>0, errmsg=>$valsInHashRef->{errmsg} . " in " . (caller(0))[3]}; }
}

sub SmartReader
{
    # Generic parser usefull with much files. It takes as argument an array (typically comming from an "open")
    # and a separator. It split and places all lines that contains the separator into the "keyval" hash
    # everything else is put in an array named "strings"
    my ($self, $contentArrayRef, $separator) = @_;
    my @found_strings;
    my %organized_data;

    if ( ! defined($separator) ) { $separator = "="; }

    foreach (@$contentArrayRef)
    {
        if ( $_ =~ /$separator/ )
        {
            (my $left, my $right) = split($separator, $_);
            $organized_data{$self->Strip($left)} = $self->Strip($right);
        }
        else
        {
            push(@found_strings, $self->Strip($_));
        }
    }
    return {strings=>\@found_strings, keyval=>\%organized_data};
}

1;