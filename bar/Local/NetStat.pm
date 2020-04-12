package Local::NetStat;

use strict;
use warnings;
use v5.10;

my $get_net = sub {
	my $iface = shift;
	open(my $fh, "<", "/proc/net/dev")
		|| die "can't open /proc/net/dev: $!\n";
	my @data;
	while (<$fh>) { $_ =~ m/$iface/ ? push @data, $_ : () }
	chomp(my @out = split(/\s+/, shift @data));
	return $out[1] . ":" . $out[9];
};

sub update {
	my $self = shift;
	$self->{STATS} = $get_net->($self->{IFACE});
	return 1;
}

sub get {
	my $self = shift;
	return $self->{STATS};
}

sub new {
	my ($class, $iface) = @_;
	die "interface not provided for $class object\n"
		unless $iface;
	my $self = bless {
		IFACE => $iface,
		STATS => undef
	}, $class;
	$self->update();
	return $self;
}

1;
