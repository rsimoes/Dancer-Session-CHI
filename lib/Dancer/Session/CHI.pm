package Dancer::Session::CHI;

use strict;
use warnings;
use utf8;
use CHI;
use Dancer ":syntax";
use Dancer::Logger;
use Dancer::ModuleLoader;
use Dancer::Exception qw(raise);
use File::Spec::Functions qw(rel2abs);
use Scalar::Util qw(blessed);

use base "Dancer::Session::Abstract";

# VERSION
# ABSTRACT: CHI-based session engine for Dancer

# Class methods:

my $chi;
sub _chi {

    return $chi if blessed($chi);

    my $options = setting("session_CHI");
    if ( ref($options) ne "HASH" ) {
        raise core_session => "CHI session options not found";
    }

    # Don't let CHI determine the absolute path:
    if ( exists $options->{root_dir} ) {
        $options->{root_dir} = rel2abs($options->{root_dir});
    }

    my $use_plugin = delete $options->{use_plugin};
    my $is_loaded = exists setting("plugins")->{"Cache::CHI"};
    if ( $use_plugin && !$is_loaded ) {
        raise core_session => "CHI plugin requested but not loaded";
    }

    $chi = $use_plugin
        ? do {
            my $plugin = "Dancer::Plugin::Cache::CHI";
            unless ( Dancer::ModuleLoader->load($plugin) ) {
                raise core_session => "$plugin is needed and is not installed";
            }
            Dancer::Plugin::Cache::CHI::cache()
        }
        : CHI->new(%$options);
    return $chi;
}

sub create {
    my $self = __PACKAGE__->new->flush;
    Dancer::Logger->debug("Session (id: " . $self->id . " created.");
    return $self;
}

sub retrieve {
    my (undef, $session_id) = @_;
    return _chi->get("session_$session_id");
}

# Object methods:

sub flush {
    my ($self) = @_;
    my $session_id = $self->id;
    _chi->set( "session_$session_id" => $self );
    return $self;
}

sub purge {
    _chi->purge;
    return;
}

#sub reset :method { goto &purge }

sub destroy {
    my ($self) = @_;
    my $session_id = $self->id;
    _chi->remove("session_$session_id");
    cookies->{setting("session_name")}->expires(0);
    Dancer::Logger->debug("Session (id: $session_id) destroyed.");
    return $self;
}

1;
