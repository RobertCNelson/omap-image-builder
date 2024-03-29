#!/bin/bash

export apt_proxy=192.168.1.10:3142/

config=bb.org-debian-bookworm-iot-v6.1-ti-armhf-am335x
filesize=4gb
rootfs="debian-armhf-12-bookworm-iot-v6.1-ti"

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

	echo "sudo ./setup_sdcard.sh --img-${filesize} am335x-${export_filename} --dtb beaglebone --distro-bootloader --enable-bypass-bootup-scripts"
	sudo ./setup_sdcard.sh --img-${filesize} am335x-${export_filename} --dtb beaglebone --distro-bootloader --enable-bypass-bootup-scripts
	mv ./*.img ../

	cd ../

	device="am335x"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	echo "Compressing...${device}-${export_filename}-${filesize}.img"
	zstd -T0 -18 -z ${device}-${export_filename}-${filesize}.img
	sha256sum ${device}-${export_filename}-${filesize}.img.zst > ${device}-${export_filename}-${filesize}.img.zst.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.zst /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.zst.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	#echo "Compressing...${export_filename}.tar"
	#zstd -T0 -18 -z ${export_filename}.tar
	#sha256sum ${export_filename}.tar.zst > ${export_filename}.tar.zst.sha256sum
	#sudo -uvoodoo cp -v ./${export_filename}.tar.zst /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	#sudo -uvoodoo cp -v ./${export_filename}.tar.zst.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	rm -rf ${tempdir} || true
else
	echo "failure"
	exit 2
fi
#
