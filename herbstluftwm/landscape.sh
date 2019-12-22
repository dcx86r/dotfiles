#!/bin/sh

herbstclient set_monitors 1920x1080+0+0
xrandr -o normal
# refresh conky position
kill -HUP $(pidof conky)
