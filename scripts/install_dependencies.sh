#!/bin/bash -e
#
# Copyright (c) 2012-2024 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#http://ftp.us.debian.org/debian/pool/main/d/debootstrap/
#1.0.${minimal_debootstrap}
#Debian Trixie/Sid usr merge....
actual_debootstrap="136"
minimal_debootstrap="136"
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
