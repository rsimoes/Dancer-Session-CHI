package Dancer::Session::CHI;

use strict;
use warnings;
use utf8;
use Carp;
use CHI;
use Dancer qw(cookie);
use Dancer::Logger;
use Dancer::Config qw(setting);
use Dancer::ModuleLoader;
use File::Spec::Functions qw(rel2abs);
use Scalar::Util qw(blessed);

use base "Dancer::Session::Abstract";

# VERSION
# ABSTRACT: CHI-based session engine for Dancer

# Class methods:

sub create {
    my ($class) = @_;
    my $self = $class->new;
    $self->flush;
    Dancer::Logger->debug("Session (id: " . $self->id . " created.");
    return $self;
}

sub retrieve {
    my (undef, $session_id) = @_;
    my $chi = _build_chi();
    return $chi->get("session_$session_id")
}

# Object methods:

sub flush {
    my ($self) = @_;
    my $chi = _build_chi();
    my $session_id = $self->id;
    $chi->set( "session_$session_id" => $self );
    return $self;
}

sub purge {
    my ($self) = @_;
    my $chi = _build_chi();
    $chi->purge;
    return $self;
}

sub destroy {
    my ($self) = @_;
    my $session_id = $self->id;
    my $chi = _build_chi();
    $chi->remove("session_$session_id");
    cookie setting("session_name") => undef;
    Dancer::Logger->debug("Session (id: $session_id) destroyed.");
    return $self;
}

my $chi;
sub _build_chi {

    return $chi if blessed($chi) && $chi->isa("CHI");

    my $options = setting("session_CHI");
    ( ref $options eq ref {} ) or croak "CHI session options not found";

    # Don't let CHI determine the absolute path:
    if ( exists $options->{root_dir} ) {
        $options->{root_dir} = rel2abs($options->{root_dir});
    }

    my $use_plugin = delete $options->{use_plugin};
    my $is_loaded = exists setting("plugins")->{"Cache::CHI"};
    if ( $use_plugin && !$is_loaded ) {
        croak "CHI plugin requested but not loaded";
    }

    return $use_plugin
        ? do {
            my $plugin = "Dancer::Plugin::Cache::CHI";
            my $error_msg = "$plugin is needed and is not installed";
            unless ( Dancer::ModuleLoader->load($plugin) ) {
                raise( core_session => $error_msg );
            }
            Dancer::Plugin::Cache::CHI::cache()
        }
        : CHI->new( %{$options} );
}

1;
