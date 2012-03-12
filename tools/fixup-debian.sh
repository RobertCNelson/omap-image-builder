#!/bin/bash
set -e

ISC_PKG_MIRROR="http://rcn-ee.homeip.net:81/dl/deb-sbuild/wheezy-armhf/isc-dhcp-4.2.2"

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

#smsc95xx kevent workaround/hack
echo "vm.min_free_kbytes = 8192" >> /etc/sysctl.conf

if which git >/dev/null 2>&1; then
  cd /tmp/
  git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
  cd -

  mkdir -p /lib/firmware/ti-connectivity
  cp -v /tmp/linux-firmware/LICENCE.ti-connectivity /lib/firmware/ti-connectivity
  cp -v /tmp/linux-firmware/ti-connectivity/* /lib/firmware/ti-connectivity
  rm -rf /tmp/linux-firmware/

  #v3.1+ needs 1.9.4 version of the firmware
  rm -f /lib/firmware/carl9170-1.fw || true
  wget --directory-prefix=/lib/firmware/ http://rcn-ee.net/firmware/carl9170/1.9.4/carl9170-1.fw
fi

	DPKG_ARCH=$(dpkg --print-architecture | grep arm)
	case "${DPKG_ARCH}" in
	armel)
		ARCH="armel"
		;;
	armhf)
		ARCH="armhf"
		;;
	esac

if [ "x${ARCH}" == "xarmhf" ] ; then
	#just temp, till sid's isc-dhcp-client gets pulled into wheezy...
	DHCLIENT=$(dpkg -l | grep isc-dhcp-client | awk '{print $2}')
	if [ "x${DHCLIENT}" != "xisc-dhcp-client" ] ; then
		mkdir -p /tmp/dhclient/
		wget --directory-prefix=/tmp/dhclient/ ${ISC_PKG_MIRROR}/isc-dhcp-client_4.2.2-2_armhf.deb
		wget --directory-prefix=/tmp/dhclient/ ${ISC_PKG_MIRROR}/isc-dhcp-common_4.2.2-2_armhf.deb
		dpkg -i /tmp/dhclient/*.deb
		apt-get -f install
		apt-get clean
		rm -rf /tmp/dhclient/ || true
	fi
fi

rm -f /tmp/*.deb || true
rm -rf /usr/src/linux-headers* || true
rm -f /rootstock-user-script || true

