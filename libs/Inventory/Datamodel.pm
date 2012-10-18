use strict;
use warnings;

package Inventory::Datamodel;

our $C_HOSTNAME                         =    "hostname";
our $C_UPTIME                           =    "uptime";
our $C_HW                               =    "hardware";
our $C_HWVENDOR                         =    "sysvendor";
our $C_HWMODEL                          =    "sysmodel";
our $C_HWTYPE                           =    "systype";
our $C_HWSERIAL                         =    "syssn";
our $C_HWPRODUCTNUMBER                  =    "syspn";
our $C_USERS                            =    "users";
our $C_GROUPS                           =    "groups";
our $C_PACKAGES                         =    "packages";
our $C_OS                               =    "os";
our $C_OS_MAJVER                        =    "majorversion";
our $C_OS_MINVER                        =    "minorversion";
our $C_OS_FAMILY                        =    "family";
our $C_OS_DISTRIB                       =    "distrib";
our $C_CPU                              =    "cpu";
our $C_CPU_MODEL                        =    "model";
our $C_CPU_PHYSCORENUMBER               =    "phys_cores_nbr";
our $C_CPU_VIRTCORENUMBER               =    "virt_cores_nbr";
our $C_CPU_CLOCK                        =    "clock";
our $C_MEMORY                           =    "memory";
our $C_KERNEL                           =    "kernel";
our $C_KERNEL_VER                       =    "version";
our $C_KERNEL_ARCH                      =    "arch";
our $C_NET                              =    "network";
our $C_NET_DEVS                         =    "devices";
our $C_NET_LINKSTATUS                   =    "linkstatus";
our $C_NET_LINKSPEED                    =    "linkspeed";
our $C_NET_LINKMODE                     =    "linkmode";
our $C_NET_DEVICESLAVEOF                =    "master";
our $C_NET_DEVICEIPV4                   =    "ipv4";
our $C_NET_DEVICEIPV6                   =    "ipv6";
our $C_NET_DEVICEMACADDR                =    "mac";
our $C_NET_DEVICEDRIVER                 =    "driver";
our $C_NET_DEVICEBONDINGMODE            =    "bonding_mode";
our $C_NET_ROUTEGW                      =    "defaultroutes";
our $C_NET_ROUTEGW_METRIC               =    "metric";
our $C_NET_ROUTEGW_DEVICE               =    "dev";
our $C_NET_ROUTEGW_PROTO                =    "proto";
our $C_NET_ROUTEGW_TABLE                =    "table";
our $C_NET_DNS                          =    "dns_resolver";
our $C_STOR                             =    "storage";
our $C_STOR_DEV                         =    "devices";
our $C_STOR_DEV_DEVPATH                 =    "dev_path";
our $C_STOR_DEV_SYSPATH                 =    "sys_path";
our $C_STOR_DEV_MAJNUM                  =    "majnum";
our $C_STOR_DEV_MINNUM                  =    "minnum";
our $C_STOR_DEV_VENDOR                  =    "vendor";
our $C_STOR_DEV_MODEL                   =    "model";
our $C_STOR_DEV_TYPE                    =    "dev_type";
our $C_STOR_DEV_SIZE                    =    "size";
our $C_STOR_MULTIPATH                   =    "multipath";
our $C_STOR_MULTIPATH_STATE             =    "state";
our $C_STOR_MULTIPATH_ID                =    "ids";
our $C_STOR_MULTIPATH_PATHS             =    "paths";
our $C_STOR_MULTIPATH_VENDOR            =    "vendor";
our $C_STOR_MULTIPATH_PRODUCT           =    "product";
our $C_STOR_HBA                         =    "hbas";
our $C_STOR_HBA_PORTSPEED               =    "speed";
our $C_STOR_HBA_PORTSTATE               =    "state";
our $C_STOR_HBA_LINKBLKDEVS             =    "devices";
our $C_STOR_HBA_WWN                     =    "wwn";
our $C_STOR_HBA_DESCR                   =    "description";
our $C_STOR_HBA_DEVPROVIDED             =    "provided_dev";


