#!/usr/bin/perl
# basic.t
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 5;
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
