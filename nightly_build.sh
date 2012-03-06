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
ONEIRIC_RELEASE="ubuntu-11.10-r6"

ONEIRIC_CURRENT=${ONEIRIC_RELEASE}

#Precise Schedule:
#https://wiki.ubuntu.com/PrecisePangolin/ReleaseSchedule
#alpha-1 : Dec 1st
PRECISE_ALPHA="ubuntu-precise-alpha1"
#alpha-2 : Feb 2nd
PRECISE_ALPHA2="ubuntu-precise-alpha2-1"
#beta-1 : March 1st
PRECISE_BETA1="ubuntu-precise-beta1"
#beta-2 : March 29th
PRECISE_BETA2="ubuntu-precise-beta2"
#12.04 : April 26th

PRECISE_CURRENT=${PRECISE_BETA2}

SQUEEZE_CURRENT="debian-6.0.4"
WHEEZY_CURRENT="debian-wheezy"

MINIMAL="-minimal"

DEB_MIRROR="http://rcn-ee.net/deb"

DEB_COMPONENTS="main,contrib,non-free"
UBU_COMPONENTS="main,universe,multiverse"

MIRROR_UBU="--mirror http://ports.ubuntu.com/ubuntu-ports/"
MIRROR_DEB="--mirror http://ftp.us.debian.org/debian/"

DIR=$PWD

echo ""
echo "debootstrap mininum"
echo "wget http://ports.ubuntu.com/pool/main/d/debootstrap/debootstrap_1.0.38_all.deb"
echo "sudo dpkg -i debootstrap_1*"
echo ""

function reset_vars {

unset DIST
unset PRIMARY_KERNEL
unset SECONDARY_KERNEL
unset EXTRA
unset USER_PASS

MINIMAL_APT="git-core,nano,pastebinit,usbutils,wget"
MINIMAL_APT="${MINIMAL_APT},i2c-tools,uboot-envtools,uboot-mkimage"
MINIMAL_APT="${MINIMAL_APT},openssh-server,apache2"
MINIMAL_APT="${MINIMAL_APT},btrfs-tools,usb-modeswitch,wireless-tools,wpasupplicant"
MINIMAL_APT="${MINIMAL_APT},cpufrequtils,fbset"

#Hostname:
FQDN="omap"

USER_LOGIN="ubuntu"
USER_PASS="temppwd"
USER_NAME="Demo User"

SERIAL="ttyO2"

IMAGESIZE="2G"
}

function set_mirror {

if [ $SYST == "work-p4" ] || [ $SYST == "work-celeron" ] || [ $SYST == "work-e6400" ]; then
	MIRROR_UBU="--mirror http://192.168.0.10:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.0.10:3142/ftp.us.debian.org/debian/"
	DEB_MIRROR="http://192.168.0.10/dl/mirrors/deb"
fi

if [ $SYST == "hera" ] || [ $SYST == "lvrm" ] || [ $SYST == "x4-955" ] || [ "$SYST" == "${RELEASE_HOST}" ]; then
	MIRROR_UBU="--mirror http://192.168.1.95:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.1.95:3142/ftp.us.debian.org/debian/"
	DEB_MIRROR="http://192.168.1.95:81/dl/mirrors/deb"
fi

}

function dl_rootstock {
 if [ ! -f ${DIR}/git/project-rootstock/.git/config ] ; then
  mkdir -p ${DIR}/git/
  cd ${DIR}/git/
  git clone git://github.com/RobertCNelson/project-rootstock.git
  cd ${DIR}/
 fi

 cd ${DIR}/git/project-rootstock
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
 --dist ${DIST} --serial ${SERIAL} \
 ${PRIMARY_KERNEL} ${SECONDARY_KERNEL} --apt-upgrade --arch=${ARCH} "
 echo "-------------------------"
 echo ""

 sudo ${DIR}/git/project-rootstock/rootstock  --imagesize ${IMAGESIZE} --fqdn ${FQDN} \
 --login ${USER_LOGIN} --password ${USER_PASS} --fullname "${USER_NAME}" \
 --seed ${MINIMAL_APT}${EXTRA} ${MIRROR} --components "${COMPONENTS}" \
 --dist ${DIST} --serial ${SERIAL} \
 ${PRIMARY_KERNEL} ${SECONDARY_KERNEL} --apt-upgrade --arch=${ARCH}
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

	cp -v ${DIR}/tools/setup_sdcard.sh ${DIR}/deploy/${TIME}-${PRIMARY_KERNEL_SEL}/$BUILD

	echo "Starting Compression"
	cd ${DIR}/deploy/${TIME}-${PRIMARY_KERNEL_SEL}/
	#tar cvfz $BUILD.tar.gz ./$BUILD
	#tar cvfj $BUILD.tar.bz2 ./$BUILD
	#tar cvfJ $BUILD.tar.xz ./$BUILD

if [ -f ${DIR}/release ] ; then
	tar cvf $BUILD.tar ./$BUILD
	xz -z -7 -v $BUILD.tar
else
	tar cvf $BUILD.tar ./$BUILD
fi

	cd ${DIR}/deploy/
}

function kernel_select {

unset OVERRIDE
#OVERRIDE="v3.2.9-x5"

if [ ! "${OVERRIDE}" ] ; then

if [ -f /tmp/LATEST-${SUBARCH} ] ; then
	rm -f /tmp/LATEST-${SUBARCH}
fi

wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/${DIST}-${ARCH}/LATEST-${SUBARCH}
FTP_DIR=$(cat /tmp/LATEST-${SUBARCH} | grep "ABI:1 ${PRIMARY_KERNEL_SEL}" | awk '{print $3}')
FTP_DIR=$(echo ${FTP_DIR} | awk -F'/' '{print $6}')
else
FTP_DIR=${OVERRIDE}
fi

if [ -f /tmp/index.html ] ; then
	rm -f /tmp/index.html
fi

wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/${DIST}-${ARCH}/${FTP_DIR}/
ACTUAL_DEB_FILE=$(cat /tmp/index.html | grep linux-image | awk -F "\"" '{print $2}')

PRIMARY_KERNEL="--kernel-image ${DEB_MIRROR}/${DIST}-${ARCH}/${FTP_DIR}/${ACTUAL_DEB_FILE}"

echo "Using: ${PRIMARY_KERNEL}"

}

