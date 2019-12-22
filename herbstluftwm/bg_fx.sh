#!/bin/bash

# source herbstclient function
rpath="$HOME/.config/herbstluftwm"
. $rpath/hlc_fn.sh

tint="#777777"
# not ideal, feh makes breaking changes...
wallpaper=$(sed -n 2p < ~/.fehbg | cut -d ' ' -f 4)

ROOT() {
	clients=$(HC attr tags.focus.client_count)
	if [ "$clients" -ge "1" ] ; then
		echo "--tint '$tint' $wallpaper"
	else
		echo "$wallpaper"
	fi
}

HC --idle 'tag_flags|tag_changed' | while read hook; do
	eval setroot -z "$(ROOT 0)" &
done
