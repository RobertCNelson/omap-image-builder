#!/bin/bash -e
#
# Copyright (c) 2009-2011 Robert Nelson <robertcnelson@gmail.com>
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

SYST=$(cat /etc/hostname)
ARCH=$(uname -m)
TIME=$(date +%y%m%d)

unset USE_OEM

#Natty Schedule:
#https://wiki.ubuntu.com/NattyReleaseSchedule
#alpha-1 : December 2nd
NATTY_ALPHA="ubuntu-natty-alpha1-r1"
#alpha-2 : February 3rd
NATTY_ALPHA2="ubuntu-natty-alpha2-r0"
#alpha-3 : March 3rd
NATTY_ALPHA3="ubuntu-natty-alpha3-r0"
#beta1 : March 31st
NATTY_BETA1="ubuntu-natty-beta1"
#beta2 : April 14th
NATTY_BETA2="ubuntu-natty-beta2"
#10.10 : April 28th
NATTY_RELEASE="ubuntu-11.04-r2"

#Oneiric Schedule:
#https://wiki.ubuntu.com/OneiricReleaseSchedule
#alpha-1 : June 2nd
ONEIRIC_ALPHA="ubuntu-oneiric-alpha1"
#alpha-2 : June  30th
ONEIRIC_ALPHA2="ubuntu-oneiric-alpha2"
#alpha-3 : August 4th
ONEIRIC_ALPHA3="ubuntu-oneiric-alpha3"
#beta1 : September 1st
ONEIRIC_BETA1="ubuntu-oneiric-beta1"
#beta2 : September 22nd
ONEIRIC_BETA2="ubuntu-oneiric-beta2"
#10.10 : October 10th
ONEIRIC_RELEASE="ubuntu-11.10-r0"

MINIMAL="-minimal-armel"
XFCE="-xfce4-armel"
GUI="-desktop-armel"
NET="-netbook-armel"

MINIMAL_APT="btrfs-tools,i2c-tools,nano,pastebinit,uboot-envtools,uboot-mkimage,usbutils,wget,wireless-tools,wpasupplicant"
#cpufrequtils

DEB_MIRROR="http://rcn-ee.net/deb"

DEB_COMPONENTS="main,contrib,non-free"
UBU_COMPONENTS="main,universe,multiverse"

MIRROR_UBU="--mirror http://ports.ubuntu.com/ubuntu-ports/"
MIRROR_DEB="--mirror http://ftp.us.debian.org/debian/"
MIRROR_DEB_ARMHF="--mirror http://ftp.debian-ports.org/debian/"

DIR=$PWD

function reset_vars {

unset DIST
unset KERNEL
unset EXTRA
unset USER_PASS

}

function set_mirror {

if [ $SYST == "work-p4" ] || [ $SYST == "work-celeron" ] || [ $SYST == "voodoo-e6400" ]; then
	MIRROR_UBU="--mirror http://192.168.0.10:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.0.10:3142/ftp.us.debian.org/debian/"
	MIRROR_DEB_ARMHF="--mirror http://192.168.0.10:3142/ftp.debian-ports.org/debian/"
fi

if [ $SYST == "lvrm" ] || [ $SYST == "x4-955" ] || [ "$ARCH" = "armv5tel" ] || [ "$ARCH" = "armv7l" ]; then
	MIRROR_UBU="--mirror http://192.168.1.95:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.1.95:3142/ftp.us.debian.org/debian/"
	MIRROR_DEB_ARMHF="--mirror http://192.168.1.95:3142/ftp.debian-ports.org/debian/"
	DEB_MIRROR="http://192.168.1.95:81/dl/mirrors/deb"
fi

}

function dl_rootstock {
	rm -rfd ${DIR}/../project-rootstock
	cd ${DIR}/../
	bzr branch lp:project-rootstock
	cd ${DIR}/../project-rootstock

	patch -p0 < ${DIR}/patches/apt-source-fix.diff
	bzr commit -m 'Svein Seldal apt source fix'

	patch -p0 < ${DIR}/patches/01-rootstock-tar-output.diff
	bzr commit -m 'tar output'

	patch -p0 < ${DIR}/patches/tar-use-numeric-owner.diff
	bzr commit -m 'use numeric-owner'

	patch -p0 < ${DIR}/patches/03-rootstock-source-updates.diff
	bzr commit -m 'source updates'

if [ "${USE_OEM}" ] ; then
#disable with debian
	patch -p0 < ${DIR}/patches/oemconfig-and-user.diff
	bzr commit -m 'set default user name and use oemconfig..'
fi

	cd ${DIR}/deploy/
}

