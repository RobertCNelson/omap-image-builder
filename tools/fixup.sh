#!/bin/bash
set -e

mkdir -p /boot/uboot

echo "/dev/mmcblk0p2   /           auto   errors=remount-ro   0   1" >> /etc/fstab
echo "/dev/mmcblk0p1   /boot/uboot auto   defaults            0   0" >> /etc/fstab

#smsc95xx kevent workaround/hack
echo "vm.min_free_kbytes = 8192" >> /etc/sysctl.conf

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
    natty)
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

#help in the ttyS2 to ttyO2 conversion:
if ! ls /etc/init/ttyS2.conf >/dev/null 2>&1;then

cat > /etc/init/ttyS2.conf <<EOF_S2
start on stopped rc RUNLEVEL=[2345]
stop on runlevel [!2345]

respawn
exec /sbin/getty 115200 ttyS2
EOF_S2

fi

if ! ls /etc/init/ttyO2.conf >/dev/null 2>&1;then

cat > /etc/init/ttyO2.conf <<EOF_O2
start on stopped rc RUNLEVEL=[2345]
stop on runlevel [!2345]

respawn
exec /sbin/getty 115200 ttyO2
EOF_O2

fi

rm -f /tmp/*.deb
rm -rfd /usr/src/linux-headers*

