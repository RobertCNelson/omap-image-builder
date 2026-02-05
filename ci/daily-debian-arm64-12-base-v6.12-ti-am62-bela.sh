#!/bin/bash

#export apt_proxy=192.168.1.10:3142/
set -e

OPT=$(getent passwd voodoo && echo true || echo false)
config=bela.io-debian-bookworm-iot-v6.12-ti-arm64-k3-am62
filesize=8gb
rootfs="debian-arm64-12-iot-v6.12-ti-bela"

r_processor="TI AM62"

compress_snapshot_image () {
	yml_file="${device}-${export_filename}-${filesize}.img.xz.yml.txt"
	$OPT && sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sync

	echo "- name: ${r_board} Debian 12 ${r_name}" >> ${yml_file}
	echo "  description: Debian 12 (Bookworm) with ${r_description} for ${r_board} based on ${r_processor} processor" >> ${yml_file}
	echo "  icon: https://media.githubusercontent.com/media/beagleboard/bb-imager-rs/refs/heads/main/assets/os/debian.png" >> ${yml_file}
	echo "  url: https://files.beagle.cc/file/beagleboard-public-2021/images/${device}-${export_filename}-${filesize}.img.xz" >> ${yml_file}
	echo "  bmap: https://raw.githubusercontent.com/beagleboard/distros/refs/heads/main/bmap-temp/${device}-${export_filename}-${filesize}.bmap" >> ${yml_file}

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
	echo "  devices:" >> ${yml_file}
	echo "    - ${r_devices}" >> ${yml_file}
	echo "    - recommended" >> ${yml_file}

	sync

	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	$OPT && sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.bmap /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	$OPT && sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	$OPT && sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	$OPT && sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.yml.txt /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
}

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy/* || true
fi

touch .notar
touch .gitea.mirror
echo "./RootStock-NG.sh -c ${config}"
./RootStock-NG.sh -c ${config}

source .project

if [ -d ./deploy/${export_filename}/ ] ; then
	cd ./deploy/${export_filename}/

	echo "sudo ./setup_sdcard.sh --img-${filesize} pocketbeagle2-${export_filename} --dtb bela-pocketbeagle2"
	sudo ./setup_sdcard.sh --img-${filesize} pocketbeagle2-${export_filename} --dtb bela-pocketbeagle2
	mv ./*.img ../

	cd ../

	r_description="no desktop environment"

	r_board="PocketBeagle 2"
	r_processor="TI AM62"
	r_devices="pocketbeagle2-am62"

	r_name="v6.12.x-ti Minimal (Recommended)"
	#device="pocketbeagle2" ; compress_snapshot_image

	#rm -rf ${tempdir} || true
else
	echo "failure"
	exit 2
fi
#
