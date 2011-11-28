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

SYST=$(uname -n)
HOST_ARCH=$(uname -m)
TIME=$(date +%Y-%m-%d)

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
NATTY_RELEASE="ubuntu-11.04-r6"

NATTY_CURRENT=${NATTY_RELEASE}

#Oneiric Schedule:
#https://wiki.ubuntu.com/OneiricReleaseSchedule
#alpha-1 : June 2nd
ONEIRIC_ALPHA="ubuntu-oneiric-alpha1"
#alpha-2 : July  7th
ONEIRIC_ALPHA2="ubuntu-oneiric-alpha2"
#alpha-3 : August 4th
ONEIRIC_ALPHA3="ubuntu-oneiric-alpha3"
#beta1 : September 1st
ONEIRIC_BETA1="ubuntu-oneiric-beta1"
#beta2 : September 22nd
ONEIRIC_BETA2="ubuntu-oneiric-beta2"
#10.10 : October 13th
ONEIRIC_RELEASE="ubuntu-11.10-r1"

ONEIRIC_CURRENT=${ONEIRIC_RELEASE}

#Precise Schedule:
#https://wiki.ubuntu.com/PrecisePangolin/ReleaseSchedule?action=show&redirect=PreciseReleaseSchedule
#alpha-1 : Dec 1st
PRECISE_ALPHA="ubuntu-precise-alpha1"
#alpha-2 : Feb 2nd
#beta-1 : March 1st
#beta-2 : March 29th
#12.04 : April 26th

PRECISE_CURRENT=${PRECISE_ALPHA}

MINIMAL="-minimal"

MINIMAL_APT="git-core,nano,pastebinit,usbutils,wget"
MINIMAL_APT="${MINIMAL_APT},i2c-tools,uboot-envtools,uboot-mkimage"
MINIMAL_APT="${MINIMAL_APT},openssh-server,apache2"
MINIMAL_APT="${MINIMAL_APT},btrfs-tools,usb-modeswitch,wireless-tools,wpasupplicant"
MINIMAL_APT="${MINIMAL_APT},cpufrequtils"

DEB_MIRROR="http://rcn-ee.net/deb"

DEB_COMPONENTS="main,contrib,non-free"
UBU_COMPONENTS="main,universe,multiverse"

MIRROR_UBU="--mirror http://ports.ubuntu.com/ubuntu-ports/"
MIRROR_DEB="--mirror http://ftp.us.debian.org/debian/"
MIRROR_DEB_ARMHF="--mirror http://ftp.debian-ports.org/debian/"

DIR=$PWD

function reset_vars {

unset DIST
unset PRIMARY_KERNEL
unset SECONDARY_KERNEL
unset EXTRA
unset USER_PASS

}

function set_mirror {

if [ $SYST == "work-p4" ] || [ $SYST == "work-celeron" ] || [ $SYST == "voodoo-e6400" ]; then
	MIRROR_UBU="--mirror http://192.168.0.10:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.0.10:3142/ftp.us.debian.org/debian/"
	MIRROR_DEB_ARMHF="--mirror http://192.168.0.10:3142/ftp.debian-ports.org/debian/"
fi

if [ $SYST == "lvrm" ] || [ $SYST == "x4-955" ] || [ "$HOST_ARCH" = "armv5tel" ] || [ "$HOST_ARCH" = "armv7l" ]; then
	MIRROR_UBU="--mirror http://192.168.1.95:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.1.95:3142/ftp.us.debian.org/debian/"
	MIRROR_DEB_ARMHF="--mirror http://192.168.1.95:3142/ftp.debian-ports.org/debian/"
	DEB_MIRROR="http://192.168.1.95:81/dl/mirrors/deb"
fi

}

function dl_rootstock {
	rm -rf ${DIR}/../project-rootstock
	cd ${DIR}/../
	git clone git://github.com/RobertCNelson/project-rootstock.git
	cd ${DIR}/../project-rootstock

if [ "$HOST_ARCH" = "armv7l" ]; then
	patch -p0 < ${DIR}/patches/add-debian-ports-keyring.diff
fi

if [ "${USE_OEM}" ] ; then
#disable with debian
	patch -p0 < ${DIR}/patches/oemconfig-and-user.diff
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
	${PRIMARY_KERNEL} ${SECONDARY_KERNEL} --apt-upgrade --arch=${ARCH}
}

