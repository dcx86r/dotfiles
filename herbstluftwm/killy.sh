#!/bin/dash

bar_path="$HOME/.config/bar"
bg_fx_path="$HOME/.config/herbstluftwm"

{
# get screen width
	width=$(herbstclient list_monitors | sed -n 1p | awk '{split($2, a, "x"); print a[1]}')
# start dzen panel
	$bar_path/bar.pl -x 0 -y 0 -w $width -h 30 -t "Terminus:size=12" &
	pids=${pids:-$!}
# start bg_fx.sh
	$bg_fx_path/bg_fx.sh &
	pids=$pids" $!"
# wait for exit hooks
	herbstclient -w '(quit_panel|reload|dimens)'
# reap abandoned procs
	printf '%s\n' "$pids" | tr ' ' '\n' | \
	while read pid; do
		kill $(pstree $pid -p -a -l | cut -d',' -f2 | cut -d' ' -f1)
	done
} 2>/dev/null &
