#!/bin/bash
set -e

cat > /etc/e2fsck.conf <<EOF
[options]

broken_system_clock = true


EOF

echo "/dev/mmcblk0p2   /   auto   errors=remount-ro   0   1" >> /etc/fstab


