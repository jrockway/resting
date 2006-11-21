package Resting;

use warnings;
use strict;
use base 'Exporter';
use Carp;
use CGI;
use DBIx::Class;
use Template;
use URI;
use Text::SimpleTable;

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

# TODO
#local $SIG{__DIE__} = sub {
#    print {*STDERR} "fatal error: @_";
#    exit(255);
#};

my $app_name = 'Resting';
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
sub error($){
    print {*STDERR} "*** [$app_name:$$][error] @_\n";
}
sub info($){
    print {*STDERR} "[$app_name:$$][info] @_\n";
}

## page functions ##
my %pages;
sub page($@) {
    my $name   = shift;
    my %params = @_;
    
    debug "Registering page $name";
    $pages{$name} = {
		     action   => ($params{action}   || $::{(caller)[0]}),
		     template => ($params{template} || $name)
		    };
}

## database functions ##

my $database;
sub database(;$) {
    my $connect_info = shift;
    debug "Setting current database to $connect_info"; 
}

my %tables;
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
	debug "Adding foreign key relation to $fk_table.$fk_col";
    }

    else {
	debug "Adding primary key";
    }

}

sub primary($){
    my $key = shift;
    debug "Primary key";
}

sub foreign($){
    my $key = shift;
    debug "Foreign key";
}

# database types
sub varchar(;$){
    return 1;
}

sub datetime(){
    return 1;
}

sub text(){
    return 1;
}

sub integer(;$){
    # optional $ is for "integer primary key" syntax
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

my %groups;
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
    debug "Showing $what";
}

sub template($){
    my $template = shift;
    debug "Template $template";
    return "template: $template";
}

sub form($){
    my $table = shift;
    debug "Generate form for $table";
    return "form: $table";
}

## generated HTML stuff
my $doctype = "xml";
sub doctype($){
    $doctype = $_[0] if $_[0];
    debug "doctype is $doctype now";
    return $doctype;
}

my %style;
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

sub everything($){
    return $_[0];
}

sub before($){
    my $template = shift;
    debug "Will print '$template' before content";
    return $template;
}

sub after($){
    my $template = shift;
    debug "Will print '$template' after content";
    return $template;
}


## request stuff

sub stash($@){
    my $name = shift;
    my @data = @_;
    debug "Stashing $name";
}

my $request;
sub request() {
    return "Resting"; # used like 
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

##
sub _error($$){
    my $code = shift;
    my $msg  = shift;
    return "Error $code: $msg\n";
}

sub _find_action($){
    my $path = shift;
    my ($action, @args);
    do {
	$action = $pages{$path};
	last if $action;
	$path =~ m{(.+)/([^/]+)};
	$path = $1;
	unshift @args, $2;
    } while($path);
    # todo: index, default
    return ($action, @args);
}

## dispatcher

## real functions

sub _dispatch($) {
    my $uri  = shift;
    $request->{path} = $uri;
    my $path = $uri->path;    

    my ($action, @args) = _find_action $path;
    return _error 404, "No action matching `$path'" if $@;
    
}

sub test($){
    my $path = shift;
    my $uri = URI->new;
    $uri->path($path);
    _dispatch $uri;
    return "Hello, world!";
}

## main loop
my $already_started = 0;
sub start() {
    $already_started = 1;
    my $actions = Text::SimpleTable->new([15, 'page'], [15, 'template'], 
					 [50, 'action']); 
    foreach my $page (keys %pages){
	$actions->row($page, $pages{$page}->{template}, $pages{$page}->{action});
    }
    debug "Loaded pages";
    debug "\n". $actions->draw();
    debug "$app_name initialized!  Starting.";    
}

END {
    return if(scalar keys %pages == 0); # nothing to do
    # auto-start the app if start() isn't explicitly called
    start unless $already_started;
}


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
  '""' => sub { return "xhtml" },
  '++' => sub { return "xml"   };
1;