#!/usr/bin/env perl
# FILENAME: clock.pl
# CREATED: 05/25/15 08:59:49 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: HexClock

use strict;
use warnings;
use utf8;

use Time::HiRes qw( usleep gettimeofday );
use Graphics::ColorObject;

my $secs_per_day     = 60 * 60 * 24;
my $hex_secs_per_day = 256 * 256 * 256;

sub fg {
    my ( $hh, $hm, $hs ) = @_;
    for ( $hh, $hm, $hs ) {
        $_ > 0xFF && warn "$_ Over 0xFF!";
    }
    my ($fg_hue) = $hh / 0xFF * 360;
    my ($fg_sat) = 1;
    my ($fg_val) = $hm / 0xFF;
    return [ $fg_hue, $fg_sat, $fg_val ];
}

sub bg {
    my ( $hh, $hm, $hs ) = @_;
    for ( $hh, $hm, $hs ) {
        $_ > 0xFF && warn "$_ Over 0xFF!";
    }
    my ( $fgh, $fgs, $fgv ) = @{ fg( $hh, $hm, $hs ) };
    my ($bg_hue) = ( $fgh + ( 360 / 4 ) ) % 360;
    my ($bg_sat) = 0.5;
    my ($bg_val) = 1 - ($fgv*2);
    return [ $bg_hue, $bg_sat, $bg_val ];
}

sub hexrgb {
    return @{ Graphics::ColorObject->new_HSV(@_)->as_RGB255 };
}

sub clock_to_hex {
    my ( $unixtime, $msec ) = @_;
    $msec = 0 unless defined $msec;
    my ( $sec, $min, $hour, @rest ) = localtime($unixtime);
    my $day_msec =
      ( ( ( $hour * 60 ) + $min ) * 60 ) + $sec + ( $msec / 1_000_000 );
    my $day_hexsecs  = $day_msec / $secs_per_day * $hex_secs_per_day;
    my $day_hexmins  = int( $day_hexsecs / 256 );
    my $day_hexhours = int( $day_hexmins / 256 );
    $day_hexmins = $day_hexmins - ( 256 * $day_hexhours );
    $day_hexsecs =
      $day_hexsecs - ( 256 * 256 * $day_hexhours ) - ( 256 * $day_hexmins );
    return ( $day_hexhours, $day_hexmins, $day_hexsecs );
}
$|++;

sub now_hexbits {
    my ( $unixtime, $msec ) = gettimeofday;

    my ( $hh, $hm, $hs ) = clock_to_hex( $unixtime, $msec );

    printf "\e[38;2;%d;%d;%dm\e[48;2;%d;%d;%dm # %02X%02X\n",
      hexrgb( fg( $hh, $hm, $hs ) ),
      hexrgb( bg( $hh, $hm, $hs ) ),
      $hh, $hm;

}

if ( $ENV{COLORTEST} ) {
    for my $r ( 0 .. 255 ) {
        for my $g ( 0 .. 255 ) {

            #    for my $b ( 0 .. 255 ) {
            printf "\e[38;2;%d;%d;%dm\e[48;2;%d;%d;%dm#",
              hexrgb( fg( $r, $g, 0 ) ),
              hexrgb( bg( $r, $g, 0 ) );

            #    }
        }
    }
    exit;
}


my ($hour,$minute,$sec);

while (1) {
    my ( $unixtime, $msec ) = gettimeofday;

    my ( $hh, $hm, $hs ) = clock_to_hex( $unixtime, $msec );
    my ( $exh ) = sprintf "%02X", $hh;
    my ( $exm ) = sprintf "%02X", $hm;


    if ( not defined $hour or $hour ne $exh ) {
      undef $minute;
      printf "\n\e[38;2;%d;%d;%dm\e[48;2;%d;%d;%dm # %s:", hexrgb( fg( $hh, 255, 255 ) ),
          hexrgb( bg( $hh, 255, 255 ) ),
          $exh
    }
    $hour = $exh;
    if ( not defined $minute or $minute ne substr($exm,0,1) ) {
      undef $sec;
      printf "\e[38;2;%d;%d;%dm\e[48;2;%d;%d;%dm(%s)", hexrgb( fg( $hh, $hm, $hs ) ),
          hexrgb( bg( $hh, $hm, $hs ) ),
        substr( $exm, 0, 1 );
    }

    $minute = substr( $exm, 0, 1 );
    if ( not defined $sec or $sec ne substr($exm,1,1) ) {
      printf "\e[38;2;%d;%d;%dm\e[48;2;%d;%d;%dm%s", hexrgb( fg( $hh, $hm, $hs ) ),
          hexrgb( bg( $hh, $hm, $hs ) ),
        substr( $exm, 1, 1 );
    }
    $sec = substr( $exm, 1, 1);

    usleep( 1000000 / $hex_secs_per_day * $secs_per_day * 0xFF );
}

