#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 5;
use Dancer::Test;
use Dancer::Session::CHI;

my $class = 'Dancer::Session::CHI';

throws_ok(
	sub { $class->create },
	qr'Dancer::Plugin::Cache::CHI not loaded',
	'CHI session without CHI plugin throws expection'
);

my $plugins = { 'Cache::CHI' => { driver => 'Memory', global => 1, expires_in => '1 min' } };
Dancer::set( plugins => $plugins );
Dancer::set( chi_session_opts => { use_plugin => 1 } );

my $session;
lives_ok(
	sub { $session = $class->create },
	'CHI session with CHI plugin is okay'
);

can_ok $session, qw/create retrieve flush destroy/;
isa_ok $session, $class, '&create yields session engine that';

my $sess_id = int $session->id;
ok $sess_id, '&create yields valid session ID ($sess_id)';
