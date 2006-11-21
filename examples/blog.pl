#!/usr/bin/perl
# blog.pl 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Resting;
use strict;
use warnings;

application 'Blog';
database 'dbi:SQLite:blog.db';

# setup our HTML
doctype xhtml++;
style h1 => {color => 'blue'};
before everything 'This is a blog!';
after everything 'I hope you liked it!';

# setup the database
table posts => 
  id     => primary key,
  author => varchar(30),
  time   => datetime,
  title  => text,
  body   => text,
  parent => foreign key(posts => 'id');

# add some groups
group 'posters';
group 'admins';

# add some pages
page index =>
  template => 'index',
  action   => &index,
  access   => public;

page 'history';
# default action is &history
# default access is public
# default template is 'history'

page post  =>
  action   => &post,
  access   => ['posters', 'admins'];

# that's it

sub index {
    my @posts = all 'posts';
    stash posts => @posts;
}

sub post {
    if (request()->method eq 'GET') {
	show template 'postform';
    } else {
	insert request() => 'posts';
	show template 'postok';    
    }
}
__DATA__
__index__
<h1>Welcome to the blog!</h1>
<ul>
[% WHILE post = posts %]
<li>[% post.author %] wrote "[% post.title %]".</li>
[% END %]
</ul>
__post__
Fill out this form to post:
[% form %]
__postok__
Thanks for posting an entry!
  
