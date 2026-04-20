#!/bin/bash -e

# SPDX-FileCopyrightText: 2012 Robert Nelson <robertcnelson@gmail.com>
#
# SPDX-License-Identifier: MIT

#http://ftp.us.debian.org/debian/pool/main/d/debootstrap/
#1.0.${minimal_debootstrap}
#Debian Trixie/Sid usr merge....
actual_debootstrap="143"
minimal_debootstrap="143"
host_arch="$(uname -m)"

debootstrap_is_installed () {
	if [ -f /usr/bin/dpkg ] ; then
		unset deb_pkgs
		dpkg -l | grep debootstrap >/dev/null || deb_pkgs="${deb_pkgs}debootstrap "

		if [ "x${host_arch}" = "xx86_64" ] ; then
			#FIXME: while this is not a catch-all, x86_64 users would need qemu...
			#If your building RISC-V on ARM64, i'm just going to assume you have qemu installed, instead of fancy logic here...
			dpkg -l | grep qemu-user-static >/dev/null || deb_pkgs="${deb_pkgs}qemu-user-static "
		fi

		if [ "${deb_pkgs}" ] ; then
			echo "Installing: ${deb_pkgs}"
			sudo apt-get update
			sudo apt-get -y install ${deb_pkgs}
		fi
	fi
}

debootstrap_what_version () {
	test_debootstrap=$(/usr/sbin/debootstrap --version | cut -f3 -d. | grep -o '^[0-9.]\+')
	echo "Log: debootstrap version: 1.0.$test_debootstrap"
}

install_debootstrap () {
	if [ -f /usr/bin/dpkg ] ; then
		#if [[ "$test_debootstrap" < "$minimal_debootstrap" ]] ; then
		#if [ "$test_debootstrap" -lt "$minimal_debootstrap" ] ; then
		if [ ! "x$test_debootstrap" = "x$actual_debootstrap" ] ; then
			echo "Log: Installing minimal debootstrap version: 1.0.${minimal_debootstrap}..."
			sudo apt-get install -yq distro-info || true
			wget https://rcn-ee.com/mirror/debootstrap/debootstrap_1.0.${minimal_debootstrap}_all.deb
			sudo dpkg -i debootstrap_1.0.${minimal_debootstrap}_all.deb
			rm -rf debootstrap_1.0.${minimal_debootstrap}_all.deb || true
		fi
	fi
}

debootstrap_is_installed
debootstrap_what_version
install_debootstrap
