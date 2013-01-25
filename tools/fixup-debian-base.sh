#!/bin/bash
set -e

mkdir -p /boot/uboot

echo "/dev/mmcblk0p2  /                  auto     errors=remount-ro   0   1" >> /etc/fstab
echo "/dev/mmcblk0p1  /boot/uboot        auto     defaults            0   0" >> /etc/fstab
echo "debugfs         /sys/kernel/debug  debugfs  rw                  0   0" >> /etc/fstab

#Add eth0 to network interfaces, so ssh works on startup.
echo ""  >> /etc/network/interfaces
echo "# The primary network interface" >> /etc/network/interfaces
echo "#auto eth0"  >> /etc/network/interfaces
echo "#iface eth0 inet dhcp"  >> /etc/network/interfaces
echo "# Example to keep MAC address between reboots"  >> /etc/network/interfaces
echo "#hwaddress ether DE:AD:BE:EF:CA:FE"  >> /etc/network/interfaces
echo "" >> /etc/network/interfaces
echo "# WiFi Example" >> /etc/network/interfaces
echo "#auto wlan0" >> /etc/network/interfaces
echo "#iface wlan0 inet dhcp" >> /etc/network/interfaces
echo "#    wpa-ssid \"essid\"" >> /etc/network/interfaces
echo "#    wpa-psk  \"password\"" >> /etc/network/interfaces

#rootstock seems to leave an almost blank /etc/sudoers hanging, remove and just install sudo
if [ -f /etc/sudoers ] ; then
	rm -f /etc/sudoers || true
	apt-get -y install sudo
	usermod -aG sudo debian
fi

#serial access as a normal user:
usermod -aG  dialout debian

cat > /etc/init.d/board_tweaks.sh <<-__EOF__
	#!/bin/sh -e
	### BEGIN INIT INFO
	# Provides:          board_tweaks.sh
	# Required-Start:    \$local_fs
	# Required-Stop:     \$local_fs
	# Default-Start:     2 3 4 5
	# Default-Stop:      0 1 6
	# Short-Description: Start daemon at boot time
	# Description:       Enable service provided by daemon.
	### END INIT INFO

	case "\$1" in
	start|reload|force-reload|restart)
	        if [ -f /boot/uboot/SOC.sh ] ; then
	                board=\$(cat /boot/uboot/SOC.sh | grep "board" | awk -F"=" '{print \$2}')
	                case "\${board}" in
	                BEAGLEBONE_A)
	                        if [ -f /boot/uboot/tools/target/BeagleBone.sh ] ; then
	                                /bin/sh /boot/uboot/tools/target/BeagleBone.sh &> /dev/null &
	                        fi;;
	                esac
	        fi
	        ;;
	stop)
	        exit 0
	        ;;
	*)
	        echo "Usage: /etc/init.d/board_tweaks.sh {start|stop|reload|restart|force-reload}"
	        exit 1
	        ;;
	esac

	exit 0

__EOF__

chmod u+x /etc/init.d/board_tweaks.sh
insserv board_tweaks.sh || true

apt-get clean
rm -f /rootstock-user-script || true
