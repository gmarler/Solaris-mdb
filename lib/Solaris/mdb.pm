package Solaris::mdb;

use Moose;
use Moose::Util::TypeConstraints;
with 'MooseX::Log::Log4perl';
use namespace::autoclean;
use Log::Log4perl qw(:easy);
use Expect;

has 'expect',     is => 'ro', isa => 'Expect', lazy_build => 1;

#sub _build_expect {
#  my $self = shift;
#  my $exp  =  Expect->new;
#  return $exp;
#}

#sub DEMOLISH {
#  my $self = shift;
#  $self->expect->soft_close();
#}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
