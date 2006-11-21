#!/usr/bin/perl
# simple_static_page.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 3;
use FindBin qw($Bin);
use File::Spec;

my $test = File::Spec->catfile($Bin, 'scripts', 'run.pl');
ok(-e $test, 'test script exists');

{
    ok(do($test), "run $test");
    my $output = test('/');
    like($output, qr/Hello, world!/i, 'got hello world');
}
