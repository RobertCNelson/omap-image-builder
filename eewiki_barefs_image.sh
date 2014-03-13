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

image_type="bare"

. ${DIR}/lib/distro.sh

minimal_armel () {
	rm -f "${DIR}/.project" || true

	#Actual Releases will use version numbers..
	case "${deb_codename}" in
	wheezy)
		#http://www.debian.org/releases/wheezy/
		export_filename="${deb_distribution}-${wheezy_release}-${image_type}-${deb_arch}-${time}"
		;;
	quantal)
		export_filename="${deb_distribution}-${quantal_release}-${image_type}-${deb_arch}-${time}"
		;;
	saucy)
		export_filename="${deb_distribution}-${saucy_release}-${image_type}-${deb_arch}-${time}"
		;;
	*)
		export_filename="${deb_distribution}-${deb_codename}-${image_type}-${deb_arch}-${time}"
		;;
	esac

	tempdir=$(mktemp -d -p ${DIR}/ignore)

	cat > ${DIR}/.project <<-__EOF__
		tempdir="${tempdir}"
		export_filename="${export_filename}"

		deb_distribution="${deb_distribution}"
		deb_codename="${deb_codename}"
		deb_arch="${deb_arch}"
		deb_include="${deb_include}"
		deb_exclude="${deb_exclude}"
		deb_components="${deb_components}"

		time="${time}"

		deb_mirror="${deb_mirror}"

		apt_proxy="${apt_proxy}"

		base_pkg_list="${base_pkg_list}"
		chroot_multiarch_armel="${chroot_multiarch_armel}"

		rfs_hostname="${rfs_hostname}"

		rfs_username="${rfs_username}"
		rfs_fullname="${rfs_fullname}"
		rfs_password="${rfs_password}"

		include_firmware="${include_firmware}"

		chroot_very_small_image="${chroot_very_small_image}"
		chroot_generic_startup_scripts="${chroot_generic_startup_scripts}"
		chroot_ENABLE_DEB_SRC="${chroot_ENABLE_DEB_SRC}"
		chroot_KERNEL_HTTP_DIR="${chroot_KERNEL_HTTP_DIR}"

		repo_external="${repo_external}"
		repo_external_arch="${repo_external_arch}"
		repo_external_server="${repo_external_server}"
		repo_external_dist="${repo_external_dist}"
		repo_external_components="${repo_external_components}"
		repo_external_key="${repo_external_key}"

		chroot_COPY_SETUP_SDCARD="${chroot_COPY_SETUP_SDCARD}"

		chroot_hook="${chroot_hook}"
		chroot_script="${chroot_script}"
		chroot_uenv_txt="${chroot_uenv_txt}"

		chroot_enable_debian_backports="${chroot_enable_debian_backports}"
		chroot_debian_backports_pkg_list="${chroot_debian_backports_pkg_list}"

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
				cp -v arm*.tar /mnt/farm/images/ || true
				actual_dir="/mnt/farm/testing/pending"
			fi
		fi
	fi

	cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
	#!/bin/bash
	#This script's only purpose is to remember a mundane task from release to release for the release manager.

	xz -z -7 -v debian-${wheezy_release}-${image_type}-armel-${time}.tar
	xz -z -7 -v debian-${wheezy_release}-${image_type}-armhf-${time}.tar

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

		deb_include=""

		if [ "x${include_firmware}" = "xenable" ] ; then
			base_pkg_list="${base_pkgs} ${extra_pkgs} ${firmware_pkgs}"
		else
			base_pkg_list="${base_pkgs} ${extra_pkgs}"
		fi
	fi
}

is_ubuntu () {
	deb_distribution="ubuntu"

	rfs_hostname="arm"
	rfs_username="ubuntu"
	rfs_password="temppwd"
	rfs_fullname="Demo User"

	deb_mirror="ports.ubuntu.com/ubuntu-ports/"

	pkg_list
	deb_exclude=""
	deb_components="main universe multiverse"
}

is_debian () {
	deb_distribution="debian"

	rfs_hostname="arm"
	rfs_username="debian"
	rfs_password="temppwd"
	rfs_fullname="Demo User"

	deb_mirror="ftp.us.debian.org/debian/"

	pkg_list
	deb_exclude="aptitude,aptitude-common,groff-base,info,install-info,libept1.4.12,manpages,man-db,tasksel,tasksel-data,vim-common,vim-tiny,wget,whiptail"
	deb_components="main contrib non-free"
	chroot_very_small_image="enable"
}

#13.10
saucy_release () {
	extra_pkgs="devmem2 python-software-properties"
	firmware_pkgs="linux-firmware"
	is_ubuntu
	deb_codename="saucy"

	minimal_armel
	compression
}

#14.04
trusty_release () {
	extra_pkgs="devmem2 python-software-properties"
	firmware_pkgs="linux-firmware"
	is_ubuntu
	deb_codename="trusty"

	minimal_armel
	compression
}

wheezy_release () {
	extra_pkgs=""
	firmware_pkgs="atmel-firmware firmware-ralink firmware-realtek libertas-firmware zd1211-firmware"
	is_debian
	deb_codename="wheezy"

	minimal_armel
	compression
}

jessie_release () {
	extra_pkgs=""
	firmware_pkgs="atmel-firmware firmware-ralink firmware-realtek libertas-firmware zd1211-firmware"
	is_debian
	deb_codename="jessie"

	minimal_armel
	compression
}

sid_release () {
	extra_pkgs=""
	firmware_pkgs="atmel-firmware firmware-ralink firmware-realtek libertas-firmware zd1211-firmware"
	is_debian
	deb_codename="sid"

	minimal_armel
	compression
}

if [ ! "${apt_proxy}" ] ; then
	apt_proxy=""
fi
if [ ! "${mirror}" ] ; then
	mirror="https://rcn-ee.net/deb"
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
#include_firmware="enable"
#chroot_generic_startup_scripts="enable"
#chroot_script=""

#repo_external=""
#repo_external_arch=""
#repo_external_server=""
#repo_external_dist=""
#repo_external_components=""
#repo_external_key=""

no_pkgs="enable"

#chroot_multiarch_armel=""

#chroot_enable_debian_backports=""
#chroot_debian_backports_pkg_list=""

deb_arch="armel"
wheezy_release
#jessie_release

deb_arch="armhf"
wheezy_release
#jessie_release
#saucy_release
#trusty_release

production

rm -rf ${tempdir} || true

echo "done"
