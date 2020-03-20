#!/bin/sh

interface=$1
received_bytes=""
old_received_bytes=$(cat /tmp/rcvd)
transmitted_bytes=""
old_transmitted_bytes=$(cat /tmp/xmtd)

get_bytes()
{
    line=$(cat /proc/net/dev | grep $interface | cut -d ':' -f 2 | \
    	awk '{print "received_bytes="$1, "transmitted_bytes="$9}')
    eval $line
}

get_velocity()
{
    value=$1
    old_value=$2
    vel=$(($value-$old_value))
    check=$(($vel/1024))
    unit="kB/s"
    outpt=$(printf "scale=2;%s/1024\n" $vel | bc)
    printf "%8.2f" $outpt | sed 's/ /\${color 6b6b6b}-\${color}/g'
    printf " %4s" $unit
}

get_bytes
vel_recv=$(get_velocity $received_bytes $old_received_bytes)
vel_trans=$(get_velocity $transmitted_bytes $old_transmitted_bytes)
[ $2 = "down" ] && echo "$vel_recv"
[ $2 = "up" ] && echo "$vel_trans"
echo "$received_bytes" > /tmp/rcvd
echo "$transmitted_bytes" > /tmp/xmtd
