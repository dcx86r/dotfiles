#!/bin/dash

rpath="$HOME/.config/herbstluftwm"

{
# start dzen panel
	$rpath/wsi.pl -x 10 -y 7 -w 14 -h 13 -s 24 &
#	$rpath/wsiu.pl -x 7 -y 0 -w 150 -h 30 &
	pids=${pids:-$!}
# wait for exit hooks
	herbstclient -w '(quit_panel|reload)'
# reap abandoned procs
	printf '%s\n' "$pids" | tr ' ' '\n' | \
	while read pid; do
		kill $(pstree $pid -p -a -l | cut -d',' -f2 | cut -d' ' -f1)
	done
} 2>/dev/null &
