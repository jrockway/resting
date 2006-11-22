package Resting;

use warnings;
use strict;
use base 'Exporter';
use Getopt::Long;
use Carp;
use Getopt::Long;
use CGI;
use DBIx::Class;
use Template;
use URI;
use Symbol;
use Text::SimpleTable;
use Template;

our @EXPORT_OK = qw{application database table group page
                    debug message info warning error
		    style doctype html xhtml
		    after before everything
		    insert all
		    text varchar integer datetime
		    primary foreign key
		    request stash method
		    public group
		    show form template
                    start test
		};
our @EXPORT  = @EXPORT_OK;
our $VERSION = '0.01';

=head1 NAME

Resting - micro web framework

=head1 SYNOPSIS

C<Resting> lets you write a 1-file MVC web app.  It's good for
protoyping small apps before implementing them with a real framework,
like L<Catalyst|Catalyst>.

     [[[ TODO: copy-n-paste blog.pl here ]]]

=head1 METHODS

=cut

## 'global' variables
my $app_name = 'Resting';
my $errors = 0;
my %pages;
my $database;
my %tables;
my %groups;
my $output;
my $html = 'xhtml'; 
my $doctype = bless \$html => 'xhtml';
my %style;
my @before;
my @after;
my %stash;
my %flash;
my $request;
my %templates;
my $already_started = 0;

## signal handlers
$SIG{__WARN__} = sub { my $m=shift; chomp $m; warning($m) };
$SIG{__DIE__}  = sub { $errors = 1; my $m=shift; chomp $m; fatal($m); };

sub application(;$){
    $app_name = shift if $_[0];
    return $app_name;
}

## logging
sub debug($) {
    return if $ENV{NO_RESTING_DEBUG};
    print {*STDERR} "[$app_name:$$][debug] @_\n";
}
sub warning($){
    print {*STDERR} "[$app_name:$$][warn] @_\n";
}
sub message($){
    print {*STDERR} "[$app_name:$$][message] @_\n";
}
# kills request
sub error($){
    print {*STDERR} "[$app_name:$$][error] @_\n";
    local $SIG{__DIE__};
    die @_; # eval can trap this
}
# kills program
sub fatal($){
    print {*STDERR} "[$app_name:$$][fatal] *** @_\n";
    local $SIG{__DIE__};
    die(@_);
}
sub info($){
    print {*STDERR} "[$app_name:$$][info] @_\n";
}

## page functions ##

sub page($@) {
    my $name   = shift;
    my %params = @_;

    debug "Registering page $name";
    
    my $page = \%params;
    $page->{template} ||= $name;
    $page->{action}   ||= main->can($name);

    if($page->{action} && Resting->can($name) && 
       $page->{action} == Resting->can($name)){
	warning "Action for $name conflicts with Resting's internals!";
	delete $page->{action};
    }
    
    if(!$page->{action} && $page->{template}){
	$page->{action} = sub { show(template($pages{$name}->{template}))};
    }

    croak "No action specified for $name" if !$page->{action};
    
    return $pages{$name} = $page;
}

## database  functions ##


sub database(;$) {
    my $connect_info = shift;
    $database = $connect_info if $connect_info;
    return $database;
}


sub table($@){
    my $name = shift;
    my %cols = @_;

    debug "Declaring table $name: @_";
}

# column attributes

sub key(;$$){
    my $fk_table = shift;
    my $fk_col   = shift;

    if($fk_table && $fk_col){
	return {foreign => 1, table => $fk_table, column => $fk_col};
    }
    
    else {
	return {primary => 1};
    }
}

sub primary($){
    my $key = shift;
    return $key;
}

sub foreign($){
    my $key = shift;
    return $key;
}

# database types
sub varchar($){
    return {type => 'varchar', length => $_[0]};
}

sub datetime(){
    return {type => 'datetime'};
}

sub text(){
    return {type => 'text'};
}

sub integer(;$){
    # optional $ is for "integer primary key" syntax
    return {type => 'integer', @%{$_[0]}};
}

# database operations

sub all($){
    my $table = shift;
    debug "Returning everything in $table";
}

sub insert($$){
    my $what  = shift;
    my $where = shift;
    debug "Inserting $what into $where";
}

## acl stuff ##


sub group($){
    my $name = shift;
    debug "Registering group $name";
}

sub public(){
    debug "Public access";
}

## template stuff

sub show($){
    my $what = shift;
    $what = $what->{template} if ref $what;
    
    debug "Rendering $what";
    eval {
	$output = _render_template($what);
    };
    die "Couldn't render template $what: $@" if $@;
    goto actionexec;
}

sub _render_template($){
    my $template = shift;
    my $tt = Template->new({EVAL_PERL => 1});
    my $vars = \%stash;

    my $result;
    $template = $templates{$template};
    $tt->process(\$template, $vars, \$result)
      || die $tt->error();
    return $result;
}


sub template($){
    my $template = shift;
    return {template => $template};
}

sub form($){
    my $table = shift;
    debug "Generate form for $table";
    return "form: $table";
}

## generated HTML stuff


sub doctype(;$){
    $doctype = $_[0];
    debug "Doctype is set to $doctype";
    return $doctype;
}


sub style($$){
    # need to merge hashes here
    debug "adding style info";
}

sub html(){
    return "html";
}

sub xhtml() : lvalue {
    my $type = "xhtml";
    my $ref = \$type;
    bless $ref => 'xhtml'; # heh
    return $ref;
};

