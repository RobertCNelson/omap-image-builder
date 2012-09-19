#!/bin/bash -e
#
# Copyright (c) 2009-2012 Robert Nelson <robertcnelson@gmail.com>
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

unset USE_OEM

ONEIRIC_CURRENT="ubuntu-11.10"
PRECISE_CURRENT="ubuntu-12.04"
QUANTAL_RELEASE="ubuntu-12.10"
SQUEEZE_CURRENT="debian-6.0.5"
WHEEZY_CURRENT="debian-wheezy"

MINIMAL="-lxde"

DIR=$PWD

function reset_vars {
	unset DIST
	unset PRIMARY_KERNEL
	unset SECONDARY_KERNEL
	unset EXTRA
	unset USER_PASS

	source ${DIR}/var/pkg_list.sh

	#Hostname:
	FQDN="arm"

	USER_LOGIN="ubuntu"
	USER_PASS="temppwd"
	USER_NAME="Demo User"

	SERIAL="ttyO2"

	IMAGESIZE="3G"

	unset PRIMARY_KERNEL_OVERRIDE
	unset SECONDARY_KERNEL_OVERRIDE

#	PRIMARY_KERNEL_OVERRIDE="v3.2.28-x14"
#	SECONDARY_KERNEL_OVERRIDE="v3.2.28-psp21"
}

function dl_rootstock {
	if [ ! -f ${DIR}/git/project-rootstock/.git/config ] ; then
		mkdir -p ${DIR}/git/
		cd ${DIR}/git/
		git clone git://github.com/RobertCNelson/project-rootstock.git
		cd ${DIR}/
	fi

	cd ${DIR}/git/project-rootstock

	git checkout origin/master -b tmp-master
	git branch -D master

	git checkout origin/master -b master
	git branch -D tmp-master

	git pull

	cd ${DIR}/deploy/
}

function minimal_armel {
rm -f ${DIR}/deploy/armel-rootfs-*.tar || true
rm -f ${DIR}/deploy/vmlinuz-* || true
rm -f ${DIR}/deploy/initrd.img-* || true
rm -f ${DIR}/deploy/rootstock-*.log || true

echo ""
echo "Running as:"
echo "-------------------------"
echo "sudo ${DIR}/git/project-rootstock/rootstock  --imagesize ${IMAGESIZE} --fqdn ${FQDN} \
--login ${USER_LOGIN} --password ${USER_PASS} --fullname \"${USER_NAME}\" \
--seed ${MINIMAL_APT}${EXTRA} ${MIRROR} --components \"${COMPONENTS}\" \
--dist ${DIST} --serial ${SERIAL} --script ${DIR}/tools/${FIXUPSCRIPT} \
${PRIMARY_KERNEL} ${SECONDARY_KERNEL} --apt-upgrade --arch=${ARCH} "
echo "-------------------------"
echo ""

sudo ${DIR}/git/project-rootstock/rootstock  --imagesize ${IMAGESIZE} --fqdn ${FQDN} \
--login ${USER_LOGIN} --password ${USER_PASS} --fullname "${USER_NAME}" \
--seed ${MINIMAL_APT}${EXTRA} ${MIRROR} --components "${COMPONENTS}" \
--dist ${DIST} --serial ${SERIAL} --script ${DIR}/tools/${FIXUPSCRIPT} \
${PRIMARY_KERNEL} ${SECONDARY_KERNEL} --apt-upgrade --arch=${ARCH}
}

