#!/bin/bash -e

LUCID_KERNEL="http://rcn-ee.net/deb/kernel/beagle/lucid/v2.6.32.11-l12/linux-image-2.6.32.11-l12_1.0lucid_armel.deb"

DIR=$PWD

function dl_rootstock {
	rm -rfd ${DIR}/project-rootstock
	bzr branch lp:project-rootstock
	cd ${DIR}/project-rootstock

	echo "Applying local patches"
	patch -p0 < ${DIR}/patches/01-rootstock-tar-output.diff
	patch -p0 < ${DIR}/patches/02-rootstock-create-initramfs.diff
	patch -p0 < ${DIR}/patches/03-rootstock-source-updates.diff
	cd ${DIR}/
}


function minimal_lucid {
	sudo ${DIR}/project-rootstock/rootstock --fqdn beagleboard --login ubuntu --password temppwd  --imagesize 2G \
	--seed wget,nano,linux-firmware,wireless-tools,usbutils \
	--dist lucid --serial ttyS2 --script fixup.sh \
	--kernel-image $LUCID_KERNEL
}


dl_rootstock
minimal_lucid


