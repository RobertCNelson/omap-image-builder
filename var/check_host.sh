#!/bin/bash

if [ ! $(which fakeroot) ] ; then
	echo "Missing fakeroot"
	sudo apt-get -y install fakeroot
fi

DEBOOT_TEST=$(/usr/sbin/debootstrap --version | awk '{print $2}')

if [ "${DEBOOT_TEST}" != "${DEBOOT_VER}" ] ; then
	echo "Installing minimal debootstrap version..."
	wget ${DEBOOT_HTTP}/debootstrap_${DEBOOT_VER}_all.deb
	sudo dpkg -i debootstrap_${DEBOOT_VER}_all.deb
	rm -rf debootstrap_${DEBOOT_VER}_all.deb || true
fi

RAMTMP_TEST=$(cat /etc/default/tmpfs | grep -v "#" | grep RAMTMP | awk -F"=" '{print $2}')
if [ -f /etc/default/tmpfs ] ; then
	if [ "-${RAMTMP_TEST}-" == "-yes-" ] ; then
		if [ "-${HOST_ARCH}-" == "-armv7l-" ] ; then
			echo ""
			echo "ERROR"
			echo "With RAMTMP=yes in /etc/default/tmpfs on ARM, debootstrap will fail, as /tmp is mounted as nodev."
			echo "Please modify /etc/default/tmpfs and set RAMTMP=no and reboot."
			echo ""
			exit
		else
			echo ""
			echo "WARNING"
			echo "With RAMTMP=yes in /etc/default/tmpfs, this script will probally fail due to running out of memory."
			echo "Please modify /etc/default/tmpfs and set RAMTMP=no and reboot."
			echo ""
		fi
	fi
fi