function compression {
	rm -rf ${DIR}/deploy/${TIME}/$BUILD || true
	mkdir -p ${DIR}/deploy/${TIME}/$BUILD

	if ls ${DIR}/deploy/armel-rootfs-*.tar >/dev/null 2>&1;then
		mv -v ${DIR}/deploy/armel-rootfs-*.tar ${DIR}/deploy/${TIME}/$BUILD
	fi

	if ls ${DIR}/deploy/vmlinuz-* >/dev/null 2>&1;then
		mv -v ${DIR}/deploy/vmlinuz-* ${DIR}/deploy/${TIME}/$BUILD
	fi

	if ls ${DIR}/deploy/initrd.img-* >/dev/null 2>&1;then
		mv -v ${DIR}/deploy/initrd.img-* ${DIR}/deploy/${TIME}/$BUILD
	fi

	if [ "${PRIMARY_DTB_FILE}" ] ; then
		wget --no-verbose --directory-prefix=${DIR}/deploy/${TIME}/$BUILD ${PRIMARY_DTB_FILE}
	fi

	if [ "${SECONDARY_DTB_FILE}" ] ; then
		wget --no-verbose --directory-prefix=${DIR}/deploy/${TIME}/$BUILD ${SECONDARY_DTB_FILE}
	fi

	cp -v ${DIR}/tools/setup_sdcard.sh ${DIR}/deploy/${TIME}/$BUILD

	echo "Starting Compression"
	cd ${DIR}/deploy/${TIME}/
	#tar cvfz $BUILD.tar.gz ./$BUILD
	#tar cvfj $BUILD.tar.bz2 ./$BUILD
	#tar cvfJ $BUILD.tar.xz ./$BUILD

	if [ -f ${DIR}/release ] ; then
		tar cvf $BUILD.tar ./$BUILD
		xz -z -7 -v $BUILD.tar
		if [ $SYST == "${RELEASE_HOST}" ] ; then
			if [ -d /mnt/farm/testing/pending/ ] ; then
				cp -v $BUILD.tar.xz /mnt/farm/testing/pending/$BUILD.tar.xz
			fi
		fi
	else
		tar cvf $BUILD.tar ./$BUILD
	fi

	cd ${DIR}/deploy/
}

function kernel_chooser {
	if [ ! "${OVERRIDE}" ] ; then
		if [ -f /tmp/LATEST-${SUBARCH} ] ; then
			rm -f /tmp/LATEST-${SUBARCH}
		fi

		wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/${DIST}-${ARCH}/LATEST-${SUBARCH}
		FTP_DIR=$(cat /tmp/LATEST-${SUBARCH} | grep "ABI:1 ${KERNEL_ABI}" | awk '{print $3}')
		FTP_DIR=$(echo ${FTP_DIR} | awk -F'/' '{print $6}')
	else
		FTP_DIR=${OVERRIDE}
	fi

	if [ -f /tmp/index.html ] ; then
		rm -f /tmp/index.html || true
	fi

	wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/${DIST}-${ARCH}/${FTP_DIR}/
	ACTUAL_DEB_FILE=$(cat /tmp/index.html | grep linux-image | awk -F "\"" '{print $2}')

	ACTUAL_DTB_FILE=$(cat /tmp/index.html | grep dtbs.tar.gz) || true
	if [ "x${ACTUAL_DTB_FILE}" != "x" ] ; then
		#<a href="3.5.0-imx2-dtbs.tar.gz">3.5.0-imx2-dtbs.tar.gz</a> 08-Aug-2012 21:34 8.7K
		ACTUAL_DTB_FILE=$(echo ${ACTUAL_DTB_FILE} | awk -F "\"" '{print $2}')
	else
		unset ACTUAL_DTB_FILE
	fi
}

function select_rcn-ee-net_kernel {
	#KERNEL_ABI="STABLE"
	KERNEL_ABI="TESTING"
	#KERNEL_ABI="EXPERIMENTAL"

	if [ "${PRIMARY_KERNEL_OVERRIDE}" ] ; then
		OVERRIDE="${PRIMARY_KERNEL_OVERRIDE}"
	else
		unset OVERRIDE
	fi

	SUBARCH="omap"
	kernel_chooser
	PRIMARY_KERNEL="--kernel-image ${DEB_MIRROR}/${DIST}-${ARCH}/${FTP_DIR}/${ACTUAL_DEB_FILE}"
	echo "Using: ${PRIMARY_KERNEL}"
	unset PRIMARY_DTB_FILE
	if [ "x${ACTUAL_DTB_FILE}" != "x" ] ; then
		PRIMARY_DTB_FILE="${DEB_MIRROR}/${DIST}-${ARCH}/${FTP_DIR}/${ACTUAL_DTB_FILE}"
		echo "Using dtbs: ${PRIMARY_DTB_FILE}"
	fi

	KERNEL_ABI="STABLE"
	if [ "${SECONDARY_KERNEL_OVERRIDE}" ] ; then
		OVERRIDE="${SECONDARY_KERNEL_OVERRIDE}"
	else
		unset OVERRIDE
	fi

	SUBARCH="omap-psp"
	kernel_chooser
	SECONDARY_KERNEL="--secondary-kernel-image ${DEB_MIRROR}/${DIST}-${ARCH}/${FTP_DIR}/${ACTUAL_DEB_FILE}"
	echo "Using: ${SECONDARY_KERNEL}"
	unset SECONDARY_DTB_FILE
	if [ "x${ACTUAL_DTB_FILE}" != "x" ] ; then
		SECONDARY_DTB_FILE="${DEB_MIRROR}/${DIST}-${ARCH}/${FTP_DIR}/${ACTUAL_DTB_FILE}"
		echo "Using dtbs: ${SECONDARY_DTB_FILE}"
	fi
}

