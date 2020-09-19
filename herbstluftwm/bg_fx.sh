#!/bin/dash

# source herbstclient function
rpath="$HOME/.config/herbstluftwm"
. $rpath/hlc_fn.sh

colora="#30221D"
file="$HOME/rices/curbg.jpg"

ROOT() {
	clients=$(HC attr tags.focus.client_count)
	if [ "$clients" -gt "1" ] ; then
		echo "-sc '$colora'"
	else
		echo "-c '$file'"
	fi
}

HC --idle 'tag_flags|tag_changed' | while read hook; do
	eval setroot -z "$(ROOT 0)" &
done
