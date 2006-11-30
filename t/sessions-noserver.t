#!/usr/bin/perl
# sessions-noserver.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 4;
use Resting;

my $result;

$result = test('get');
like($result, qr/foo is set to NOTHING/, 'foo is NOTHING');
$result = test('set');
like($result, qr/foo was set to bar[.]/, 'foo set to bar');
$result = test('get');
like($result, qr/foo is set to bar[.]/, 'foo is still bar');
$result = test('get');
like($result, qr/foo is set to NOTHING/, 'foo is NOTHING');

BEGIN {
    application 'SessionTest';

    page 'set' => action {
	flash foo => 'bar';
    };

    page 'get' => action {
	stash foo => flash 'bar';
    }
}

__DATA__
__set__
foo was set to bar.
__get__
foo was set to [% IF foo.defined  %][% foo %][% ELSE %]NOTHING[% END %].
