#!/bin/sh

herbstclient set_monitors 1920x1080+0+0
xrandr -o normal
# trigger killy.sh to reload bar
herbstclient emit_hook dimens
dash "$HOME/.config/herbstluftwm/killy.sh" &
# refresh conky position
#kill -HUP $(pidof conky)
