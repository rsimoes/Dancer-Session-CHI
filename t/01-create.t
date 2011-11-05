#!/usr/bin/env perl

use strict;
use warnings;
use Carp::Always 0.10;
use Test::Most 0.22 tests => 10;
use Dancer::Test;
use Dancer::Session::CHI;
use Dancer::Plugin::Cache::CHI;

my $class       = 'Dancer::Session::CHI';
my %CHI_options = ( driver => 'Memory', datastore => \ my %hash );
throws_ok(
	sub { Dancer::Session::CHI->create },
	qr/CHI session options not found/,
	'CHI session without any options throws expection'
);

Dancer::set( session_CHI => { use_plugin => 1 } );

throws_ok(
	sub { $class->create },
	qr/CHI plugin requested but not loaded/,
	'Requesting CHI plugin without it being loaded throws expection'
);

# Run the following tests twice, first using the plugin and then without:
Dancer::set( plugins => { 'Cache::CHI' => \%CHI_options } );
my $with = 'with';
for ( 1..2 ) {
#	Dancer::ModuleLoader->load(Dancer::Engine->build( session => 'CHI', Dancer::config ));
	my $session;
	lives_ok(
		sub { $session = $class->create },
		"CHI session $with plugin created"
	);
	can_ok $session, qw/init create retrieve flush destroy id/;
	isa_ok $session, $class, "&create $with plugin yields session engine that";
	my $sess_id = $session->id;
	ok $sess_id, "&create $with plugin yields valid session ID ($sess_id)";

	$with = 'without';
	Dancer::set( session_CHI => \%CHI_options );
}
