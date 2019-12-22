#!/bin/dash

l=$(amixer sget Master | grep 'Left:' | awk -F'[][]' '{ print $2 }')
r=$(amixer sget Master | grep 'Right:' | awk -F'[][]' '{ print $2 }')

printf '%s %s' "L $l" "R $r"
