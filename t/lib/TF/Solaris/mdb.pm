# NOTE: TF stands for TestsFor::...
package TF::Solaris::mdb;

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

sub test_startup {
  my $test = shift;

  unless ($^O eq 'Win32') {
    $test->test_skip("Tests won't run on $^O");
  }
}

sub test_load {
  my $test = shift;

  diag "test load";
}

1;
