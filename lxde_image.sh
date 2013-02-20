#!/bin/bash -e
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
HOST_ARCH=$(uname -m)
TIME=$(date +%Y-%m-%d)
time=$(date +%Y-%m-%d)

unset USE_OEM

MINIMAL="-lxde"

DIR=$PWD
tempdir=$(mktemp -d)

function reset_vars {
	unset DIST
	unset PRIMARY_KERNEL
	unset SECONDARY_KERNEL
	unset EXTRA
	unset USER_PASS

	source ${DIR}/var/pkg_list.sh

	unset PRIMARY_KERNEL_OVERRIDE
	unset SECONDARY_KERNEL_OVERRIDE

	if [ -f ${DIR}/release ] ; then
		source ${DIR}/host/rcn-ee-demo-image.sh
	fi

	#Hostname:
	FQDN="arm"

	SERIAL="ttyO2"

	IMAGESIZE="3G"
}

function minimal_armel {
	rm -f "${DIR}/.project" || true

	pkgs="${MINIMAL_APT}${EXTRA}"

	base_pkg_list=$(echo ${pkgs} | sed -e 's/,/ /g')

	#Actual Releases will use version numbers..
	case "${DIST}" in
	squeeze)
		#http://www.debian.org/releases/squeeze/
		export_filename="${distro}-6.0.6-lxde-${ARCH}-${time}"
		;;
	quantal)
		export_filename="${distro}-12.10-lxde-${ARCH}-${time}"
		;;
	*)
		export_filename="${distro}-${DIST}-lxde-${ARCH}-${time}"
		;;
	esac

	tempdir=$(mktemp -d)

	cat > ${DIR}/.project <<-__EOF__
		tempdir="${tempdir}"
		export_filename="${export_filename}"

		distro="${distro}"

		release="${DIST}"
		dpkg_arch="${ARCH}"

		apt_proxy="${apt_proxy}"
		base_pkg_list="${base_pkg_list}"

		image_hostname="${FQDN}"

		user_name="${user_name}"
		full_name="${full_name}"
		password="${password}"

		chroot_ENABLE_DEB_SRC="${chroot_ENABLE_DEB_SRC}"

		chroot_KERNEL_HTTP_DIR="${chroot_KERNEL_HTTP_DIR}"

	__EOF__

	cat ${DIR}/.project

	/bin/bash -e "${DIR}/RootStock-NG.sh" || { exit 1 ; }
}

function compression {
	echo "Starting Compression"
	cd ${DIR}/deploy/

	tar cvf ${export_filename}.tar ./${export_filename}

	if [ -f ${DIR}/release ] ; then
		echo "xz -z -7 -v ${export_filename}.tar" >> /mnt/farm/testing/pending/compress.txt

		if [ "x${SYST}" == "x${RELEASE_HOST}" ] ; then
			if [ -d /mnt/farm/testing/pending/ ] ; then
				cp -v ${export_filename}.tar /mnt/farm/testing/pending/${export_filename}.tar
			fi
		fi
	fi
	cd ${DIR}/
}

function kernel_chooser {
	if [ ! "${OVERRIDE}" ] ; then
		if [ -f ${tempdir}/LATEST-${SUBARCH} ] ; then
			rm -f ${tempdir}/LATEST-${SUBARCH}
		fi

		wget --no-verbose --directory-prefix=${tempdir}/ http://rcn-ee.net/deb/${DIST}-${ARCH}/LATEST-${SUBARCH}
		FTP_DIR=$(cat ${tempdir}/LATEST-${SUBARCH} | grep "ABI:1 ${KERNEL_ABI}" | awk '{print $3}')
		FTP_DIR=$(echo ${FTP_DIR} | awk -F'/' '{print $6}')
	else
		FTP_DIR=${OVERRIDE}
	fi
}

