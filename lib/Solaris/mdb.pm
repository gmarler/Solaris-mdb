use strict;
use warnings;

package Solaris::mdb;

# VERSION
# ABSTRACT: Provides a Perl interface to the Solaris mdb utility in kernel mode
#
use namespace::autoclean;
use Expect;
use Moose;

# Expect instance that's a connection to an mdb session
has mdb => ( isa          => Expect,
             is           => ro,
             lazy_builder => 1,
             predicate    => 'has_mdb',
             clearer      => 'clear_mdb',
           );

sub _build_mdb {
  my ($self) = shift;

  my $e = Expect->new();
  $e->raw_pty(1);
  $e->spawn('mdb', '-k') or die "cannot spawn mdb -k: $!\n";
  return $e;
}

sub DEMOLISH {
  my ($self) = shift;

  # Refactor
  my $e = $self->mdb;
  $e->send('$q' . "\n");
  $e->soft_close();
  $e->hard_close();
}
sub variable_exists {

}

1;
