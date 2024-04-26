#!/bin/bash

export apt_proxy=192.168.1.10:3142/

config=bb.org-debian-bookworm-minimal-v6.1-ti-armhf-am335x
filesize=2gb

compress_snapshot_image () {
	json_file="${device}-${export_filename}-${filesize}.img.xz.json"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	sync

	echo "        {" >> ${json_file}
	echo "            \"icon\": \"https://rcn-ee.net/rootfs/release/BorisImageWriter.png\"," >> ${json_file}
	echo "            \"url\": \"https://rcn-ee.net/rootfs/release/${time}/${device}-${export_filename}-${filesize}.img.xz\"," >> ${json_file}
	extract_size=$(du -b ./${device}-${export_filename}-${filesize}.img | awk '{print $1}')
	echo "            \"extract_size\": ${extract_size}," >> ${json_file}
	extract_sha256=$(sha256sum ./${device}-${export_filename}-${filesize}.img | awk '{print $1}')
	echo "            \"extract_sha256\": \"${extract_sha256}\"," >> ${json_file}

	echo "Creating... ${device}-${export_filename}-${filesize}.bmap"
	bmaptool -d create -o ./${device}-${export_filename}-${filesize}.bmap ./${device}-${export_filename}-${filesize}.img

	echo "Compressing... ${device}-${export_filename}-${filesize}.img"
	xz -T0 -z ${device}-${export_filename}-${filesize}.img
	sync

	image_download_size=$(du -b ./${device}-${export_filename}-${filesize}.img.xz | awk '{print $1}')
	echo "            \"image_download_size\": ${image_download_size}," >> ${json_file}
	echo "            \"release_date\": \"${time}\"," >> ${json_file}
	echo "        }," >> ${json_file}
	sync

	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.bmap /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.json /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
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

	echo "sudo ./setup_sdcard.sh --img-${filesize} am335x-${export_filename} --dtb beaglebone --distro-bootloader --enable-bypass-bootup-scripts"
	sudo ./setup_sdcard.sh --img-${filesize} am335x-${export_filename} --dtb beaglebone --distro-bootloader --enable-bypass-bootup-scripts
	mv ./*.img ../

	echo "sudo ./setup_sdcard.sh --img-${filesize} am335x-eMMC-flasher-${export_filename} --dtb beaglebone --distro-bootloader --enable-bypass-bootup-scripts --emmc-flasher"
	sudo ./setup_sdcard.sh --img-${filesize} am335x-eMMC-flasher-${export_filename} --dtb beaglebone --distro-bootloader --enable-bypass-bootup-scripts --emmc-flasher
	mv ./*.img ../

	cd ../

	device="am335x" ; compress_snapshot_image
	device="am335x-eMMC-flasher" ; compress_snapshot_image

	#echo "Compressing...${export_filename}.tar"
	#xz -T0 -z ${export_filename}.tar
	#sha256sum ${export_filename}.tar.xz > ${export_filename}.tar.xz.sha256sum
	#sudo -uvoodoo cp -v ./${export_filename}.tar.xz /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/
	#sudo -uvoodoo cp -v ./${export_filename}.tar.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/snapshot/${time}/${deb_codename}-${image_type}-${deb_arch}/

	rm -rf ${tempdir} || true
else
	echo "failure"
	exit 2
fi
#
