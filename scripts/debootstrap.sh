#!/bin/bash -e

DIR=$(pwd)
TEMPDIR=$(mktemp -d)

debarch="armhf"
distro="wheezy"
apt_proxy="192.168.0.10:3142/"
deb_mirror="ftp.us.debian.org/debian"
host_arch="$(uname -m)"

#1.0.${minimal_debootstrap}
minimal_debootstrap="46"

debootstrap_is_installed () {
	unset deb_pkgs
	dpkg -l | grep debootstrap >/dev/null || deb_pkgs+="debootstrap "

	if [ "${deb_pkgs}" ] ; then
		echo "Installing: ${deb_pkgs}"
		sudo apt-get update
		sudo apt-get -y install ${deb_pkgs}
	fi
}

debootstrap_what_version () {
	test_debootstrap=$(/usr/sbin/debootstrap --version | awk '{print $2}' | awk -F"." '{print $3}')
	echo "debootstrap version: 1.0."$test_debootstrap""
}

debootstrap_is_installed
debootstrap_what_version

if [[ "$test_debootstrap" < "$minimal_debootstrap" ]] ; then
	echo "Installing minimal debootstrap version: 1.0."${minimal_debootstrap}"..."
	wget http://rcn-ee.net/mirror/debootstrap/debootstrap_1.0.${minimal_debootstrap}_all.deb
	sudo dpkg -i debootstrap_1.0.${minimal_debootstrap}_all.deb
	rm -rf debootstrap_1.0.${minimal_debootstrap}_all.deb || true
fi

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
