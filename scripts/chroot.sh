#!/bin/bash -e
#
# Copyright (c) 2012-2013 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

DIR=$PWD
host_arch="$(uname -m)"

source ${DIR}/.project

check_defines () {
	if [ ! "${tempdir}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: tempdir undefined"
		exit 1
	fi

	if [ ! "${distro}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: distro undefined"
		exit 1
	fi

	if [ ! "${release}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: release undefined"
		exit 1
	fi

	if [ ! "${dpkg_arch}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: dpkg_arch undefined"
		exit 1
	fi

	if [ ! "${apt_proxy}" ] ; then
		apt_proxy=""
	fi

	if [ ! "${deb_mirror}" ] ; then
		case "${distro}" in
		debian)
			deb_mirror="ftp.us.debian.org/debian/"
			;;
		ubuntu)
			deb_mirror="ports.ubuntu.com/ubuntu-ports/"
			;;
		esac
	fi
}

report_size () {
	echo "Log: Size of: [${tempdir}]: `du -sh ${tempdir} 2>/dev/null | awk '{print $1}'`"
}

chroot_mount () {
	if [ "$(mount | grep ${tempdir}/sys | awk '{print $3}')" != "${tempdir}/sys" ] ; then
		sudo mount -t sysfs sysfs ${tempdir}/sys
	fi

	if [ "$(mount | grep ${tempdir}/proc | awk '{print $3}')" != "${tempdir}/proc" ] ; then
		sudo mount -t proc proc ${tempdir}/proc
	fi

	if [ ! -d ${tempdir}/dev/pts ] ; then
		sudo mkdir -p ${tempdir}/dev/pts || true
	fi

	if [ "$(mount | grep ${tempdir}/dev/pts | awk '{print $3}')" != "${tempdir}/dev/pts" ] ; then
		sudo mount -t devpts devpts ${tempdir}/dev/pts
	fi
}

chroot_umount () {
	if [ "$(mount | grep ${tempdir}/dev/pts | awk '{print $3}')" == "${tempdir}/dev/pts" ] ; then
		sudo umount -f ${tempdir}/dev/pts
	fi

	if [ "$(mount | grep ${tempdir}/proc | awk '{print $3}')" == "${tempdir}/proc" ] ; then
		sudo umount -f ${tempdir}/proc
	fi

	if [ "$(mount | grep ${tempdir}/sys | awk '{print $3}')" == "${tempdir}/sys" ] ; then
		sudo umount -f ${tempdir}/sys
	fi
}

check_defines

if [ "x${host_arch}" != "xarmv7l" ] ; then
	sudo cp $(which qemu-arm-static) ${tempdir}/usr/bin/
fi

echo "Log: Running: debootstrap second-stage in [${tempdir}]"
sudo chroot ${tempdir} debootstrap/debootstrap --second-stage
report_size

case "${distro}" in
debian)
	deb_components="main contrib non-free"
	deb_mirror="ftp.us.debian.org/debian/"
	;;
ubuntu)
	deb_components="main universe multiverse"
	deb_mirror="ports.ubuntu.com/ubuntu-ports/"
	;;
esac

case "${release}" in
squeeze|quantal)
	echo "deb http://${deb_mirror} ${release} ${deb_components}"| sudo tee ${tempdir}/etc/apt/sources.list >/dev/null
	echo "deb-src http://${deb_mirror} ${release} ${deb_components}" | sudo tee -a ${tempdir}/etc/apt/sources.list >/dev/null
	echo "" | sudo tee -a /etc/apt/sources.list >/dev/null
	echo "deb http://${deb_mirror} ${release}-updates ${deb_components}" | sudo tee -a ${tempdir}/etc/apt/sources.list >/dev/null
	echo "deb-src http://${deb_mirror} ${release}-updates ${deb_components}" | sudo tee -a ${tempdir}/etc/apt/sources.list >/dev/null
	;;
wheezy|sid|raring)
	echo "deb http://${deb_mirror} ${release} ${deb_components}" | sudo tee ${tempdir}/etc/apt/sources.list >/dev/null
	echo "deb-src http://${deb_mirror} ${release} ${deb_components}" | sudo tee -a ${tempdir}/etc/apt/sources.list >/dev/null
	echo "" | sudo tee -a /etc/apt/sources.list >/dev/null
	echo "#deb http://${deb_mirror} ${release}-updates ${deb_components}" | sudo tee -a ${tempdir}/etc/apt/sources.list >/dev/null
	echo "#deb-src http://${deb_mirror} ${release}-updates ${deb_components}" | sudo tee -a ${tempdir}/etc/apt/sources.list >/dev/null
	;;
esac

if [ "${apt_proxy}" ] ; then
	echo "Acquire::http::Proxy \"http://${apt_proxy}\";" | sudo tee ${tempdir}/etc/apt/apt.conf >/dev/null
fi

cat > ${DIR}/chroot_script.sh <<-__EOF__
	#!/bin/sh -e
	export LC_ALL=C
	export DEBIAN_FRONTEND=noninteractive

	stop_init () {
		cat > /usr/sbin/policy-rc.d <<EOF
		#!/bin/sh
		exit 101
		EOF
		chmod +x /usr/sbin/policy-rc.d
	}

	install_pkg_updates () {
		apt-get update
		apt-get upgrade -y --force-yes
	}

	install_pkgs () {
		apt-get -y --force-yes install ${base_pkg_list}
	}

	git_firmware () {
		dpkg -l | grep git-core >/dev/null || deb_pkgs+="git-core "
		if [ "${deb_pkgs}" ] ; then
			sudo apt-get -y --force-yes install ${deb_pkgs}
		fi

		git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git /tmp/linux-firmware

		mkdir -p /lib/firmware/ti-connectivity
		cp -v /tmp/linux-firmware/LICENCE.ti-connectivity /lib/firmware/
		cp -v /tmp/linux-firmware/ti-connectivity/* /lib/firmware/ti-connectivity

		cp -v /tmp/linux-firmware/carl9170-1.fw /lib/firmware/

		rm -rf /tmp/linux-firmware || true

		git clone git://arago-project.org/git/projects/am33x-cm3.git /tmp/am33x-cm3

		cp -v /tmp/am33x-cm3/bin/am335x-pm-firmware.bin /lib/firmware/am335x-pm-firmware.bin

		rm -rf /tmp/am33x-cm3 || true
	}

	dl_pkg_src () {
		mkdir -p /tmp/pkg_src/
		cd /tmp/pkg_src/
		dpkg -l | tail -n+6 | awk '{print \$2}' | sed "s/:armel//g" | sed "s/:armhf//g" > /tmp/pkg_src/pkg_list
		apt-get source --download-only \`cat /tmp/pkg_src/pkg_list\`
		cd -
	}

	cleanup () {
		if [ -f /etc/apt/apt.conf ] ; then
			rm -rf /etc/apt/apt.conf || true
		fi
		apt-get update
		apt-get clean

		rm -f /usr/sbin/policy-rc.d
	}

	#cat /chroot_script.sh

	install_pkg_updates
	install_pkgs
	git_firmware

	#dl_pkg_src
	cleanup
__EOF__

sudo mv ${DIR}/chroot_script.sh ${tempdir}/chroot_script.sh

chroot_mount
sudo chroot ${tempdir} /bin/sh chroot_script.sh
sudo rm -rf ${tempdir}/chroot_script.sh || true
report_size
chroot_umount

cd ${tempdir}
sudo LANG=C tar --numeric-owner -cf ${DIR}/${distro}-${release}-${dpkg_arch}-rootfs.tar .
cd ${DIR}/
#
