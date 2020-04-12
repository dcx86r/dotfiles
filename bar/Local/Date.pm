package Local::Date;

use strict;
use warnings;
use v5.10;

my $get_dt = sub {
	require POSIX;
	return POSIX::strftime("%S", localtime) if @_;
	return POSIX::strftime("%a %b %d %H:%M %Z", localtime);
};

sub update {
	my $self = shift;
	$self->{DTA} = $get_dt->();
	return 1;
}

sub gettime {
	my $self = shift;
	return $self->{DTA};
}

sub getsec {
	my $self = shift;
	return $get_dt->('s');
}

sub new {
# need this path?
	my $class = shift;
	my $self = bless {
		DTA => undef
	}, $class;
	$self->update;
	return $self;
}

1;
