#!/usr/bin/env perl

# refactoring needed...

# remember - dzen/draw.c MAX_ICON_CACHE to 0

# consider another way to get network info -
# /sys/class/net/$IFACE/statistics/(rx|tx)_bytes

use v5.10;
use strict;
use warnings;
use Getopt::Std;
use File::Copy qw(cp);
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib (dirname abs_path($0)) . '';
use Local::Date;
use Local::NetStat;
use IO::Async::Loop;
use IO::Async::Stream;
use IO::Async::Timer::Periodic;
use constant IFACE => "wlp6s0";
use constant FONTWDTH => 8;

$SIG{INT} = sub { kill( "HUP", -$$ ) };
$Getopt::Std::STANDARD_HELP_VERSION = 1;

sub HELP_MESSAGE {
	say "Usage: perl wsiu.pl" . " -x n -y n -w n -h n\n";
	say "Flags:\n"
	  . "\t-x\t bar X-axis position\n"
	  . "\t-y\t bar Y-axis position\n"
	  . "\t-w\t bar width\n"
	  . "\t-h\t bar height\n";
}

sub error {
	open( my $fh, ">>", "/tmp/wsi.err.log" );
	say $fh shift, shift;
	exit 1;
}

sub get_opts {
	my $flags = "x:y:w:h:";
	getopts( $flags, \my %opts )
	  || HELP_MESSAGE() && error("bad flags");
	foreach ( split( /:/, $flags ) ) {
		defined $opts{$_} ? next : HELP_MESSAGE()
		  && error("insufficient arguments");
	}
	return \%opts;
}

sub setup {
	my $cfgroot = "$ENV{HOME}/.config/herbstluftwm";
	my @group   = ( 1..6, "dn", "up", "snap", "vol", "xbt",
		"cal", "delta2", "play", "pause", "stop", "next", "prev", "sep" );
	foreach (@group) {
		cp( "$cfgroot/icons/${_}.xbm", "/tmp/${_}.xbm" )
		  || error( "copy failed: ", $! );
	}
}

sub get_tag_status {
	chomp( my $tagstr = qx/herbstclient tag_status/ )
	  || error( "couldn't exec herbstclient: ", $! );
	$tagstr =~ s/^\t//;
	my @count = split( /\t/, $tagstr );
	return \@count;
}

sub draw_bar {
	my $bh;
	my $optsref   = shift;
	my %opts      = %{$optsref};
	my %dzen_args = (
		'ta' => "l",
		'sa' => "l",
		'bg' => "#392925",
		'fg' => "#c8b55b",
		'fn' => "gomme",
		'x'  => $opts{x},
		'y'  => $opts{y},
		'w'  => $opts{w},
		'h'  => $opts{h},
	);
	my $dzen = sub {
		my $bar = "dzen2";
		my $args;
		foreach ( sort keys %dzen_args ) {
			$args .= " " if $args;
			$args .= "-$_ $dzen_args{$_}";
		}
		return "$bar $args";
	};
	my $pid = open( $bh, "|-" );
	defined($pid) || error( "can't fork: ", $! );
	$SIG{PIPE} = sub { error( "dzen pipe broke: ", $! ) };
	select( ( select($bh), $| = 1 )[0] );
	if ( !$pid ) { exec( &{$dzen} ) || error( "can't exec dzen: ", $! ); }
	return $bh;
}

sub get_vol { return qx|/home/dc/.config/conky/vol.sh| }

sub vol_data {
	my $out = shift;
	return sub { return $out };
}

sub get_lvs { return qx|/home/dc/.config/conky/lvscript.sh| }

sub lvs_data {
	my $out = shift;
	return sub { return $out };
}

sub get_xbt { return qx|/home/dc/.config/conky/xbtc.sh USD| }

sub xbt_data {
	my $out = shift;
	return sub { return $out };
}

