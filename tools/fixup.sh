#!/bin/bash
set -e

cat > /etc/e2fsck.conf <<EOF
[options]

broken_system_clock = true


EOF

mkdir -p /boot/mmc

echo "/dev/mmcblk0p2   /           auto   errors=remount-ro   0   1" >> /etc/fstab
echo "/dev/mmcblk0p1   /boot/mmc   auto   defaults            0   0" >> /etc/fstab