function minimal_armel_nokernel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	sudo ${DIR}/../project-rootstock/rootstock --fqdn omap ${USER_PASS} --fullname "Demo User" --imagesize 2G \
	--seed ${MINIMAL_APT},${EXTRA} ${MIRROR} --components "${COMPONENTS}" \
	--dist ${DIST} --serial ${SERIAL} --script ${DIR}/tools/fixup-debian.sh --apt-upgrade --arch=${ARCH}
}

function compression {
	rm -rf ${DIR}/deploy/${TIME}-${PRIMARY_KERNEL_SEL}/$BUILD || true
	mkdir -p ${DIR}/deploy/${TIME}-${PRIMARY_KERNEL_SEL}/$BUILD

	if ls ${DIR}/deploy/armel-rootfs-*.tar >/dev/null 2>&1;then
		mv -v ${DIR}/deploy/armel-rootfs-*.tar ${DIR}/deploy/${TIME}-${PRIMARY_KERNEL_SEL}/$BUILD
	fi

	if ls ${DIR}/deploy/vmlinuz-* >/dev/null 2>&1;then
		mv -v ${DIR}/deploy/vmlinuz-* ${DIR}/deploy/${TIME}-${PRIMARY_KERNEL_SEL}/$BUILD
	fi

	if ls ${DIR}/deploy/initrd.img-* >/dev/null 2>&1;then
		mv -v ${DIR}/deploy/initrd.img-* ${DIR}/deploy/${TIME}-${PRIMARY_KERNEL_SEL}/$BUILD
	fi

	if ls ${DIR}/deploy/rootstock-*.log >/dev/null 2>&1;then
		rm -f ${DIR}/deploy/rootstock-*.log || true
	fi

	cp -v ${DIR}/tools/setup_sdcard.sh ${DIR}/deploy/${TIME}-${PRIMARY_KERNEL_SEL}/$BUILD

	echo "Starting Compression"
	cd ${DIR}/deploy/${TIME}-${PRIMARY_KERNEL_SEL}/
	#tar cvfz $BUILD.tar.gz ./$BUILD
	#tar cvfj $BUILD.tar.bz2 ./$BUILD
	#tar cvfJ $BUILD.tar.xz ./$BUILD

if ls ${DIR}/release >/dev/null 2>&1 ; then
	tar cvf $BUILD.tar ./$BUILD
	xz -z -7 -v $BUILD.tar
else
	tar cvf $BUILD.tar ./$BUILD
fi

	cd ${DIR}/deploy/
}

function kernel_select {

if [ -f /tmp/LATEST-${SUBARCH} ] ; then
	rm -f /tmp/LATEST-${SUBARCH}
fi

wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/${DIST}-${ARCH}/LATEST-${SUBARCH}
FTP_DIR=$(cat /tmp/LATEST-${SUBARCH} | grep "ABI:1 ${PRIMARY_KERNEL_SEL}" | awk '{print $3}')
FTP_DIR=$(echo ${FTP_DIR} | awk -F'/' '{print $6}')

if [ -f /tmp/index.html ] ; then
	rm -f /tmp/index.html
fi

wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/${DIST}-${ARCH}/${FTP_DIR}/
ACTUAL_DEB_FILE=$(cat /tmp/index.html | grep linux-image | awk -F "\"" '{print $2}')

PRIMARY_KERNEL="--kernel-image ${DEB_MIRROR}/${DIST}-${ARCH}/${FTP_DIR}/${ACTUAL_DEB_FILE}"

echo "Using: ${PRIMARY_KERNEL}"

}

function secondary_kernel_select {

if [ -f /tmp/LATEST-${SUBARCH} ] ; then
	rm -f /tmp/LATEST-${SUBARCH}
fi

wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/${DIST}/LATEST-${SUBARCH}
FTP_DIR=$(cat /tmp/LATEST-${SUBARCH} | grep "ABI:1 ${SECONDARY_KERNEL_SEL}" | awk '{print $3}')
FTP_DIR=$(echo ${FTP_DIR} | awk -F'/' '{print $6}')

if [ -f /tmp/index.html ] ; then
	rm -f /tmp/index.html
fi

wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/${DIST}/${FTP_DIR}/
SECONDARY_ACTUAL_DEB_FILE=$(cat /tmp/index.html | grep linux-image | awk -F "\"" '{print $2}')

SECONDARY_KERNEL="--secondary-kernel-image ${DEB_MIRROR}/${DIST}/${FTP_DIR}/${SECONDARY_ACTUAL_DEB_FILE}"

echo "Using: ${SECONDARY_KERNEL}"

}

