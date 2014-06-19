package Solaris::mdb;

use Moose;
use Moose::Util::TypeConstraints;
with 'MooseX::Log::Log4perl';
use namespace::autoclean;
use Log::Log4perl qw(:easy);
use Expect        qw(exp_continue);
#use Try::Tiny;
#use Throwable::Factory
#  GeneralException => undef;

has [ 'expect' ]   =>   ( is => 'ro', isa => 'Expect', 
                          builder => '_build_expect', lazy_build => 1, );
has [ 'mdb_bin' ]  =>   ( is => 'ro', isa => 'Str', default => '/usr/bin/mdb' );

sub _build_expect {
  my $self = shift;

  # mdb might not like your default TERM, so we set it to something we know it's
  # ok with here
  $ENV{'TERM'} = "vt100";

  my $exp  =  Expect->new;
  # Needs a raw pseudo-tty
  $exp->raw_pty(1);
  # TODO: Make this an option to the constructor
  #$exp->debug(1);
  $exp->spawn($self->mdb_bin, "-k") or
    die("Cannot execute mdb_bin");

  $self->logger->debug( "Expect object built" );

  return $exp;
}

sub DEMOLISH {
  my $self = shift;

  # Only try soft close if the spawned PID is still alive
  if ($self->expect->pid) {
    $self->expect->soft_close();
  }
}

=head1 quit

Quit/Exit the mdb process this object is connected to

=cut

sub quit {
  my $self = shift;
  my $exp_obj = $self->expect;
  my $log = $self->logger;
  my $str;

  $log->debug("Quitting mdb");

  # The clean way
  $exp_obj->expect(5,
    [ qr/\r?\>\s/,  sub { my $self = shift;
                          $str = $self->match();
                          $log->debug("BEFORE: [" . $self->before() . "]");
                          $log->debug("MATCHED: [$str]");
                          $self->send("\$q\n");
                          exp_continue;
                        } ],
    [ 'eof',        sub { $log->debug("Encountered EOF");
                        } ],
    [ 'timeout',    sub { $log->die("TIMEOUT, match failed");
                        } ],
  );

  # Just in case we failed miserably above
  $exp_obj->soft_close();

  my $exit_status = $exp_obj->exitstatus();

  if (defined($exit_status)) {
    $exit_status >>= 8;
    $log->debug("Exited with status $exit_status");
  } else {
    $log->die("Could not extract exit status");
  }

  return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
