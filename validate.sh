#!/bin/bash

export apt_proxy=192.168.1.10:3142/

cleanup_deploy () {
	if [ -d ./deploy ] ; then
		sudo rm -rf ./deploy || true
	fi
}

run_config () {
	cleanup_deploy
	echo "./RootStock-NG.sh -c ${config}"
	./RootStock-NG.sh -c ${config}
	source .project
	if [ ! -f ./deploy/${export_filename}.tar ] ; then
		echo "Error: deploy/${export_filename}.tar"
		exit 1
	else
		echo "Compressing: deploy/${export_filename}.tar"
		xz ./deploy/${export_filename}.tar
	fi
}

#config="bb.org-debian-buster-console-v4.19"
#run_config

#config="octavo-debian-buster-console-v4.19"
#run_config

#config="bb.org-debian-bullseye-console-v5.10-ti-armhf"
#run_config

#config="bb.org-debian-bullseye-console-arm64"
#run_config

#config="bela.io-debian-stretch-armhf-v4.14-ti-xenomai"
#run_config

#config="bela.io-debian-bullseye-v4.14-ti-xenomai-armhf"
#run_config

config="eewiki_minfs_ubuntu_focal_arm64"
run_config

if [ -d ./ignore ] ; then
	sudo rm -rf ./ignore || true
fi
