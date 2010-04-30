#!/bin/bash
set -e

mkdir -p /boot/uboot

echo "/dev/mmcblk0p2   /           auto   errors=remount-ro   0   1" >> /etc/fstab
echo "/dev/mmcblk0p1   /boot/uboot auto   defaults            0   0" >> /etc/fstab

cat > /etc/flash-kernel.conf <<FK
#!/bin/sh

echo "flash-kernel stopped:"
echo "You are currently running the Community Kernel edition"
echo "remove /etc/flash-kernel.conf to run Ubuntu's Kernel"
DONT_FLASH=1
exit 0

FK

