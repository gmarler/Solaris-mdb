use strict;
use warnings;

package Solaris::mdb::Variable;

# VERSION
# ABSTRACT: Provides a Perl interface to Solaris mdb variable instances
#
use namespace::autoclean;
use Expect;
use Moose;

has size_bytes => ( isa        => 'Int',
                    is         => 'ro',
                  # required   => 1,
                  );

has name       => ( isa        => 'Str',
                    is         => 'ro',
                    required   => 1,
                  );



1;
