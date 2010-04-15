#!/bin/bash
set -e

cat > /etc/e2fsck.conf <<EOF
[options]

broken_system_clock = true

EOF

echo "/dev/mmcblk0p2   /   auto   errors=remount-ro   0   1" >> /etc/fstab

cat > /etc/X11/xorg.conf <<XORG

Section "Monitor"
    Identifier "Configured Monitor"
EndSection

Section "Screen"
    Identifier "Default Screen"
    Device "Configured Video Device"
    #Limited by SGX?
    DefaultDepth 16
EndSection

Section "Device"
    Identifier "Configured Video Device"
    Driver "omapfb"
    Option "fb" "/dev/fb0"
EndSection

XORG