function select_rcn-ee-net_kernel {
	SUBARCH="omap"
	KERNEL_ABI="STABLE"
	kernel_chooser
	chroot_KERNEL_HTTP_DIR="${mirror}/${DIST}-${ARCH}/${FTP_DIR}/"

	SUBARCH="omap-psp"
	KERNEL_ABI="TESTING"
	kernel_chooser
	chroot_KERNEL_HTTP_DIR="${chroot_KERNEL_HTTP_DIR} ${mirror}/${DIST}-${ARCH}/${FTP_DIR}/"
}

is_ubuntu () {
	user_name="ubuntu"
	password="temppwd"
	full_name="Demo User"
}

is_debian () {
	user_name="debian"
	password="temppwd"
	full_name="Demo User"
}

#12.10
function quantal_release {
	distro="ubuntu"
	reset_vars
	is_ubuntu
	DIST="quantal"
	select_rcn-ee-net_kernel
	EXTRA=",${UBUNTU_ONLY}"

	MIRROR="${MIRROR_UBU}"
	COMPONENTS="${UBU_COMPONENTS}"
	BUILD="${QUANTAL_CURRENT}${MINIMAL}-${ARCH}-${TIME}"
	minimal_armel
	compression
}

#13.04
function raring_release {
	distro="ubuntu"
	reset_vars
	is_ubuntu
	DIST="raring"
	select_rcn-ee-net_kernel
	EXTRA=",${UBUNTU_ONLY}"

	MIRROR="${MIRROR_UBU}"
	COMPONENTS="${UBU_COMPONENTS}"
	BUILD="${RARING_CURRENT}${MINIMAL}-${ARCH}-${TIME}"
	minimal_armel
	compression
}

function squeeze_release {
	distro="debian"
	reset_vars
	is_debian
	DIST=squeeze
	select_rcn-ee-net_kernel
	EXTRA=",isc-dhcp-client,${DEBIAN_ONLY}"
	USER_LOGIN="debian"

	MIRROR="${MIRROR_DEB}"
	COMPONENTS="${DEB_COMPONENTS}"
	BUILD="${SQUEEZE_CURRENT}${MINIMAL}-${ARCH}-${TIME}"
	minimal_armel
	compression
}

function wheezy_release {
	distro="debian"
	reset_vars
	is_debian
	DIST=wheezy
	select_rcn-ee-net_kernel
	EXTRA=",${DEBIAN_ONLY},lowpan-tools"
	USER_LOGIN="debian"

	MIRROR="${MIRROR_DEB}"
	COMPONENTS="${DEB_COMPONENTS}"
	BUILD="${WHEEZY_CURRENT}${MINIMAL}-${ARCH}-${TIME}"
	minimal_armel
	compression
}

function sid_release {
	distro="debian"
	reset_vars
	is_debian
	DIST=sid
	select_rcn-ee-net_kernel
	EXTRA=",${DEBIAN_ONLY},lowpan-tools"
	USER_LOGIN="debian"

	MIRROR="${MIRROR_DEB}"
	COMPONENTS="${DEB_COMPONENTS}"
	BUILD="${DIST}${MINIMAL}-${ARCH}-${TIME}"
	minimal_armel
	compression
}

source ${DIR}/var/defaults.sh
source ${DIR}/var/check_host.sh

mirror="http://rcn-ee.net/deb"
if [ -f ${DIR}/rcn-ee.host ] ; then
	source ${DIR}/host/rcn-ee-host.sh
	source ${DIR}/host/rcn-ee-demo-image.sh
fi

mkdir -p ${DIR}/deploy/

if [ -f ${DIR}/release ] ; then
	echo "Building Release Package, with no mirrors"

	if [ "x${SYST}" == "x${RELEASE_HOST}" ] ; then
		#use local kernel *.deb files from synced mirror
		DEB_MIRROR="http://192.168.1.95:81/dl/mirrors/deb"
		MIRROR_UBU="--mirror http://ports.ubuntu.com/ubuntu-ports/"
		MIRROR_DEB="--mirror http://ftp.us.debian.org/debian/"
	fi

	chroot_ENABLE_DEB_SRC="enable"
fi

ARCH=armhf
quantal_release
raring_release

echo "done"
