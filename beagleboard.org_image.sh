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

if [ -f ${DIR}/config ] ; then
	. ${DIR}/config
fi

image_type="lxde"

. ${DIR}/lib/distro.sh

bborg_pkg_list=""

#Development tools:
bborg_pkg_list="${bborg_pkg_list} autoconf automake1.9 build-essential bison device-tree-compiler libtool less flex g++ gdb pkg-config vim"

#Node libs:
bborg_pkg_list="${bborg_pkg_list} libc-ares-dev"

#Cloud9 stuff:
bborg_pkg_list="${bborg_pkg_list} curl libssl-dev apache2-utils libxml2-dev tmux"

#xorg:
bborg_pkg_list="${bborg_pkg_list} xserver-xorg-video-modesetting xserver-xorg x11-xserver-utils xinput"

#lxde:
bborg_pkg_list="${bborg_pkg_list} lxde-core lightdm leafpad alsa-utils evtest screen"

#lxde wifi:
bborg_pkg_list="${bborg_pkg_list} wicd-gtk"

#lxde wifi:
#bborg_pkg_list="${bborg_pkg_list} connman"

#touchscreen: (xinput_calibrator)
#when we have to build it...
bborg_pkg_list="${bborg_pkg_list} libxi-dev"

#development libs:
bborg_pkg_list="${bborg_pkg_list} python-opencv libsdl1.2-dev python-pip python-setuptools python2.7-dev python-serial"

#Web Stuff:
bborg_pkg_list="${bborg_pkg_list} xchat"

#Chromium libs:
bborg_pkg_list="${bborg_pkg_list} libxss1 libnss3 libxslt1.1 libspeechd2"

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
	saucy)
		export_filename="${distro}-${saucy_release}-${image_type}-${dpkg_arch}-${time}"
		;;
	*)
		export_filename="${distro}-${release}-${image_type}-${dpkg_arch}-${time}"
		;;
	esac

	#When doing offical releases, always hard lock the kernel version...
	#chroot_KERNEL_HTTP_DIR="http://rcn-ee.net/deb/${release}-${dpkg_arch}/v3.8.13-bone40/"

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
		chroot_multiarch_armel="${chroot_multiarch_armel}"

		image_hostname="${image_hostname}"

		user_name="${user_name}"
		full_name="${full_name}"
		password="${password}"

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
		repo_external_pkg_list="${repo_external_pkg_list}"

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

	if [ -d ./debian-${wheezy_release}-${image_type}-armhf-${time} ] ; then
		rm -rf debian-${wheezy_release}-${image_type}-armhf-${time} || true
	fi

	#user may run ./ship.sh twice...
	if [ -f debian-${wheezy_release}-${image_type}-armhf-${time}.tar.xz ] ; then
		tar xf debian-${wheezy_release}-${image_type}-armhf-${time}.tar.xz
	else
		tar xf debian-${wheezy_release}-${image_type}-armhf-${time}.tar
	fi

	if [ -f BBB-eMMC-flasher-debian-${wheezy_release}-${time}-2gb.img ] ; then
		rm BBB-eMMC-flasher-debian-${wheezy_release}-${time}-2gb.img || true
	fi

	if [ -f bone-debian-${wheezy_release}-${time}-2gb.img ] ; then
		rm bone-debian-${wheezy_release}-${time}-2gb.img || true
	fi

	cd debian-${wheezy_release}-${image_type}-armhf-${time}/

	#using [boneblack_flasher] over [bone] for flasher, as this u-boot ignores the factory eeprom for production purposes...
	sudo ./setup_sdcard.sh --img BBB-blank-eMMC-flasher-debian-${wheezy_release}-${time} --uboot boneblack_flasher --beagleboard.org-production --bbb-flasher --boot_label BEAGLE_BONE --rootfs_label eMMC-Flasher --enable-systemd

	sudo ./setup_sdcard.sh --img BBB-eMMC-flasher-debian-${wheezy_release}-${time} --uboot bone --beagleboard.org-production --bbb-flasher --boot_label BEAGLE_BONE --rootfs_label eMMC-Flasher --enable-systemd

	sudo ./setup_sdcard.sh --img bone-debian-${wheezy_release}-${time} --uboot bone --beagleboard.org-production --boot_label BEAGLE_BONE --enable-systemd

	mv *.img ../
	cd ..
	rm -rf debian-${wheezy_release}-${image_type}-armhf-${time}/ || true

	if [ ! -f debian-${wheezy_release}-${image_type}-armhf-${time}.tar.xz ] ; then
		xz -z -7 -v debian-${wheezy_release}-${image_type}-armhf-${time}.tar
	fi

	if [ -f BBB-blank-eMMC-flasher-debian-${wheezy_release}-${time}-2gb.img.xz ] ; then
		rm BBB-blank-eMMC-flasher-debian-${wheezy_release}-${time}-2gb.img.xz || true
	fi
	xz -z -7 -v BBB-blank-eMMC-flasher-debian-${wheezy_release}-${time}-2gb.img

	if [ -f BBB-eMMC-flasher-debian-${wheezy_release}-${time}-2gb.img.xz ] ; then
		rm BBB-eMMC-flasher-debian-${wheezy_release}-${time}-2gb.img.xz || true
	fi
	xz -z -7 -v BBB-eMMC-flasher-debian-${wheezy_release}-${time}-2gb.img

	if [ -f bone-debian-${wheezy_release}-${time}-2gb.img.xz ] ; then
		rm bone-debian-${wheezy_release}-${time}-2gb.img.xz || true
	fi
	xz -z -7 -v bone-debian-${wheezy_release}-${time}-2gb.img

	__EOF__

	chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

	if [ ! "x${actual_dir}" = "x" ] ; then
		cp ${DIR}/deploy/gift_wrap_final_images.sh ${actual_dir}/gift_wrap_final_images.sh
		chmod +x ${actual_dir}/gift_wrap_final_images.sh
	fi

	cd ${DIR}/
}

