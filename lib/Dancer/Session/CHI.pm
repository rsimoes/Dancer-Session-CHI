package Dancer::Session::CHI;

use v5.10;
use strict;
use warnings;
use utf8::all;
use namespace::autoclean;
use CHI;
use Dancer::Config ();
use Dancer::Logger ();
use English '-no_match_vars';
use Moose;
use MooseX::NonMoose;
use Scalar::Util 'blessed';

extends 'Dancer::Session::Abstract';

# VERSION
# ABSTRACT: CHI-based session backend for Dancer

my $CHI; # private "class attribute"

sub _config;

# Pre-construction:
before [qw/create retrieve/] => sub {
	my ($class) = @ARG;
	return if blessed $CHI;
	my $options = _config->{session_CHI};
	confess 'CHI session options not found' if not ref $options;
	my $use_plugin = $options->{use_plugin} ? 1 : 0;
	my $is_loaded = exists _config->{plugins}{'Cache::CHI'};
	confess "CHI plugin requested but not loaded" if $use_plugin and not $is_loaded;
	$CHI = do {
		given ($use_plugin) {
			when (1) {
				require Dancer::Plugin::Cache::CHI;
				Dancer::Plugin::Cache::CHI->import;
				cache();
			}
			default {
				my %options = %$options;
				delete $options{use_plugin};
				CHI->new(\%options);
			}
		}
	};
};

# Class methods:

sub create {
	my ($class) = @ARG;
	# Indirectly create new session by flushing:
	my $self = $class->new;
	$self->flush;
	return $self;
}

sub retrieve {
	my ($class, $session_id) = @ARG;
	my $session = $CHI->get( 'dancer_session_' . $session_id );
	return $session;
}

# Object methods:

sub flush {
	my ($self) = @ARG;
	my $session_key = 'dancer_session_' . $self->id;
	$CHI->set( $session_key => $self );
	_debug("Session data written to $session_key.");
	return;
}

sub destroy {
	my ($self) = @ARG;
	my $session_key = 'dancer_session_' . $self->id;
	$CHI->remove($session_key);
	_debug("Session $session_key destroyed.");
	return;
}

# Utility functions:

sub _debug {
	my ($msg) = @ARG;
	return Dancer::Logger::debug($msg);
}

sub _config {
	my ($key) = @ARG;
	return Dancer::Config::settings($key);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
