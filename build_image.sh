#!/bin/bash -e

SYST=$(cat /etc/hostname)
ARCH=$(uname -m)

#KARMIC_RELEASE="ubuntu-9.10-minimal-armel-1.1"
KARMIC_RELEASE="ubuntu-9.10.2"

#Lucid Schedule:
#https://wiki.ubuntu.com/LucidReleaseSchedule
#alpha-3 :
LUCID_ALPHA3="ubuntu-lucid-alpha3.1"
#beta-2 : April 8th
LUCID_BETA2="ubuntu-lucid-beta2.1"
#RC : April 22nd
LUCID_RC="ubuntu-10.04-rc"
#10.04 : April 29th
LUCID_RELEASE="ubuntu-10.04"
#10.04.1 : July 29th

#Maverick Schedule:
#https://wiki.ubuntu.com/MaverickReleaseSchedule
#alpha-1 : June 3rd
MAVERICK_ALPHA="ubuntu-maverick-alpha1"
#alpha-2 : July 1st
#alpha-3 : August 5th
#alpha-4 : September 2nd
#beta : September 23rd
#10.10 : October 10th

SID_KERNEL="http://rcn-ee.net/deb/kernel/beagle/sid/v2.6.32.11-x13/linux-image-2.6.32.11-x13_1.0sid_armel.deb"

MINIMAL="-minimal-armel"
XFCE="-xfce4-armel"
GUI="-desktop-armel"
NET="-netbook-armel"

UBOOT="uboot-envtools,uboot-mkimage,"

UBUNTU_COMPONENTS="main universe multiverse"
DEBIAN_COMPONENTS="main contrib non-free"

DIR=$PWD

function set_mirror {

MIRROR_DEB="--mirror http://ftp.us.debian.org/debian/"

if [ $SYST == "work-p4" ]; then
	MIRROR_UBU="--mirror http://192.168.0.10:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.0.10:3142/ftp.us.debian.org/debian/"
fi

if [ $SYST == "work-celeron" ]; then
	MIRROR_UBU="--mirror http://192.168.0.10:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.0.10:3142/ftp.us.debian.org/debian/"
fi

if [ $SYST == "voodoo-e6400" ]; then
	MIRROR_UBU="--mirror http://192.168.0.10:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.0.10:3142/ftp.us.debian.org/debian/"
fi

if [ $SYST == "lvrm" ]; then
	MIRROR_UBU="--mirror http://192.168.1.27:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.1.27:3142/ftp.us.debian.org/debian/"
fi

if [ "$ARCH" = "armv5tel" ] || [ "$ARCH" = "armv7l" ];then
	MIRROR_UBU="--mirror http://192.168.1.27:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.1.27:3142/ftp.us.debian.org/debian/"
fi

}

function dl_rootstock {
	rm -rfd ${DIR}/../project-rootstock
	cd ${DIR}/../
	bzr branch lp:project-rootstock
	cd ${DIR}/../project-rootstock

	echo "Applying local patches"
	patch -p0 < ${DIR}/patches/01-rootstock-tar-output.diff
	patch -p0 < ${DIR}/patches/02-rootstock-remove-bashism.diff
	patch -p0 < ${DIR}/patches/03-rootstock-source-updates.diff
	patch -p0 < ${DIR}/patches/native-arm.diff
	patch -p0 < ${DIR}/patches/native-arm-fix.diff
#nasty hack to use /dev/sda1
#if [ $SYST == "lvrm" ]; then
#	patch -p0 < ${DIR}/patches/05-use-real-hardware.diff
#        FORCE_SEC="--force-sec-hd /dev/sda1"
#fi
#	bzr commit -m 'temp'
#exit
	cd ${DIR}/deploy/
}

function minimal_armel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	sudo ${DIR}/../project-rootstock/rootstock --fqdn beagleboard ${USER_PASS} --imagesize 2G \
	--seed ${UBOOT}${EXTRA}wget,nano,wireless-tools,usbutils ${MIRROR} \
	--components "${COMPONENTS}" \
	--dist ${DIST} --serial ttyS2 --script ${DIR}/tools/fixup.sh \
	--kernel-image ${KERNEL}
}

function xfce4_armel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	time sudo ${DIR}/../project-rootstock/rootstock --fqdn beagleboard ${USER_PASS} --imagesize 2G \
	--seed ${UBOOT}${EXTRA}xfce4,gdm,xubuntu-gdm-theme,xubuntu-artwork,wget,nano,wireless-tools,usbutils,xserver-xorg-video-omap3 ${MIRROR} \
	--components "${COMPONENTS}" \
	--dist ${DIST} --serial ttyS2 --script ${DIR}/tools/fixup-gui.sh \
	--kernel-image ${KERNEL}
}

function xubuntu_armel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	time sudo ${DIR}/../project-rootstock/rootstock --fqdn beagleboard ${USER_PASS} --imagesize 2G \
	--seed ${UBOOT}${EXTRA}xubuntu-desktop,wget,nano,wireless-tools,usbutils,xserver-xorg-video-omap3 ${MIRROR} \
	--components "${COMPONENTS}" \
	--dist ${DIST} --serial ttyS2 --script ${DIR}/tools/fixup-gui.sh \
	--kernel-image ${KERNEL}
}

function gui_armel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	sudo ${DIR}/../project-rootstock/rootstock --fqdn beagleboard ${USER_PASS} --imagesize 3G \
	--seed `cat ${DIR}/tools/xfce4-gui-packages | tr '\n' ','` ${MIRROR} \
	--components "${COMPONENTS}" \
	--dist ${DIST} --serial ttyS2 --script ${DIR}/tools/fixup-gui.sh \
	--kernel-image ${KERNEL}
}

