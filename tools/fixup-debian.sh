#!/bin/bash
set -e

mkdir -p /boot/uboot

echo "/dev/mmcblk0p2   /           auto   errors=remount-ro   0   1" >> /etc/fstab
echo "/dev/mmcblk0p1   /boot/uboot auto   defaults            0   0" >> /etc/fstab

#Add eth0 to network interfaces, so ssh works on startup.
echo ""  >> /etc/network/interfaces
echo "# The primary network interface" >> /etc/network/interfaces
echo "auto eth0"  >> /etc/network/interfaces
echo "iface eth0 inet dhcp"  >> /etc/network/interfaces
echo "# Example to keep MAC address between reboots"  >> /etc/network/interfaces
echo "#hwaddress ether DE:AD:BE:EF:CA:FE"  >> /etc/network/interfaces
echo "" >> /etc/network/interfaces
echo "# WiFi Example" >> /etc/network/interfaces
echo "#auto wlan0" >> /etc/network/interfaces
echo "#iface wlan0 inet dhcp" >> /etc/network/interfaces
echo "#    wpa-ssid \"essid\"" >> /etc/network/interfaces
echo "#    wpa-psk  \"password\"" >> /etc/network/interfaces

if which git >/dev/null 2>&1; then
	cd /tmp/
	git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git

	#beaglebone firmware:
	git clone git://arago-project.org/git/projects/am33x-cm3.git
	cd -

	mkdir -p /lib/firmware/ti-connectivity
	cp -v /tmp/linux-firmware/LICENCE.ti-connectivity /lib/firmware/ti-connectivity
	cp -v /tmp/linux-firmware/ti-connectivity/* /lib/firmware/ti-connectivity
	rm -rf /tmp/linux-firmware/

	if [ -f /lib/firmware/ti-connectivity/TIInit_7.6.15.bts ] ; then
		rm -rf /lib/firmware/ti-connectivity/TIInit_7.6.15.bts || true
	fi
	wget --directory-prefix=/lib/firmware/ti-connectivity http://rcn-ee.net/firmware/ti/7.6.15_ble/WL1271L_BLE_Enabled_BTS_File/115K/TIInit_7.6.15.bts

	cp -v /tmp/am33x-cm3/bin/am335x-pm-firmware.bin /lib/firmware/am335x-pm-firmware.bin
	rm -rf /tmp/am33x-cm3/

	#v3.1+ needs 1.9.4 version of the firmware
	rm -f /lib/firmware/carl9170-1.fw || true
	wget --directory-prefix=/lib/firmware/ http://rcn-ee.net/firmware/carl9170/1.9.6/carl9170-1.fw
fi

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
rm -f /tmp/*.deb || true
rm -rf /usr/src/linux-headers* || true
rm -f /rootstock-user-script || true