function secondary_kernel_select {

unset OVERRIDE
#OVERRIDE="v3.2.0-psp3"

if [ ! "${OVERRIDE}" ] ; then
if [ -f /tmp/LATEST-${SUBARCH} ] ; then
	rm -f /tmp/LATEST-${SUBARCH}
fi

wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/${DIST}-${ARCH}/LATEST-${SUBARCH}
FTP_DIR=$(cat /tmp/LATEST-${SUBARCH} | grep "ABI:1 ${SECONDARY_KERNEL_SEL}" | awk '{print $3}')
FTP_DIR=$(echo ${FTP_DIR} | awk -F'/' '{print $6}')
else
FTP_DIR=${OVERRIDE}
fi

if [ -f /tmp/index.html ] ; then
	rm -f /tmp/index.html
fi

wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/${DIST}-${ARCH}/${FTP_DIR}/
SECONDARY_ACTUAL_DEB_FILE=$(cat /tmp/index.html | grep linux-image | awk -F "\"" '{print $2}')

SECONDARY_KERNEL="--secondary-kernel-image ${DEB_MIRROR}/${DIST}-${ARCH}/${FTP_DIR}/${SECONDARY_ACTUAL_DEB_FILE}"

echo "Using: ${SECONDARY_KERNEL}"

}

${SECONDARY_KERNEL}

#11.10
function oneiric_release {

reset_vars

DIST=oneiric
SUBARCH="omap"
kernel_select
SUBARCH="omap-psp"
secondary_kernel_select
EXTRA=",linux-firmware,devmem2,u-boot-tools,python-software-properties"
MIRROR=$MIRROR_UBU
COMPONENTS="${UBU_COMPONENTS}"
BUILD=$ONEIRIC_CURRENT$MINIMAL-$ARCH
minimal_armel
compression

}

#12.04
function precise_release {

reset_vars

DIST=precise
SUBARCH="omap"
kernel_select
SUBARCH="omap-psp"
secondary_kernel_select
EXTRA=",linux-firmware,devmem2,u-boot-tools,python-software-properties"
MIRROR=$MIRROR_UBU
COMPONENTS="${UBU_COMPONENTS}"
BUILD=$PRECISE_CURRENT$MINIMAL-$ARCH
minimal_armel
compression

}

function squeeze_release {

reset_vars

DIST=squeeze
SUBARCH="omap"
kernel_select
SUBARCH="omap-psp"
secondary_kernel_select
EXTRA=",isc-dhcp-client,initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware"
USER_LOGIN="debian"
MIRROR=$MIRROR_DEB
COMPONENTS="${DEB_COMPONENTS}"
BUILD=${SQUEEZE_CURRENT}$MINIMAL-$ARCH-${TIME}
minimal_armel
compression

}

function wheezy_release {

reset_vars

DIST=wheezy
SUBARCH="omap"
kernel_select
SUBARCH="omap-psp"
secondary_kernel_select
EXTRA=",initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware"
USER_LOGIN="debian"
MIRROR=$MIRROR_DEB
COMPONENTS="${DEB_COMPONENTS}"
BUILD=${WHEEZY_CURRENT}$MINIMAL-$ARCH-${TIME}
minimal_armel
compression

}

function sid_release {

reset_vars

DIST=sid
SUBARCH="omap"
kernel_select
SUBARCH="omap-psp"
secondary_kernel_select
EXTRA=",initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware"
USER_LOGIN="debian"
MIRROR=$MIRROR_DEB
COMPONENTS="${DEB_COMPONENTS}"
BUILD=${DIST}$MINIMAL-$ARCH-${TIME}
minimal_armel
compression

}

mkdir -p ${DIR}/deploy/

RAMTMP_TEST=$(cat /etc/default/rcS | grep -v "#" | grep RAMTMP | awk -F"=" '{print $2}')
if [ -f /etc/default/rcS ] ; then
	if [ "-${RAMTMP_TEST}-" == "-yes-" ] ; then
		if [ "-${HOST_ARCH}-" == "-armv7l-" ] ; then
			echo ""
			echo "ERROR"
			echo "With RAMTMP=yes in /etc/default/rcS on ARM, debootstrap will fail, as /tmp is mounted as nodev."
			echo "Please modify /etc/default/rcS and set RAMTMP=no and reboot."
			echo ""
			exit
		else
			echo ""
			echo "WARNING"
			echo "With RAMTMP=yes in /etc/default/rcS, this script will probally fail due to running out of memory."
			echo "Please modify /etc/default/rcS and set RAMTMP=no and reboot."
			echo ""
		fi
	fi
fi

set_mirror

dl_rootstock

PRIMARY_KERNEL_SEL="STABLE"
#PRIMARY_KERNEL_SEL="TESTING"
#PRIMARY_KERNEL_SEL="EXPERIMENTAL"

SECONDARY_KERNEL_SEL="STABLE"
#SECONDARY_KERNEL_SEL="TESTING"
#SECONDARY_KERNEL_SEL="EXPERIMENTAL"

ARCH=armel
oneiric_release
if [ "-${HOST_ARCH}-" == "-armv7l-" ] ; then
squeeze_release
fi

ARCH=armhf
precise_release
wheezy_release


