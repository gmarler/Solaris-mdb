# NOTE: TF stands for TestsFor::...
package TF::Solaris::mdb::Variable;

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

sub test_startup {
  my $test = shift;

  unless ($^O eq 'solaris') {
    $test->test_skip("Tests won't run on $^O");
  }
}

sub test_setup {
  my $test = shift;
  my $test_method = $test->test_report->current_method;

  #
  # To be used if we need to skip certain tests
  #
  #if ( 'test_without_priv' eq $test_method->name ) {
  #    $test->test_skip("Need to handle failure in non-privileged case");
  #}
}

sub test_load {
  my $test = shift;

  use_ok($test->test_class);
}

sub test_instance_attributes {
  my $test = shift;

  # More appropriate as class attributes/methods
  #can_ok($test->test_class, 'name');
  #can_ok($test->test_class, 'size_bytes');

  my $v = Solaris::mdb::Variable->new( name => 'bogus_variable' );

  isa_ok($v, 'Solaris::mdb::Variable');
  can_ok($v, 'name');
  can_ok($v, 'size_bytes');
}
