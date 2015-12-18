package Solaris::mdb;

use strict;
use warnings;

# VERSION
# ABSTRACT: Perl Interface to Solaris mdb command
#
#

=head1 NAME

Solaris::mdb - A Perl Interface to the Solaris mdb command

=cut

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
has [ 'timeout' ]  =>   ( is => 'ro', isa => 'Int', default => 5 );

sub _build_expect {
  my $self = shift;
  my $log = $self->logger;

  # mdb might not like your default TERM, so we set it to something we know it's
  # ok with here
  $ENV{'TERM'} = "vt100";

  my $exp  =  Expect->new;
  # Needs a raw pseudo-tty
  $exp->raw_pty(1);
  $exp->log_stdout(0);
  # TODO: Make this an option to the constructor
  #$exp->debug(1);
  $exp->spawn("/usr/bin/pfexec", $self->mdb_bin, "-k")
    or die("Cannot spawn [/usr/bin/pfexec " . $self->mdb_bin . "]: $!");

  # See if process immediately exited with error message due to no having
  # proper privileges:
  $exp->expect($self->timeout,
    [ qr{mdb:\sfailed\sto\sopen\s/dev/kmem:\sPermission\sdenied},
                        sub {
                          my $self = shift;
                          my $str = $self->match();
                          $log->logdie( "Insufficient Privileges" );
                        } ],
  );

  #
  # mdb: failed to open /dev/kmem: Permission denied
  #

  $self->logger->debug( "Expect object built" );

  return $exp;
}

=method DEMOLISH

Standard Moose destructor, needed to cleanly close the Expect object's
connection to the mdb command.

=cut

sub DEMOLISH {
  my $self = shift;

  # Only try soft close if the spawned PID is still alive
  if ($self->expect->pid) {
    $self->expect->soft_close();
  }
}

=method quit

Quit/Exit the mdb process this object is connected to

=cut

sub quit {
  my $self = shift;
  my $exp_obj = $self->expect;
  my $log = $self->logger;
  my $str;

  $log->debug("Quitting mdb");

  # The clean way
  $exp_obj->expect($self->timeout,
    [ qr/\r?\>\s/,  sub { my $self = shift;
                          $str = $self->match();
                          $log->debug("BEFORE: [" . $self->before() . "]");
                          $log->debug("MATCHED: [$str]");
                          $self->send("\$q\n");
                          exp_continue;
                        } ],
    [ 'eof',        sub { $log->debug("Encountered EOF");
                        } ],
    [ 'timeout',    sub { $log->logdie("TIMEOUT, match failed");
                        } ],
  );

  # Just in case we failed miserably above
  $exp_obj->soft_close();

  my $exit_status = $exp_obj->exitstatus();

  if (defined($exit_status)) {
    $exit_status >>= 8;
    $log->debug("Exited with status $exit_status");
  } else {
    $log->logdie("Could not extract exit status");
  }

  return 1;
}

=method capture_dcmd

Return the output of a given mdb dcmd

=cut

sub capture_dcmd {
  my $self    = shift;
  my $dcmd    = shift;
  my $log     = $self->logger;
  my $exp_obj = $self->expect;
  my ($str,$retval,$output);

  $log->debug("Running dcmd [$dcmd]");

  $exp_obj->expect($self->timeout,
    #
    # Valid dcmd will return possibly multiline output, followed by a prompt
    #
    [ qr/Total[^\n]+\n/,
                    sub { my $self = shift;
                          $log->debug("BEFORE: [" . $self->before() . "]");
                          $log->debug("MATCHED: [" . $self->match() . "]");
                          $log->debug("AFTER: [" . $self->after() . "]");
                          $str  = $self->before() . $self->match();
                          # Strip the dcmd + newline off the beginning of the
                          # output
                          ($output = $str) =~ s/^\Q${dcmd}\E\n//smx;
                          $log->debug("USEFUL OUTPUT: [$output]");
                          if ($output) { $retval = $output; }
                          else         { $retval =   undef; }
                        } ],
    # invalid dcmd
    [ qr/mdb:\sinvalid\scommand\s'${dcmd}':\sunknown\sdcmd\sname/,
                    sub { my $self = shift;
                          $str = $self->match();
                          $log->debug("BEFORE: [" . $self->before() . "]");
                          $log->debug("MATCHED: [$str]");
                          $log->warn("${dcmd} appears to be a non-existent dcmd");
                          $retval = undef; # FALSE/FAILED/DOESN'T EXIST
                        } ],
    [ qr/\r?\>\s/,  sub { my $self = shift;
                          $str = $self->match();
                          $log->debug("BEFORE: [" . $self->before() . "]");
                          $log->debug("MATCHED: [$str]");
                          $self->send("${dcmd}\n");
                          exp_continue;
                        } ],
    [ 'eof',        sub { $log->debug("Encountered EOF");
                        } ],
    [ 'timeout',    sub { $log->logdie("TIMEOUT, match failed");
                        } ],
  );

  return $retval;
}

