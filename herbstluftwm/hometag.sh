#!/bin/dash

# source herbstclient function
rpath="$HOME/.config/herbstluftwm"
. $rpath/hlc_fn.sh

SPLIT() {
	HC split "$@"
}

RESIZE() {
	#0.01 increments
	HC resize "$@"
}

FOCUS() {
	#left right up down
	HC focus "$@"
}

HC lock
SPLIT right 0.5
RESIZE left 0.21
FOCUS right
SPLIT right 0.5
FOCUS right
RESIZE right 0.09
FOCUS left
HC spawn st
HC unlock
