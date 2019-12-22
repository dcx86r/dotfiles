#!/bin/dash

# source herbstclient function
rpath="$HOME/.config/herbstluftwm"
. $rpath/hlc_fn.sh

# quick n dirty...

$(HC tags.focus.floating) || HC floating

HC lock

HC spawn st
perl -e 'select(undef,undef,undef,0.1)'
HC focus_nth -1
wmv 100 100 $(HC attr clients.focus.winid)

HC spawn st
perl -e 'select(undef,undef,undef,0.1)'
HC focus_nth -1
wmv 200 200 $(HC attr clients.focus.winid)

HC spawn st
perl -e 'select(undef,undef,undef,0.1)'
HC focus_nth -1
wmv 300 300 $(HC attr clients.focus.winid)

HC unlock
