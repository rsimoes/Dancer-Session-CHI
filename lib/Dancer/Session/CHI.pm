package Dancer::Session::CHI;

use strict;
use warnings;
use utf8;
use Carp;
use CHI;
use Dancer::Logger;
use Dancer::Config "setting";
use Dancer::ModuleLoader;
use File::Spec::Functions "rel2abs";


use base "Dancer::Session::Abstract";

# VERSION
# ABSTRACT: CHI-based session engine for Dancer

my $chi;

# Class methods:

sub create {
	my ($class) = @_;
	my $self = $class->new;
	$self->flush;
	my $session_id = $self->id;
	Dancer::Logger->debug("Session (id: $session_id) created.");
	return $self }

sub retrieve {
	my (undef, $session_id) = @_;
	$chi ||= _build_chi();
	return $chi->get("session_$session_id") }

# Object methods:

sub flush {
	my ($self) = @_;
	$chi ||= _build_chi();
	my $session_id = $self->id;
	$chi->set( "session_$session_id" => $self );
	return $self; }

sub destroy {
	my ($self) = @_;
	my $session_id = $self->id;
	$chi->remove("session_$session_id");
	Dancer::Logger->debug("Session (id: $session_id) destroyed.");
	return $self }

sub reset :method {
	my ($class) = @_;
	$chi->clear;
	return $class }

sub _build_chi {
	my $options = setting("session_CHI");
	( ref $options eq ref {} ) or croak "CHI session options not found";

	# Don't let CHI determine the absolute path:
	exists $options->{root_dir}
		and $options->{root_dir} = rel2abs($options->{root_dir});

	my $use_plugin = delete $options->{use_plugin};
	my $is_loaded = exists setting("plugins")->{"Cache::CHI"};
	( $use_plugin && !$is_loaded )
		and croak "CHI plugin requested but not loaded";

	return $use_plugin
		? do {
			my $plugin = "Dancer::Plugin::Cache::CHI";
			my $error_msg = "$plugin is needed and is not installed";
			Dancer::ModuleLoader->load($plugin)
				  or raise( core_session => $error_msg );
			Dancer::Plugin::Cache::CHI::cache() }
		: CHI->new( %{$options} ) }

1;
