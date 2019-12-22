#!/usr/bin/perl

# conky
# -----
# 15m interval
# ${execi 900 /path/to/script/weather.pl}

# notify
# ------
# notify-send "Forecast" "$(perl weather.pl)"

use Encode;
use v5.10;
use LWP::Simple qw(get $ua);
use XML::LibXML;
use XML::LibXML::XPathContext;
use Getopt::Std;
use Data::Dumper;

$Getopt::Std::STANDARD_HELP_VERSION = 1;
getopts('c', \my %opts) || die 
	"Bad flag(s)\n";
	my $cur_temp = 1 if $opts{c};


sub net_error {
	my $msg = shift;
	print encode_utf8($msg);
	exit;
}

sub prnt_all {
	my $dataref = shift;
	for my $i (@{$dataref}) { print encode_utf8($i->to_literal()) . "\n"; };
}

net_error("no network connection") unless defined(my $bool = $ua->is_online);

# local weather feed from Weather Canada
my $feed;
open(my $fh, "<", "location.txt") || die "can't open location.txt: $!";
while (<$fh>) { chomp; $feed = $_; }
close($fh) || die "can't close location.txt: $!";

# get feed or die trying
$ua->timeout(5);
my $page = get($feed);
net_error("API not reached") unless defined($page);

$page =~ m/<?xml/ or print "Doc empty or invalid" and exit;

my $dom = eval {
	XML::LibXML->load_xml(string => (\$page));
};
if($@) {
	print "Error parsing XML" and exit;
}

# register Atom namespace
my $xpc = XML::LibXML::XPathContext->new($dom);
$xpc->registerNs('Atom', 'http://www.w3.org/2005/Atom');

# find and print just the node with current conditions
my @current = $xpc->findnodes('//Atom:entry/Atom:title');
if ($cur_temp) { 
	my $str =  $current[1]->to_literal();
	my @vals = split(/ /, $str);
	splice(@vals, 0, 2);
	print encode_utf8(join(' ', @vals));
} else { prnt_all(\@current); }

exit;
