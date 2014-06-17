package Solaris::mdb;

use Moose;
use Moose::Util::TypeConstraints;
with 'MooseX::Log::Log4perl';
with 'Throwable';
use namespace::autoclean;
use Log::Log4perl qw(:easy);
use Expect;
use Try::Tiny;

has [ 'expect' ]   =>   ( is => 'ro', isa => 'Expect', 
                          builder => '_build_expect', lazy_build => 1, );
has [ 'mdb_bin' ]  =>   ( is => 'ro', isa => 'Str', default => '/usr/bin/mdb' );

sub _build_expect {
  my $self = shift;

  my $exp  =  Expect->new;
  # Needs a raw pseudo-tty
  $exp->raw_pty(1);
  # TODO: Make this an option to the constructor
  #$exp->debug(1);
  try {
    $exp->spawn($self->mdb_bin, "-k");
  } catch {
    $self->throw({error => 'Cannot execute mdb_bin'});
  };
  
  $self->logger->debug( "Expect object built" );

  return $exp;
}

sub DEMOLISH {
  my $self = shift;
  $self->expect->soft_close();
}

=head1 quit

Quit/Exit the mdb process this object is connected to

=cut

sub quit {
  my $self = shift;
  my $exp_obj = $self->expect;

  $self->logger->info("Quitting mdb");

  $exp_obj->expect(5,'-re',"\r\n>\s");
  $exp_obj->send("\$q\n");
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
