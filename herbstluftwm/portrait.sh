#!/bin/sh

herbstclient set_monitors 1080x1920+0+0
xrandr -o left
# trigger killy.sh to reload bar
herbstclient emit_hook dimens
dash "$HOME/.config/herbstluftwm/killy.sh" &
# refresh conky position
#kill -HUP $(pidof conky)
