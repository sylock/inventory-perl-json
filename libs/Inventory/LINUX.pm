use strict;
use warnings;

package Inventory::LINUX;

# Inheritance
use vars qw/@ISA/;

use Inventory::Mecanism;

our @ISA = qw/Inventory::Mecanism/;

# Import targets;
use Inventory::Datamodel;

sub run
{
    my ($class, %params) = @_;
    my $self = {};

    $self->{targetsMap} = Inventory::Datamodel->getTargets();
    $self->{remainingTargets} = [ keys( %{ $self->{targetsMap} } ) ];
    $self->{modulesMap} = defineModules();
    $self->{params} = \%params;
    $self->{inventory} = {};
    bless($self, $class);

    # Start the inventory process here
    $self->log({msg=>"Starting the inventory process."});
    $self->RunModules();

    return $self->ReturnCustomedCleanInventory();
}

sub defineModules
{
    # Here it the list of things to launch. Each will grab some data
    # and will populate the inventory hash through the StoreValue below
    # So they all require the current object as argument
    my $modulesMap =
    [
        # The order may be of importance since some module are based on data already acquired and stored
        ["Inventory::Linuxlib::Simple",                  "Mixed"         ],
        ["Inventory::Sharedlib::Uname",                  "nonPrivileged" ],
        ["Inventory::Linuxlib::Dmidecode",               "Privileged"    ],
        ["Inventory::Linuxlib::OsEtc",                   "nonPrivileged" ],
        ["Inventory::Linuxlib::Network",                 "nonPrivileged" ],
        # Ethtool needs to be executed after Network since it needs C_NET to be already populated
        ["Inventory::Linuxlib::Ethtool",                 "Privileged"    ],
        ["Inventory::Linuxlib::Bonding",                 "nonPrivileged" ],
        ["Inventory::Linuxlib::CPU",                     "nonPrivileged" ],
        ["Inventory::Linuxlib::Storage",                 "nonPrivileged" ],
        ["Inventory::Linuxlib::Powerpath",               "Privileged"    ],
        ["Inventory::Linuxlib::HBA",                     "nonPrivileged" ],        
    ];

    return $modulesMap;
}

1;

__DATA__

        ["Inventory::Linuxlib::Partitions",              "nonPrivileged"    ],
        ["Inventory::Linuxlib::Mounts",                  "nonPrivileged"    ],
        ["Inventory::Linuxlib::LVM",                     "Privileged"    ],
        ["Inventory::Linuxlib::ASM",                     "Privileged"    ],
        ["Inventory::Linuxlib::Nfs",                     "nonPrivileged" ],
        