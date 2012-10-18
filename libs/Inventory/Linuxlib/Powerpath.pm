use strict;
use warnings;

package Inventory::Linuxlib::Powerpath;

# Inheritance
use vars qw/@ISA/;

use Inventory::Tools;

our @ISA = qw/Inventory::Tools/;

use Inventory::Linuxlib::Storage;
use File::Spec::Functions qw(rel2abs catfile);

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

  # If we don't find the powermt executable then we don't have powermt installed
  if (! $self->Which("powermt"))
  {
    return;
  }

  my $valsInHashRef = $self->Sudo("powermt display dev=all");
  if (! $valsInHashRef->{status})
  {
      $self->{INVOBJ}->log({
                    msg=>$valsInHashRef->{errmsg},
                    from=>$from,
                    status=>0,
                  });

      # don't remove the return since ->run need to know the status of the parser
      return;
  }

  my @oneBlock;
  my $cpt = 0;
  my $end = 0;
  foreach (@{ $valsInHashRef->{data} })
  {
    $cpt++;
    $end = 0;
    # If true we are parsing the last line
    if ($cpt > $#{ $valsInHashRef->{data} }) { $end = 1; }

    # Process one device at a time
    if ( ($_ =~ m/Pseudo name/) or $end )
    {
      # If we are at the last line we store it in the @oneBlock since we'll process only @onceBlock
      if ($end) { push(@oneBlock, $_); }
      # Initialize arrays to store any IP(s) found
      my $multipath_devs = {};
      my $dev;
      # We will parse one net device information. All information about that device
      # is in @oneBlock
      foreach my $blockLine (@oneBlock)
      {
        # Line look like this :
        #Pseudo name=emcpowerf
        if ($blockLine =~ m/^Pseudo\s+name=(\w+)$/)
        {
          $dev = $1;
        }
        # Line look like this:
        #Symmetrix ID=000292600896
        elsif ($blockLine =~ m/^Symmetrix ID=(\w+)/)
        {
          $self->{INVOBJ}->StoreValue("C_STOR_DEV_SYMMETRIXID", $1, $from, [$dev]);
        }
        # Line looks like this:
        #Logical device ID=153E
        elsif ($blockLine =~ m/^Logical device ID=(\w+)/)
        {
          $self->{INVOBJ}->StoreValue("C_STOR_DEV_SYMMETRIXLOGID", $1, $from, [$dev]);
        }
        # Line looks like this:
        #state=alive; policy=SymmOpt; priority=0; queued-IOs=0
        elsif ($blockLine =~ m/^state=(\w+)/)
        {
          $self->{INVOBJ}->StoreValue("C_STOR_DEV_SYMMSTATE", $1, $from, [$dev]); 
        }
        # Line looks like this:
        #  1 lpfc                      sdj       FA 10fB   active  alive      0      0
        elsif ($blockLine =~ m/\s+\d+\s+lpfc\s+(\w+)\s+/)
        {
          my $rhash = $self->{INVOBJ}->GetTarget("C_STOR_DEV");
          $multipath_devs->{$1} = $rhash->{$1};
          delete $rhash->{$1};
        }
      }
      # Now we store the multipath devs
      if ($dev)
      {
        if(%$multipath_devs) { $self->{INVOBJ}->StoreValue( "C_STOR_DEV_MULTIPATH"
                                                            , $multipath_devs
                                                            , $from
                                                            , [$dev]); }
        $self->setPaths($dev);
        Inventory::Linuxlib::Storage::getDevNumbers($self, $dev);
        Inventory::Linuxlib::Storage::getSize($self, $dev);
      }
    
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

sub setPaths
{
  my ($self, $dev) = @_;
  my $from = (caller(0))[3];

  my $sys_path = catfile("/sys/block/", $dev);
  my $dev_path = catfile("/dev", $dev);
  $self->{INVOBJ}->StoreValue("C_STOR_DEV_DEVPATH", $dev_path, $from, [$dev]);
  $self->{INVOBJ}->StoreValue("C_STOR_DEV_SYSPATH", $sys_path, $from, [$dev]);
}

1;