# Using undef when the value will be set at runtime.
# When storing the value by calling the StoreValue function
# the caller will need to provide an array with as much values
# as there are "undef" in the array below
#
# Exemple : $C_CPU_MODEL = [$C_CPU, undef, $C_CPU_MODEL]
# When need to store the value : $self->StoreValue("C_CPU_MODEL", "INTEL Xeon", ["cpu0"]);
# So the StoreValue will store the value in {inventory}->{cpu}->{cpu0}->{model}
our $targetsMap = {
     "C_UPTIME"                              =>   [$C_UPTIME],
     "C_HW"                                  =>   [$C_HW],
     "C_HWVENDOR"                            =>   [$C_HW, $C_HWVENDOR],
     "C_HWMODEL"                             =>   [$C_HW, $C_HWMODEL],
     "C_HWTYPE"                              =>   [$C_HW, $C_HWTYPE],
     "C_HWSERIAL"                            =>   [$C_HW, $C_HWSERIAL],
     "C_HWPRODUCTNUMBER"                     =>   [$C_HW, $C_HWPRODUCTNUMBER],
     "C_USERS"                               =>   [$C_USERS],
     "C_GROUPS"                              =>   [$C_GROUPS],
     "C_PACKAGES"                            =>   [$C_PACKAGES],
     "C_OS"                                  =>   [$C_OS],
     "C_OS_MAJVER"                           =>   [$C_OS, $C_OS_MAJVER],
     "C_OS_MINVER"                           =>   [$C_OS, $C_OS_MINVER],
     "C_OS_FAMILY"                           =>   [$C_OS, $C_OS_FAMILY],
     "C_OS_DISTRIB"                          =>   [$C_OS, $C_OS_DISTRIB],
     "C_CPU"                                 =>   [$C_CPU],
     "C_CPU_THIS"                            =>   [$C_CPU, undef],
     "C_CPU_MODEL"                           =>   [$C_CPU, undef, $C_CPU_MODEL],
     "C_CPU_PHYSCORENUMBER"                  =>   [$C_CPU, undef, $C_CPU_PHYSCORENUMBER],
     "C_CPU_VIRTCORENUMBER"                  =>   [$C_CPU, undef, $C_CPU_VIRTCORENUMBER],
     "C_CPU_CLOCK"                           =>   [$C_CPU, undef, $C_CPU_CLOCK],
     "C_MEMORY"                              =>   [$C_MEMORY],
     "C_KERNEL"                              =>   [$C_KERNEL],
     "C_KERNEL_VER"                          =>   [$C_KERNEL, $C_KERNEL_VER],
     "C_KERNEL_ARCH"                         =>   [$C_KERNEL, $C_KERNEL_ARCH],
     "C_HOSTNAME"                            =>   [$C_NET, $C_HOSTNAME],
     "C_NET_DEVS"                            =>   [$C_NET, $C_NET_DEVS],
     "C_NET_LINKSTATUS"                      =>   [$C_NET, $C_NET_DEVS, undef, $C_NET_LINKSTATUS],
     "C_NET_LINKSPEED"                       =>   [$C_NET, $C_NET_DEVS, undef, $C_NET_LINKSPEED],
     "C_NET_LINKMODE"                        =>   [$C_NET, $C_NET_DEVS, undef, $C_NET_LINKMODE],
     "C_NET_DEVICESLAVEOF"                   =>   [$C_NET, $C_NET_DEVS, undef, $C_NET_DEVICESLAVEOF],
     "C_NET_DEVICEIPV4"                      =>   [$C_NET, $C_NET_DEVS, undef, $C_NET_DEVICEIPV4],
     "C_NET_DEVICEIPV6"                      =>   [$C_NET, $C_NET_DEVS, undef, $C_NET_DEVICEIPV6],
     "C_NET_DEVICEMACADDR"                   =>   [$C_NET, $C_NET_DEVS, undef, $C_NET_DEVICEMACADDR],
     "C_NET_DEVICEDRIVER"                    =>   [$C_NET, $C_NET_DEVS, undef, $C_NET_DEVICEDRIVER],
     "C_NET_DEVICEBONDINGMODE"               =>   [$C_NET, $C_NET_DEVS, undef, $C_NET_DEVICEBONDINGMODE],
     "C_NET_ROUTEGW"                         =>   [$C_NET, $C_NET_ROUTEGW],
     "C_NET_ROUTEGW_METRIC"                  =>   [$C_NET, $C_NET_ROUTEGW, undef, $C_NET_ROUTEGW_METRIC],
     "C_NET_ROUTEGW_DEVICE"                  =>   [$C_NET, $C_NET_ROUTEGW, undef, $C_NET_ROUTEGW_DEVICE],
     "C_NET_ROUTEGW_PROTO"                   =>   [$C_NET, $C_NET_ROUTEGW, undef, $C_NET_ROUTEGW_PROTO],
     "C_NET_ROUTEGW_TABLE"                   =>   [$C_NET, $C_NET_ROUTEGW, undef, $C_NET_ROUTEGW_TABLE],
     "C_NET_DNS"                             =>   [$C_NET, $C_NET_DNS],     
     "C_STOR"                                =>   [$C_STOR],
     "C_STOR_DEV"                            =>   [$C_STOR, $C_STOR_DEV],
     "C_STOR_DEV_DEVPATH"                    =>   [$C_STOR, $C_STOR_DEV, undef, $C_STOR_DEV_DEVPATH],
     "C_STOR_DEV_SYSPATH"                    =>   [$C_STOR, $C_STOR_DEV, undef, $C_STOR_DEV_SYSPATH],
     "C_STOR_DEV_MAJNUM"                     =>   [$C_STOR, $C_STOR_DEV, undef, $C_STOR_DEV_MAJNUM],
     "C_STOR_DEV_MINNUM"                     =>   [$C_STOR, $C_STOR_DEV, undef, $C_STOR_DEV_MINNUM],
     "C_STOR_DEV_VENDOR"                     =>   [$C_STOR, $C_STOR_DEV, undef, $C_STOR_DEV_VENDOR],
     "C_STOR_DEV_MODEL"                      =>   [$C_STOR, $C_STOR_DEV, undef, $C_STOR_DEV_MODEL],
     "C_STOR_DEV_TYPE"                       =>   [$C_STOR, $C_STOR_DEV, undef, $C_STOR_DEV_TYPE],
     "C_STOR_DEV_SIZE"                       =>   [$C_STOR, $C_STOR_DEV, undef, $C_STOR_DEV_SIZE],
     "C_STOR_MULTIPATH"                      =>   [$C_STOR, $C_STOR_MULTIPATH],
     "C_STOR_MULTIPATH_STATE"                =>   [$C_STOR, $C_STOR_MULTIPATH, undef, $C_STOR_MULTIPATH_STATE],
     "C_STOR_MULTIPATH_ID"                   =>   [$C_STOR, $C_STOR_MULTIPATH, undef, $C_STOR_MULTIPATH_ID, undef],
     "C_STOR_MULTIPATH_PATHS"                =>   [$C_STOR, $C_STOR_MULTIPATH, undef, $C_STOR_MULTIPATH_PATHS],
     "C_STOR_MULTIPATH_VENDOR"                =>   [$C_STOR, $C_STOR_MULTIPATH, undef, $C_STOR_MULTIPATH_VENDOR],
     "C_STOR_MULTIPATH_PRODUCT"                =>   [$C_STOR, $C_STOR_MULTIPATH, undef, $C_STOR_MULTIPATH_PRODUCT],
     "C_STOR_HBA"                            =>   [$C_STOR, $C_STOR_HBA],
     "C_STOR_HBA_PORTSPEED"                  =>   [$C_STOR, $C_STOR_HBA, undef, $C_STOR_HBA_PORTSPEED],
     "C_STOR_HBA_PORTSTATE"                  =>   [$C_STOR, $C_STOR_HBA, undef, $C_STOR_HBA_PORTSTATE],
     "C_STOR_HBA_LINKBLKDEVS"                =>   [$C_STOR, $C_STOR_HBA, undef, $C_STOR_HBA_LINKBLKDEVS],
     "C_STOR_HBA_WWN"                        =>   [$C_STOR, $C_STOR_HBA, undef, $C_STOR_HBA_WWN],
     "C_STOR_HBA_DESCR"                      =>   [$C_STOR, $C_STOR_HBA, undef, $C_STOR_HBA_DESCR],
     "C_STOR_HBA_DEVPROVIDED"                =>   [$C_STOR, $C_STOR_HBA, undef, $C_STOR_HBA_DEVPROVIDED],
     
};

sub getTargets
{
     return $targetsMap;
}

1;