function toucbook_armel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	sudo ${DIR}/../project-rootstock/rootstock --fqdn beagleboard ${USER_PASS} --imagesize 3G \
	--seed `cat ${DIR}/tools/touchbook | tr '\n' ','` ${MIRROR} \
	--components "${COMPONENTS}" \
	--dist ${DIST} --serial ttyS2 --script ${DIR}/tools/fixup-gui.sh \
	--kernel-image ${KERNEL}
}

function netbook_armel {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	time sudo ${DIR}/../project-rootstock/rootstock --fqdn beagleboard ${USER_PASS} --imagesize 3G \
	--seed ${UBOOT}${EXTRA}ubuntu-netbook ${MIRROR} \
	--components "${COMPONENTS}" \
	--dist ${DIST} --serial ttyS2 --script ${DIR}/tools/fixup-gui.sh \
	--kernel-image ${KERNEL} ${FORCE_SEC}
}

function compression {
	rm -rfd ${DIR}/deploy/$BUILD || true
	mkdir -p ${DIR}/deploy/$BUILD
	cp -v ${DIR}/deploy/armel-rootfs-*.tar ${DIR}/deploy/$BUILD
	cp -v ${DIR}/deploy/vmlinuz-* ${DIR}/deploy/$BUILD
	cp -v ${DIR}/deploy/initrd.img-* ${DIR}/deploy/$BUILD
	cp -v ${DIR}/tools/boot.cmd ${DIR}/deploy/$BUILD
	cp -v ${DIR}/tools/flash.cmd ${DIR}/deploy/$BUILD
	cp -v ${DIR}/tools/setup_sdcard.sh ${DIR}/deploy/$BUILD

#	echo "Calculating MD5SUMS" 
#	cd ${DIR}/deploy/$BUILD
#	md5sum ./* > ${DIR}/deploy/$BUILD.md5sums 2> /dev/null

	echo "Starting Compression"
	cd ${DIR}/deploy/
	#tar cvfz $BUILD.tar.gz ./$BUILD
	#tar cvfj $BUILD.tar.bz2 ./$BUILD
	#tar cvfJ $BUILD.tar.xz ./$BUILD
if [ "$ARCH" = "armv5tel" ] || [ "$ARCH" = "armv7l" ];then
	tar cvf $BUILD.tar ./$BUILD
else
	tar cvf $BUILD.tar ./$BUILD
	7za a $BUILD.tar.7z $BUILD.tar
fi
	cd ${DIR}/deploy/
}

function karmic_release {

DIST=karmic
KERNEL="http://rcn-ee.net/deb/kernel/beagle/karmic/v2.6.32.11-x13/linux-image-2.6.32.11-x13_1.0karmic_armel.deb"
EXTRA="linux-firmware,"
USER_PASS="--login ubuntu --password temppwd"
COMPONENTS=$UBUNTU_COMPONENTS
BUILD=$KARMIC_RELEASE$MINIMAL
minimal_armel
compression

}

function lucid_release {

DIST=lucid
KERNEL="http://rcn-ee.net/deb/lucid/v2.6.34-l1/linux-image-2.6.34-l1_1.0lucid_armel.deb"
EXTRA="linux-firmware,"
USER_PASS="--login ubuntu --password temppwd"
COMPONENTS=$UBUNTU_COMPONENTS
MIRROR=$MIRROR_UBU
BUILD=$LUCID_RELEASE$MINIMAL
minimal_armel
compression

}

function lucid_xfce4 {

DIST=lucid
KERNEL="http://rcn-ee.net/deb/lucid/v2.6.34-l2/linux-image-2.6.34-l2_1.0lucid_armel.deb"
EXTRA="linux-firmware,"
USER_PASS="--login ubuntu --password temppwd"
COMPONENTS=$UBUNTU_COMPONENTS
#MIRROR=$MIRROR_UBU
BUILD=$LUCID_RELEASE$XFCE
toucbook_armel
compression

}

function maverick_release {

DIST=maverick
KERNEL="http://rcn-ee.net/deb/maverick/v2.6.34-l1/linux-image-2.6.34-l1_1.0maverick_armel.deb"
EXTRA="linux-firmware,"
USER_PASS="--login ubuntu --password temppwd"
COMPONENTS=$UBUNTU_COMPONENTS
MIRROR=$MIRROR_UBU
BUILD=$MAVERICK_ALPHA$MINIMAL
minimal_armel
compression

}

function squeeze_release {

DIST=squeeze
KERNEL="http://rcn-ee.net/deb/squeeze/v2.6.34-x1/linux-image-2.6.34-x1_1.0squeeze_armel.deb"
EXTRA="initramfs-tools,atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware,"
USER_PASS="--login ubuntu --password temppwd"
COMPONENTS=$DEBIAN_COMPONENTS
MIRROR=$MIRROR_DEB
BUILD=squeeze$MINIMAL
minimal_armel
compression

}


sudo rm -rfd ${DIR}/deploy || true
mkdir -p ${DIR}/deploy

#set_mirror
dl_rootstock

lucid_xfce4

#DIST=lucid
#KERNEL=$LUCID_KERNEL
#COMPONENTS=$UBUNTU_COMPONENTS
#BUILD=$LUCID_BETA2$GUI
#gui_armel
#compression

#DIST=lucid
#KERNEL=$LUCID_KERNEL
#COMPONENTS=$UBUNTU_COMPONENTS
#BUILD=$LUCID_BETA2$NET
#netbook_armel
#compression

