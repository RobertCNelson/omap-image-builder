#!/bin/bash

export apt_proxy=192.168.1.12:3142/

config=bb.org-debian-bookworm-minimal-mainline-arm64
filesize=4gb
rootfs="debian-arm64-12-bookworm-minimal-mainline"

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

touch .notar
echo "./RootStock-NG.sh -c ${config}"
./RootStock-NG.sh -c ${config}

source .project

if [ -d ./deploy/${export_filename}/ ] ; then
	cd ./deploy/${export_filename}/

	echo "sudo ./setup_sdcard.sh --img-${filesize} bbai64-${export_filename} --dtb bbai64-ti-2023.04 --hostname BeagleBone-AI64"
	sudo ./setup_sdcard.sh --img-${filesize} bbai64-${export_filename} --dtb bbai64-ti-2023.04 --hostname BeagleBone-AI64
	mv ./*.img ../

	echo "sudo ./setup_sdcard.sh --img-${filesize} beagleplay-${export_filename} --dtb beagleplay-ti-2023.04 --hostname BeaglePlay"
	sudo ./setup_sdcard.sh --img-${filesize} beagleplay-${export_filename} --dtb beagleplay-ti-2023.04 --hostname BeaglePlay
	mv ./*.img ../

	cd ../

	device="bbai64"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	echo "Compressing...${device}-${export_filename}-${filesize}.img"
	xz -T4 -z ${device}-${export_filename}-${filesize}.img
	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	device="beagleplay"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	echo "Compressing...${device}-${export_filename}-${filesize}.img"
	xz -T4 -z ${device}-${export_filename}-${filesize}.img
	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	#echo "Compressing...${export_filename}.tar"
	#xz -T4 -z ${export_filename}.tar
	#sha256sum ${export_filename}.tar.xz > ${export_filename}.tar.xz.sha256sum
	#sudo -uvoodoo cp -v ./${export_filename}.tar.xz /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	#sudo -uvoodoo cp -v ./${export_filename}.tar.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	rm -rf ${tempdir} || true
else
	echo "failure"
	exit 2
fi
#