=method kvar_exists

Return true if specified kernel variable exists, false (0), otherwise

=cut

sub kvar_exists {
  my $self = shift;
  my $kvar = shift;
  my $exp_obj = $self->expect;
  my $log = $self->logger;
  my ($str, $retval);

  $log->debug("Checking whether kernel variable [$kvar] exists in this kernel");

  $exp_obj->expect($self->timeout,
    # invalid kernel variable
    [ qr/mdb:\sfailed\sto\sdereference\ssymbol:\sunknown\ssymbol\sname/,
                    sub { my $self = shift;
                          $str = $self->match();
                          $log->debug("BEFORE: [" . $self->before() . "]");
                          $log->debug("MATCHED: [$str]");
                          $retval = 0; # FALSE/FAILED/DOESN'T EXIST
                        } ],
    # Valid kernel variable will return a valid numeric size > 0
    # TODO: Validate the captured match value
    [ qr/\r?\d+/,   sub { $retval = 1; } ],
    [ qr/\r?\>\s/,  sub { my $self = shift;
                          $str = $self->match();
                          $log->debug("BEFORE: [" . $self->before() . "]");
                          $log->debug("MATCHED: [$str]");
                          $self->send("${kvar}::nm -f sz -dh\n");
                          exp_continue;
                        } ],
    [ 'eof',        sub { $log->debug("Encountered EOF");
                        } ],
    [ 'timeout',    sub { $log->logdie("TIMEOUT, match failed");
                        } ],
  );

  return $retval;
}

=method kvar_size

Returns size (in bytes) of specified kernel variable.

Returns 0 in case the output couldn't be extracted

Returns undef if the variable doesn't exist.

=cut

sub kvar_size {
  my $self = shift;
  my $kvar = shift;
  my $exp_obj = $self->expect;
  my $log = $self->logger;
  my ($str, $retval, $sz);

  $log->debug("Checking size (in bytes) of kernel variable [$kvar]");

  $exp_obj->expect($self->timeout,
    # invalid kernel variable
    [ qr/mdb:\sfailed\sto\sdereference\ssymbol:\sunknown\ssymbol\sname/,
                    sub { my $self = shift;
                          $str = $self->match();
                          $log->debug("BEFORE: [" . $self->before() . "]");
                          $log->debug("MATCHED: [$str]");
                          $retval = undef; # FALSE/FAILED/DOESN'T EXIST
                        } ],
    # Valid kernel variable will return a valid numeric size > 0
    # TODO: Extract the actual value and verify it's a decimal number
    [ qr/\r?\d+/,   sub { my $self = shift;
                          $str  = $self->match();
                          ($sz) = $str =~ m{(\d+)};
                          if ($sz) { $retval = $sz; }
                          else     { $retval =   0; }
                        } ],
    [ qr/\r?\>\s/,  sub { my $self = shift;
                          $str = $self->match();
                          $log->debug("BEFORE: [" . $self->before() . "]");
                          $log->debug("MATCHED: [$str]");
                          $self->send("${kvar}::nm -f sz -dh\n");
                          exp_continue;
                        } ],
    [ 'eof',        sub { $log->debug("Encountered EOF");
                        } ],
    [ 'timeout',    sub { $log->logdie("TIMEOUT, match failed");
                        } ],
  );

  return $retval;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
