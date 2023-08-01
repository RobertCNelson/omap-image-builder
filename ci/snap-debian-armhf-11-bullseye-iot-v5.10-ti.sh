#!/bin/bash

export apt_proxy=192.168.1.12:3142/

config=bb.org-debian-bullseye-iot-v5.10-ti-armhf
filesize=4gb

compress_snapshot_image () {
	json_file="/mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/${device}-${export_filename}-${filesize}.img.xz.json"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	sync

	echo "                {" >> ${json_file}
	echo "                    \"name\": \"Debian 11 ${image_type} (${deb_arch})\"," >> ${json_file}
	echo "                    \"description\": \"A port of Debian Bullseye with the ${image_type} package set\"," >> ${json_file}
	echo "                    \"icon\": \"https://downloads.raspberrypi.org/raspios_armhf/Raspberry_Pi_OS_(32-bit).png\"," >> ${json_file}
	echo "                    \"url\": \"https://rcn-ee.net/rootfs/release/${time}/${device}-${export_filename}-${filesize}.img.xz\"," >> ${json_file}
	extract_size=$(du -b ./${device}-${export_filename}-${filesize}.img | awk '{print $1}')
	echo "                    \"extract_size\": ${extract_size}," >> ${json_file}
	extract_sha256=$(sha256sum ./${device}-${export_filename}-${filesize}.img | awk '{print $1}')
	echo "                    \"extract_sha256\": \"${extract_sha256}\"," >> ${json_file}

	echo "Compressing...${device}-${export_filename}-${filesize}.img"
	xz -T4 -z ${device}-${export_filename}-${filesize}.img
	sync

	image_download_size=$(du -b ./${device}-${export_filename}-${filesize}.img.xz | awk '{print $1}')
	echo "                    \"image_download_size\": ${image_download_size}," >> ${json_file}
	echo "                    \"release_date\": \"${time}\"," >> ${json_file}
	echo "                    \"init_format\": \"systemd\"" >> ${json_file}
	echo "                }," >> ${json_file}
	sync

	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
}

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

	device="am335x" ; compress_snapshot_image
	device="am335x-eMMC-flasher" ; compress_snapshot_image
	device="am57xx" ; compress_snapshot_image
	device="am57xx-eMMC-flasher" ; compress_snapshot_image

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
