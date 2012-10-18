use strict;
use warnings;

package Inventory;

use Inventory::JSON_WRAPPER;
use Inventory::LINUX;
use Inventory::AIX;
use Inventory::SOLARIS;
use Inventory::Log;

sub new
{
    # Oject related stuffs
    my ($class, %params) = @_;
    my $self = {inventory=>{}};

    my %defaults = (disablePrivilegedMethods=>0);
    %params = (%defaults, %params);

    # Get the inventory done
    $self->{inventory} = $class->_GuessAndRun(%params);

    # Return the object populated with the inventory
    bless($self, $class);
    return $self;
}

sub _GuessAndRun
{
    my ($class, %params) = @_;
    my $inventory;

    # $^O is a special Perl variable that contains the name
    # of the system on which the perl executable currently
    # runing was compiled for. So we start the right
    # inventory workflow to get data
    if ($^O =~ m/linux/)
    {
        $inventory = Inventory::LINUX->run(%params);
    }
    elsif ($^O =~ m/aix/)
    {
        $inventory = Inventory::AIX->run(%params);
    }
    elsif ($^O =~ m/solaris/)
    {
        $inventory = Inventory::SOLARIS->run(%params);
    }
    else
    {
        $inventory = {status=>\0,msg=>"I'm sorry but I don't know your system: $^O"};
    }

    $inventory->{status} = \1;
    return $inventory;
}

sub get_json
{
    my $self = shift;
    my $json_obj = Inventory::JSON_WRAPPER->new;
    return $json_obj->encode($self->{inventory});
}

sub get_hash
{
    my $self = shift;
    return $self->{inventory};
}

sub print_json
{
    my $self = shift;
    my $json_obj = Inventory::JSON_WRAPPER->new->pretty;
    print $json_obj->encode($self->{inventory});
}

1;