function minimal_armel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	sudo ${DIR}/../project-rootstock/rootstock --fqdn omap ${USER_PASS} --fullname "Demo User" --imagesize 2G \
	--seed ${MINIMAL_APT},${EXTRA} ${MIRROR} --components "${COMPONENTS}" \
	--dist ${DIST} --serial ${SERIAL} --script ${DIR}/tools/fixup.sh \
	--kernel-image ${KERNEL} --apt-upgrade
}

function minimal_armel_nokernel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	sudo ${DIR}/../project-rootstock/rootstock --fqdn omap ${USER_PASS} --fullname "Demo User" --imagesize 2G \
	--seed ${MINIMAL_APT},${EXTRA} ${MIRROR} --components "${COMPONENTS}" \
	--dist ${DIST} --serial ${SERIAL} --script ${DIR}/tools/fixup.sh --apt-upgrade
}

function xfce4_armel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	time sudo ${DIR}/../project-rootstock/rootstock --fqdn omap ${USER_PASS} --fullname "Demo User" --imagesize 2G \
	--seed ${MINIMAL_APT},${EXTRA}xfce4,gdm,xubuntu-gdm-theme,xubuntu-artwork,xserver-xorg-video-omap3 \
	${MIRROR} --components "${COMPONENTS}" \
	--dist ${DIST} --serial ${SERIAL} --script ${DIR}/tools/fixup-gui.sh \
	--kernel-image ${KERNEL} --apt-upgrade
}

function xubuntu_armel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	time sudo ${DIR}/../project-rootstock/rootstock --fqdn omap ${USER_PASS} --fullname "Demo User" --imagesize 2G \
	--seed ${MINIMAL_APT},${EXTRA}xubuntu-desktop,xserver-xorg-video-omap3 ${MIRROR} --components "${COMPONENTS}" \
	--dist ${DIST} --serial ${SERIAL} --script ${DIR}/tools/fixup-gui.sh \
	--kernel-image ${KERNEL} --apt-upgrade
}

function gui_armel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	sudo ${DIR}/../project-rootstock/rootstock --fqdn omap ${USER_PASS} --fullname "Demo User" --imagesize 2G \
	--seed $(cat ${DIR}/tools/xfce4-gui-packages | tr '\n' ',') ${MIRROR} --components "${COMPONENTS}" \
	--dist ${DIST} --serial ${SERIAL} --script ${DIR}/tools/fixup-gui.sh \
	--kernel-image ${KERNEL} --apt-upgrade
}

function netbook_armel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	sudo ${DIR}/../project-rootstock/rootstock --fqdn omap ${USER_PASS} --fullname "Demo User" --imagesize 2G \
	--seed ${MINIMAL_APT},${EXTRA}ubuntu-netbook ${MIRROR} \
	--dist ${DIST} --serial ${SERIAL} --script ${DIR}/tools/fixup-gui.sh \
	--kernel-image ${KERNEL} ${FORCE_SEC} --apt-upgrade --sources ${DIR}/tools/${DIST}.list
}

