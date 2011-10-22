package Dancer::Session::CHI;

use v5.10;
use strict;
use warnings;
use utf8::all;
use namespace::autoclean;
use Moose;
use MooseX::NonMoose;
use Carp;
use Dancer 'config';
use Dancer::Config 'setting';
use Dancer::Plugin::Cache::CHI;
use English '-no_match_vars';
use Method::Signatures;

extends 'Dancer::Session::Abstract';

# VERSION
# ABSTRACT: CHI-based session backend for Dancer

# Class methods:

method create ($class:) { ## no critic (Modules::RequireEndWithOne)
	# Check for presence of Dancer::Plugin::Cache::CHI:
	my @plugins = keys %{config->{plugins}};
	croak('Dancer::Plugin::Cache::CHI not loaded') if not 'Cache::CHI' ~~ @plugins;

	# Indirectly create new session by flushing:
	my $self = $class->new;
	$self->flush;
	return $self;
}

method retrieve ($class: Int $session_id) {
	my $session = cache_get 'session_' . $session_id;
	return $session;
}

# Object methods:

method flush ($self:) {
	my $session_id = $self->id;
	my $key = "session_$session_id";
	cache_set $key => $self;
	Dancer::Logger::core("Session data written to $key.");
}

method destroy ($self:) {
	my $session_id = $self->id;
	my $key = "session_$session_id";
	cache_remove $key;
	Dancer::Logger::core("Session $session_id destroyed.");
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
