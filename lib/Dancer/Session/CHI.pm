package Dancer::Session::CHI;

use v5.10;
use strict;
use warnings;
use utf8::all;
use namespace::autoclean;
use CHI;
use Dancer qw/config debug/;
use English '-no_match_vars';
use Method::Signatures;
use Moose;
use MooseX::NonMoose;
use Scalar::Util 'blessed';

extends 'Dancer::Session::Abstract';

# VERSION
# ABSTRACT: CHI-based session backend for Dancer

my $CHI; # private "class attribute"

# Pre-construction:
before [qw/create retrieve/] => method ($class: @ARG) {
	return if blessed $CHI;
	my $options = config->{chi_session_opts}
		or confess 'CHI session options not found';
	my $use_plugin = $options->{use_plugin} ? 1 : 0;
	my $is_loaded = exists config->{plugins}{'Cache::CHI'};
	confess "CHI plugin requested but not loaded" if $use_plugin and not $is_loaded;
	$CHI = do {
		given ($use_plugin) {
			when (1) {
				require Dancer::Plugin::Cache::CHI;
				Dancer::Plugin::Cache::CHI->import;
				cache();
			}
			default {
				delete $options->{use_plugin};
				CHI->new(%$options);
			}
		};
	};
};

# Class methods:

method create ($class:) { ## no critic (Modules::RequireEndWithOne)
	# Indirectly create new session by flushing:
	my $self = $class->new;
	$self->flush;
	return $self;
}

method retrieve ($class: Int $session_id) {
	my $session = $CHI->get( 'session_' . $session_id );
	return $session;
}

# Object methods:

method flush ($self:) {
	my $session_id = $self->id;
	my $key = "session_$session_id";
	$CHI->set( $key => $self );
	debug("Session data written to $key.");
}

method destroy ($self:) {
	my $session_id = $self->id;
	my $key = "session_$session_id";
	$CHI->remove($key);
	debug("Session $session_id destroyed.");
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
