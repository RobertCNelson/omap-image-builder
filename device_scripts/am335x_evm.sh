#!/bin/sh -e

#Based off:
#https://github.com/beagleboard/meta-beagleboard/blob/master/meta-beagleboard-extras/recipes-support/usb-gadget/gadget-init/g-ether-load.sh

if [ ! -d /boot/uboot/debug/ ] ; then
	mkdir -p /boot/uboot/debug/ || true
fi

eeprom="/sys/bus/i2c/devices/0-0050/eeprom"
SERIAL_NUMBER=$(hexdump -e '8/1 "%c"' ${eeprom} -s 14 -n 2)-$(hexdump -e '8/1 "%c"' ${eeprom} -s 16 -n 12)
ISBLACK=$(hexdump -e '8/1 "%c"' ${eeprom} -s 8 -n 4)

BLACK=""
if [ "x${ISBLACK}" = "xBBBK" ] || [ "x${ISBLACK}" = "xBNLT" ] ; then
	BLACK="Black"
fi

mac_address="/proc/device-tree/ocp/ethernet@4a100000/slave@4a100200/mac-address"
if [ -f ${mac_address} ] ; then
	cpsw_0_mac=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')
fi

mac_address="/proc/device-tree/ocp/ethernet@4a100000/slave@4a100300/mac-address"
if [ -f ${mac_address} ] ; then
	cpsw_1_mac=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')
fi

modprobe g_multi file=/dev/mmcblk0p1 cdrom=0 stall=0 removable=1 nofua=1 iSerialNumber=${SERIAL_NUMBER} iManufacturer=Circuitco  iProduct=BeagleBone${BLACK} host_addr=${cpsw_1_mac}

sleep 1

sed -i -e 's:DHCPD_ENABLED="no":#DHCPD_ENABLED="no":g' /etc/default/udhcpd
#Distro default...
deb_udhcpd=$(cat /etc/udhcpd.conf | grep Sample)
if [ "${deb_udhcpd}" ] ; then
	mv /etc/udhcpd.conf /etc/udhcpd.conf.bak
fi

if [ ! -f /etc/udhcpd.conf ] ; then
	echo "start      192.168.7.1" > /etc/udhcpd.conf
	echo "end        192.168.7.1" >> /etc/udhcpd.conf
	echo "interface  usb0" >> /etc/udhcpd.conf
	echo "max_leases 1" >> /etc/udhcpd.conf
	echo "option subnet 255.255.255.252" >> /etc/udhcpd.conf
fi
/etc/init.d/udhcpd restart

/sbin/ifconfig usb0 192.168.7.2 netmask 255.255.255.252
/usr/sbin/udhcpd -S /etc/udhcpd.conf

if [ -e /sys/class/drm/card0/card0-HDMI-A-1/edid ] ; then
	if which fbset > /dev/null ; then
		echo "fbset:" > /boot/uboot/debug/edid.txt
		fbset >> /boot/uboot/debug/edid.txt
	fi
	if which parse-edid > /dev/null ; then
		echo "edid:" >> /boot/uboot/debug/edid.txt
		parse-edid /sys/class/drm/card0/card0-HDMI-A-1/edid >> /boot/uboot/debug/edid.txt
	fi
fi

if [ ! -f /opt/scripts/beaglebone-black-eMMC-flasher.sh ] ; then
	if [ -f /boot/uboot/flash-eMMC.txt ] ; then
		if [ -f /boot/uboot/tools/scripts/beaglebone-black-copy-microSD-to-eMMC.sh ] ; then
			/bin/bash /boot/uboot/tools/scripts/beaglebone-black-copy-microSD-to-eMMC.sh >/boot/uboot/debug/flash-eMMC.log 2>&1
		fi
	fi
fi

dmesg | grep cape > /boot/uboot/debug/cape.txt
