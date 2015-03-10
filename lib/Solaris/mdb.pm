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
  $e->send('$q' . "\n");
  $e->soft_close();
  $e->hard_close();
}

sub variable_exists {

}

1;
