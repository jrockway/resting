package Resting;

use warnings;
use strict;
use base 'Exporter';
use Getopt::Long;
use Carp;
use CGI;
use DBIx::Class;
use Template;
use Text::SimpleTable;
use URI;
use HTTP::Request;
use HTTP::Response;
use HTTP::Daemon;
use Readonly;

our @EXPORT_OK = qw{application database table group page
                    debug message info warning error
		    style doctype html xhtml
		    after before everything
		    insert all
		    text varchar integer datetime
		    primary foreign key
		    request stash method
		    public group
		    detach forward show form template
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

## constants

Readonly 
  my %LOG_LEVEL_FOR => (debug	  => 6,
			info	  => 5,
			information  => 5,
			message	  => 4,
			mess	  => 4,
			warning	  => 3,
			warn         => 3,
			error        => 2,
			err          => 2,
			fatal        => 1,
			critical     => 1,
			quiet        => 0,
		       );

## 'global' variables
my $app_name = 'Resting';
my $log_level = $LOG_LEVEL_FOR{warning};
   $log_level = $LOG_LEVEL_FOR{debug} if $ENV{RESTING_DEBUG};
my %pages;
my $database;
my %tables;
my %groups;
my $output;
my $doctype = 'xhtml';
my %style;
my @before;
my @after;
my %stash;
my %flash;
my $request;
my %templates;
my $template;
my $already_started = 0;
my $req_table;
my %sessions;

## signal handler
$SIG{__WARN__} = sub { my $m=shift; chomp $m; warning($m) };

sub application(;$){
    $app_name = shift if $_[0];
    return $app_name;
}

## logging
sub _msg($;@){
    my $level = shift;
    
    return if $log_level < ($LOG_LEVEL_FOR{$level} || 0);
    print {*STDERR} "[$app_name:$$][$level] @_\n";
}

sub debug($)  { _msg('debug',@_) }
sub warning($){ _msg('warn', @_)  }
sub message($){ _msg('message', @_) }

# kills request
sub error($){
    _msg('error', @_);
    local $SIG{__DIE__};
    die @_; # eval can trap this
}

# kills program
sub fatal($){
    _msg('fatal'," *** @_");
    local $SIG{__DIE__};
    die(@_);
}

sub info($){
    _msg('info', @_);
}

## page functions ##

sub page($@) {
    my $name   = shift;
    my %params = @_;

    debug "Registering page $name";
    
    my $page = \%params;
    $page->{template} ||= $name;
    $page->{action}   ||= main->can($name);
    $page->{name}       = $name; # for display later
    
    # check to make sure the user doesn't accidentally
    # specify an exported sub as an action (test is a common one)
    if($page->{action} && Resting->can($name) && 
       $page->{action} == Resting->can($name)){
	warning "Action for $name conflicts with Resting's internals!";
	delete $page->{action};
    }
    
    # if no action is specified, just render the template
    if(!$page->{action} && $page->{template}){
	$page->{action} = sub { show(template($pages{$name}->{template}))};
    }
    
    # no action AND no template (?)
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
    
    eval {
	$output = _render_template($what);
    };
    die "Couldn't render template $what: $@" if $@;
    detach();
}

sub _render_template($){
    my $template_name = shift;
    die "No template to render" if !$template_name;

    my $tt = Template->new({EVAL_PERL => 1});
    my $vars = \%stash;
    $req_table->row('render template', $template_name);
    
    my $result;
    $template = $templates{$template_name};
    $tt->process(\$template, $vars, \$result)
      || die $tt->error();
    return $result;
}

sub template(;$){
    my $_template = shift;
    $template = $_template if $_template;
    return $template;
}

sub form($){
    my $table = shift;
    debug "Generate form for $table";
    return "form: $table";
}

## generated HTML stuff
sub style($$){
    # need to merge hashes here
    debug "adding style info";
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
    return eval { $request->can('method')->() };
}

sub params() {
    return $request->{params};
}

sub args() {
    return @{$request->{args}||[]};
}


## dispatcher

sub _run_action($;@){
    my $name   = shift;
    my @args   = @_;
    my $action = $pages{$name};
    die "Cannot run '$action': no action" if !$action->{action};
    template($action->{template}) if !template(); # default template
    _action_row($name, @args);
    return $action->{action}->(@args);
}

sub detach(;$) {
    my $where = shift;
    forward($where) if($where);
    $req_table->row('detach');
    goto actionexec;    
}

# dispatch to private name
sub forward($;@){
    my $where = shift;
    $req_table->row("forward to $where");
    return _run_action($where, @_);
}

sub _find_action($){
    my $path = shift;
    my ($action, @args);
    my $orig_path = $path;
    
    $path =~ s{^/}{};
    $path =~ s{/$}{};

    $action = $pages{index};
    $action = $pages{"$path/index"} if $path;


    while(!$action && $path){
	#debug "Path: $path (@args)";
	# "index" and "default" becomes an arguments
	while($path =~ m{^(.*)/?(index|default)$}){
	    $path = $1;
	    unshift @args, $2;
	}
	
	# try matching the literal path
	$action = $pages{$path};
	last if $action;
	
	# or perhaps the nearest default action
	$action = $pages{"$path/default"};
	last if $action;
	
	# failing that, strip off an argument, and try again
	if($path =~ m{^(.+)/([^/]*)$}){
	    $path = $1;
	    unshift @args, $2 if $2;
	}
	else {
	    unshift @args, $path;
	    $path = "";
	}
    };
    
    $action = $pages{default} if !$action;
    die "No action found for $orig_path" if !$action;

    return ($action, @args);
}

# given an HTTP::Request, generate an HTTP::Response
sub request($){
    my $req = shift;
    my $res = HTTP::Response->new(200);
    my $result;

    eval {
	$result  = _request($req);
    };
    if($@ && !$result){
	$res->code(500);
	
	if ($@ =~ /N(o action|ot) found/){
	    $res->code(404);
	}
	$result = $@;
    }
    
    $res->content($result);    
    return $res;
}

my $request_count = 0;
sub _request($){
    $request = shift;
    my $path = $request->uri->path;
    start();
    $request_count++;
    
    # clear request globals;
    undef $output;
    undef %stash;
    undef $template;
    
    $req_table = Text::SimpleTable->new([28, 'action'],[42, 'details']);
    
    my $result;
    eval {	
	# find action
	my ($action, @args) = _find_action($path);     
	
	# run action
	$result = _run_action($action->{name}, @args);
	stash('_result', $result);
	
	# render template
	$result = _render_template($template) if template();
	return;
	
	# if show(), etc. is called, jump here immediately
      actionexec:
	$result = $output;
	$result = _render_template($template) if template() && !$output;
    };
    $req_table->row('error', $@) if($@);
    
    debug "Request for '$path' [$request_count]:\n". 
      $req_table->draw;
    die "Error executing action: $@" if $@;
    
    $result = _finalize_output($result);    
    return $result;
}

sub _action_row {
    my $action = shift;
    my $args = @_ ? 'arguments '. join ',', map {"{$_}"} @_
      : 'no arguments';
    
    $req_table->row("run $action", $args);
}

sub _finalize_output($){
    my $in = shift;
    my $result;
    
    my $tt  = Template->new;
    my $stash = {%stash, Resting => {body => $in}};
    my $template = $templates{_main};
    
    $tt->process(\$template, $stash, \$result)
      or die "Error finalizing output: ". $tt->error;
    
    return $result;
}

## setup


sub _load_templates(){
    my $templates = do { no warnings; local $/; <DATA> ."\n". <main::DATA> };
    return unless $templates;
    my @lines = split/\n+/, $templates;
    my $line_count = 1;
    my $cur_template;

    foreach my $line (@lines){
	if($line =~ /^__(.+)__/){
	    $cur_template = $1;
	}
	else {
	    die "invalid template format at __DATA__:$line_count" 
	      if !$cur_template; 
	    $templates{$cur_template} .= "$line\n";
	}
	$line_count++;
    }
}

# init the app
sub start() {
    return if $already_started;
    $already_started = 1;

    # load everything
    _load_templates();

    # setup cookies
    # setup request object
    
    # print actions
    my $actions = Text::SimpleTable->new([14, 'page'], 
					 [14, 'path'],
					 [14, 'template'], 
					 [23, 'action']); 
    foreach my $page (sort keys %pages){
	my $title = $page;
	if ($title =~ m{(.*)(?:^|/)index$}) {
	    $title = "$1/";
	}
	elsif($title =~ m{(.*)/?default}){
	    $title = "$1/*";
	}
	if($title !~ m{^/}){
	    $title = "/$title";
	}
	
	$actions->row($page, $title, $pages{$page}->{template}, 
		      $pages{$page}->{action});
	
    }

    # print templates
    my $templates = Text::SimpleTable->new([14, 'name'], [57, 'summary']);
    foreach my $template (sort keys %templates){
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

sub _server(){
    my $d = HTTP::Daemon->new(LocalPort=>3000, ReuseAddr=>1 ) 
      || die "Cannot start server";
    info "Server started at <". $d->url. ">.  Press C-c to abort.";
    my $kids = 0;
    my $server_done;
    
    local $SIG{INT} = sub { $server_done = 1 };    
    while ((my $c = $d->accept) && !$server_done) {
	eval {
	    # catch the SIG{INT} handler when we're not already
	    # inside an eval

	    while ((my $r = $c->get_request) && !$server_done) {
		local $SIG{INT} = sub { 
		    die "Action aborted by keyboard interrupt";
		};
		    
		my $response = request($r);
		$c->send_response($response);
	    }
	    $c->close;
	    undef $c;
	};
    }
    
    debug "Shutting down the server";
    $d->shutdown(2);
    return;
}

sub _process_options(){
    my $test;
    my $server;
    my $debug = 0;
    my $log;
    GetOptions(
	       "debug"  => \$debug,
	       "test=s" => \$test,
	       "server" => \$server,
	       "log=s"  => \$log,
	      );
    
    # setup log level
    if(!defined $ENV{RESTING_DEBUG}){
	# only change if there isn't an environ variable setup
	if($log){
	    # change to the specified level
	    $log_level = $LOG_LEVEL_FOR{$log} || die "No log level $log";
	}
	# override --log xxx if --debug is set
	$log_level = $LOG_LEVEL_FOR{debug} if $debug;
    }
    
    return {test => $test, server => $server};

}

END {
    return if $already_started;
    return if(scalar keys %pages == 0); # nothing to do
    
    my $options = _process_options();
    # auto-start the app if start() isn't explicitly called
    start();
    
    if($options->{test}){
	print test($options->{test});
	exit(0);
    }
    
    if($options->{server}){
	_server();
	exit(0);
    }
}

## misc exportable functions

=head2 test($path)

Try a test request against C<$path>.  Returns the result of the request,
or dies on failure.

=cut
    
sub test($){
    my $path = shift;    
    my $uri  = URI->new;
    # clean up the URI a bit
    $uri->path($path); 
    $path = $uri->path;
    croak "Must request a path" if !$path;

    my $req = HTTP::Request->new(TEST => $uri);    
    return _request($req);
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

__DATA__
___main__
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
                      "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"
      xml:lang="en">
 <head>
  <title>[% GET Resting.title %]</title>
  [% FOREACH script = Resting.scripts -%]
   <script type="text/javascript" src="[% script %]">
  [% END -%]
  [% PROCESS resting_styles -%]
 </head>
  <body>
  [% PROCESS resting_messages -%]
  [% Resting.body -%]
 </body>
</html>

[% BLOCK resting_messages -%]
<div id="resting_messages">
  [% IF Resting.errors   %] <div class="errors">  [% Resting.errors %]  </div>[% END -%]
  [% IF Resting.warnings %] <div class="messages">[% Resting.warnings %]</div>[% END -%]
  [% IF Resting.messages %] <div class="messages">[% Resting.messages %]</div>[% END -%]
</div>
[% END -%]

[% BLOCK resting_menu %]
<div id="resting_menu">
[% internal.menu %]
</div>
[% END %]

[% BLOCK resting_styles %]
<style>
  #resting_messages .errors {
    color: red;
  }
</style>
[% END %]
