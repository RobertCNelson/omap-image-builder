#!/bin/bash

export apt_proxy=192.168.1.10:3142/

config=bb.org-debian-bookworm-cinnamon-v6.1-ti-arm64-k3-j722s
filesize=12gb
rootfs="debian-arm64-12-bookworm-cinnamon-v6.1-ti"

compress_snapshot_image () {
	yml_file="${device}-${export_filename}-${filesize}.img.xz.yml"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sync

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
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.yml /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
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

	echo "sudo ./setup_sdcard.sh --img-${filesize} beagley-ai-${export_filename} --dtb beagley-ai-swap"
	sudo ./setup_sdcard.sh --img-${filesize} beagley-ai-${export_filename} --dtb beagley-ai-swap
	mv ./*.img ../

	cd ../

	device="beagley-ai" ; compress_snapshot_image

	#echo "Compressing...${export_filename}.tar"
	#xz -T0 -z ${export_filename}.tar
	#sha256sum ${export_filename}.tar.xz > ${export_filename}.tar.xz.sha256sum
	#sudo -uvoodoo cp -v ./${export_filename}.tar.xz /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	#sudo -uvoodoo cp -v ./${export_filename}.tar.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	rm -rf ${tempdir} || true
else
	echo "failure"
	exit 2
fi
#
