# NOTE: TF stands for TestsFor::...
package TF::Solaris::mdb;

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

sub test_startup {
  my $test = shift;

  unless ($^O eq 'solaris') {
    $test->test_skip("Tests won't run on $^O");
  }
}

sub test_load {
  my $test = shift;

  use_ok($test->test_class);
}

sub test_expect_meta {
  my $test = shift;

  my $mdb = Solaris::mdb->new();

  my $e = $mdb->mdb;
  isa_ok($e, 'Expect', 'Should be Expect object');

  cmp_ok($e->log_stdout(), '==', 0, 'Logging to STDOUT disabled');
  cmp_ok($e->raw_pty(), '==', 1, 'Raw pty enabled');
}

1;
