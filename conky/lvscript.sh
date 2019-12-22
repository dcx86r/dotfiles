#/bin/sh

# note: filtering /dev/sdc /dev/sdd - lvm.conf

sudo lvs | sed -n '/snap/p' | awk '{print $6}'
