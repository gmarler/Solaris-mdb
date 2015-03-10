use v5.18.1;
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
has mdb => ( isa        => 'Expect',
             is         => 'ro',
             lazy_build => 1,
             predicate  => 'has_mdb',
             clearer    => 'clear_mdb',
           );

sub _build_mdb {
  my ($self) = shift;

  my $e = Expect->new();
  $e->raw_pty(1);
  $e->log_stdout(0);
  $e->spawn('mdb', '-k') or die "cannot spawn mdb -k: $!\n";

  # Even if we don't have the necessary privilege,
  # which is file_dac_read on /devices/pseudo/mm@0:kmem
  # Expect will still be successful.  So we need to 'expect()' on the following
  # output in such cases:

  #  mdb: cannot open /dev/kmem
  #  mdb: failed to initialize target: Permission denied
  #$e->expect( 2,
  #           # [ qr/^mdb:\s+failed\s+[^\n]+Permission\sdenied/s,
  #           [ qr/Permission\s+denied/s,
  #             sub { die "No permission to invoke mdb -k: " . $e->before(); return; }
  #           ],
  #           #[ eof => sub { die "crapped out"; } ],
  #          );

  return $e;
}

# $e->expect(2,
#   [ qr/^>\s(?!\s+)/m => sub { my $e = shift;
#                              say "PROMPT matched";
#                              #say "BEFORE:  " . $e->before();
#                              #say "MATCHED: " . $e->match();
#                              #say "AFTER:   " . $e->after();
#                              if ($done_with_mdb and not $quit_sent) {
#                                $e->send('$q' . "\n");
#                                $quit_sent++;
#                              } else {
#                                $done_with_mdb++;
#                                $e->send("::dcmds\n");
#                                exp_continue;
#                              }
#                            }
#   ],
# #  [ qr/^::(?:[^\r]+)\r/m  => sub { my $e = shift;
# #                             #say "BEFORE:  " . $e->before();
# #                             #say "MATCHED: " . $e->match();
# #                             #say "AFTER:   " . $e->after();
# #                             exp_continue;
# #                           }
# #  ],
#   [ qr/^>>\s+More\s+\[[^\?]+\?\s/m  => sub { my $e = shift;
#                              say "MULTILINE OUTPUT matched";
#                              #say "BEFORE:  " . $e->before();
#                              #say "MATCHED: " . $e->match();
#                              #say "AFTER:   " . $e->after();
#                              $e->send("c\r");
#                              exp_continue;
#                            }
#   ],
# );


sub DEMOLISH {
  my ($self) = shift;

  # Refactor
  my $e = $self->mdb;
  # say "In DEMOLISH";
  my $pid = $e->pid();
  if (defined($pid)) {
    # say "mdb PID: " . $pid; 
    # say "sending mdb quit";
    $e->send('$q' . "\n");
    $e->expect(undef);
    # say $e->before();
    my $status = $e->exitstatus();
    # if ($status == 0) {
    #   say "mdb exited cleanly";
    # } else {
    #   say "mdb exited BADLY: $status";
    # }
  } else {
    # say "mdb already dead";
  }
}

sub variable_exists {
  my ($self) = shift;
  my ($varname) = shift;

  # TODO: Throw an exception is $varname is not defined

  # Expect the mdb prompt
  my $e = $mdb->mdb();
  $e->expect( 2,
              [ qr//s,
                sub { my $sub_e = shift;
                    }
              ],
              [ eof =>
                sub { my $sub_e = shift;
                    }
              ],
  );
  # Test for the variable's existence
  #
  # EXISTS: 
  # > ncsize::nm -h -f sz
  # 0x0000000000000004
  #
  #
  # DOES NOT EXIST:
  # > junk::nm -h -f sz
  # mdb: failed to dereference symbol: unknown symbol name

  return;
}

1;
