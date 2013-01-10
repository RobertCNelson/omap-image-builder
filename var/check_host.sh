#!/bin/bash

#Debootstrap, there was no sense tagging releases, when the external debootstrap
#could disappear, so lets use my mirror..

#1.0.${minimal_debootstrap}
minimal_debootstrap="46"

check_pkgs() {
	unset deb_pkgs
	dpkg -l | grep debootstrap >/dev/null || deb_pkgs+="debootstrap "
	dpkg -l | grep fakeroot >/dev/null || deb_pkgs+="fakeroot "

	if [ "${deb_pkgs}" ] ; then
		echo "Installing: ${deb_pkgs}"
		sudo apt-get update
		sudo apt-get -y install ${deb_pkgs}
	fi
}

debootstrap_what_version () {
	test_debootstrap=$(/usr/sbin/debootstrap --version | awk '{print $2}' | awk -F"." '{print $3}')
	echo "debootstrap version: 1.0."$test_debootstrap""
}

check_pkgs
debootstrap_what_version

if [[ "$test_debootstrap" < "$minimal_debootstrap" ]] ; then
	echo "Installing minimal debootstrap version: 1.0."${minimal_debootstrap}"..."
	wget http://rcn-ee.net/mirror/debootstrap/debootstrap_1.0.${minimal_debootstrap}_all.deb
	sudo dpkg -i debootstrap_1.0.${minimal_debootstrap}_all.deb
	rm -rf debootstrap_1.0.${minimal_debootstrap}_all.deb || true
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

