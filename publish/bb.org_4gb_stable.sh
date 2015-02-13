#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

ssh_user="robertcnelson@rcn-ee.net"
server_dir="/home/robertcnelson/rcn-ee.net"

export apt_proxy=localhost:3142/

#image_name="debian-7.8-lxde-4gb-armhf-${time}"
image_name="debian-7.8-console-armhf-${time}"

options="--img-4gb bone-${image_name} --dtb beaglebone \
--beagleboard.org-production --boot_label BEAGLEBONE --enable-systemd \
--bbb-old-bootloader-in-emmc --hostname beaglebone"

#./RootStock-NG.sh -c bb.org-debian-stable-4gb
./RootStock-NG.sh -c bb.org-console-debian-stable

if [ -d ./deploy/${image_name} ] ; then
	cd ./deploy/${image_name}/
	sudo ./setup_sdcard.sh ${options}

	if [ -f bone-${image_name}-4gb.img ] ; then
		sudo chown buildbot.buildbot bone-${image_name}-4gb.img
		xz -z -3 -v bone-${image_name}-4gb.img

		#upload:
		#rsync -e ssh -av ./bone-${image_name}-4gb.img ${ssh_user}:${server_dir}/

		#cleanup:
		cd ../../
		rm -rf ./deploy/ || true
	fi
fi

