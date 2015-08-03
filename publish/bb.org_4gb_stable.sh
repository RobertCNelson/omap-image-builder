#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

ssh_user="buildbot@beagleboard.org"
rev=$(git rev-parse HEAD)
branch=$(git describe --contains --all HEAD)
server_dir="/var/lib/buildbot/masters/kernel-buildbot/public_html/images/${branch}/${rev}"

export apt_proxy=localhost:3142/

##Debian 7:
#image_name="debian-7.8-lxde-4gb-armhf-${time}"
#size="4gb"

#options="--img-4gb bone-${image_name} --dtb beaglebone \
#--beagleboard.org-production --boot_label BEAGLEBONE --enable-systemd \
#--bbb-old-bootloader-in-emmc --hostname beaglebone"

#./RootStock-NG.sh -c bb.org-debian-wheezy-lxde-4gb

##Debian 8:
#image_name="debian-8.1-lxqt-2gb-armhf-${time}"
#size="2gb"

#options="--img-2gb bone-${image_name} --dtb beaglebone \
#--beagleboard.org-production --boot_label BEAGLEBONE \
#--rootfs_label rootfs --bbb-old-bootloader-in-emmc --hostname beaglebone"

#./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-2gb-v4.1

##Debian 8:
image_name="debian-8.1-tester-2gb-armhf-${time}"
size="2gb"

options="--img-2gb bone-${image_name} --dtb beaglebone \
--beagleboard.org-production --boot_label BEAGLEBONE \
--rootfs_label rootfs --bbb-old-bootloader-in-emmc --hostname beaglebone"

./RootStock-NG.sh -c bb.org-debian-jessie-tester-2gb-v4.1

keep_net_alive () {
	while : ; do
		sleep 15
		echo "size: [`ls -lh ./bone-${image_name}-${size}.img.xz`]"
	done
}

if [ -d ./deploy/${image_name} ] ; then
	cd ./deploy/${image_name}/
	sudo ./setup_sdcard.sh ${options}

	if [ -f bone-${image_name}-${size}.img ] ; then
		sudo chown buildbot.buildbot bone-${image_name}-${size}.img

		keep_net_alive & KEEP_NET_ALIVE_PID=$!

		sync ; sync ; sleep 5

		bmaptool create -o bone-${image_name}-${size}.bmap bone-${image_name}-${size}.img

		xz -z -3 -v -v --verbose bone-${image_name}-${size}.img

		#upload:
		ssh ${ssh_user} mkdir -p ${server_dir}
		rsync -e ssh -av ./bone-${image_name}-${size}.bmap ${ssh_user}:${server_dir}/
		rsync -e ssh -av ./bone-${image_name}-${size}.img.xz ${ssh_user}:${server_dir}/

		[ -e /proc/$KEEP_NET_ALIVE_PID ] && sudo kill $KEEP_NET_ALIVE_PID

		#cleanup:
		cd ../../
		rm -rf ./deploy/ || true
	fi
fi

