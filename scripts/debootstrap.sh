#!/bin/bash

DIR=$(pwd)
TEMPDIR=$(mktemp -d)

debarch="armhf"
distro="wheezy"
apt_proxy="192.168.0.10:3142/"
deb_mirror="ftp.us.debian.org/debian"

host_arch="$(uname -m)"

echo "Starting: debootstrap in ${TEMPDIR}"
sudo debootstrap --foreign --arch ${debarch} ${distro} ${TEMPDIR} http://${apt_proxy}${deb_mirror}
if [ "x${host_arch}" == "xx86_64" ] ; then
	sudo cp $(which qemu-arm-static) ${TEMPDIR}/usr/bin/
fi
echo "Starting: debootstrap second-stage in ${TEMPDIR}"
sudo chroot ${TEMPDIR} debootstrap/debootstrap --second-stage
cd ${TEMPDIR}
sudo LANG=C tar --numeric-owner -cvf ${DIR}/${debarch}-rootfs.tar .
cd ${DIR}
