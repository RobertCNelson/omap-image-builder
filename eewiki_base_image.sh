#!/bin/sh -e
#
# Copyright (c) 2009-2014 Robert Nelson <robertcnelson@gmail.com>
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
if [ ! -d ${DIR}/ignore ] ; then
	mkdir -p ${DIR}/ignore
fi
tempdir=$(mktemp -d -p ${DIR}/ignore)

image_type="minimal"
nand_pkgs="mtd-utils"

. ${DIR}/lib/distro.sh

minimal_armel () {
	rm -f "${DIR}/.project" || true

	#Actual Releases will use version numbers..
	case "${release}" in
	wheezy)
		#http://www.debian.org/releases/wheezy/
		export_filename="${distro}-${wheezy_release}-${image_type}-${dpkg_arch}-${time}"
		;;
	quantal)
		export_filename="${distro}-${quantal_release}-${image_type}-${dpkg_arch}-${time}"
		;;
	raring)
		export_filename="${distro}-${raring_release}-${image_type}-${dpkg_arch}-${time}"
		;;
	saucy)
		export_filename="${distro}-${saucy_release}-${image_type}-${dpkg_arch}-${time}"
		;;
	*)
		export_filename="${distro}-${release}-${image_type}-${dpkg_arch}-${time}"
		;;
	esac

	tempdir=$(mktemp -d -p ${DIR}/ignore)

	cat > ${DIR}/.project <<-__EOF__
		tempdir="${tempdir}"
		export_filename="${export_filename}"

		distro="${distro}"
		release="${release}"
		dpkg_arch="${dpkg_arch}"
		time="${time}"

		deb_mirror="${deb_mirror}"
		deb_components="${deb_components}"

		apt_proxy="${apt_proxy}"

		include_pkgs_list="${include_pkgs_list}"
		exclude_pkgs_list="${exclude_pkgs_list}"
		base_pkg_list="${base_pkg_list}"

		image_hostname="${image_hostname}"

		user_name="${user_name}"
		full_name="${full_name}"
		password="${password}"

		include_firmware="${include_firmware}"

		chroot_very_small_image="${chroot_very_small_image}"
		chroot_generic_startup_scripts="${chroot_generic_startup_scripts}"
		chroot_ENABLE_DEB_SRC="${chroot_ENABLE_DEB_SRC}"
		chroot_KERNEL_HTTP_DIR="${chroot_KERNEL_HTTP_DIR}"

		chroot_enable_bborg_repo="${chroot_enable_bborg_repo}"

		chroot_COPY_SETUP_SDCARD="${chroot_COPY_SETUP_SDCARD}"

		chroot_hook="${chroot_hook}"
		chroot_script="${chroot_script}"

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
			fi
		fi
	fi
	cd ${DIR}/
}

production () {
	echo "Starting Production Stage"
	cd ${DIR}/deploy/

	unset actual_dir
	if [ -f ${DIR}/release ] ; then
		if [ "x${SYST}" = "x${RELEASE_HOST}" ] ; then
			if [ -d /mnt/farm/testing/pending/ ] ; then
				cp -v arm*.tar /mnt/farm/images/
				actual_dir="/mnt/farm/testing/pending"
			fi
		fi
	fi

	cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
	#!/bin/bash
	#This script's only purpose is to remember a mundane task from release to release for the release manager.

	xz -z -7 -v debian-${wheezy_release}-${image_type}-armel-${time}.tar
	xz -z -7 -v debian-${wheezy_release}-${image_type}-armhf-${time}.tar

	xz -z -7 -v ubuntu-13.10-${image_type}-armhf-${time}.tar

	__EOF__

	chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

	if [ ! "x${actual_dir}" = "x" ] ; then
		cp ${DIR}/deploy/gift_wrap_final_images.sh ${actual_dir}/gift_wrap_final_images.sh
		chmod +x ${actual_dir}/gift_wrap_final_images.sh
	fi

	cd ${DIR}/
}

pkg_list () {
	base_pkg_list=""
	if [ ! "x${no_pkgs}" = "xenable" ] ; then
		. ${DIR}/var/pkg_list.sh

		include_pkgs_list="initramfs-tools,locales,sudo"

		if [ "x${include_firmware}" = "xenable" ] ; then
			base_pkg_list="${nand_pkgs} ${base_pkgs} ${extra_pkgs} ${firmware_pkgs}"
		else
			base_pkg_list="${nand_pkgs} ${base_pkgs} ${extra_pkgs}"
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
	exclude_pkgs_list=""
#	chroot_very_small_image="enable"
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

#14.04
trusty_release () {
	extra_pkgs="devmem2 python-software-properties"
	firmware_pkgs="linux-firmware"
	is_ubuntu
	release="trusty"

	minimal_armel
	compression
}

wheezy_release () {
	extra_pkgs="systemd"
	firmware_pkgs="atmel-firmware firmware-ralink firmware-realtek libertas-firmware zd1211-firmware"
	is_debian
	release="wheezy"

	minimal_armel
	compression
}

jessie_release () {
	extra_pkgs="systemd"
	firmware_pkgs="atmel-firmware firmware-ralink firmware-realtek libertas-firmware zd1211-firmware"
	is_debian
	release="jessie"

	minimal_armel
	compression
}

sid_release () {
	extra_pkgs="systemd"
	firmware_pkgs="atmel-firmware firmware-ralink firmware-realtek libertas-firmware zd1211-firmware"
	is_debian
	release="sid"

	minimal_armel
	compression
}

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

#chroot_COPY_SETUP_SDCARD="enable"

#FIXME: things to add to .config:
include_firmware="enable"
chroot_generic_startup_scripts="enable"
#chroot_script=""

#chroot_enable_bborg_repo=""
#no_pkgs="enable"

dpkg_arch="armel"
wheezy_release
#jessie_release

dpkg_arch="armhf"
wheezy_release
#jessie_release
#raring_release
saucy_release
#trusty_release

production

rm -rf ${tempdir} || true

echo "done"
