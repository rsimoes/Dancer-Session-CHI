package Dancer::Session::CHI;

use strict;
use warnings;
use utf8;
use Carp;
use CHI;
use Dancer::Logger;
use Dancer::Config "setting";
use Dancer::ModuleLoader;
use File::Spec::Functions qw(rel2abs);
use Storable "dclone";

use base "Dancer::Session::Abstract";

# VERSION
# ABSTRACT: CHI-based session engine for Dancer

# Class methods:

my $chi;

sub create {
	my ($class) = @_;
	my $self = $class->new;
	$self->flush;
	my $session_id = $self->id;
	Dancer::Logger::debug("Session (id: $session_id) created.");
	return $self }

sub retrieve {
	my (undef, $session_id) = @_;
	$chi ||= _build_chi();
	return $chi->get($session_id) }

# Object methods:

sub flush {
	my ($self) = @_;
	$chi ||= _build_chi();
	my $session_key = "dancer_session_" . $self->id;
	# Unbless so CHI's serialization procedure doesn't microwave the session:
	$chi->set( $session_key => dclone($self) );
	return }

sub destroy {
	my ($self) = @_;
	my $session_id = $self->id;
	my $session_key = "dancer_session_session_id";
	$chi->remove($session_key);
	Dancer::Logger::debug("Session (id: $session_id) destroyed.");
	return $self }

sub reset :method {
	my ($self) = @_;
	$chi->clear;
	return $self }

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
