package Dancer::Session::CHI;

use strictures 1;
use utf8;
use namespace::autoclean 0.13 -also => [qw( config debug )];
use CHI 0.49;
use Dancer::Config ();
use Dancer::Logger ();
use English '-no_match_vars';
use Moose 2.0205;
use MooseX::ClassAttribute 0.26;
use MooseX::NonMoose 0.22;

extends 'Dancer::Session::Abstract';

# VERSION
# ABSTRACT: CHI-based session engine for Dancer

class_has _cache => (
	is         => 'ro',
	isa        => 'Object',
	lazy_build => 1
);

my $class = __PACKAGE__;
sub config;

# Class methods:

sub create { goto &new }

sub retrieve {
	my ($class, $session_id) = @ARG;
	my $session = $class->_cache->get( 'dancer_session_' . $session_id );
	return $session;
}

# Object methods:

sub BUILD {
	my ($self) = @ARG;
	$self->flush;
	my $session_id = $self->id;
	debug("Session (id: $session_id) created.");
	return $self;
}

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
	my $use_plugin = delete $options->{use_plugin};
	my $is_loaded = exists config->{plugins}{'Cache::CHI'};

	confess "CHI plugin requested but not loaded" if $use_plugin and not $is_loaded;
	if ($use_plugin) {
		require Dancer::Plugin::Cache::CHI;
		Dancer::Plugin::Cache::CHI->import;
		return cache();
	} else {
		return CHI->new( %{$options} );
	}
}

sub debug {
	my ($msg) = @ARG;
	return Dancer::Logger::debug($msg);
}

sub config { return Dancer::Config::settings }

no Moose;
__PACKAGE__->meta->make_immutable;

1;
