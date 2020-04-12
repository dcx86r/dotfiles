#!/bin/dash

bar_path="$HOME/.config/bar"

{
# start dzen panel
	$bar_path/bar.pl -x 0 -y 0 -w 1920 -h 30 &
	pids=${pids:-$!}
# wait for exit hooks
	herbstclient -w '(quit_panel|reload)'
# reap abandoned procs
	printf '%s\n' "$pids" | tr ' ' '\n' | \
	while read pid; do
		kill $(pstree $pid -p -a -l | cut -d',' -f2 | cut -d' ' -f1)
	done
} 2>/dev/null &
