#!/usr/bin/perl

# conky
# -----
# 15m interval
# ${execi 900 /path/to/script/weather.pl -c}

# notify
# ------
# notify-send "Forecast" "$(perl weather.pl)"

use Encode;
use v5.10;
use LWP::Simple qw(get $ua);
use XML::LibXML;
use XML::LibXML::XPathContext;
use List::MoreUtils qw(firstidx);
use HTML::Strip;
use Getopt::Std;

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
open(my $fh, "<", "/home/dc/.config/conky/location.txt") || die "can't open location.txt: $!";
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

my @forecast = $xpc->findnodes('//Atom:entry/Atom:title');
my @current = $xpc->findnodes('//Atom:entry/Atom:summary');

my $idx = firstidx { /CDATA/ } @current;
die "Error finding current summary\n" unless ($idx >= 0); 

if ($cur_temp) { 
	my $str =  $current[$idx]->to_literal();
	my $hs = HTML::Strip->new();
	my $cleaned = $hs->parse($str);
	$hs->eof;
	my @vals = split(/\n/, $cleaned);
	my $newstr;
	foreach (@vals) {
		$newstr = $_ if $_ =~ m/Temp/;
	}
	undef @vals;
	@vals = split(/:/, $newstr);
	$vals[-1] =~ s/^\s+|\s+$//g;
	print encode_utf8($vals[-1]);
} else { prnt_all(\@forecast); }

exit;
