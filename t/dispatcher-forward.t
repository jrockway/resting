#!/usr/bin/perl
# dispatcher-forward.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Resting;
use Test::More tests => 2;

my $result;
$result = test('bar');
ok($result, 'got bar');

$result = test('foo');
like($result, qr/foo=foo;bar=bar;baz=baz;/, 'forwarding as expected');

BEGIN {
    application 'test';
    
    page 'foo', 
      template => 'foo',
	action => sub {
	    stash baz => 'baz';
	    stash foo => 'foo';
	    forward 'bar';
	    detach;
	    forward 'baz';
	};
    
    page 'bar', action => sub {
	stash bar => 'bar';
    };
    
    page 'baz', action => sub {
	stash baz => 'BAZ!';
    };
    
    page 'default', template => 'default';
}

__DATA__
__foo__
foo=[% foo %];bar=[% bar %];baz=[% baz %];
__default__
ERROR
__bar__
bar