sub sender {
	my $tags_ref = shift;
	my $dataref = shift;
	state $status = sub {
		my $key  = shift;
		my %hash = (
			'.' => "empty",      # empty
			':' => "full",       # full
			'#' => "focused",    # focused
			'!' => "urgent",     # urgent
		);
		return $hash{$key};
	};
	state $str;
	open( state $vh, ">", \$str );
	foreach ( @{$tags_ref} ) {
		if ( $status->( substr( $_, 0, 1 ) ) eq "focused" ) {
			print $vh "^bg(#98724c)";
		}
		if ( $status->( substr( $_, 0, 1 ) ) eq "empty" ) {
			print $vh "^fg(#6b5644)";
		}
		my $tmp;
		my %vals = (
			1 => "one",
			2 => "two",
			3 => "three",
			4 => "four",
			5 => "five",
			6 => "six",
		);
# gradient
		my %tvals = (
			1 => "^fg(#E4DC8C)o^fg(#DEDB8A)n^fg(#D8D988)e^fg()",
			2 => "^fg(#D2D886)t^fg(#CCD684)w^fg(#C7D582)o^fg()",
			3 => "^fg(#C1D380)t^fg(#BBD17E)h^fg(#B5CE7D)r^fg(#B0CC7C)e^fg(#AAC97A)e^fg()",
			4 => "^fg(#A5C779)f^fg(#A0C478)o^fg(#9AC176)u^fg(#95BE75)r^fg()",
			5 => "^fg(#90BB74)f^fg(#8BB773)i^fg(#86B472)v^fg(#82B071)e^fg()",
			6 => "^fg(#7DAD70)s^fg(#79A96E)i^fg(#74A56D)x^fg()"
		);
		if ( $status->( substr( $_, 0, 1 ) ) eq "focused" ) {
			print $vh "^ca(1, herbstclient use "
			. substr( $_, 1 ) . ") "
			. "^fg(#e4dc8c)"
			. $vals{substr( $_, 1)}
			. "^fg() ^ca()";
		} elsif ( $status->( substr( $_, 0, 1 ) ) eq "empty" ) {
			print $vh "^ca(1, herbstclient use "
			. substr( $_, 1 ) . ") "
			. $vals{substr( $_, 1)}
			. " ^ca()";
		} else {
			print $vh "^ca(1, herbstclient use "
			. substr( $_, 1 ) . ") "
#			. substr( $_, 1 )
			. $tvals{substr( $_, 1)}
			. " ^ca()";
		}

		if ( $status->( substr( $_, 0, 1 ) ) eq "empty" ) {
			print $vh "^fg()";
		}
		if ( $status->( substr( $_, 0, 1 ) ) eq "focused" ) {
			$tmp = (length($vals{substr($_, 1)}) + 2) * FONTWDTH;
			print $vh "^bg()^ib(1)^p(-$tmp;+20)^fg(#70A16C)^r(${tmp}x5)^fg()^p()";
			print $vh "^ib(0)";
		}
	}

# maybe add music controls...
#	print $vh "^fg(#544B2E)^i(/tmp/sep.xbm)^fg()";
#	print $vh " ^p(;-2)^i(/tmp/prev.xbm) ^i(/tmp/stop.xbm) ^i(/tmp/pause.xbm)"
#	. " ^i(/tmp/play.xbm) ^i(/tmp/next.xbm)^p()";
	
	my $out = $dataref->{VOL}->() . " " x 3
		. $dataref->{LVS}->() . " " x 3
		. $dataref->{NDN}->() . " " x 3
		. $dataref->{NUP}->() . " " x 3
		. $dataref->{XBT}->() . " " x 3
		. $dataref->{DTA}->() . " " x 3;

# for centering date
#	my $dtlen = int((length($dataref->{DTA}->() . " " x 3)/2) * FONTWDTH);

# ughh having to run this twice
	$out =~ s/\^\w{2}\(.*?\)//g;

	my $rpos = length($out) * FONTWDTH + 20;
	my @keys = ("VOL", "LVS", "NDN", "NUP", "XBT", "DTA");
	my %lengths;
	
	foreach (@keys) {
		my $tmp = $dataref->{$_}->();
		$tmp =~ s/\^\w{2}\(.*?\)//g;
#		$lengths{$_} = int(length($dataref->{$_}->()) * FONTWDTH);
		$lengths{$_} = int(length($tmp) * FONTWDTH);
	}

	$lengths{VOL} += 18;
	my $volen = $lengths{VOL} + 1;
	$lengths{LVS} += 18;
	my $lvlen = $lengths{LVS} + 1;
	$lengths{NDN} += 18;
	$lengths{NUP} += 18;
	$lengths{XBT} += 18;
	$lengths{DTA} += 18;

# for centering date
#
#	print $vh "^p(_CENTER)^p(-$dtlen)";
#	print $vh "^p(;-3)^fg(#AF652F)^i(/tmp/cal.xbm)^fg()^p() " 
#		. $dataref->{DTA}->()
#		. "^ib(1)^p(-$lengths{DTA};+20)^fg(#746c48)^r(${lengths{DTA}}x5)^fg()^ib(0)"
#		. "^p()";
	
	print $vh "^p(_RIGHT)^p(-$rpos)";

	print $vh "^p(;-3)^fg(#AF652F)^i(/tmp/vol.xbm)^fg()^p() " 
		. $dataref->{VOL}->()
		. "^ib(1)^p(-$lengths{VOL};+20)^fg(#70a16c)^r(${volen}x5)^fg()^ib(0)"
		. "^p() ";
	print $vh "^p(;-3)^fg(#AF652F)^i(/tmp/delta2.xbm)^fg()^p() " 
		. $dataref->{LVS}->()
		. "^ib(1)^p(-$lengths{LVS};+20)^fg(#778725)^r(${lvlen}x5)^fg()^ib(0)"
		. "^p() ";
	print $vh "^p(;-3)^fg(#AF652F)^i(/tmp/dn.xbm)^fg()^p() " 
		. $dataref->{NDN}->()
		. "^ib(1)^p(-$lengths{NDN};+20)^fg(#c3c13d)^r(${lengths{NDN}}x5)^fg()^ib(0)"
		. "^p() ";
	print $vh "^p(;-3)^fg(#AF652F)^i(/tmp/up.xbm)^fg()^p() " 
		. $dataref->{NUP}->()
		. "^ib(1)^p(-$lengths{NUP};+20)^fg(#98724c)^r(${lengths{NUP}}x5)^fg()^ib(0)"
		. "^p() ";
	print $vh "^p(;-3)^fg(#AF652F)^i(/tmp/xbt.xbm)^fg()^p() "
		. $dataref->{XBT}->()
		. "^ib(1)^p(-$lengths{XBT};+20)^fg(#af652f)^r(${lengths{XBT}}x5)^fg()^ib(0)"
		. "^p() ";
	print $vh "^p(;-3)^fg(#AF652F)^i(/tmp/cal.xbm)^fg()^p() " 
		. $dataref->{DTA}->()
		. "^ib(1)^p(-$lengths{DTA};+20)^fg(#746c48)^r(${lengths{DTA}}x5)^fg()^ib(0)"
		. "^p()";

#	say $str;
	return $str;
}

