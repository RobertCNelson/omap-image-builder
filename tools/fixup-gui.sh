#!/bin/bash
set -e

cat > /etc/e2fsck.conf <<EOF
[options]

broken_system_clock = true

EOF

mkdir -p /boot/uboot

echo "/dev/mmcblk0p2   /           auto   errors=remount-ro   0   1" >> /etc/fstab
echo "/dev/mmcblk0p1   /boot/uboot auto   defaults            0   0" >> /etc/fstab

cat > /etc/fw_env.config <<FW
# Configuration file for fw_(printenv/saveenv) utility.
# Up to two entries are valid, in this case the redundand
# environment sector is assumed present.
# MTD device name       Device offset   Env. size       Flash sector size
       /dev/mtd2               0x0000          0x20000         0x20000

FW

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



