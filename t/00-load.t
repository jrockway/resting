#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Resting' );
}

diag( "Testing Resting $Resting::VERSION, Perl $], $^X" );
