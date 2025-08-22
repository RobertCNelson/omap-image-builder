#!/bin/bash

export apt_proxy=192.168.1.10:3142/

config=bb.org-debian-trixie-base-v6.6-armhf-am335x
filesize=4gb
rootfs="debian-armhf-13-base-v6.6"

compress_snapshot_image () {
	yml_file="${device}-${export_filename}-${filesize}.img.xz.yml.txt"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sync

	echo "  icon: https://media.githubusercontent.com/media/beagleboard/bb-imager-rs/refs/heads/main/assets/os/debian.png" >> ${yml_file}
	echo "  url: https://files.beagle.cc/file/beagleboard-public-2021/images/${device}-${export_filename}-${filesize}.img.xz" >> ${yml_file}
	echo "  bmap: https://rcn-ee.net/rootfs/${rootfs}/${time}/${device}-${export_filename}-${filesize}.bmap" >> ${yml_file}

	extract_size=$(du -b ./${device}-${export_filename}-${filesize}.img | awk '{print $1}')
	echo "  extract_size: ${extract_size}" >> ${yml_file}
	extract_sha256=$(sha256sum ./${device}-${export_filename}-${filesize}.img | awk '{print $1}')
	echo "  extract_sha256: ${extract_sha256}" >> ${yml_file}

	echo "Creating... ${device}-${export_filename}-${filesize}.bmap"
	bmaptool -d create -o ./${device}-${export_filename}-${filesize}.bmap ./${device}-${export_filename}-${filesize}.img

	echo "Compressing... ${device}-${export_filename}-${filesize}.img"
	xz -T0 -z ${device}-${export_filename}-${filesize}.img
	sync

	image_download_size=$(du -b ./${device}-${export_filename}-${filesize}.img.xz | awk '{print $1}')
	echo "  image_download_size: ${image_download_size}" >> ${yml_file}
	image_download_sha256=$(sha256sum ./${device}-${export_filename}-${filesize}.img.xz | awk '{print $1}')
	echo "  image_download_sha256: ${image_download_sha256}" >> ${yml_file}

	echo "  release_date: '${time}'" >> ${yml_file}
	echo "  init_format: sysconf" >> ${yml_file}

	sync

	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.bmap /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.yml.txt /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
}

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

	echo "sudo ./setup_sdcard.sh --img-${filesize} am335x-${export_filename} --dtb beaglebone-fat-swap"
	sudo ./setup_sdcard.sh --img-${filesize} am335x-${export_filename} --dtb beaglebone-fat-swap
	mv ./*.img ../

	cd ../

	device="am335x" ; compress_snapshot_image

	rm -rf ${tempdir} || true
	cd ../
else
	echo "failure"
	exit 2
fi
#
