package Test::Solaris::mdb;

use Test::Class::Moose parent => 'My::Test::Class::AutoUse';

sub test_constructor {
  my ($test, $report) = @_;

  my $mdb = Solaris::mdb->new();

  isa_ok $mdb, $test->class_name, 'The object the constructor returns';
}

1;
