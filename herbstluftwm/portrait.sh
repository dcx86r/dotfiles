#!/bin/sh

herbstclient set_monitors 1080x1920+0+0
xrandr -o left
# refresh conky position
kill -HUP $(pidof conky)
