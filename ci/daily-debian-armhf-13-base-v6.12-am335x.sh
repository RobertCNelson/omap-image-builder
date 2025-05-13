#!/bin/bash

export apt_proxy=192.168.1.10:3142/

config=bb.org-debian-trixie-base-v6.12-armhf-am335x
filesize=4gb
rootfs="debian-armhf-13-base-v6.12"

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

touch .notar
touch .gitea.mirror
echo "./RootStock-NG.sh -c ${config}"
./RootStock-NG.sh -c ${config}

source .project

if [ -d ./deploy/${export_filename}/ ] ; then
	cd ./deploy/${export_filename}/

	echo "sudo ./setup_sdcard.sh --img-${filesize} am335x-swap-${export_filename} --dtb beaglebone-fat-swap"
	sudo ./setup_sdcard.sh --img-${filesize} am335x-swap-${export_filename} --dtb beaglebone-fat-swap
	mv ./*.img ../

	cd ../

	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	device="am335x-swap"
	echo "Compressing...${device}-${export_filename}-${filesize}.img"
	xz -T0 -z ${device}-${export_filename}-${filesize}.img
	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	rm -rf ${tempdir} || true
else
	echo "failure"
	exit 2
fi

config=bb.org-debian-trixie-base-vscode-v6.12-armhf-am335x
filesize=4gb
rootfs="debian-armhf-13-base-v6.12"

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

touch .notar
touch .gitea.mirror
echo "./RootStock-NG.sh -c ${config}"
./RootStock-NG.sh -c ${config}

source .project

if [ -d ./deploy/${export_filename}/ ] ; then
	cd ./deploy/${export_filename}/

	echo "sudo ./setup_sdcard.sh --img-${filesize} am335x-swap-vscode-${export_filename} --dtb beaglebone-fat-swap"
	sudo ./setup_sdcard.sh --img-${filesize} am335x-swap-vscode-${export_filename} --dtb beaglebone-fat-swap
	mv ./*.img ../

	cd ../

	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	device="am335x-swap-vscode"
	echo "Compressing...${device}-${export_filename}-${filesize}.img"
	xz -T0 -z ${device}-${export_filename}-${filesize}.img
	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	rm -rf ${tempdir} || true
else
	echo "failure"
	exit 2
fi
#