#11.10
function oneiric_release {
	reset_vars
	DIST=oneiric
	select_rcn-ee-net_kernel
	EXTRA=",linux-firmware,devmem2,python-software-properties"
	FIXUPSCRIPT="fixup.sh"
	MIRROR=$MIRROR_UBU
	COMPONENTS="${UBU_COMPONENTS}"
	BUILD=$ONEIRIC_CURRENT$MINIMAL-$ARCH-${TIME}
	minimal_armel
	compression
}

#12.04
function precise_release {
	reset_vars
	DIST=precise
	select_rcn-ee-net_kernel
	EXTRA=",linux-firmware,devmem2,python-software-properties,lxde,lxde-core,lxde-icon-theme,build-essential"
	FIXUPSCRIPT="fixup.sh"
	MIRROR=$MIRROR_UBU
	COMPONENTS="${UBU_COMPONENTS}"
	BUILD=$PRECISE_CURRENT$MINIMAL-$ARCH-${TIME}
	minimal_armel
	compression
}

#12.10
function quantal_release {
	reset_vars
	DIST="quantal"
	select_rcn-ee-net_kernel
	EXTRA=",linux-firmware,devmem2,python-software-properties"
	FIXUPSCRIPT="fixup.sh"
	MIRROR=$MIRROR_UBU
	COMPONENTS="${UBU_COMPONENTS}"
	BUILD=$QUANTAL_CURRENT$MINIMAL-$ARCH-${TIME}
	minimal_armel
	compression
}

function squeeze_release {
	reset_vars
	DIST=squeeze
	select_rcn-ee-net_kernel
	EXTRA=",isc-dhcp-client,initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware,lsb-release"
	USER_LOGIN="debian"
	FIXUPSCRIPT="fixup-debian.sh"
	MIRROR=$MIRROR_DEB
	COMPONENTS="${DEB_COMPONENTS}"
	BUILD=${SQUEEZE_CURRENT}$MINIMAL-$ARCH-${TIME}
	minimal_armel
	compression
}

function wheezy_release {
	reset_vars
	DIST=wheezy
	select_rcn-ee-net_kernel
	EXTRA=",initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware,lsb-release"
	USER_LOGIN="debian"
	FIXUPSCRIPT="fixup-debian.sh"
	MIRROR=$MIRROR_DEB
	COMPONENTS="${DEB_COMPONENTS}"
	BUILD=${WHEEZY_CURRENT}$MINIMAL-$ARCH-${TIME}
	minimal_armel
	compression
}

function sid_release {
	reset_vars
	DIST=sid
	select_rcn-ee-net_kernel
	EXTRA=",initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware,lsb-release"
	USER_LOGIN="debian"
	FIXUPSCRIPT="fixup-debian.sh"
	MIRROR=$MIRROR_DEB
	COMPONENTS="${DEB_COMPONENTS}"
	BUILD=${DIST}$MINIMAL-$ARCH-${TIME}
	minimal_armel
	compression
}

source ${DIR}/var/defaults.sh

if [ -f ${DIR}/rcn-ee.host ] ; then
	source ${DIR}/host/rcn-ee-host.sh
	source ${DIR}/host/rcn-ee-demo-image.sh
fi

mkdir -p ${DIR}/deploy/

DEBOOT_TEST=$(sudo debootstrap --version | awk '{print $2}')

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

if [ -f ${DIR}/release ] ; then
	echo "Building Release Package, with no mirrors"
	if [ "x${SYST}" == "x${RELEASE_HOST}" ] ; then
		#use local kernel *.deb files from synced mirror
		DEB_MIRROR="http://192.168.1.95:81/dl/mirrors/deb"
		MIRROR_UBU="--mirror http://ports.ubuntu.com/ubuntu-ports/"
		MIRROR_DEB="--mirror http://ftp.us.debian.org/debian/"
	fi
fi

dl_rootstock

#ARCH=armel
#oneiric_release

ARCH=armhf
precise_release


