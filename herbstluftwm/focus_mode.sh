#!/bin/dash

# source herbstclient function
rpath="$HOME/.config/herbstluftwm"
. $rpath/hlc_fn.sh

[ $(HC get frame_gap) -eq 40 ] && \
	HC set frame_gap 0 || \
	HC set frame_gap 40

[ $(HC get frame_border_width) -eq 10 ] && \
	HC set frame_border_width 0 || \
	HC set frame_border_width 10
