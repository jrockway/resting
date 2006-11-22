#!/usr/bin/perl
# run.pl 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Resting;

application 'test';
page 'index';

sub index {
    show template 'index';
}

__DATA__
__index__
Hello, world!

