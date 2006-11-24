#!/usr/bin/perl
# basic.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Resting;
use Test::More tests => 9;

## the application is at the end of this file

# test named action
{
    my $output = test('/test');
    like($output, qr/The test works!/i, 'got test message');
}

# test (root) index action
{
    my $output = test('/');
    like($output, qr/Hello, world!/i, 'got hello world');
}

# fallthrough without a root-level default action
{
    eval {
	test('/this/does/not/exist');
    };
    ok($@, 'exception thrown when no action matches');
}

# these test template rendering when show() isn't called
# and also test arguments
{
    my $output = test('/arguments/1');
    like($output, qr/Argument 1/i, 'arguments/1');
}

{
    my $output = test('/arguments/2');
    like($output, qr/Argument 2/i, 'arguments/2');
}

# test non-root index
{
    my $output = test('/foo');
    like($output, qr/This is the foo index./i, 'real foo index');
}
{
    my $output = test('/foo/');
    like($output, qr/This is the foo index./i, 'real foo index');
}

# test non-root default action
{
    my $output = test('/foo/1/2');
    # not the foo index!
    unlike($output, qr/This is the foo index./i, 'should not be foo index');
}

# test matching the literal index action
{
    my $output = test('/foo/index');
    # not the foo index!
    unlike($output, qr/This is the foo index./i, 
	   '/foo/index should not be foo index');
}

# the app
BEGIN {
    application 'test';

    page 'foo/default',
      template => 'not_found';

    page 'index';
    sub index {
	stash who => 'world';
	show template 'index';
    }

    page 'arguments',
      action => sub {
	  my $arg = shift;
	  if ($arg == 1) {
	      template 'arg_1';
	  } else {
	      template 'arg_2';
	  }
	  stash text => 'Argument';
      };

    page 'test',
      action => sub { show template 'test' };

    page 'foo/index',
      template => 'foo';
}

__DATA__
__index__
Hello, [% who %]!
__test__
The test works!  Hooray for the "test" action!
__not_found__
404 Not found: The page you're looking for doesn't exist.
__arg_1__
[% text %] 1
__arg_2__
[% text %] 2
__foo__
This is the foo index.
