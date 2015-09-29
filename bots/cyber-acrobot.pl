#!/usr/bin/perl -w
# acronym bot for twitter, cyber edition
# 9/28/15 chris_commat_misentropic_dot_commercial
use strict;
use warnings;
use utf8;
binmode( STDOUT, ":utf8" );
use Net::Twitter;
use Acme::POE::Acronym::Generator;
use Config::IniFiles;

################################################################
my $settings = Config::IniFiles->new( -file => "acro.ini" );
my $ckey = $settings->val( 'twitter', 'ckey' ) or die "no consumer key";
my $csec = $settings->val( 'twitter', 'csec' ) or die "no consumer secret";
my $at   = $settings->val( 'twitter', 'at' )   or die "no access token";
my $asec = $settings->val( 'twitter', 'asec' ) or die "no access token secret.";
my ( $sleep, $dict, $acro );
$sleep = $settings->val( 'bot', 'sleep' ) or $sleep = 900;
$dict  = $settings->val( 'bot', 'dict' )  or $dict  = '/usr/share/dict/words';
$acro  = $settings->val( 'bot', 'acro' )  or $acro  = 'CYBER';

################################################################

sub zero {
    my $nt = Net::Twitter->new(
        traits               => [qw/API::RESTv1_1/],
        consumer_key         => $ckey,
        consumer_secret      => $csec,
        access_token         => $at,
        access_token_secret  => $asec,
        decode_html_entities => '0',
        ssl                  => '1',
    );
    die unless $nt->authorized;
    my $generator = Acme::POE::Acronym::Generator->new(
        dict => $dict,
        key  => $acro,
    );
    my $msg = $generator->generate();

    if ( rand(100) > 60 ) { $msg =~ y/!-~/\x{ff01}-\x{ff5e}/; }
    print "Posting: $msg";
    $SIG{ALRM} = \&derped;
    eval { alarm(10); $nt->update( { status => $msg } ) and alarm(0); }
      and print " OK!\n"
      or print " Failed!\n";
}

sub derped {
    die "RIP\n";
}
while (1) {
    &zero;
    sleep $sleep;
}
