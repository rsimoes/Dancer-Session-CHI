package Dancer::Session::CHI;

use v5.10;
use strictures 1;
use utf8::all 0.002;
use namespace::autoclean 0.13;
use CHI 0.49;
use Dancer 1.3072 qw/config debug/;
use English '-no_match_vars';
use Moose 2.0205;
use MooseX::ClassAttribute 0.26;
use MooseX::NonMoose 0.22;
use Scalar::Util 'blessed';

extends 'Dancer::Session::Abstract';

# VERSION
# ABSTRACT: CHI-based session engine for Dancer

class_has _cache => (
	is         => 'ro',
	isa        => 'Object',
	lazy_build => 1
);

my $class = __PACKAGE__;

# Class methods:

sub create {
	# Indirectly create new session by flushing:
	my ($class) = @ARG;
	my $self = $class->new;
	$self->flush;
	my $session_id = $self->id;
	debug("Session (id: $session_id) created.");
	return $self;
};

sub retrieve {
	my ($class, $session_id) = @ARG;
	my $session = $class->_cache->get( 'dancer_session_' . $session_id );
	return $session;
}

# Object methods:

sub flush {
	my ($self) = @ARG;
	my $session_key = 'dancer_session_' . $self->id;
	$class->_cache->set( $session_key => $self );
	return;
}

sub destroy {
	my ($self) = @ARG;
	my $session_key = 'dancer_session_' . $self->id;
	$class->_cache->remove($session_key);
	debug("Session $session_key destroyed.");
	return;
}

# Attribute builders:

sub _build__cache {
	my $options = config->{session_CHI};
	confess 'CHI session options not found' if not ref $options;
	my $use_plugin = $options->{use_plugin} ? 1 : 0;
	my $is_loaded = exists config->{plugins}{'Cache::CHI'};

	confess "CHI plugin requested but not loaded" if $use_plugin and not $is_loaded;
	if ($use_plugin) {
		require Dancer::Plugin::Cache::CHI;
		Dancer::Plugin::Cache::CHI->import;
		return cache();
	} else {
		my %options = %$options;
		delete $options{use_plugin};
		return CHI->new(\%options);
	}
}

__PACKAGE__->meta->make_immutable;

1;
