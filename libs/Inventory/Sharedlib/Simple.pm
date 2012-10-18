use strict;
use warnings;

package Inventory::Sharedlib::Simple;


sub jobLauncher
{
  my ($self, $optionalFunctionParamsHashRef) = @_;

  if (! defined($optionalFunctionParamsHashRef))
  {
    $optionalFunctionParamsHashRef = {};
  }

  foreach ($self->{functionMaps})
  {
    foreach my $purposeArrayRef (@$_)
    {
      # $tag is the name of the piece of information we want to grab such as memory, hostname ...
      # and comes from the Constants.pm .
      my $tag     = $purposeArrayRef->[0];
      # $methods is an array ref to a list of arrays. Each of the later contains the
      # name of the function as first value and the second saying if we need sudo or not.
      my $methods = $purposeArrayRef->[1];

      foreach my $lastArray (@$methods)
      {
        my $function   = $lastArray->[0];
        my $privileged = $lastArray->[1];

        # Check if we have disabled the use of the methods that needs sudo.
        # If yes we won't even try to execute the function and skip to the next one
        if ( ($self->{INVOBJ}->{params}->{disablePrivilegedMethods}) && ($privileged eq "Privileged") )
        {
          next;
        }

        # We are here if we have to execute any kind of subroutine (sudo needed or not).
        # We pass the given optional arguments (if any)
        my $valsInHashRef =  $self->$function($optionalFunctionParamsHashRef);
        # Now we'll check the return code of the just executed function()
        # There are 3 possible status returned by any routine to grab a piece of information:
        #   0 - The function failed to grab the needed data
        #       Consequence: the fact is logged and we try the next one if any
        #   1 - The function entirely succeeded to get it
        #       The fact is logged and the data is stored in the hash specified by the caller

        # STATUS IS 1
        #------------
        if ($valsInHashRef->{status})
        {
          # We check if it is not an empty value (to be sure)
          if (defined($valsInHashRef->{data}))
          {
            # We store the value where asked by the caller
            $self->{INVOBJ}->StoreValue($tag, $valsInHashRef->{data}, $valsInHashRef->{funcname});
            # Skip remaining functions to process the next target
            last;
          }
          # The function returned a success status but the data given is empty!
          else
          {
              $self->{INVOBJ}->log({
                      tag=>$tag,
                      msg=>"The function said it was OK but the returned value is undefined!",
                      from=>$valsInHashRef->{funcname},
                      status=>0,
                    });
          }
        }
        # STATUS IS 0
        #------------
        else
        {
          $self->{INVOBJ}->log({
                      tag=>$tag,
                      msg=>$valsInHashRef->{errmsg},
                      from=>$valsInHashRef->{funcname},
                      status=>0,
                    });
        }
      }
    }
  }

}

sub UsersPasswd
{
    my $self = shift;
    my $from = (caller(0))[3];

    my $valsInHashRef = $self->ReadFile("/etc/passwd" );
    if ($valsInHashRef->{status})
    {
        my @users;
        foreach my $user_line (@{ $valsInHashRef->{data} })
        {
            my ($user, undef, $uid, $gid, $desc, $home, $shell) = split(":", $user_line);
            push(@users, {name=>$user,uid=>$uid,gid=>$gid,desc=>$desc,home=>$home,shell=>$shell} );
        }
        return {status=>1,funcname=>$from,data=>\@users} ;
    }
    else
    {
        return {status=>0,errmsg=>$valsInHashRef->{errmsg},funcname=>$from };
    }
}

sub GroupsGroup
{
    my $self = shift;
    my $from = (caller(0))[3];

    my $valsInHashRef = $self->ReadFile("/etc/group" );
    if ($valsInHashRef->{status})
    {
        my @groups;
        foreach my $group_line (@{ $valsInHashRef->{data} })
        {
            my ($group, undef, $gid, $members_raw) = split(":", $group_line);
            my @members = split(",", $members_raw);
            push(@groups, {name=>$group,gid=>$gid,members=>\@members} );
        }
        return {status=>1,funcname=>$from,data=>\@groups} ;
    }
    else
    {
        return {status=>0,errmsg=>$valsInHashRef->{errmsg},funcname=>$from };
    }
}

1;