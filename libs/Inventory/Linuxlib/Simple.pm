use strict;
use warnings;

package Inventory::Linuxlib::Simple;

# Inheritance
use vars qw/@ISA/;

use Inventory::Tools;
use Inventory::Sharedlib::Simple;

our @ISA = qw/Inventory::Tools
              Inventory::Sharedlib::Simple
              /;

sub run
{
    my $class   = shift;
    my $INVOBJ  = shift;

    my $self    = {};
    $self->{functionMaps} = defineFunctionsMap();
    $self->{INVOBJ} = $INVOBJ;

    bless($self, $class);
    # jobLauncher is defined in Inventory::Sharedlib::Simple.
    # It was placed there to be reused on other platforms.
    $self->jobLauncher();
}

sub defineFunctionsMap
{
    my $functionsMap =
        [
            ["C_UPTIME",
                [
                    ["UptimeProc",                  "nonPrivileged" ],
                ],
            ],
            ["C_HOSTNAME",
                [
                    ["HostnameProc",                "nonPrivileged" ],
                ],
            ],
            ["C_HWVENDOR",
                [     
                    ["HardwareVendorSys",           "nonPrivileged" ],                 
                    ["HardwareVendorCciss",         "nonPrivileged" ],
                ],
            ],
            ["C_HWTYPE",
                [
                    ["HardwareTypeVendor",          "nonPrivileged"],
                ],
            ],
            ["C_HWSERIAL",
                [
                    ["HardwareSerialSys",           "Privileged"],
                ],
            ],
            ["C_MEMORY",
                [
                    ["MemoryProc",                  "nonPrivileged"],
                ],
            ],
            ["C_USERS",
                [
                    ["UsersPasswd",                 "nonPrivileged"],
                ],
            ],
            ["C_GROUPS",
                [
                    ["GroupsGroup",                 "nonPrivileged"],
                ],
            ],
            ["C_PACKAGES",
                [
                    ["PackageList",                 "nonPrivileged"],
                ],
            ],
        ];

    return $functionsMap;
}

sub UptimeProc
{
    my $self = shift;
    my $valsInHashRef = $self->ReadFile("/proc/uptime");
    if ($valsInHashRef->{status})
    {
        my $uptime = int($self->Strip((split(' ', $valsInHashRef->{data}->[0]))[1]));
        return {status=>1,data=>$uptime,funcname=>(caller(0))[3] };
    }
    else
    {
        return {status=>0,errmsg=>$valsInHashRef->{errmsg},funcname=>(caller(0))[3] };
    }
}

sub HostnameProc
{
    my $self = shift;
    my $valsInHashRef = $self->ReadFile("/proc/sys/kernel/hostname");
    if ($valsInHashRef->{status})
    {
        my $hostname = $self->Strip($valsInHashRef->{data}->[0]);
        # Regex commented out because after thinking about it it is preferable to report
        # the exact value as found in the system without any modifications
        # The regex below take only the host part when the hostname is a FQDN
        #$hostname =~ s/(^\w+)\..*$/$1/;
        return {status=>1,data=>$hostname,funcname=>(caller(0))[3] };
    }
    else
    {
        return {status=>0,errmsg=>$valsInHashRef->{errmsg},funcname=>(caller(0))[3] };   
    }
}

sub HardwareVendorSys
{
    my $self = shift;
    my $valsInHashRef = $self->ReadFile("/sys/devices/virtual/dmi/id/sys_vendor" );
    if ($valsInHashRef->{status})
    {
        my $vendor = $self->Strip($valsInHashRef->{data}->[0]);
        return {status=>1,funcname=>(caller(0))[3],data=>$vendor} ;
    }
    else
    {
        return {status=>0,errmsg=>$valsInHashRef->{errmsg},funcname=>(caller(0))[3] };
    }
}

