#!/bin/dash

dt=$(date +%Y-%m-%d)
randstr=$(dd if=/dev/urandom bs=10 count=1 2>/dev/null | sha1sum | head -c 4)

notify-send -i "$HOME/rices/Film-Roll.png" "Screenshot" "$dt-$randstr.png"
scrot "$dt-$randstr.png" -q 100 -e 'mv $f ~/rices/'
