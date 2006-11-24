#!/usr/bin/perl
# run.pl 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Resting;

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
      if($arg == 1){
	  template 'arg_1';
      }
      else {
	  template 'arg_2';
      }
      stash text => 'Argument';
  };

page 'test',
  action => sub { show template 'test' };

page 'foo/index',
  template => 'foo';

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
