#!/bin/bash

export apt_proxy=192.168.1.10:3142/

config=bb.org-ubuntu-2310-console-riscv64
filesize=4gb
rootfs="ubuntu-riscv64-23.10-minimal"

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

touch .gitea.mirror
echo "./RootStock-NG.sh -c ${config}"
./RootStock-NG.sh -c ${config}

source .project

if [ -f ./deploy/${export_filename}.tar ] ; then
	cd ./deploy/${export_filename}/

	#setup stuff...

	cd ..

	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	echo "Compressing...${export_filename}.tar"
	zstd -T0 -18 -z ${export_filename}.tar
	sha256sum ${export_filename}.tar.zst > ${export_filename}.tar.zst.sha256sum
	sudo -uvoodoo cp -v ./${export_filename}.tar.zst /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${export_filename}.tar.zst.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	echo "${export_filename}.tar.zst" > latest
	sudo -uvoodoo cp -v ./latest /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/

	rm -rf ${tempdir} || true
else
	echo "failure"
	exit 2
fi
#
