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
	echo "building: bone-${image_name}-${size}.img"

	if [ -d ./deploy/${image_name} ] ; then
		cd ./deploy/${image_name}/
		sudo ./setup_sdcard.sh ${options}

		if [ -f bone-${image_name}-${size}.img ] ; then
			sudo chown buildbot.buildbot bone-${image_name}-${size}.img
			sudo chown buildbot.buildbot bone-${image_name}-${size}.img.xz.job.txt

			sync ; sync ; sleep 5

			bmaptool create -o bone-${image_name}-${size}.bmap bone-${image_name}-${size}.img

			xz -z -3 -v -v --verbose bone-${image_name}-${size}.img
			sha256sum bone-${image_name}-${size}.img.xz > bone-${image_name}-${size}.img.xz.sha256sum

			#upload:
			ssh ${ssh_user} mkdir -p ${server_dir}
			rsync -e ssh -av ./bone-${image_name}-${size}.bmap ${ssh_user}:${server_dir}/
			rsync -e ssh -av ./bone-${image_name}-${size}.img.xz ${ssh_user}:${server_dir}/
			rsync -e ssh -av ./bone-${image_name}-${size}.img.xz.job.txt ${ssh_user}:${server_dir}/
			rsync -e ssh -av ./bone-${image_name}-${size}.img.xz.sha256sum ${ssh_user}:${server_dir}/

			#cleanup:
			cd ../../
			sudo rm -rf ./deploy/ || true
		fi
	fi
}

keep_net_alive & KEEP_NET_ALIVE_PID=$!
echo "pid: [${KEEP_NET_ALIVE_PID}]"

## Stable/shipping
##Debian 7:
image_name="debian-7.9-lxde-4gb-armhf-${time}"
size="4gb"

options="--img-4gb bone-${image_name} --dtb beaglebone \
--beagleboard.org-production --boot_label BEAGLEBONE --enable-systemd \
--bbb-old-bootloader-in-emmc --hostname beaglebone"

./RootStock-NG.sh -c bb.org-debian-wheezy-lxde-4gb
build_and_upload_image

##Debian 8:
#image_name="debian-8.2-lxqt-2gb-armhf-${time}"
#size="2gb"

#options="--img-2gb bone-${image_name} --dtb beaglebone \
#--beagleboard.org-production --boot_label BEAGLEBONE \
#--rootfs_label rootfs --bbb-old-bootloader-in-emmc --hostname beaglebone"

#./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-2gb-v4.1
#build_and_upload_image

# Next/cape-tester image
##Debian 8:
image_name="debian-8.2-tester-2gb-armhf-${time}"
size="2gb"

options="--img-2gb bone-${image_name} --dtb beaglebone \
--beagleboard.org-production --boot_label BEAGLEBONE \
--rootfs_label rootfs --bbb-old-bootloader-in-emmc --hostname beaglebone"

./RootStock-NG.sh -c bb.org-debian-jessie-tester-2gb-v4.1
build_and_upload_image

[ -e /proc/$KEEP_NET_ALIVE_PID ] && sudo kill $KEEP_NET_ALIVE_PID