kernel_chooser () {
	if [ -f ${tempdir}/LATEST-${SUBARCH} ] ; then
		rm -rf ${tempdir}/LATEST-${SUBARCH} || true
	fi

	wget --no-verbose --directory-prefix=${tempdir}/ http://rcn-ee.net/deb/${release}-${dpkg_arch}/LATEST-${SUBARCH}
	FTP_DIR=$(cat ${tempdir}/LATEST-${SUBARCH} | grep "ABI:1 ${KERNEL_ABI}" | awk '{print $3}')
	FTP_DIR=$(echo ${FTP_DIR} | awk -F'/' '{print $6}')
}

select_rcn_ee_net_kernel () {
	SUBARCH="omap-psp"
	KERNEL_ABI="STABLE"
	kernel_chooser
	chroot_KERNEL_HTTP_DIR="${mirror}/${release}-${dpkg_arch}/${FTP_DIR}/"
}

pkg_list () {
	base_pkg_list=""
	if [ ! "x${no_pkgs}" = "xenable" ] ; then
		. ${DIR}/var/pkg_list.sh

		include_pkgs_list="git-core,initramfs-tools,locales,sudo,wget"

		if [ "x${include_firmware}" = "xenable" ] ; then
			base_pkg_list="${base_pkgs} ${extra_pkgs} ${bborg_pkg_list} ${firmware_pkgs}"
		else
			base_pkg_list="${base_pkgs} ${extra_pkgs} ${bborg_pkg_list}"
		fi
	fi
}

is_ubuntu () {
	image_hostname="beaglebone"
	distro="ubuntu"
	user_name="ubuntu"
	password="temppwd"
	full_name="Demo User"

	deb_mirror="ports.ubuntu.com/ubuntu-ports/"
	deb_components="main universe multiverse"

	pkg_list
}

is_debian () {
	image_hostname="beaglebone"
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

#12.10
quantal_release () {
	extra_pkgs="devmem2"
	firmware_pkgs="linux-firmware"
	is_ubuntu
	release="quantal"
	select_rcn_ee_net_kernel
	minimal_armel
	compression
}

#13.10
saucy_release () {
	extra_pkgs="devmem2"
	firmware_pkgs="linux-firmware"
	is_ubuntu
	release="saucy"
	select_rcn_ee_net_kernel
	minimal_armel
	compression
}

#14.04
trusty_release () {
	extra_pkgs="devmem2"
	firmware_pkgs="linux-firmware"
	is_ubuntu
	release="trusty"
	select_rcn_ee_net_kernel
	minimal_armel
	compression
}

wheezy_release () {
	extra_pkgs="systemd"
	firmware_pkgs="atmel-firmware firmware-ralink firmware-realtek libertas-firmware zd1211-firmware"
	is_debian
	release="wheezy"
	select_rcn_ee_net_kernel
	minimal_armel
	compression
}

jessie_release () {
	extra_pkgs="systemd"
	firmware_pkgs="atmel-firmware firmware-ralink firmware-realtek libertas-firmware zd1211-firmware"
	is_debian
	release="jessie"
	select_rcn_ee_net_kernel
	minimal_armel
	compression
}

sid_release () {
	extra_pkgs="systemd"
	firmware_pkgs="atmel-firmware firmware-ralink firmware-realtek libertas-firmware zd1211-firmware"
	is_debian
	release="sid"
	select_rcn_ee_net_kernel
	minimal_armel
	compression
}

if [ -f ${DIR}/releases.sh ] ; then
	. ${DIR}/releases.sh
fi

if [ ! "${apt_proxy}" ] ; then
	apt_proxy=""
fi
if [ ! "${mirror}" ] ; then
	mirror="http://rcn-ee.net/deb"
fi

#FIXME: (something simple)
if [ -f ${DIR}/rcn-ee.host ] ; then
	. ${DIR}/host/rcn-ee-host.sh
fi
if [ -f ${DIR}/circuitco.host ] ; then
	. ${DIR}/host/circuitco-host.sh
fi

mkdir -p ${DIR}/deploy/

chroot_COPY_SETUP_SDCARD="enable"

#FIXME: things to add to .config:
include_firmware="enable"
chroot_generic_startup_scripts="enable"
chroot_script="beagleboard.org.sh"
chroot_uenv_txt="beagleboard.org.txt"

repo_external="enable"
repo_external_arch="armhf"
repo_external_server="http://beagle.s3.amazonaws.com/debian"
repo_external_dist="wheezy-bbb"
repo_external_components="main"
repo_external_key="http://beagle.s3.amazonaws.com/debian/beagleboneblack-archive-keyring.asc"
repo_external_pkg_list="libsoc2"

#no_pkgs="enable"

#add's /lib/ld-linux.so.3 so users who don't use a hardfp compiler atleast can run their program...
chroot_multiarch_armel="enable"

chroot_enable_debian_backports="enable"
chroot_debian_backports_pkg_list="nodejs nodejs-legacy npm"

#FIXME: when backports is added, the src dump fails..
if [ "x${chroot_enable_debian_backports}" = "x" ] ; then
	if [ -f ${DIR}/release ] ; then
		chroot_ENABLE_DEB_SRC="enable"
	fi
fi

dpkg_arch="armhf"
DEFAULT_RELEASES="wheezy"
for REL in ${RELEASES:-$DEFAULT_RELEASES} ; do
	${REL}_release
done
production

rm -rf ${tempdir} || true

echo "done"
