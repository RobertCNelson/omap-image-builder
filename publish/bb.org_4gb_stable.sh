#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

ssh_user="buildbot@beagleboard.org"
rev=$(git rev-parse HEAD)
branch=$(git describe --contains --all HEAD)
server_dir="/var/lib/buildbot/masters/kernel-buildbot/public_html/images/${branch}/${rev}"

export apt_proxy=localhost:3142/

image_name="debian-7.8-lxde-4gb-armhf-${time}"
#image_name="debian-7.8-console-armhf-${time}"

options="--img-4gb bone-${image_name} --dtb beaglebone \
--beagleboard.org-production --boot_label BEAGLEBONE --enable-systemd \
--bbb-old-bootloader-in-emmc --hostname beaglebone"

./RootStock-NG.sh -c bb.org-debian-wheezy-lxde-4gb
#./RootStock-NG.sh -c bb.org-debian-wheezy-console

if [ -d ./deploy/${image_name} ] ; then
	cd ./deploy/${image_name}/
	sudo ./setup_sdcard.sh ${options}

	if [ -f bone-${image_name}-4gb.img ] ; then
		sudo chown buildbot.buildbot bone-${image_name}-4gb.img
		xz -z -3 -v -v --verbose bone-${image_name}-4gb.img

		#upload:
		ssh ${ssh_user} mkdir -p ${server_dir}
		rsync -e ssh -av ./bone-${image_name}-4gb.img.xz ${ssh_user}:${server_dir}/

		#cleanup:
		cd ../../
		rm -rf ./deploy/ || true
	fi
fi