${SECONDARY_KERNEL}

#11.04
function natty_release {

reset_vars

DIST=natty
SERIAL=ttyO2
ARCH=armel
SUBARCH="omap"
kernel_select
SUBARCH="omap-psp"
secondary_kernel_select
EXTRA="linux-firmware,devmem2,u-boot-tools,"
MIRROR=$MIRROR_UBU
COMPONENTS="${UBU_COMPONENTS}"
BUILD=$NATTY_CURRENT$MINIMAL-$ARCH
USER_PASS="--login ubuntu --password temppwd"
minimal_armel
compression

}

#11.10
function oneiric_release {

reset_vars

DIST=oneiric
SERIAL=ttyO2
ARCH=armel
SUBARCH="omap"
kernel_select
SUBARCH="omap-psp"
secondary_kernel_select
EXTRA="linux-firmware,devmem2,u-boot-tools,"
MIRROR=$MIRROR_UBU
COMPONENTS="${UBU_COMPONENTS}"
BUILD=$ONEIRIC_CURRENT$MINIMAL-$ARCH
USER_PASS="--login ubuntu --password temppwd"
minimal_armel
compression

}

#12.04
function precise_armel_release {

reset_vars

DIST=precise
SERIAL=ttyO2
ARCH=armel
SUBARCH="omap"
kernel_select
SUBARCH="omap-psp"
secondary_kernel_select
EXTRA="linux-firmware,devmem2,u-boot-tools,"
MIRROR=$MIRROR_UBU
COMPONENTS="${UBU_COMPONENTS}"
BUILD=$PRECISE_CURRENT$MINIMAL-$ARCH
USER_PASS="--login ubuntu --password temppwd"
minimal_armel
compression

}

function squeeze_release {

reset_vars

DIST=squeeze
SERIAL=ttyO2
ARCH=armel
SUBARCH="omap"
kernel_select
SUBARCH="omap-psp"
secondary_kernel_select
EXTRA="initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware,"
USER_PASS="--login ubuntu --password temppwd"
MIRROR=$MIRROR_DEB
COMPONENTS="${DEB_COMPONENTS}"
BUILD=squeeze$MINIMAL-$ARCH
minimal_armel
compression

}

function wheezy_release {

reset_vars

DIST=wheezy
SERIAL=ttyO2
ARCH=armel
SUBARCH="omap"
kernel_select
SUBARCH="omap-psp"
secondary_kernel_select
EXTRA="initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware,"
USER_PASS="--login ubuntu --password temppwd"
MIRROR=$MIRROR_DEB
COMPONENTS="${DEB_COMPONENTS}"
BUILD=${DIST}$MINIMAL-$ARCH
minimal_armel
compression

}

function armhf_release {

sudo apt-get install debian-ports-archive-keyring
reset_vars

DIST=unstable
SERIAL=ttyO2
ARCH=armhf
SUBARCH="omap"
kernel_select
SUBARCH="omap-psp"
secondary_kernel_select
#EXTRA=''
EXTRA="initramfs-tools,"
MIRROR=$MIRROR_DEB_ARMHF
COMPONENTS="main"
BUILD=unstable$MINIMAL-$ARCH
USER_PASS="--login debian --password temppwd"
minimal_armel
compression

}

mkdir -p ${DIR}/deploy/

if ls ${DIR}/release >/dev/null 2>&1 ; then
 echo "Building Release Package, no mirrors"
else
 echo "Building with mirror files"
 set_mirror
fi

dl_rootstock

#USE_OEM=1
#lucid..

#unset USE_OEM
#anything else

PRIMARY_KERNEL_SEL="STABLE"
#PRIMARY_KERNEL_SEL="TESTING"
#PRIMARY_KERNEL_SEL="EXPERIMENTAL"

SECONDARY_KERNEL_SEL="STABLE"
#SECONDARY_KERNEL_SEL="TESTING"
#SECONDARY_KERNEL_SEL="EXPERIMENTAL"


natty_release
oneiric_release
precise_armel_release
#precise_armhf_release

exit

squeeze_release
#wheezy_release
armhf_release

PRIMARY_KERNEL_SEL="TESTING"

natty_release
oneiric_release
precise_armel_release
#precise_armhf_release
squeeze_release
#wheezy_release
armhf_release

