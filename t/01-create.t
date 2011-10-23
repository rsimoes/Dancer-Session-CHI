#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 10;
use Dancer::Test;
use Dancer::Session::CHI;

my $class       = 'Dancer::Session::CHI';
my %CHI_options = ( driver => 'Memory', datastore => \ my %hash );
throws_ok(
	sub { Dancer::Session::CHI->create },
	qr/CHI session options not found/,
	'CHI session without any options throws expection'
);

Dancer::set( chi_session_opts => { use_plugin => 1 } );

throws_ok(
	sub { $class->create },
	qr/CHI plugin requested but not loaded/,
	'Requesting CHI plugin without it being loaded throws expection'
);

# Run the following tests twice, first using the plugin and then without:
Dancer::set( plugins => { 'Cache::CHI' => \%CHI_options } );
my $with = 'with plugin';
for ( 1..2 ) {
	my $session;
	lives_ok(
		sub { $session = $class->create },
		"CHI session $with created"
	);
	can_ok $session, qw/init create retrieve flush destroy id/;
	isa_ok $session, $class, "&create $with yields session engine that";
	my $sess_id = $session->id;
	ok $sess_id, "&create $with yields valid session ID ($sess_id)";

	$with = 'without plugin';
	Dancer::set( chi_session_opts => \%CHI_options );
}
