package TestsFor::Solaris::mdb;

use Path::Class::File ();

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';


sub test_startup {
  my ($test, $report) = @_;
  $test->next::method;

  # Log::Log4perl Configuration in a string ...
  my $conf = q(
    #log4perl.rootLogger          = DEBUG, Logfile, Screen
    log4perl.rootLogger          = DEBUG, Screen
  
    #log4perl.appender.Logfile          = Log::Log4perl::Appender::File
    #log4perl.appender.Logfile.filename = test.log
    #log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
    #log4perl.appender.Logfile.layout.ConversionPattern = [%r] %F %L %m%n
  
    log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr  = 0
    log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
  );

  # ... passed as a reference to init()
  Log::Log4perl::init( \$conf );

  # Exract live data tests if LIVE_TEST_DATA env variable exists and is set to a
  # 'truthy' value
  #if ( exists($ENV{'LIVE_TEST_DATA'}) and $ENV{'LIVE_TEST_DATA'} ) {
  #  # TODO: Only proceed if we're running on Solaris 11 or later
  #  diag "LIVE_TEST_DATA is set: testing with live data";
  #} else {
  #  diag "Testing with canned data";
  #  diag "If you want to test with live data, set envvar LIVE_TEST_DATA=1";
  #}
}



sub test_constructor {
  my ($test, $report) = @_;

  my $mdb = new_ok("Solaris::mdb" => [],
                   "Object constructed correctly");
}

sub test_expect {
  my ($test, $report) = @_;

  my $mdb = new_ok("Solaris::mdb" => [ ],
                   "Object constructed correctly");

  isa_ok $mdb->expect, 'Expect',
    'lazy builder for Expect object works as expected';

  isnt($mdb->expect->pid, undef, 'There is an mdb PID');

  can_ok($mdb, 'quit');

#  TODO: {
#    local $TODO = "Not done figuring out Try::Tiny exceptions";
#
   my $bad_mdb = new_ok("Solaris::mdb" => [ "mdb_bin", "/usr/bin/junk_mdb" ], 
     "Create object with bad mdb_bin");

   dies_ok { $bad_mdb->expect } 'expect to die while trying to build Expect object';

   #throws_ok( sub { $bad_mdb->expect },
   #           "Cannot execute mdb_bin",
   #           'expect to die while trying to build Expect object' );

    undef $bad_mdb;
#  }
}

sub test_quit {
  my $test = shift;

  my $mdb = new_ok("Solaris::mdb" => [ ],
                   "Object constructed correctly");

  isa_ok $mdb->expect, 'Expect',
    'lazy builder for Expect object works as expected';

  isnt($mdb->expect->pid, undef, 'There is an mdb PID');

  can_ok($mdb, 'quit');

  ok($mdb->quit(), 'Ran quit() method');

  is($mdb->expect->pid, undef, 'mdb PID is now gone');
}

sub test_kvar_exists {
  my $test = shift;

  my $mdb = new_ok("Solaris::mdb" => [ ],
                   "Object constructed correctly");

  isa_ok $mdb->expect, 'Expect',
    'lazy builder for Expect object works as expected';

  diag("This is the pid: " . $mdb->expect->pid);

  cmp_ok($mdb->expect->pid, ">", 0, 'There is a valid mdb PID');

  can_ok($mdb,'kvar_exists');

  # Pick a well known and *very* unlikely to be eliminated kernel variable
  cmp_ok($mdb->kvar_exists('bufhwm'), "==", 1, "real kernel variable exists");

  cmp_ok($mdb->kvar_exists('bogus_kvar'), "!=", 1,
         "bogus kernel variable is not present");
}
