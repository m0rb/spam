#!/usr/bin/perl -w 
# SwiftOnSecurity Tweet UnDelete (@lnSecuritay)
# 3/23/16 chris_commat_misentropic_commercial  
#
# https://twitter.com/SwiftOnSecurity/status/712456958637445122
# <@SwiftOnSecurity> @m0rb stop subtweeting me
#
# ...ok! >:3
use 5.10.1;
use warnings;
use strict;
use utf8;
use Storable;
use Net::Twitter;
use AnyEvent::Twitter::Stream;
use Term::ANSIColor;
use Config::IniFiles;
binmode( STDOUT, ":utf8" );
################################################################
my $settings = Config::IniFiles->new( -file => "m0rb.ini" )
  or die "unable to open config";
my $ckey = $settings->val( 'twitter', 'ckey' ) or die "no consumer key";
my $csec = $settings->val( 'twitter', 'csec' ) or die "no consumer secret";
my $at   = $settings->val( 'twitter', 'at' )   or die;
my $asec = $settings->val( 'twitter', 'asec' ) or die;
################################################################
my $tweets = "swift.tweets";
my @swifttweets;
eval {
    @swifttweets = @{ retrieve($tweets) };
    my $tweetcount = ( scalar @swifttweets );
    print colored( "[!] backlog loaded ($tweetcount)\n", 'green' );
} or @swifttweets = ();
my $nt = Net::Twitter->new(
    traits               => [qw/API::RESTv1_1/],
    consumer_key         => $ckey,
    consumer_secret      => $csec,
    access_token         => $at,
    access_token_secret  => $asec,
    decode_html_entities => '1',
    ssl                  => '1',
);
die unless $nt->authorized;
my $derp   = AE::cv;
my $stream = AnyEvent::Twitter::Stream->new(
    consumer_key    => $ckey,
    consumer_secret => $csec,
    token           => $at,
    token_secret    => $asec,
    method          => "filter",
    follow          => "2436389418",
    on_tweet        => sub {
        my $t   = shift;
        my $sn  = $t->{user}->{screen_name};
        my $tid = $t->{id};
        my $msg = $t->{text} or return 1;
        if ( $sn eq "SwiftOnSecurity" ) {
            print "$tid: <$sn> $msg\n";
            push @swifttweets, ( $tid . $msg )
              and store( \@swifttweets, $tweets );
        }
    },
    on_delete => sub {
        my ( $tid, $uid ) = @_;
        print "Delete: $tid by $uid\n";
        my @swiftsort = grep { /$tid/ } @swifttweets;
        if (@swiftsort) {
            my ($output) = @swiftsort;
            $output =~ s/$tid//g;
            print colored( "<TayBot> $output\n", 'red' );
            eval { $nt->update({ status => "$output"}); };
        }
    },
);
$derp->recv;
