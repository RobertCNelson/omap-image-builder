#!/bin/bash

export apt_proxy=192.168.1.12:3142/

config=bb.org-debian-bullseye-iot-v5.10-ti-armhf
filesize=4gb

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

touch .notar
echo "./RootStock-NG.sh -c ${config}"
./RootStock-NG.sh -c ${config}

source .project

if [ -d ./deploy/${export_filename}/ ] ; then
	cd ./deploy/${export_filename}/

	echo "sudo ./setup_sdcard.sh --img-${filesize} am335x-${export_filename} --dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-disable-pru --enable-bypass-bootup-scripts"
	sudo ./setup_sdcard.sh --img-${filesize} am335x-${export_filename} --dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-disable-pru --enable-bypass-bootup-scripts
	mv ./*.img ../

	echo "sudo ./setup_sdcard.sh --img-${filesize} am335x-eMMC-flasher-${export_filename} --dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-disable-pru --enable-bypass-bootup-scripts --emmc-flasher"
	sudo ./setup_sdcard.sh --img-${filesize} am335x-eMMC-flasher-${export_filename} --dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-disable-pru --enable-bypass-bootup-scripts --emmc-flasher
	mv ./*.img ../

	echo "sudo ./setup_sdcard.sh --img-${filesize} am57xx-${export_filename} --dtb am57xx-beagle-x15 --distro-bootloader --enable-uboot-cape-overlays --enable-bypass-bootup-scripts"
	sudo ./setup_sdcard.sh --img-${filesize} am57xx-${export_filename} --dtb am57xx-beagle-x15 --distro-bootloader --enable-uboot-cape-overlays --enable-bypass-bootup-scripts
	mv ./*.img ../

	echo "sudo ./setup_sdcard.sh --img-${filesize} am57xx-eMMC-flasher-${export_filename} --dtb am57xx-beagle-x15 --distro-bootloader --enable-uboot-cape-overlays --enable-bypass-bootup-scripts --emmc-flasher"
	sudo ./setup_sdcard.sh --img-${filesize} am57xx-eMMC-flasher-${export_filename} --dtb am57xx-beagle-x15 --distro-bootloader --enable-uboot-cape-overlays --enable-bypass-bootup-scripts --emmc-flasher
	mv ./*.img ../

	cd ../

	device="am335x"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	echo "Compressing...${device}-${export_filename}-${filesize}.img"
	xz -T4 -z ${device}-${export_filename}-${filesize}.img
	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/

	device="am335x-eMMC-flasher"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	echo "Compressing...${device}-${export_filename}-${filesize}.img"
	xz -T4 -z ${device}-${export_filename}-${filesize}.img
	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/

	device="am57xx"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	echo "Compressing...${device}-${export_filename}-${filesize}.img"
	xz -T4 -z ${device}-${export_filename}-${filesize}.img
	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/

	device="am57xx-eMMC-flasher"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	echo "Compressing...${device}-${export_filename}-${filesize}.img"
	xz -T4 -z ${device}-${export_filename}-${filesize}.img
	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/

	#echo "Compressing...${export_filename}.tar"
	#xz -T4 -z ${export_filename}.tar
	#sha256sum ${export_filename}.tar.xz > ${export_filename}.tar.xz.sha256sum
	#sudo -uvoodoo cp -v ./${export_filename}.tar.xz /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	#sudo -uvoodoo cp -v ./${export_filename}.tar.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/

	rm -rf ${tempdir} || true
else
	echo "failure"
	exit 2
fi
#
