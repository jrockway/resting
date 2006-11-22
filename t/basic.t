#!/usr/bin/perl
# basic.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 11;
use FindBin qw($Bin);
use File::Spec;

my $test = File::Spec->catfile($Bin, 'scripts', 'run.pl');
ok(-e $test, 'test script exists');
ok(do($test), "start $test");

{
    my $output = test('/test');
    like($output, qr/The test works!/i, 'got test message');
}

{
    my $output = test('/');
    like($output, qr/Hello, world!/i, 'got hello world');
}

{
    my $output = test('/this/does/not/exist');
    like($output, qr/Not found/i, 'not found');
}

# these test template rendering when show() isn't called
# as well as arguments
{
    my $output = test('/arguments/1');
    like($output, qr/Argument 1/i, 'arguments/1');
}

{
    my $output = test('/arguments/2');
    like($output, qr/Argument 2/i, 'arguments/2');
}

# test non-root paths
{
    my $output = test('/foo');
    like($output, qr/This is the foo index./i, 'real foo index');
}
{
    my $output = test('/foo/');
    like($output, qr/This is the foo index./i, 'real foo index');
}
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

