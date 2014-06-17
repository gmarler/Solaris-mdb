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
  if ( exists($ENV{'LIVE_TEST_DATA'}) and $ENV{'LIVE_TEST_DATA'} ) {
    # TODO: Only proceed if we're running on Solaris 11 or later
    diag "LIVE_TEST_DATA is set: testing with live data";
  } else {
    diag "Testing with canned data";
    diag "If you want to test with live data, set envvar LIVE_TEST_DATA=1";
  }
}



sub test_constructor {
  my ($test, $report) = @_;

  my $mdb = Solaris::mdb->new();

  isa_ok $mdb, $test->class_name,
    'The object the constructor returns';
}