sub main {
	my $optsref = get_opts();
	my $bh      = draw_bar($optsref);
	my $tag_status = get_tag_status();
	setup();

	my $loop = IO::Async::Loop->new;
	my $dt = Local::Date->new;
	my $net = Local::NetStat->new(IFACE);
	my $net_last_tick = $net->get;
	my $vol_str = vol_data(get_vol());
	my $lvs_str = lvs_data(get_lvs());
	my $xbt_str = xbt_data(get_xbt());
	my $last_dn_rate = 0;
	my $last_up_rate = 0;
	my $net_up_str = "NaN";
	my $net_dn_str = "NaN";
	my $data = {
		DTA => sub { return $dt->gettime },
		VOL => sub { return $vol_str->() },
		LVS => sub { return $lvs_str->() },
		NUP => sub { return $net_up_str },
		NDN => sub { return $net_dn_str },
		XBT => sub { return $xbt_str->() }
	};

	open( my $status, "-|", "herbstclient --idle 2>&1" )
	  || error( "can't fork: ", $! );

	my $stream = IO::Async::Stream->new(
		handle => $status,
		on_read => sub {
			my ( $self, $bufref, $eof ) = @_;
			while( $$bufref =~ s/^(.*\n)// ) {
				if ($1 =~ /tag_(changed|flags)/) {
					$tag_status = get_tag_status();
					say {$bh} sender( $tag_status, $data );
				}
			}
		}
	);

	my $net_timer = IO::Async::Timer::Periodic->new(
		interval => 1,
		on_tick => sub {
			my $rate = sub {
				my $dxn = shift;
				return (substr($net->get, 0, index($net->get, ":"))
					- substr($net_last_tick, 0, index($net_last_tick, ":")))
					/ 1024 if $dxn eq "down";
				return (substr($net->get, (index($net->get, ":") + 1))
					- substr($net_last_tick, (index($net_last_tick, ":") + 1)))
					/ 1024 if $dxn eq "up";
			};

			my $fmtd = sub {
				my $val = shift;
				my $str;
				open(my $sh, ">", \$str);
				printf $sh "%8.2f", $val;
# presentation here? blah!
				$str =~ s/\s/-/g;
				$str =~ s/^(.)/\^fg\(#746c48\)$1/;
				$str =~ s/(-)(?=\d)/$1\^fg\(\)/;
				return $str;
			};

			$net->update;

#			say $last_dn_rate;
#			say $rate->("down");
#			say "-------";
#			say $last_up_rate;
#			say $rate->("up");
#			say "xxxxxxxxxxxxxx";

			unless ($net->get eq $net_last_tick) {
				$net_dn_str = $fmtd->($rate->("down")) . " kB/s";
				$net_up_str = $fmtd->($rate->("up")) . " kB/s";
				say {$bh} sender( $tag_status, $data );
			}
			if ($net->get eq $net_last_tick 
				&& $net_dn_str !~ m/-0\.00/
				|| $net_up_str !~ m/-0\.00/) {
				$net_dn_str = $fmtd->($rate->("down")) . " kB/s";
				$net_up_str = $fmtd->($rate->("up")) . " kB/s";
				say {$bh} sender( $tag_status, $data );
			}
			$net_last_tick = $net->get;
			$last_dn_rate = $rate->("down");
			$last_up_rate = $rate->("up");
		}
	);

	my $dt_timer = IO::Async::Timer::Periodic->new(
		interval => 60,
		on_tick => sub { 
			$dt->update;
			say {$bh} sender( $tag_status, $data );
		}
	);

	my $vol_timer = IO::Async::Timer::Periodic->new(
		interval => 1,
		on_tick => sub {
			my $tmp = get_vol();
			unless ($tmp eq $vol_str->()) {
				$vol_str = vol_data($tmp);
				say {$bh} sender( $tag_status, $data );
			}
		}
	);

	my $lvs_timer = IO::Async::Timer::Periodic->new(
		interval => 600,
		on_tick => sub {
			my $tmp = get_lvs();
			unless ($tmp eq $lvs_str->()) {
				$lvs_str = lvs_data($tmp);
				say {$bh} sender( $tag_status, $data );
			}
		}
	);

	my $xbt_timer = IO::Async::Timer::Periodic->new(
		interval => 1200,
		on_tick => sub {
			my $tmp = get_xbt();
			unless ($tmp eq $xbt_str->()) {
				$xbt_str = xbt_data($tmp);
				say {$bh} sender( $tag_status, $data );
			}
		}
	);

	my $secs = ( 60 - $dt->getsec());
	my $dt_future = $loop->new_future;
	$loop->watch_time(
		after => $secs, 
		code => sub {
			$dt_future->done( $dt->update )
		}
	);

	$dt_future->on_ready(sub {
		say {$bh} sender( $tag_status, $data );
		$dt_timer->start;
	});

	my $net_future = $loop->new_future;
	$loop->watch_time(
		after => 1,
		code => sub {
			$net_future->done
		}
	);

	$net_future->on_ready(sub {
		$net_timer->start;
	});
	
	$loop->add($stream);
	$loop->add($net_timer);
	$loop->add($dt_timer);
	$loop->add($vol_timer);
	$loop->add($lvs_timer);
	$loop->add($xbt_timer);
	$vol_timer->start;
	$lvs_timer->start;
	$xbt_timer->start;
	$loop->run;
}

main();
