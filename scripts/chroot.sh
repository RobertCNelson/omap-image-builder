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
time=$(date +%Y-%m-%d)

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

echo "127.0.0.1       localhost" | sudo tee ${tempdir}/etc/hosts >/dev/null
echo "127.0.1.1       ${image_hostname}" | sudo tee -a ${tempdir}/etc/hosts >/dev/null

echo "${image_hostname}" | sudo tee ${tempdir}/etc/hostname >/dev/null

cat > ${DIR}/chroot_script.sh <<-__EOF__
	#!/bin/sh -e
	export LC_ALL=C
	export DEBIAN_FRONTEND=noninteractive

	check_n_install () {
		unset deb_pkgs
		dpkg -l | grep "\${pkg}" >/dev/null || deb_pkgs="\${pkg} "

		if [ "\${deb_pkgs}" ] ; then
			apt-get -y --force-yes install \${deb_pkgs}
		fi
	}

	stop_init () {
		cat > /usr/sbin/policy-rc.d <<EOF
		#!/bin/sh
		exit 101
		EOF
		chmod +x /usr/sbin/policy-rc.d

		distro="\$(lsb_release -si)"

		if [ "x\${distro}" = "xUbuntu" ] ; then
			dpkg-divert --local --rename --add /sbin/initctl
			ln -s /bin/true /sbin/initctl
		fi
	}

	install_pkg_updates () {
		apt-get update

		packages="lsb-release initramfs-tools wget"
		for pkg in \${packages} ; do check_n_install ; done

		apt-get upgrade -y --force-yes
	}

	install_pkgs () {
		apt-get -y --force-yes install ${base_pkg_list}
	}

	dl_pkg_src () {
		mkdir -p /tmp/pkg_src/
		cd /tmp/pkg_src/
		dpkg -l | tail -n+6 | awk '{print \$2}' | sed "s/:armel//g" | sed "s/:armhf//g" > /tmp/pkg_src/pkg_list
		apt-get source --download-only \`cat /tmp/pkg_src/pkg_list\`
		cd -
	}

	dl_kernel () {
		wget --directory-prefix=/tmp/ \${kernel_url}

		actual_deb_file=\$(cat /tmp/index.html | grep linux-image)
		actual_deb_file=\$(echo \${actual_deb_file} | awk -F ".deb" '{print \$1}')
		actual_deb_file=\${actual_deb_file##*linux-image-}

		kernel_version=\$(echo \${actual_deb_file} | awk -F "_" '{print \$1}')
		echo "Log: Using: \${kernel_version}"

		actual_deb_file="linux-image-\${actual_deb_file}.deb"
		wget --directory-prefix=/tmp/ \${kernel_url}\${actual_deb_file}

		dpkg -x /tmp/\${actual_deb_file} /

		depmod \${kernel_version}
		update-initramfs -c -k \${kernel_version}
		rm -f /tmp/index.html || true
		rm -f /tmp/\${actual_deb_file} || true
		rm -f /boot/System.map-\${kernel_version} || true
		rm -f /boot/config-\${kernel_version} || true
	}

	cleanup () {
		if [ -f /etc/apt/apt.conf ] ; then
			rm -rf /etc/apt/apt.conf || true
		fi
		apt-get update
		apt-get clean

		rm -f /usr/sbin/policy-rc.d

		if [ "x\${distro}" = "xUbuntu" ] ; then
			rm -f /sbin/initctl || true
			dpkg-divert --local --rename --remove /sbin/initctl
		fi

		if [ "x\${distro}" = "xDebian" ] ; then
			passwd <<-EOF
			root
			root
			EOF
		fi
	}

	#cat /chroot_script.sh

	install_pkg_updates
	install_pkgs

	if [ "x${chroot_ENABLE_DEB_SRC}" = "xenable" ] ; then
		dl_pkg_src
	fi

	if [ "${chroot_KERNEL_HTTP_DIR}" ] ; then
		for kernel_url in ${chroot_KERNEL_HTTP_DIR} ; do dl_kernel ; done
	fi

	cleanup
	rm -f /chroot_script.sh || true
__EOF__

sudo mv ${DIR}/chroot_script.sh ${tempdir}/chroot_script.sh

if [ -d ${DIR}/git/linux-firmware/ti-connectivity/ ] ; then
	sudo mkdir -p ${tempdir}/lib/firmware/ti-connectivity
	sudo cp -v ${DIR}/git/linux-firmware/LICENCE.ti-connectivity ${tempdir}/lib/firmware/
	sudo cp -v ${DIR}/git/linux-firmware/ti-connectivity/* ${tempdir}/lib/firmware/ti-connectivity
fi

if [ -f ${DIR}/git/linux-firmware/carl9170-1.fw ] ; then
	sudo cp -v ${DIR}/git/linux-firmware/carl9170-1.fw ${tempdir}/lib/firmware/
fi

if [ -f ${DIR}/git/am33x-cm3/bin/am335x-pm-firmware.bin ] ; then
	sudo cp -v ${DIR}/git/am33x-cm3/bin/am335x-pm-firmware.bin ${tempdir}/lib/firmware/am335x-pm-firmware.bin
fi

chroot_mount
sudo chroot ${tempdir} /bin/sh chroot_script.sh

#Actual Releases will use version numbers..
case "${release}" in
squeeze)
	#http://www.debian.org/releases/squeeze/
	final_dir="${DIR}/deploy/${distro}-6.0.6-console-${dpkg_arch}-${time}"
	;;
quantal)
	final_dir="${DIR}/deploy/${distro}-12.10-console-${dpkg_arch}-${time}"
	;;
*)
	final_dir="${DIR}/deploy/${distro}-${release}-console-${dpkg_arch}-${time}"
	;;
esac

mkdir -p ${final_dir} || true

if ls ${tempdir}/boot/vmlinuz-* >/dev/null 2>&1 ; then
	sudo mv -v ${tempdir}/boot/vmlinuz-* ${final_dir}/
fi

if ls ${tempdir}/boot/initrd.img-* >/dev/null 2>&1;then
	sudo mv -v ${tempdir}/boot/initrd.img-* ${final_dir}/
fi

report_size
chroot_umount

if [ "x${chroot_ENABLE_DEB_SRC}" == "xenable" ] ; then
	cd ${tempdir}/tmp/pkg_src/
	sudo LANG=C tar --numeric-owner -cf ${DIR}/deploy/${dpkg_arch}-rootfs-${distro}-${release}-src.tar .
	cd ${tempdir}
	ls -lh ${DIR}/deploy/${dpkg_arch}-rootfs-${distro}-${release}-src.tar
	sudo rm -rf ${tempdir}/tmp/pkg_src/ || true
	report_size
fi

cd ${tempdir}
sudo LANG=C tar --numeric-owner -cf ${final_dir}/${dpkg_arch}-rootfs-${distro}-${release}.tar .
cd ${DIR}/
ls -lh ${final_dir}/${dpkg_arch}-rootfs-${distro}-${release}.tar

sudo chown -R ${USER}:${USER} ${final_dir}/
#
