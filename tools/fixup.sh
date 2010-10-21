#!/bin/bash
set -e

mkdir -p /boot/uboot

echo "/dev/mmcblk0p2   /           auto   errors=remount-ro   0   1" >> /etc/fstab
echo "/dev/mmcblk0p1   /boot/uboot auto   defaults            0   0" >> /etc/fstab

cat > /etc/flash-kernel.conf <<FK
#!/bin/sh
UBOOT_PART=/dev/mmcblk0p1

echo "flash-kernel stopped by: /etc/flash-kernel.conf"
echo "You are currently running an image built by rcn-ee.net running an rcn-ee"
echo "kernel, to use Ubuntu's Kernel remove the next line"
USE_RCN_EE_KERNEL=1

if [ "\$USE_RCN_EE_KERNEL" ] ; then

DIST=\$(lsb_release -cs)

case "\$DIST" in
    lucid)
            exit 0
        ;;
    maverick)
            FLASH_KERNEL_SKIP=yes
        ;;
esac

fi

FK

#so far only in maverick/natty, so this is for lucid
if [ ! $(which devmem2) ];then
 wget http://ports.ubuntu.com/pool/universe/d/devmem2/devmem2_0.0-0ubuntu1_armel.deb
 dpkg -i devmem2_0.0-0ubuntu1_armel.deb
 rm -f devmem2_0.0-0ubuntu1_armel.deb
fi

rm -f /tmp/*.deb
rm -rfd /usr/src/linux-headers*

