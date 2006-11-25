#!/usr/bin/perl
# server-simple.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 4;
use Resting;
use LWP::UserAgent;

ok(start(), 'start app');

my $pid;
if(($pid = fork()) == 0 ){
    Resting::_server();
}

sleep 1;
my $ua = LWP::UserAgent->new;
my $response = $ua->get('http://localhost:3000/');

ok($response->is_success, 'request was successful');
like($response->content, qr/Everything is ok[.]/, 'content was correct');
kill 15, $pid or warn "Can't kill $pid: $!";
waitpid $pid, 0;
is($?, 15, "$pid exited");

BEGIN {
    application "ServerTest";
    page 'default';
}

__DATA__
__default__
Everything is ok.
