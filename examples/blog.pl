#!/usr/bin/perl
# blog.pl 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Resting;
use strict;
use warnings;

application 'Blog';
database 'dbi:SQLite:blog.db';

# setup our HTML
style h1 => {color => 'blue'};

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
  action   => \&index,
  access   => public;

page 'articles';
# default action is &articles
# default access is public
# default template is 'articles'

page post  =>
  action   => \&post,
  access   => ['posters', 'admins'];

# that's it

sub index {
    stash posts => (all 'posts')[0..5];
}

sub post {
    if (method eq 'GET') {
	show template 'postform';
    } else {
	insert formdata => 'posts';
	show template 'postok';    
    }
}

sub articles {
    stash posts => all 'posts';
}

__DATA__
__index__
<h1>Welcome to the blog!</h1>
<ul>
[% FOREACH post = posts %]
<li>
  <div class="post">
   <div class="header">
    <p><b>[% post.title %]</b></p>
    <p>Written by [% post.author %] on [% post.date %]</p>
   </div>
   <div class="body">
     [% post.body %]
   </div>
  </div>
</li>
[% END %]
</ul>
__post__
Fill out this form to post:
[% form %]
__postok__
Thanks for posting an entry!
__articles__
<p>Here are all the posts that have ever been posted.</p>
<ul>
[% FOREACH post = posts %]
<li>[% post.author %] wrote "[% post.title %]".</li>
[% END %]
</ul>
