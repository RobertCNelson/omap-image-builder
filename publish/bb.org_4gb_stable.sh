#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

ssh_user="buildbot@beagleboard.org"
rev=$(git rev-parse HEAD)
branch=$(git describe --contains --all HEAD)
server_dir="/var/lib/buildbot/masters/kernel-buildbot/public_html/images/${branch}/${rev}"

export apt_proxy=localhost:3142/

keep_net_alive () {
	while : ; do
		sleep 15
		echo "log: [Running: ./publish/bb.org_4gb_stable.sh]"
	done
}

build_and_upload_image () {
	echo "***BUILDING***: ${config_name}: ${target_name}-${image_name}-${size}.img"
	
	./RootStock-NG.sh -c ${config_name}

	if [ -d ./deploy/${image_name} ] ; then
		cd ./deploy/${image_name}/
		echo "debug: [./setup_sdcard.sh ${options}]"
		sudo ./setup_sdcard.sh ${options}

		if [ -f ${target_name}-${image_name}-${size}.img ] ; then
			sudo chown buildbot.buildbot ${target_name}-${image_name}-${size}.img
			sudo chown buildbot.buildbot ${target_name}-${image_name}-${size}.img.xz.job.txt

			sync ; sync ; sleep 5

			bmaptool create -o ${target_name}-${image_name}-${size}.bmap ${target_name}-${image_name}-${size}.img

			xz -T0 -z -3 -v -v --verbose ${target_name}-${image_name}-${size}.img
			sha256sum ${target_name}-${image_name}-${size}.img.xz > ${target_name}-${image_name}-${size}.img.xz.sha256sum

			#upload:
			ssh ${ssh_user} mkdir -p ${server_dir}
			rsync -e ssh -av ./${target_name}-${image_name}-${size}.bmap ${ssh_user}:${server_dir}/
			rsync -e ssh -av ./${target_name}-${image_name}-${size}.img.xz ${ssh_user}:${server_dir}/
			rsync -e ssh -av ./${target_name}-${image_name}-${size}.img.xz.job.txt ${ssh_user}:${server_dir}/
			rsync -e ssh -av ./${target_name}-${image_name}-${size}.img.xz.sha256sum ${ssh_user}:${server_dir}/

			#cleanup:
			cd ../../
			sudo rm -rf ./deploy/ || true
		else
			echo "***ERROR***: Could not find ${target_name}-${image_name}-${size}.img"
		fi
	else
		echo "***ERROR***: Could not find ./deploy/${image_name}"
	fi
}

keep_net_alive & KEEP_NET_ALIVE_PID=$!
echo "pid: [${KEEP_NET_ALIVE_PID}]"

# IoT BeagleBone image
##Debian 8:
#image_name="${deb_distribution}-${release}-${image_type}-${deb_arch}-${time}"
image_name="debian-8.10-iot-2gb-armhf-${time}"
size="2gb"
target_name="bone"
options="--img-2gb ${target_name}-${image_name} --dtb beaglebone \
--bbb-old-bootloader-in-emmc --hostname beaglebone --enable-cape-universal"
config_name="bb.org-debian-jessie-iot-2gb-v4.4"
build_and_upload_image

# LXQT BeagleBone image
##Debian 8:
#image_name="${deb_distribution}-${release}-${image_type}-${deb_arch}-${time}"
image_name="debian-8.10-lxqt-4gb-armhf-${time}"
size="4gb"
target_name="bone"
options="--img-4gb ${target_name}-${image_name} --dtb beaglebone \
--bbb-old-bootloader-in-emmc --hostname beaglebone --enable-cape-universal"
config_name="bb.org-debian-jessie-lxqt-4gb-v4.4"
build_and_upload_image

# LXQT BeagleBoard-xM image
##Debian 8:
#image_name="${deb_distribution}-${release}-${image_type}-${deb_arch}-${time}"
image_name="debian-8.10-lxqt-xm-4gb-armhf-${time}"
size="4gb"
target_name="bbxm"
options="--img-4gb ${target_name}-${image_name} --dtb omap3-beagle-xm --rootfs_label rootfs --hostname beagleboard"
config_name="bb.org-debian-jessie-lxqt-4gb-xm"
build_and_upload_image

# LXQT BeagleBoard-X15 image
##Debian 8:
#image_name="${deb_distribution}-${release}-${image_type}-${deb_arch}-${time}"
image_name="debian-8.10-lxqt-4gb-armhf-${time}"
size="4gb"
target_name="bbx15"
options="--img-4gb ${target_name}-${image_name} --dtb am57xx-beagle-x15 --hostname beagleboard"
config_name="bb.org-debian-jessie-lxqt-4gb-v4.4"
build_and_upload_image

[ -e /proc/$KEEP_NET_ALIVE_PID ] && sudo kill $KEEP_NET_ALIVE_PID

