#!/bin/sh -e
#
# Copyright (c) 2009-2013 Robert Nelson <robertcnelson@gmail.com>
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

SYST=$(uname -n)
time=$(date +%Y-%m-%d)

DIR=$PWD
tempdir=$(mktemp -d)

image_type="bare"

minimal_armel () {
	rm -f "${DIR}/.project" || true

	#Actual Releases will use version numbers..
	case "${release}" in
	wheezy)
		#http://www.debian.org/releases/wheezy/
		export_filename="${distro}-7.1-${image_type}-${dpkg_arch}-${time}"
		;;
	raring)
		export_filename="${distro}-13.04-${image_type}-${dpkg_arch}-${time}"
		;;
	*)
		export_filename="${distro}-${release}-${image_type}-${dpkg_arch}-${time}"
		;;
	esac

	tempdir=$(mktemp -d)

	cat > ${DIR}/.project <<-__EOF__
		tempdir="${tempdir}"
		export_filename="${export_filename}"

		distro="${distro}"
		release="${release}"
		dpkg_arch="${dpkg_arch}"

		deb_mirror="${deb_mirror}"
		deb_components="${deb_components}"

		apt_proxy="${apt_proxy}"
		base_pkg_list="${base_pkg_list}"

		image_hostname="${image_hostname}"

		user_name="${user_name}"
		full_name="${full_name}"
		password="${password}"

		include_firmware="${include_firmware}"

		chroot_no_lsb_release="${chroot_no_lsb_release}"
		chroot_no_sudo="${chroot_no_sudo}"
		chroot_no_locales="${chroot_no_locales}"
		chroot_no_aptitude="${chroot_no_aptitude}"
		chroot_no_tasksel="${chroot_no_tasksel}"
		chroot_no_manpages="${chroot_no_manpages}"
		chroot_rcnee_startup_scripts="${chroot_rcnee_startup_scripts}"
		chroot_ENABLE_DEB_SRC="${chroot_ENABLE_DEB_SRC}"
		chroot_KERNEL_HTTP_DIR="${chroot_KERNEL_HTTP_DIR}"

	__EOF__

	cat ${DIR}/.project

	/bin/sh -e "${DIR}/RootStock-NG.sh" || { exit 1 ; }
}

compression () {
	echo "Starting Compression"
	cd ${DIR}/deploy/

	tar cvf ${export_filename}.tar ./${export_filename}

	if [ -f ${DIR}/release ] ; then
		if [ "x${SYST}" = "x${RELEASE_HOST}" ] ; then
			if [ -d /mnt/farm/testing/pending/ ] ; then
				cp -v ${export_filename}.tar /mnt/farm/testing/pending/${export_filename}.tar
				cp -v arm*.tar /mnt/farm/images/

				if [ ! -f /mnt/farm/testing/pending/compress.txt ] ; then
					echo "xz -z -7 -v ${export_filename}.tar" > /mnt/farm/testing/pending/compress.txt
				else
					echo "xz -z -7 -v ${export_filename}.tar" >> /mnt/farm/testing/pending/compress.txt
				fi

			fi
		fi
	fi
	cd ${DIR}/
}

pkg_list () {
	base_pkg_list=""
	if [ ! "x${no_pkgs}" = "xenable" ] ; then
		. ${DIR}/var/pkg_list.sh
		if [ "x${include_firmware}" = "xenable" ] ; then
			base_pkg_list="${base_pkgs} ${extra_pkgs} ${firmware_pkgs}"
		else
			base_pkg_list="${base_pkgs} ${extra_pkgs}"
		fi
	fi
}

is_ubuntu () {
	image_hostname="arm"
	distro="ubuntu"
	user_name="ubuntu"
	password="temppwd"
	full_name="Demo User"

	deb_mirror="ports.ubuntu.com/ubuntu-ports/"
	deb_components="main universe multiverse"

	pkg_list
	chroot_no_lsb_release="Ubuntu"
}

is_debian () {
	image_hostname="arm"
	distro="debian"
	user_name="debian"
	password="temppwd"
	full_name="Demo User"

	deb_mirror="ftp.us.debian.org/debian/"
	deb_components="main contrib non-free"

	pkg_list
	chroot_no_lsb_release="Debian"
	chroot_no_sudo="enable"
	chroot_no_locales="enable"
	chroot_no_aptitude="enable"
	chroot_no_tasksel="enable"
	chroot_no_manpages="enable"
}

#13.04
raring_release () {
	extra_pkgs="devmem2 python-software-properties"
	firmware_pkgs="linux-firmware"
	is_ubuntu
	release="raring"

	minimal_armel
	compression
}

#13.10
saucy_release () {
	extra_pkgs="devmem2 python-software-properties"
	firmware_pkgs="linux-firmware"
	is_ubuntu
	release="saucy"

	minimal_armel
	compression
}

wheezy_release () {
	extra_pkgs=""
	firmware_pkgs="atmel-firmware firmware-ralink libertas-firmware zd1211-firmware"
	is_debian
	release="wheezy"

	minimal_armel
	compression
}

jessie_release () {
	extra_pkgs=""
	firmware_pkgs="atmel-firmware firmware-ralink libertas-firmware zd1211-firmware"
	is_debian
	release="jessie"

	minimal_armel
	compression
}

sid_release () {
	extra_pkgs=""
	firmware_pkgs="atmel-firmware firmware-ralink libertas-firmware zd1211-firmware"
	is_debian
	release="sid"

	minimal_armel
	compression
}

. ${DIR}/var/check_host.sh

if [ ! "${apt_proxy}" ] ; then
	apt_proxy=""
fi
if [ ! "${mirror}" ] ; then
	mirror="http://rcn-ee.net/deb"
fi
if [ -f ${DIR}/rcn-ee.host ] ; then
	. ${DIR}/host/rcn-ee-host.sh
fi

mkdir -p ${DIR}/deploy/

if [ -f ${DIR}/release ] ; then
	chroot_ENABLE_DEB_SRC="enable"
fi

#FIXME: things to add to .config:
#include_firmware="enable"
#chroot_rcnee_startup_scripts="enable"
no_pkgs="enable"

#dpkg_arch="armel"
#wheezy_release
#jessie_release

dpkg_arch="armhf"
wheezy_release
#jessie_release
raring_release
#saucy_release

echo "done"
