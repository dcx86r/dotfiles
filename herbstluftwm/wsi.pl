#!/usr/bin/perl

# remember - dzen/draw.c MAX_ICON_CACHE to 0

use v5.10;
use Getopt::Std;
use File::Copy qw(cp);

$SIG{INT} = sub { kill("HUP", -$$) };
$Getopt::Std::STANDARD_HELP_VERSION = 1;

sub HELP_MESSAGE {
	say "Usage: herbstclient --idle"
		. " | perl wsi_panel.pl"
		. " -x n -y n -w n -h n"
		. " -s n\n";
	say "Flags:\n"
		. "\t-x\t bar X-axis position\n"
		. "\t-y\t bar Y-axis position\n"
		. "\t-w\t bar width\n"
		. "\t-h\t bar height\n"
		. "\t-s\t spacing between bars\n";
}

sub error {
	open(my $fh, ">>", "/tmp/wsi.err.log");
	say $fh shift, shift;
	exit 1;
}

sub chk_opts {
	my $flags = "x:y:w:h:s:";
	getopts($flags, \my %opts) 
	|| HELP_MESSAGE() && error("bad flags");
	foreach (split(/:/, $flags)) {
		$opts{$_} ? next : HELP_MESSAGE() 
		&& error("insufficient arguments");
	}
	return \%opts;
}

sub setup {
	my $cfgroot = "$ENV{HOME}/.config/herbstluftwm";
	my @group = ("empty", "full", "urgent");
	foreach (@group) {
		cp("$cfgroot/icons/rubik-${_}.xpm", "/tmp/rubik-${_}.xpm")
			|| error("copy failed: ", $!);
	}
}

sub get_tag_status {
	chomp(my $tagstr = qx/herbstclient tag_status/)
		|| error("couldn't exec herbstclient: ", $!);
	$tagstr =~ s/^\t//;
	my @count = split(/\t/, $tagstr);
	return \@count;
}

# github.com/dcx86r/rubikon
sub gen_icon {
	my $icon = qx/rubikon/
		|| error("couldn't exec rubikon: ", $!);
	open(my $fh, ">", shift) 
		|| error("couldn't open xpm file: ", $!);
	print $fh $icon;
	close $fh;
}

sub draw_bars {
#	filehandles for dzen instances
	my @bar_fh;
	my $tag_amt = shift;
	my $optsref = shift;
	my %opts = %{$optsref};
	my %dzen_args = (
		'ta' => "l",
		'sa' => "l",
		'x'  => $opts{x},
		'y'  => $opts{y},
		'w'  => $opts{w},
		'h'  => $opts{h},
	);
	for my $i (1 .. $tag_amt) {
		my $dzen = sub {
			my $bar = "dzen2";
			my $args;
			foreach (sort keys %dzen_args) {
				$args .= " " if $args;
				$args .= "-$_ $dzen_args{$_}";
			}
			return "$bar $args";
		};
		my $pid = open($bar_fh[$i], "|-");
		defined($pid) || error("can't fork: ", $!);
		$SIG{PIPE} = sub { error("dzen pipe broke: ", $!) };
		select((select($bar_fh[$i]), $| = 1)[0]);
		if (!$pid) { exec(&{$dzen}) || error("can't exec dzen: ", $!); }
		$dzen_args{x} += $opts{s};
	}
	return \@bar_fh;
}

sub sender {
	my $tags_ref = shift;
	my $fh_ref = shift;

	state $status = sub {
		my $key = shift;
		my %hash = (
			'.'  => "empty",
			':'  => "full",
			'#' => "focused",
			'!'  => "urgent",
		);
		return $hash{$key};
	};

	foreach (@{$tags_ref}) {
		say { @{$fh_ref}[substr($_, 1)] } 
			"^ca(1, herbstclient use "
			. substr($_, 1)
			. ")^i(/tmp/rubik-"
			. $status->(substr($_, 0, 1))
			. ".xpm)^ca()";
	}
}

sub main {
	my $optsref = chk_opts();
	setup();
	my $init_vals = get_tag_status();
	my $barsref = draw_bars(scalar(@{$init_vals}), $optsref);
	undef $init_vals;

#	icon initialization animation ... ?

	open(my $status, "-|", "herbstclient --idle 2>&1") 
		|| error("can't fork: ", $!);

	while (defined($_ = <$status>)) {
		chomp;
		next if $_ !~ /tag_(changed|flags)/;
		gen_icon("/tmp/rubik-focused.xpm") if $_ !~ /tag_flags/;
		sender(get_tag_status(), $barsref);
	}
}

main();
