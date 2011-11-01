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
ARCH=$(uname -m)
TIME=$(date +%Y-%m-%d)

unset USE_OEM

MINIMAL="-minimal"

MINIMAL_APT="git-core,nano,pastebinit,usbutils,wget"
MINIMAL_APT="${MINIMAL_APT},i2c-tools,uboot-envtools,uboot-mkimage"
MINIMAL_APT="${MINIMAL_APT},btrfs-tools,openssh-server,usb-modeswitch,wireless-tools,wpasupplicant"
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
	rm -rf ${DIR}/../project-rootstock
	cd ${DIR}/../
	git clone git://github.com/RobertCNelson/project-rootstock.git
	cd ${DIR}/../project-rootstock
        git checkout origin/rcn-ee-images -b rcn-ee-images

	patch -p1 < ${DIR}/patches/bash-if-else-workaround.diff

if [ "$ARCH" = "armv7l" ]; then
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

	sudo ${DIR}/../project-rootstock/rootstock --fqdn dev ${USER_PASS} --fullname "Demo User" --imagesize 2G \
	--seed ${MINIMAL_APT},${EXTRA} ${MIRROR} --components "${COMPONENTS}" \
	--dist ${DIST} --apt-upgrade --arch=${ARCH}
}

function compression {
	rm -rf ${DIR}/deploy/${TIME}-${KERNEL_SEL}/$BUILD || true
	mkdir -p ${DIR}/deploy/${TIME}-${KERNEL_SEL}/$BUILD

	if ls ${DIR}/deploy/armel-rootfs-*.tar >/dev/null 2>&1;then
		mv -v ${DIR}/deploy/armel-rootfs-*.tar ${DIR}/deploy/${TIME}-${KERNEL_SEL}/$BUILD
	fi

	if ls ${DIR}/deploy/rootstock-*.log >/dev/null 2>&1;then
		rm -f ${DIR}/deploy/rootstock-*.log || true
	fi

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

function debian_release {

reset_vars

DIST=squeeze
EXTRA="initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware,"
MIRROR=$MIRROR_DEB
COMPONENTS="${DEB_COMPONENTS}"
BUILD=squeeze$MINIMAL-armel-${TIME}
USER_PASS="--login debian --password temppwd"
ARCH=armel
minimal_armel
compression

}

function ubuntu_release {

reset_vars

DIST=natty
EXTRA="linux-firmware,devmem2,u-boot-tools,"
MIRROR=$MIRROR_UBU
COMPONENTS="${UBU_COMPONENTS}"
BUILD=ubuntu-natty$MINIMAL-armel-${TIME}
USER_PASS="--login ubuntu --password temppwd"
ARCH=armel
minimal_armel
compression

}

function armhf_release {

sudo apt-get install debian-ports-archive-keyring
reset_vars

DIST=unstable
EXTRA="initramfs-tools,"
MIRROR=$MIRROR_DEB_ARMHF
COMPONENTS="main"
BUILD=unstable$MINIMAL-armhf-${TIME}
USER_PASS="--login debian --password temppwd"
ARCH=armhf
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

debian_release
ubuntu_release
armhf_release

