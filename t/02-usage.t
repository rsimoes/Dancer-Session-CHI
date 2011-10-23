#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 5;
use Dancer::Test;
use Dancer 'session';
use Dancer::Session::CHI;

my $plugins = { 'Cache::CHI' => { driver => 'Memory', global => 1 } };
Dancer::set( plugins => $plugins );
Dancer::set( session_CHI => { use_plugin => 1 } );
my $sess_id = session 'id';

lives_ok { Dancer::Session::CHI->retrieve($sess_id) } 'session retrieval lives okay';
is_deeply session(), { id => $sess_id }, 'initial session data is as expected';
lives_ok { session( foo => 'bar') } 'setting session data lives okay';
lives_ok { session->flush } 'explicit session flushing lives okay';
is session('foo'), 'bar', 'new session data is as expected';