# nothing more specific yet
sub everything($){
    return  $_[0];
}



sub before($){
    my $template = shift;
    push @before, $template if $template;
    return @before if wantarray;
    return $template;
}

sub after($){
    my $template = shift;
    push @after, $template if $template;
    return @after if wantarray;
    return $template;
}


## request stuff


sub stash(;$$){
    my $name = shift;
    if($name){
	my $data = shift;
	$stash{$name} = $data;
    }
    return \%stash;
}


sub flash(;$$){
    my $name = shift;
    if($name){
	my $data = shift;
	$flash{$name} = $data;
    }
    return \%flash;
}


sub method() {
    return $request->{method};
}

sub params() {
    return $request->{params};
}

sub args() {
    return @{$request->{args}||[]};
}


## dispatcher

sub _dispatch($) {
    my $path  = shift;
    $request->{path} = $path;
    
    my ($action, @args) = _find_action($path);
    return sub { $action->{action}->(@args, @_) };
}

sub _find_action($){
    my $path = shift;
    my ($action, @args);
    my $orig_path = $path;
    
    $path =~ s{^/}{};

    $action = $pages{index};
    $action = $pages{"$path/index"} if $path;
    
    while(!$action && $path){
	$action = $pages{$path};
	last if $action;

	$action = $pages{"$path/default"};
	last if $action;
	
	if($path =~ m{^(.+)/([^/]*)$}){
	    $path = $1;
	    unshift @args, $2;
	}
	else {
	    $path = "";
	}
    };

    $action = $pages{default} if !$action;
    die "No action found for $orig_path" if !$action;
    
    return ($action, @args);
}


## misc exportable functions

=head2 test($path)

Try a test request against C<$path>.  Returns the result of the request,
or dies on failure.

=cut
    
sub test($){
    my $path = shift;    
    my $uri  = URI->new;
    $uri->path($path);
    
    croak "Must request a path" if !$path;
    debug "Request for @{[$uri->as_string]}";
    return _request($uri);
}

sub _request($){
    my $uri = shift;
    my $path = $uri->path;
    start();
    
    # clear request globals;
    $output = "";
    %stash = ();
    $request = {uri => $uri, path => $path};
    
    my $action = eval {
	_dispatch $path;
    };
    die "Error getting action for $path: $@" if($@ || !$action);

    my $result;
    eval {
	$result = $action->();
	return;
      actionexec:
	$result = $output;
    };
    die "Error executing action: $@" if $@;
    return $result;
}

## setup


sub _load_templates(){
    my $templates = do { no warnings; local $/; <DATA> ."\n". <main::DATA> };
    return unless $templates;
    my @lines = split/\n/, $templates;
    my $line_count = 1;
    my $cur_template;

    foreach my $line (@lines){
	if($line =~ /^__(.+)__/){
	    $cur_template = $1;
	}
	else {
	    die "invalid template format at __DATA__:$line_count" 
	      if !$cur_template; 
	    $templates{$cur_template} .= $line;
	}
	$line_count++;
    }
}

## main loop
sub start() {
    return if $already_started;
    $already_started = 1;

    # load everything
    _load_templates();

    # setup cookies
    # setup request object
    
    # print actions
    my $actions = Text::SimpleTable->new([14, 'page'], [14, 'template'], 
					 [40, 'action']); 
    foreach my $page (keys %pages){
	$actions->row($page, $pages{$page}->{template}, $pages{$page}->{action});
    }

    # print templates
    my $templates = Text::SimpleTable->new([14, 'name'], [57, 'summary']);
    foreach my $template (keys %templates){
	next if $template =~ /^_/; # internal use only
	my $t = $templates{$template};
	$t =~ /(.{0,57})/;
	$templates->row($template, $1);
    }
    
    # print database tables
    debug "Loaded pages\n". $actions->draw();
    debug "Loaded templates\n". $templates->draw();
    info "$app_name initialized!  Starting.";    
}

END {
    return if(scalar keys %pages == 0); # nothing to do
    # auto-start the app if start() isn't explicitly called
    start unless $already_started;
}
1;

=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-resting at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Resting>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Resting

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Resting>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Resting>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Resting>

=item * Search CPAN

L<http://search.cpan.org/dist/Resting>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Resting

package xhtml; # xhtml++ is xml 
use overload 
  fallback => 1, 
  '""' => sub { ${$_[0]} },
  '++' => sub { my $x = 'xml'; $_[0] = bless \$x };
1;

package Resting;
# HTML that we use internally

__DATA__
___html__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
  <head>[% internal.head %]</head>
  <body>[% internal.body %]</body>
</html>
___xhtml__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
  <head>[% internal.head %]</head>
  <body>[% internal.body %]</body>
</html>
___xml__
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
                      "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"
      xml:lang="en">
  <head>[% internal.head %]</head>
  <body>[% internal.body %]</body>
</html>
___frag_resting_messages__
<div id="resting_messages">
  [% IF errors %] <div class="errors">[% internal.errors %]</div>[% END %]
  [% IF warnings %] <div class="messages">[% internal.warnings %]</div>[% END %]
  [% IF messages %] <div class="messages">[% internal.messages %]</div>[% END %]
</div>
___frag_resting_menu__
<div id="resting_menu">
[% internal.menu %]
</div>
___frag_css__
<style>
  #resting_messages .errors {
    color: red;
  }
</style>
___frag_header__
[% internal.css %]
<title>[% internal.title %]</title>
