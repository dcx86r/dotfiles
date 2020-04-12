#/bin/sh

# note: filtering /dev/sdc /dev/sdd - lvm.conf

sudo lvs | sed -n '/snap/p' | awk '{printf "%.2f%s", $6, "%"}'
