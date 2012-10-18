use strict;
use warnings;

package Inventory::Linuxlib::Network;

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
    $self->devicesParser();
    $self->defaultGateway();
    $self->dnsResolvers();
}

sub devicesParser
{
  my $self = shift;

  my $from = (caller(0))[3];
  my $valsInHashRef = $self->Execute("ip address show");
  if ($valsInHashRef->{status})
  {
    my @oneBlock;
    my $cpt = 0;
    my $end = 0;
    my $dev;
    foreach (@{ $valsInHashRef->{data} })
    {
      $cpt++;
      $end = 0;
      # If true we are parsing the last line of the output of ip address show
      if ($cpt > $#{ $valsInHashRef->{data} }) { $end = 1; }

      # Process one device at a time
      if ( ($_ =~ m/^[0-9]+:/) ||  $end )
      {
        # If we are at the last line we store it in the @oneBlock since we'll process only @onceBlock
        if ($end) { push(@oneBlock, $_); }
        # Initialize arrays to store any IP(s) found
        my $ipv4 = [];
        my $ipv6 = [];
        # We will parse one net device information. All information about that device
        # is in @oneBlock
        foreach my $blockLine (@oneBlock)
        {
          # Parse the first line. Line look like this :
          #2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
          if ($blockLine =~ m/^[0-9]+:/)
          {
            (undef, $dev, my @options) = split(" ", $blockLine);
            $dev =~ s/://g;
            # Dont inventory localhost
            #if ($dev eq "lo") { last; }
            my $options = join(" ", @options);

            # 1 - will search for the LINK status
            if ($options =~ m/state\s+(\w+)\s+/)
            {
              my $linkstatus;
              if ($1 eq "UP")
              {
                  $linkstatus = \1;
              }
              elsif ($1 eq "DOWN")
              {
                  $linkstatus = \0;
              }
              $self->{INVOBJ}->StoreValue("C_NET_LINKSTATUS", $linkstatus, $from, [$dev]);
            }

            #2 - will search for a MASTER device (in case of bonding for eg)                        
            if ($options =~ m/master\s+(\w+)/)
            {
                $self->{INVOBJ}->StoreValue("C_NET_DEVICESLAVEOF", $1, $from, [$dev]);
            }
          }
          # Parse the line about the link information. Line look like this:
          #    link/ether 00:0c:29:25:3b:98 brd ff:ff:ff:ff:ff:ff
          elsif ($blockLine =~ m/link\/ether/)
          {
            my (undef, $mac) = split(" ", $blockLine);
            $self->{INVOBJ}->StoreValue("C_NET_DEVICEMACADDR", $mac, $from, [$dev]);
          }
          # Parse the line about IPV4 information. Line looks like this:
          #     inet 192.168.253.128/24 brd 192.168.253.255 scope global eth0
          elsif ($blockLine =~ m/inet\s+/)
          {
            my (undef, $ip_and_net) = split(" ", $blockLine);
            push(@{ $ipv4 }, $self->Strip($ip_and_net));
          }
          # Parse the line about IPV6 information. Line looks like this:
          #    inet6 fe80::20c:29ff:fe25:3b98/64 scope link
          elsif ($blockLine =~ m/inet6\s+/)
          { 
            my (undef, $ip_and_net) = split(" ", $blockLine);
            push(@{ $ipv6 }, $self->Strip($ip_and_net));
          }
        }
        # Now we store ipv4 and ipv6 array ref if we have at least one value
        if(@$ipv4) { $self->{INVOBJ}->StoreValue("C_NET_DEVICEIPV4", $ipv4, $from, [$dev]); }
        if(@$ipv6) { $self->{INVOBJ}->StoreValue("C_NET_DEVICEIPV6", $ipv6, $from, [$dev]); }
      
        # If we are not at the last line of the output : we just parsed the @oneBlock.
        # So we make it empty to start populating the next device. We already start by storing
        # the current line already stored in the foreach loop ($_) since it is the first line
        # of the next device.
        if (! $end)
        {
          @oneBlock = ();
          push(@oneBlock, $_);
        }
      }
      # If the regex didn't match we aren't at the end of a net device description
      # so we push the line into the array which will be parsed at the end of the block
      else
      {
          push(@oneBlock, $_);
      }
    }
  }
  else
  {
    $self->{INVOBJ}->log({
                      tag=>"C_NET_DEVS",
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                    });
  }
}

sub defaultGateway
{
  my $self = shift;
  my $from = (caller(0))[3];

  # IPV4
  my $valsInHashRef4 = $self->Execute("ip -4 route list table all");
  if ($valsInHashRef4->{status})
  {
    $self->gwParser($valsInHashRef4->{data}, "ipv4");    
  }
  else
  {
    $self->{INVOBJ}->log({
                      tag=>"C_NET_ROUTEGW",
                      msg=>$valsInHashRef4->{errmsg},
                      from=>$from,
                      status=>0,
                    });
  }

  # IPV6
  my $valsInHashRef6 = $self->Execute("ip -6 route list table all");
  if ($valsInHashRef6->{status})
  {
    $self->gwParser($valsInHashRef6->{data}, "ipv6");
  }
  else
  {
    $self->{INVOBJ}->log({
                      tag=>"C_NET_ROUTEGW",
                      msg=>$valsInHashRef6->{errmsg},
                      from=>$from,
                      status=>0,
                    });
  }
}

sub gwParser
{
  my ($self, $rawGWoutput, $proto) = @_;
  my $from = (caller(0))[3];

  foreach (@{ $rawGWoutput })
  {

    if (  $_ =~ m/^default\s+via\s+((:*\w*){1,8})\s+dev\s+(\w+)/ #ipv6
        or
          $_ =~ m/^default\s+via\s+((\d{1,4}\.*){4})\s+dev\s+(\w+)\s+/ #ipv4
        )
    {
      my $ip    = $1;
      my $dev   = $3;

      $self->{INVOBJ}->GetOrCreateTarget("C_NET_ROUTEGW", $ip, $from);
      $self->{INVOBJ}->StoreValue("C_NET_ROUTEGW_DEVICE", $dev, $from, [$ip]);
      $self->{INVOBJ}->StoreValue("C_NET_ROUTEGW_PROTO", $proto, $from, [$ip]);
      if ( $_ =~ m/table\s+(\w+)/ )
      { 
        $self->{INVOBJ}->StoreValue("C_NET_ROUTEGW_TABLE", $1, $from, [$ip]);
      }
      if ( $_ =~ m/metric\s+(\d+)/ )
      {
        $self->{INVOBJ}->StoreValue("C_NET_ROUTEGW_METRIC", $1, $from, [$ip]);
      }
    }
  }
}

sub dnsResolvers
{
  my $self = shift;
  my $from = (caller(0))[3];

  my $valsInHashRef = $self->ReadFile("/etc/resolv.conf");

  if (! $valsInHashRef->{status})
  {
    $self->{INVOBJ}->log({
                      tag=>"C_NET_DNS",
                      msg=>$valsInHashRef->{errmsg},
                      from=>$from,
                      status=>0,
                    });
    return;
  }

  my @dns = ();

  foreach (@{ $valsInHashRef->{data} })
  {
    if (  $_ =~ m/^nameserver\s+((\d{1,4}\.*){4})/
        or
          $_ =~ m/^nameserver\s+\[*((:*\w*){1,8})\]*/
        )
    {
      push(@dns, $1);
    }
  }
  $self->{INVOBJ}->StoreValue("C_NET_DNS", \@dns, $from);
  
}
1;