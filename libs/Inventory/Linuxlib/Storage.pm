use strict;
use warnings;

package Inventory::Linuxlib::Storage;

# Inheritance
use vars qw/@ISA/;

use Inventory::Tools;

our @ISA = qw/Inventory::Tools/;

use File::Basename qw(basename);
use File::Spec::Functions qw(rel2abs catfile);

sub run
{
  my $class   = shift;
  my $INVOBJ  = shift;

  my $self    = {};

  $self->{INVOBJ} = $INVOBJ;

  bless($self, $class);
  $self->{devtypes} = $self->setDevTypes();

  # We start populating and grabbing the information
  $self->getBlockDevices();
  foreach (keys %{ $self->{INVOBJ}->GetTarget("C_STOR_DEV") })
  {
    $self->getModel($_);
    $self->getVendor($_);
    $self->getDevNumbers($_);
    $self->getModel($_);
    $self->findType($_);
    $self->getSize($_);
    $self->getPartitions($_);
  }
}

sub getBlockDevices
{
  my $self = shift;
  my $from = (caller(0))[3];
  
  my @all_devices = map{basename($_)} </sys/block/*>;

  my @virtual_devices = map{basename($_)} </sys/devices/virtual/block/*>;
    
  $self->{phys_devices} = {};
  foreach my $item (@all_devices)
  {
    if (scalar(grep(/$item/, @virtual_devices)) == 0)
    {
      my $device = $item;
      my $sys_path = catfile("/sys/block/", $item);
      $item =~ s/!/\//;
      my $dev_path = catfile("/dev", $item);
      $self->{INVOBJ}->StoreValue("C_STOR_DEV_DEVPATH", $dev_path, $from, [$device]);
      $self->{INVOBJ}->StoreValue("C_STOR_DEV_SYSPATH", $sys_path, $from, [$device]);
    }
  }
}

sub getModel
{
  my ($self, $device) = @_;
  my $from = (caller(0))[3];

  my $valsInHashRef = $self->ReadFile(catfile($self->{INVOBJ}->GetTarget("C_STOR_DEV_SYSPATH", [$device])
                                              , "device"
                                              , "model"));
  if (! $valsInHashRef->{status})
  {
    $self->{INVOBJ}->log({
                      tag=>"C_STOR_DEV_MODEL",
                      tagcomplement=>[$device],
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                      });
    return;
  }
  my $model = $self->Strip($valsInHashRef->{data}->[0]);
  if ($model) { $self->{INVOBJ}->StoreValue("C_STOR_DEV_MODEL", $model, $from, [$device]) };
}
  
sub getVendor
{
  my ($self, $device) = @_;
  my $from = (caller(0))[3];

  my $valsInHashRef = $self->ReadFile(catfile($self->{INVOBJ}->GetTarget("C_STOR_DEV_SYSPATH",[$device])
                                              , "device"
                                              , "vendor"));
  if (! $valsInHashRef->{status})
  {
    $self->{INVOBJ}->log({
                      tag=>"C_STOR_DEV_VENDOR",
                      tagcomplement=>[$device],
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                      });
    return;
  }
  my $vendor = $self->Strip($valsInHashRef->{data}->[0]);
  if ($vendor) { $self->{INVOBJ}->StoreValue("C_STOR_DEV_VENDOR", $vendor, $from, [$device]) };

}

sub getDevNumbers
{
  my ($self, $device) = @_;
  my $from = (caller(0))[3];

  my $valsInHashRef = $self->ReadFile(catfile($self->{INVOBJ}->GetTarget("C_STOR_DEV_SYSPATH",[$device])
                                              , "dev"));
  if (! $valsInHashRef->{status})
  {
    $self->{INVOBJ}->log({
                      tag=>"C_STOR_DEV_MAJNUM",
                      tagcomplement=>[$device],
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                      });

    $self->{INVOBJ}->log({
                      tag=>"C_STOR_DEV_MINNUM",
                      tagcomplement=>[$device],
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                      });
    return;
  }

  my ($major, $minor) = split(":", $valsInHashRef->{data}->[0]);
  $major = int($self->Strip($major));
  $minor = int($self->Strip($minor));
  $self->{INVOBJ}->StoreValue("C_STOR_DEV_MAJNUM", $major, $from, [$device]);
  $self->{INVOBJ}->StoreValue("C_STOR_DEV_MINNUM", $minor, $from, [$device]);
}

sub findType
{
  my ($self, $device) = @_;
  my $from = (caller(0))[3];

  my $majnumber = $self->{INVOBJ}->GetTarget("C_STOR_DEV_MAJNUM",[$device]);
  my $devtype = $self->{devtypes}->{$majnumber};

  if ($devtype) { $self->{INVOBJ}->StoreValue("C_STOR_DEV_TYPE", $devtype, $from, [$device]); }

}

sub getSize
{
  my ($self, $device) = @_;
  my $from = (caller(0))[3];

  my $valsInHashRef = $self->ReadFile(catfile($self->{INVOBJ}->GetTarget("C_STOR_DEV_SYSPATH",[$device])
                                              , "size"));
  if (! $valsInHashRef->{status})
  {
    $self->{INVOBJ}->log({
                      tag=>"C_STOR_DEV_SIZE",
                      tagcomplement=>[$device],
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                      });
    return;
  }

  my $size = int($valsInHashRef->{data}->[0]) * 512;
  if ($size) { $self->{INVOBJ}->StoreValue("C_STOR_DEV_SIZE", $size, $from, [$device]); }
}

sub getPartitions
{
  my ($self, $device) = @_;
  my $from = (caller(0))[3];

  my @partitions = grep(-d $_, </sys/class/block/$device/$device*>);

  foreach (@partitions)
  {
    #print $_, "\n";
  }

  
}

sub setDevTypes
{
  # The mapping comes from http://www.kernel.org/doc/Documentation/devices.txt
  my $devtypes = {
    2   =>  "Floppy disks",
    3   =>  "First MFM, RLL and IDE hard disk/CD-ROM interface",
    8   =>  "SCSI disk devices (0-15)",
    9   =>  "Metadisk (RAID) devices",
    11  =>  "SCSI CD-ROM devices",
    15  =>  "Sony CDU-31A/CDU-33A CD-ROM",
    16  =>  "GoldStar CD-ROM",
    17  =>  "Optics Storage CD-ROM",
    18  =>  "Sanyo CD-ROM",
    20  =>  "Hitachi CD-ROM",
    22  =>  "Second IDE hard disk/CD-ROM interface",
    23  =>  "Mitsumi proprietary CD-ROM",
    24  =>  "Sony CDU-535 CD-ROM",
    25  =>  "First Matsushita (Panasonic/SoundBlaster) CD-ROM",
    26  =>  "Second Matsushita (Panasonic/SoundBlaster) CD-ROM",
    27  =>  "Third Matsushita (Panasonic/SoundBlaster) CD-ROM",
    28  =>  "Fourth Matsushita (Panasonic/SoundBlaster) CD-ROM",
    29  =>  "Aztech/Orchid/Okano/Wearnes CD-ROM",
    30  =>  "Philips LMS CM-205 CD-ROM",
    31  =>  "ROM/flash memory card",
    32  =>  "Philips LMS CM-206 CD-ROM",
    33  =>  "Third IDE hard disk/CD-ROM interface",
    34  =>  "Fourth IDE hard disk/CD-ROM interface",
    45  =>  "Parallel port IDE disk devices",
    46  =>  "Parallel port ATAPI CD-ROM devices",
    48  =>  "Mylex DAC960 PCI RAID controller; first controller",
    49  =>  "Mylex DAC960 PCI RAID controller; second controller",
    50  =>  "Mylex DAC960 PCI RAID controller; third controller",
    51  =>  "Mylex DAC960 PCI RAID controller; fourth controller",
    52  =>  "Mylex DAC960 PCI RAID controller; fifth controller",
    53  =>  "Mylex DAC960 PCI RAID controller; sixth controller",
    54  =>  "Mylex DAC960 PCI RAID controller; seventh controller",
    55  =>  "Mylex DAC960 PCI RAID controller; eighth controller",
    56  =>  "Fifth IDE hard disk/CD-ROM interface",
    57  =>  "Sixth IDE hard disk/CD-ROM interface",
    64  =>  "Scramdisk/DriveCrypt encrypted devices",
    65  =>  "SCSI disk devices (16-31)",
    66  =>  "SCSI disk devices (32-47)",
    67  =>  "SCSI disk devices (48-63)",
    68  =>  "SCSI disk devices (64-79)",
    69  =>  "SCSI disk devices (80-95)",
    70  =>  "SCSI disk devices (96-111)",
    71  =>  "SCSI disk devices (112-127)",
    72  =>  "Compaq Intelligent Drive Array, first controller",
    73  =>  "Compaq Intelligent Drive Array, second controller",
    74  =>  "Compaq Intelligent Drive Array, third controller",
    75  =>  "Compaq Intelligent Drive Array, fourth controller",
    76  =>  "Compaq Intelligent Drive Array, fifth controller",
    77  =>  "Compaq Intelligent Drive Array, sixth controller",
    78  =>  "Compaq Intelligent Drive Array, seventh controller",
    79  =>  "Compaq Intelligent Drive Array, eighth controller",
    80  =>  "I2O hard disk",
    81  =>  "I2O hard disk",
    82  =>  "I2O hard disk",
    83  =>  "I2O hard disk",
    84  =>  "I2O hard disk",
    85  =>  "I2O hard disk",
    86  =>  "I2O hard disk",
    87  =>  "I2O hard disk",
    88  =>  "Seventh IDE hard disk/CD-ROM interface",
    89  =>  "Eighth IDE hard disk/CD-ROM interface",
    90  =>  "Ninth IDE hard disk/CD-ROM interface",
    91  =>  "Tenth IDE hard disk/CD-ROM interface",
    101 =>  "AMI HyperDisk RAID controller",
    102 =>  "Compressed block device",
    104 =>  "Compaq Next Generation Drive Array, first controller",
    105 =>  "Compaq Next Generation Drive Array, second controller",
    106 =>  "Compaq Next Generation Drive Array, third controller",
    107 =>  "Compaq Next Generation Drive Array, fourth controller",
    108 =>  "Compaq Next Generation Drive Array, fifth controller",
    109 =>  "Compaq Next Generation Drive Array, sixth controller",
    110 =>  "Compaq Next Generation Drive Array, seventh controller",
    111 =>  "Compaq Next Generation Drive Array, eighth controller",
    112 =>  "IBM iSeries virtual disk",
    113 =>  "IBM iSeries virtual CD-ROM",
    117 =>  "Enterprise Volume Management System (EVMS)",
    120 =>  "EMC Multipath devices", # Not in the devices.txt but its the reality
    128 =>  "SCSI disk devices (128-143)",
    129 =>  "SCSI disk devices (144-159)",
    130 =>  "SCSI disk devices (160-175)",
    131 =>  "SCSI disk devices (176-191)",
    132 =>  "SCSI disk devices (192-207)",
    133 =>  "SCSI disk devices (208-223)",
    134 =>  "SCSI disk devices (224-239)",
    135 =>  "SCSI disk devices (240-255)",
    136 =>  "Mylex DAC960 PCI RAID controller; ninth controller",
    137 =>  "Mylex DAC960 PCI RAID controller; tenth controller",
    138 =>  "Mylex DAC960 PCI RAID controller; eleventh controller",
    139 =>  "Mylex DAC960 PCI RAID controller; twelfth controller",
    140 =>  "Mylex DAC960 PCI RAID controller; thirteenth controller",
    141 =>  "Mylex DAC960 PCI RAID controller; fourteenth controller",
    142 =>  "Mylex DAC960 PCI RAID controller; fifteenth controller",
    143 =>  "Mylex DAC960 PCI RAID controller; sixteenth controller",
    153 =>  "Enhanced Metadisk RAID (EMD) storage units",
    160 =>  "Carmel 8-port SATA Disks on First Controller",
    161 =>  "Carmel 8-port SATA Disks on Second Controller",
    179 =>  "MMC block devices",
    180 =>  "USB block devices",
    199 =>  "Veritas volume manager (VxVM) volume",
    201 =>  "Veritas VxVM dynamic multipathing driver",
    202 =>  "Xen Virtual Block Device",
    253 =>  "LVM devices", # Not in the devices.txt but its the reality
  };
  return $devtypes;
}

1;