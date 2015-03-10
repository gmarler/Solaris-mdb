# NOTE: TF stands for TestsFor::...
package TF::Solaris::mdb;

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

sub test_startup {
  my $test = shift;

  unless ($^O eq 'solaris') {
    $test->test_skip("Tests won't run on $^O");
  }

  my $privs = qx{/usr/bin/ppriv -q file_dac_read};
  my $status = $? >> 8;
  unless ($status == 0) {
    $test->test_skip("Cannot run tests without proper privilege for mdb -k");
  }

}

sub test_setup {
  my $test = shift;
  my $test_method = $test->test_report->current_method;

  if ( 'test_without_priv' eq $test_method->name ) {
      $test->test_skip("Need to handle failure in non-privileged case");
  }
}

sub test_load {
  my $test = shift;

  use_ok($test->test_class);
}

# This test will be used to test the code in the constructor when we don't
# have the privilege to run mdb -k
sub test_without_priv {
  my $test = shift;

  # TODO: Purposely give up file_dac_read privilege, then try to create Expect
  #       object for mdb
}

sub test_expect_meta {
  my $test = shift;

  my $mdb = Solaris::mdb->new();

  my $e = $mdb->mdb;
  isa_ok($e, 'Expect', 'Should be Expect object');

  cmp_ok($e->log_stdout(), '==', 0, 'Logging to STDOUT disabled');
  cmp_ok($e->raw_pty(), '==', 1, 'Raw pty enabled');
}

sub test_expect_mdb_exits_ok {
  my $test = shift;

  my $mdb = Solaris::mdb->new();
  my $e = $mdb->mdb;
  isa_ok($e, 'Expect', 'Should be Expect object');

  cmp_ok($e->pid(), '>', 0, "PID is real");

  # Wait for one second, for any output whatsoever
  $e->expect(1);
  # Now check to see if mdb has emitted its famous init message
  like($e->before(), qr/Loading\s+modules:/sm, 'Loading modules message');

  #$e->hard_close();
  #cmp_ok($e->exitstatus(), '==', 1, 'hard close exit status 1');
}

1;
