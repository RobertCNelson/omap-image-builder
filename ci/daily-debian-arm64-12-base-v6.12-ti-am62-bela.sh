#!/bin/bash

export apt_proxy=192.168.1.10:3142/

config=bela.io-debian-bookworm-iot-v6.12-ti-arm64-k3-am62
filesize=8gb
rootfs="debian-arm64-12-iot-v6.12-ti-bela-testing"

debian_short="Debian 12"
debian_long="Debian 12 (Bookworm)"

compress_snapshot_image () {
	yml_file="${device}-${export_filename}-${filesize}.img.xz.yml.txt"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sync

	echo "- name: ${r_board} ${debian_short} ${r_name}" >> ${yml_file}
	echo "  description: ${debian_long} with ${r_description} for ${r_board} based on ${r_processor} processor" >> ${yml_file}
	echo "  icon: https://raw.githubusercontent.com/BelaPlatform/bela_sample/refs/heads/master/src/images/bela_logo_colour.png" >> ${yml_file}
	echo "  url: https://files.beagle.cc/file/beagleboard-public-2021/images/${device}-${export_filename}-${filesize}.img.xz" >> ${yml_file}
	echo "  bmap: https://raw.githubusercontent.com/BelaPlatform/bela-distros/refs/heads/main/bmap-temp/${device}-${export_filename}-${filesize}.bmap" >> ${yml_file}

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

	sync

	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.bmap /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.yml.txt /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./dpkg-sbom.txt /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/${device}-${export_filename}-${filesize}.dpkg-sbom.txt || true
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

	echo "sudo ./setup_sdcard.sh --img-${filesize} pocketbeagle2-${export_filename} --dtb bela-pocketbeagle2"
	sudo ./setup_sdcard.sh --img-${filesize} pocketbeagle2-${export_filename} --dtb bela-pocketbeagle2
	mv ./*.img ../
	cp -v ./dpkg-sbom.txt ../ || true

	cd ../

	r_board="Bela Gem BeaglePlay"
	r_processor="TI AM62"
	r_devices="beagle-am62"

	r_description="Bela environment"

	r_board="PocketBeagle 2"
	r_processor="TI AM62"
	r_devices="pocketbeagle2-am62"

	r_name="v6.12.x-ti-evl"
	device="pocketbeagle2" ; compress_snapshot_image

	rm -rf ${tempdir} || true
	cd ../
else
	echo "failure"
	exit 2
fi
#
