#!/bin/dash

# source herbstclient function
rpath="$HOME/.config/herbstluftwm"
. $rpath/hlc_fn.sh

if [ $(HC get frame_gap) -eq 0 ]; then
	HC set frame_gap 40
	HC set frame_border_width 10
else
	HC set frame_gap 0
	HC set frame_border_width 0
fi
