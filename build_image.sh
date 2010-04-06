#!/bin/bash -e

KARMIC_RELEASE="ubuntu-9.10-minimal-armel-1.1"

LUCID_ALPHA3="ubuntu-lucid-alpha3.1"
LUCID_BETA2="ubuntu-lucid-beta2"

MINIMAL="-minimal-armel"
GUI="-desktop-armel"

LUCID_KERNEL="http://rcn-ee.net/deb/kernel/beagle/lucid/v2.6.32.11-l12/linux-image-2.6.32.11-l12_1.0lucid_armel.deb"

DIR=$PWD

function dl_rootstock {
	rm -rfd ${DIR}/../project-rootstock
	cd ${DIR}/../
	bzr branch lp:project-rootstock
	cd ${DIR}/../project-rootstock

	echo "Applying local patches"
	patch -p0 < ${DIR}/patches/01-rootstock-tar-output.diff
	patch -p0 < ${DIR}/patches/02-rootstock-create-initramfs.diff
	patch -p0 < ${DIR}/patches/03-rootstock-source-updates.diff
	cd ${DIR}/deploy/
}


function minimal_lucid {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	sudo ${DIR}/../project-rootstock/rootstock --fqdn beagleboard --login ubuntu --password temppwd  --imagesize 2G \
	--seed wget,nano,linux-firmware,wireless-tools,usbutils \
	--dist lucid --serial ttyS2 --script ${DIR}/tools/fixup.sh \
	--kernel-image $LUCID_KERNEL

}

function gui_lucid {

	rm -f ${DIR}/deploy/armel-rootfs-*.tar
	rm -f ${DIR}/deploy/vmlinuz-*
	rm -f ${DIR}/deploy/initrd.img-*
	rm -f ${DIR}/deploy/rootstock-*.log

	sudo ${DIR}/../project-rootstock/rootstock --fqdn beagleboard --login ubuntu --password temppwd  --imagesize 2G \
	--seed `cat ${DIR}/tools/xfce4-gui-packages | tr '\n' ','` \
	--dist lucid --serial ttyS2 --script ${DIR}/tools/fixup.sh \
	--kernel-image $LUCID_KERNEL
}

function compression {
	rm -rfd ${DIR}/deploy/$BUILD || true
	mkdir -p ${DIR}/deploy/$BUILD
	cp -v ${DIR}/deploy/armel-rootfs-*.tar ${DIR}/deploy/$BUILD
	cp -v ${DIR}/deploy/vmlinuz-* ${DIR}/deploy/$BUILD
	cp -v ${DIR}/deploy/initrd.img-* ${DIR}/deploy/$BUILD
	cp -v ${DIR}/tools/boot.cmd ${DIR}/deploy/$BUILD

	echo "Starting Compression"
	#tar cvfz $BUILD.tar.gz ${DIR}/deploy/$BUILD
	#tar cvfj $BUILD.tar.bz2 ${DIR}/deploy/$BUILD
	tar cvfJ $BUILD.tar.xz ${DIR}/deploy/$BUILD
}


rm -rfd ${DIR}/deploy || true
mkdir -p ${DIR}/deploy

dl_rootstock

BUILD=$LUCID_BETA2$MINIMAL
minimal_lucid
compression