sub HardwareVendorCciss
{
    my $self = shift;
    my $valsInHashRef = $self->Execute('find /sys/devices/pci* -regex ".*cciss.*/.*/vendor" -exec cat {} \;');
    if ($valsInHashRef->{status})
    {
        if (defined($valsInHashRef->{data}->[0]))
        {
            my $vendor = $self->Strip($valsInHashRef->{data}->[0]);
            return {status=>1,funcname=>(caller(0))[3],data=>$vendor} ;
        }
        else
        {
            return {status=>0
                    ,errmsg=>"Unable to grab any information with cciss."
                    ,funcname=>(caller(0))[3] };
        }
        
    }
    else
    {
        return {status=>0,errmsg=>$valsInHashRef->{errmsg},funcname=>(caller(0))[3] };
    }
}

sub HardwareTypeVendor
{
    my $self = shift;
    my $type = "physical";
    my @virtuals = ( "vmware", "xen", "innotek gmbh" );

    my $hwvendor = $self->{INVOBJ}->GetTarget("C_HWVENDOR");

    if (! defined($hwvendor) )
    {
        return {status=>0
                ,errmsg=>"Problem since \"C_HWVENDOR\" is not defined\""
                ,funcname=>(caller(0))[3]};
    }

    foreach (@virtuals)
    {
        if ( $hwvendor =~ /$_/i  )
        {
            $type = "virtual";
            last;
        }
    }
    return {status=>1,funcname=>(caller(0))[3],data=>$type};
}

sub HardwareSerialSys
{
    my $self = shift;
    my $serial;
    my $valsInHashRef = $self->Sudo("cat /sys/devices/virtual/dmi/id/product_serial");

    if ($valsInHashRef->{status})
    {
        my $serial = $self->Strip($valsInHashRef->{data}->[0]);
        return {status=>1,funcname=>(caller(0))[3],data=>$serial} ;
    }
    else
    {
        return {status=>0,errmsg=>$valsInHashRef->{errmsg},funcname=>(caller(0))[3] };
    }
}

sub MemoryProc
{
    my $self = shift;
    my $valsInHashRef = $self->ReadFile("/proc/meminfo");
    $valsInHashRef = $self->SmartReader($valsInHashRef->{data}, ":");

    if ($valsInHashRef->{keyval}->{MemTotal})
    {
        my $memTotal = $valsInHashRef->{keyval}->{MemTotal};
        # Remove "Kb"
        $memTotal = (split(" ", $memTotal))[0];
        # Convert value into bytes
        $memTotal *= 1024;
        return {status=>1,funcname=>(caller(0))[3],data=>$self->Strip($memTotal)};
    }
    else
    {
        return {status=>0
                ,errmsg=>"MemTotal was not found by the regex in /proc/meminfo"
                ,funcname=>(caller(0))[3]};
    }
}

sub PackageList
{
    my $self = shift;
    my $from = (caller(0))[3];

    my $cmd;
    my $sep;
    if ($self->Which("rpm") )
    {
        $cmd = 'rpm -qa --qf "%{NAME}\t%{VERSION}\t%{RELEASE}\t%{ARCH}\n"';
        $sep = '\t';
    }
    elsif ($self->Which("dpkg-query"))
    {
        $cmd = 'dpkg-query -f \'${Package}\t${Version}${Revision}\t${Architecture}\n\' -W';
        $sep = '\t';
    }
    elsif ($self->Which("pacman"))
    {
        $cmd = 'pacman -Q';
        $sep = ' ';
    }
    else
    {
        return {status=>0
                ,errmsg=>"Don't know your package manager."
                ,funcname=>$from};
    }
    my $valsInHashRef = $self->Execute($cmd);
    if ($valsInHashRef->{status})
    {
        my @packages;
        foreach my $package_line ( @{ $valsInHashRef->{data} } )
        {
            my ($name, $version, $arch) = split($sep, $package_line);
            my $packageHashRef = {name=>$name, ver=>$version };
            if ( defined($arch) )
            {
                $packageHashRef->{arch} = $arch;
            }
            push(@packages, $packageHashRef);
        }
        return {status=>1,funcname=>$from,data=>[ sort {$a->{name} cmp $b->{name}} @packages ]};
    }
    else
    {
        return {status=>0,errmsg=>$valsInHashRef->{errmsg},funcname=>$from };
    }
}

1;