function compression {
	rm -rfd ${DIR}/deploy/${TIME}-${KERNEL_SEL}/$BUILD || true
	mkdir -p ${DIR}/deploy/${TIME}-${KERNEL_SEL}/$BUILD

	if ls ${DIR}/deploy/armel-rootfs-*.tar >/dev/null 2>&1;then
		mv -v ${DIR}/deploy/armel-rootfs-*.tar ${DIR}/deploy/${TIME}-${KERNEL_SEL}/$BUILD
	fi

	if ls ${DIR}/deploy/vmlinuz-* >/dev/null 2>&1;then
		mv -v ${DIR}/deploy/vmlinuz-* ${DIR}/deploy/${TIME}-${KERNEL_SEL}/$BUILD
	fi

	if ls ${DIR}/deploy/initrd.img-* >/dev/null 2>&1;then
		mv -v ${DIR}/deploy/initrd.img-* ${DIR}/deploy/${TIME}-${KERNEL_SEL}/$BUILD
	fi

	if ls ${DIR}/deploy/rootstock-*.log >/dev/null 2>&1;then
		rm -f ${DIR}/deploy/rootstock-*.log || true
	fi

	cp -v ${DIR}/tools/setup_sdcard.sh ${DIR}/deploy/${TIME}-${KERNEL_SEL}/$BUILD

#	echo "Calculating MD5SUMS" 
#	cd ${DIR}/deploy/$BUILD
#	md5sum ./* > ${DIR}/deploy/$BUILD.md5sums 2> /dev/null

	echo "Starting Compression"
	cd ${DIR}/deploy/${TIME}-${KERNEL_SEL}/
	#tar cvfz $BUILD.tar.gz ./$BUILD
	#tar cvfj $BUILD.tar.bz2 ./$BUILD
	#tar cvfJ $BUILD.tar.xz ./$BUILD

#if [ "$ARCH" = "armv5tel" ] || [ "$ARCH" = "armv7l" ];then
#	tar cvf $BUILD.tar ./$BUILD
#else
	tar cvf $BUILD.tar ./$BUILD
	xz -z -7 -v $BUILD.tar
#fi

	cd ${DIR}/deploy/
}

function kernel_select {

if [ -f /tmp/LATEST ] ; then
	rm -f /tmp/LATEST
fi

wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/${DIST}/LATEST
FTP_DIR=$(cat /tmp/LATEST | grep "ABI:1 ${KERNEL_SEL}" | awk '{print $3}')
FTP_DIR=$(echo ${FTP_DIR} | awk -F'/' '{print $6}')
KERNEL_VER=$(echo ${FTP_DIR} | sed 's/v//')

KERNEL="${DEB_MIRROR}/${DIST}/${FTP_DIR}/linux-image-${KERNEL_VER}_1.0${DIST}_armel.deb"

echo "Using: ${KERNEL}"

}

#11.04
function natty_release {

reset_vars

DIST=natty
SERIAL=ttyO2
kernel_select
EXTRA="linux-firmware,devmem2,u-boot-tools,"
MIRROR=$MIRROR_UBU
COMPONENTS="${UBU_COMPONENTS}"
BUILD=$NATTY_RELEASE$MINIMAL
USER_PASS="--login ubuntu --password temppwd"
minimal_armel
compression

}

#11.10
function oneiric_release {

reset_vars

DIST=oneiric
SERIAL=ttyO2
kernel_select
EXTRA="linux-firmware,devmem2,u-boot-tools,"
MIRROR=$MIRROR_UBU
COMPONENTS="${UBU_COMPONENTS}"
BUILD=$ONEIRIC_ALPHA$MINIMAL
USER_PASS="--login ubuntu --password temppwd"
minimal_armel
compression

}

function squeeze_release {

reset_vars

DIST=squeeze
SERIAL=ttyO2
kernel_select
EXTRA="initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware,"
USER_PASS="--login ubuntu --password temppwd"
MIRROR=$MIRROR_DEB
COMPONENTS="${DEB_COMPONENTS}"
BUILD=squeeze$MINIMAL
minimal_armel
compression

}

function wheezy_release {

reset_vars

DIST=wheezy
SERIAL=ttyO2
kernel_select
EXTRA="initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware,"
USER_PASS="--login ubuntu --password temppwd"
MIRROR=$MIRROR_DEB
COMPONENTS="${DEB_COMPONENTS}"
BUILD=${DIST}$MINIMAL
minimal_armel
compression

}

function armhf_release {

reset_vars

DIST=unstable
SERIAL=ttyO2
kernel_select
EXTRA="initramfs-tools,"
MIRROR=$MIRROR_DEB_ARMHF
COMPONENTS="${DEB_COMPONENTS}"
BUILD=armhf$MINIMAL
USER_PASS="--login ubuntu --password temppwd"
minimal_armel_nokernel
compression

}

mkdir -p ${DIR}/deploy/

#Disable set_mirror for release
set_mirror
dl_rootstock

#USE_OEM=1
#lucid..

#unset USE_OEM
#anything else

KERNEL_SEL="STABLE"
#KERNEL_SEL="TESTING"
#KERNEL_SEL="EXPERIMENTAL"

natty_release
oneiric_release
squeeze_release
wheezy_release

KERNEL_SEL="TESTING"

natty_release
oneiric_release
squeeze_release
wheezy_release

