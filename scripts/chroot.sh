#!/bin/sh -e
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

. ${DIR}/.project

check_defines () {
	if [ ! "${tempdir}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: tempdir undefined"
		exit 1
	fi

	if [ ! "${export_filename}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: export_filename undefined"
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

	if [ ! "${deb_components}" ] ; then
		case "${distro}" in
		debian)
			deb_components="main contrib non-free"
			;;
		ubuntu)
			deb_components="main universe multiverse"
			;;
		esac
	fi

	if [ ! "${user_name}" ] ; then
		user_name="${distro}"
		echo "user_name: undefined using: [${user_name}]"
	fi

	if [ ! "${password}" ] ; then
		password="temppwd"
		echo "password: undefined using: [${password}]"
	fi

	if [ ! "${full_name}" ] ; then
		full_name="Demo User"
		echo "full_name: undefined using: [${full_name}]"
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
	if [ "$(mount | grep ${tempdir}/dev/pts | awk '{print $3}')" = "${tempdir}/dev/pts" ] ; then
		sudo umount -f ${tempdir}/dev/pts
	fi

	if [ "$(mount | grep ${tempdir}/proc | awk '{print $3}')" = "${tempdir}/proc" ] ; then
		sudo umount -f ${tempdir}/proc
	fi

	if [ "$(mount | grep ${tempdir}/sys | awk '{print $3}')" = "${tempdir}/sys" ] ; then
		sudo umount -f ${tempdir}/sys
	fi
}

check_defines

if [ "x${host_arch}" != "xarmv7l" ] ; then
	sudo cp $(which qemu-arm-static) ${tempdir}/usr/bin/
fi

echo "Log: Running: debootstrap second-stage in [${tempdir}]"
sudo chroot ${tempdir} debootstrap/debootstrap --second-stage
echo "Log: Complete: [sudo chroot ${tempdir} debootstrap/debootstrap --second-stage]"
report_size

file="${tempdir}/etc/apt/sources.list"
case "${release}" in
wheezy)
	echo "deb http://${deb_mirror} ${release} ${deb_components}"| sudo tee ${file} >/dev/null
	echo "deb-src http://${deb_mirror} ${release} ${deb_components}" | sudo tee -a ${file} >/dev/null
	echo "" | sudo tee -a ${file} >/dev/null
	echo "deb http://${deb_mirror} ${release}-updates ${deb_components}" | sudo tee -a ${file} >/dev/null
	echo "deb-src http://${deb_mirror} ${release}-updates ${deb_components}" | sudo tee -a ${file} >/dev/null
	echo "" | sudo tee -a ${file} >/dev/null
	echo "deb http://security.debian.org/ ${release}/updates ${deb_components}" | sudo tee -a ${file} >/dev/null
	echo "deb-src http://security.debian.org/ ${release}/updates ${deb_components}" | sudo tee -a ${file} >/dev/null
	;;
precise|quantal|raring)
	echo "deb http://${deb_mirror} ${release} ${deb_components}"| sudo tee ${file} >/dev/null
	echo "deb-src http://${deb_mirror} ${release} ${deb_components}" | sudo tee -a ${file} >/dev/null
	echo "" | sudo tee -a ${file} >/dev/null
	echo "deb http://${deb_mirror} ${release}-updates ${deb_components}" | sudo tee -a ${file} >/dev/null
	echo "deb-src http://${deb_mirror} ${release}-updates ${deb_components}" | sudo tee -a ${file} >/dev/null
	;;
jessie|sid|saucy)
	echo "deb http://${deb_mirror} ${release} ${deb_components}" | sudo tee ${file} >/dev/null
	echo "deb-src http://${deb_mirror} ${release} ${deb_components}" | sudo tee -a ${file} >/dev/null
	echo "" | sudo tee -a ${file} >/dev/null
	echo "#deb http://${deb_mirror} ${release}-updates ${deb_components}" | sudo tee -a ${file} >/dev/null
	echo "#deb-src http://${deb_mirror} ${release}-updates ${deb_components}" | sudo tee -a ${file} >/dev/null
	;;
esac

if [ "${apt_proxy}" ] ; then
	echo "Acquire::http::Proxy \"http://${apt_proxy}\";" | sudo tee ${tempdir}/etc/apt/apt.conf >/dev/null
fi

echo "127.0.0.1       localhost" | sudo tee ${tempdir}/etc/hosts >/dev/null
echo "127.0.1.1       ${image_hostname}" | sudo tee -a ${tempdir}/etc/hosts >/dev/null

echo "${image_hostname}" | sudo tee ${tempdir}/etc/hostname >/dev/null

case "${distro}" in
debian)
	wfile="boot_scripts.sh"
	cat > /tmp/${wfile} <<-__EOF__
		#!/bin/sh -e
		### BEGIN INIT INFO
		# Provides:          ${wfile}
		# Required-Start:    \$local_fs
		# Required-Stop:     \$local_fs
		# Default-Start:     2 3 4 5
		# Default-Stop:      0 1 6
		# Short-Description: Start daemon at boot time
		# Description:       Enable service provided by daemon.
		### END INIT INFO

		case "\$1" in
		start|reload|force-reload|restart)
		        if [ -f /boot/uboot/SOC.sh ] && [ -f /boot/uboot/run_boot-scripts ] ; then
		                board=\$(cat /boot/uboot/SOC.sh | grep "board" | awk -F"=" '{print \$2}')
		                if [ -f "/opt/boot-scripts/\${board}.sh" ] ; then
		                        /bin/sh /opt/boot-scripts/\${board}.sh >/dev/null 2>&1 &
		                fi
		        fi
		        ;;
		stop)
		        exit 0
		        ;;
		*)
		        echo "Usage: /etc/init.d/boot_scripts.sh {start|stop|reload|restart|force-reload}"
		        exit 1
		        ;;
		esac

		exit 0

	__EOF__

	sudo mv /tmp/${wfile} ${tempdir}/etc/init.d/${wfile}

	;;
ubuntu)
	wfile="boot_scripts.conf"
	cat > /tmp/${wfile} <<-__EOF__
		start on runlevel 2

		script
		if [ -f /boot/uboot/SOC.sh ] && [ -f /boot/uboot/run_boot-scripts ] ; then
		        board=\$(cat /boot/uboot/SOC.sh | grep "board" | awk -F"=" '{print \$2}')
		        if [ -f "/opt/boot-scripts/\${board}.sh" ] ; then
		                /bin/sh /opt/boot-scripts/\${board}.sh >/dev/null 2>&1 &
		        fi
		fi
		end script

	__EOF__

	sudo mv /tmp/${wfile} ${tempdir}/etc/init/${wfile}

	wfile="flash-kernel.conf"
	cat > /tmp/${wfile} <<-__EOF__
		#!/bin/sh -e
		UBOOT_PART=/dev/mmcblk0p1

		echo "flash-kernel stopped by: /etc/${wfile}"
		USE_CUSTOM_KERNEL=1

		if [ "\${USE_CUSTOM_KERNEL}" ] ; then
		        DIST=\$(lsb_release -cs)

		        case "\${DIST}" in
		        natty|oneiric|precise|quantal|raring|saucy)
		                FLASH_KERNEL_SKIP=yes
		                ;;
		        esac
		fi

	__EOF__

	sudo mv /tmp/${wfile} ${tempdir}/etc/${wfile}

	if [ -f ${tempdir}/etc/init/failsafe.conf ] ; then
		#Ubuntu: with no ethernet cable connected it can take up to 2 mins to login, removing upstart sleep calls..."
		sudo sed -i -e 's:sleep 20:#sleep 20:g' ${tempdir}/etc/init/failsafe.conf
		sudo sed -i -e 's:sleep 40:#sleep 40:g' ${tempdir}/etc/init/failsafe.conf
		sudo sed -i -e 's:sleep 59:#sleep 59:g' ${tempdir}/etc/init/failsafe.conf
	fi

	;;
esac

cat > ${DIR}/chroot_script.sh <<-__EOF__
	#!/bin/sh -e
	export LC_ALL=C
	export DEBIAN_FRONTEND=noninteractive

	check_n_install () {
		unset deb_pkgs
		dpkg -l | grep "\${pkg}" >/dev/null || deb_pkgs="\${pkg} "

		if [ "\${deb_pkgs}" ] ; then
			echo "Log: (chroot) Installing: \${deb_pkgs}"
			apt-get -y --force-yes install \${deb_pkgs}
		fi
	}

	install_chroot_pkgs () {
		apt-get update

		packages="lsb-release"
		for pkg in \${packages} ; do check_n_install ; done

		distro="\$(lsb_release -si)"
		echo "distro=\${distro}" > /etc/rcn-ee.conf
	}

	stop_init () {
		cat > /usr/sbin/policy-rc.d <<EOF
		#!/bin/sh
		exit 101
		EOF
		chmod +x /usr/sbin/policy-rc.d

		if [ "x\${distro}" = "xUbuntu" ] ; then
			dpkg-divert --local --rename --add /sbin/initctl
			ln -s /bin/true /sbin/initctl
		fi
	}

	install_pkg_updates () {
		apt-get update
		apt-get upgrade -y --force-yes
	}

	install_pkgs () {
		#These packages have binaries needed by this script.
		packages="initramfs-tools locales git-core sudo u-boot-tools wget"
		for pkg in \${packages} ; do check_n_install ; done

		#Install the user choosen list.
		apt-get -y --force-yes install ${base_pkg_list}
	}

	set_locale () {
		echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
		locale-gen
		echo "LANG=en_US.UTF-8" > /etc/default/locale
	}

	dl_pkg_src () {
		mkdir -p /tmp/pkg_src/
		cd /tmp/pkg_src/
		dpkg -l | tail -n+6 | awk '{print \$2}' | sed "s/:armel//g" | sed "s/:armhf//g" > /tmp/pkg_src/pkg_list
		apt-get source --download-only \`cat /tmp/pkg_src/pkg_list\`
		cd -
	}

	dl_kernel () {
		wget --no-verbose --directory-prefix=/tmp/ \${kernel_url}

		#This should create a list of files on the server
		#<a href="file"></a>
		cat /tmp/index.html | grep "<a href=" > /tmp/temp.html

		#Note: cat drops one \...
		#sed -i -e "s/<a href/\\n<a href/g" /tmp/temp.html
		sed -i -e "s/<a href/\\\n<a href/g" /tmp/temp.html

		sed -i -e 's/\"/\"><\/a>\n/2' /tmp/temp.html
		cat /tmp/temp.html | grep href > /tmp/index.html

		deb_file=\$(cat /tmp/index.html | grep linux-image)
		deb_file=\$(echo \${deb_file} | awk -F ".deb" '{print \$1}')
		deb_file=\${deb_file##*linux-image-}

		kernel_version=\$(echo \${deb_file} | awk -F "_" '{print \$1}')
		echo "Log: Using: \${kernel_version}"

		deb_file="linux-image-\${deb_file}.deb"
		wget --directory-prefix=/tmp/ \${kernel_url}\${deb_file}

		unset dtb_file
		dtb_file=\$(cat /tmp/index.html | grep dtbs.tar.gz | head -n 1)
		dtb_file=\$(echo \${dtb_file} | awk -F "\"" '{print \$2}')

		if [ "\${dtb_file}" ] ; then
				wget --directory-prefix=/boot/ \${kernel_url}\${dtb_file}
		fi

		unset firmware_file
		firmware_file=\$(cat /tmp/index.html | grep firmware.tar.gz | head -n 1)
		firmware_file=\$(echo \${firmware_file} | awk -F "\"" '{print \$2}')

		if [ "\${firmware_file}" ] ; then
			wget --directory-prefix=/tmp/ \${kernel_url}\${firmware_file}

			mkdir -p /tmp/cape-firmware/
			tar xf /tmp/\${firmware_file} -C /tmp/cape-firmware/
			cp -v /tmp/cape-firmware/*.dtbo /lib/firmware/ 2>/dev/null
			rm -rf /tmp/cape-firmware/ || true
			rm -f /tmp/\${firmware_file} || true
		fi

		dpkg -x /tmp/\${deb_file} /

		depmod \${kernel_version}
		update-initramfs -c -k \${kernel_version}
		mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d /boot/initrd.img-\${kernel_version} /boot/uInitrd-\${kernel_version}
		rm -f /tmp/index.html || true
		rm -f /tmp/temp.html || true
		rm -f /tmp/\${deb_file} || true
		rm -f /boot/System.map-\${kernel_version} || true
		rm -f /boot/config-\${kernel_version} || true
		rm -rf /usr/src/linux-headers* || true
	}

	add_user () {
		groupadd admin || true
		echo "%admin  ALL=(ALL) ALL" >>/etc/sudoers
		default_groups="admin,adm,dialout,cdrom,floppy,audio,dip,video"

		pass_crypt=\$(perl -e 'print crypt(\$ARGV[0], "rcn-ee-salt")' ${password})

		useradd -G "\${default_groups}" -s /bin/bash -m -p \${pass_crypt} -c "${full_name}" ${user_name}

		case "\${distro}" in
		Debian)
			usermod -aG sudo ${user_name} || true
			usermod -aG dialout ${user_name} || true

			passwd <<-EOF
			root
			root
			EOF
			;;
		Ubuntu)
			passwd -l root || true
			;;
		esac
	}

	debian_startup_script () {
		if [ -f /etc/init.d/boot_scripts.sh ] ; then
			chown root:root /etc/init.d/boot_scripts.sh
			chmod +x /etc/init.d/boot_scripts.sh
			insserv boot_scripts.sh || true
		fi
	}

	ubuntu_startup_script () {
		if [ -f /etc/init/boot_scripts.conf ] ; then
			chown root:root /etc/init/boot_scripts.conf
		fi
		if [ -f /etc/flash-kernel.conf ] ; then
			chown root:root /etc/flash-kernel.conf
		fi
	}

	startup_script () {
		case "\${distro}" in
		Debian)
			debian_startup_script
			;;
		Ubuntu)
			ubuntu_startup_script
			;;
		esac

		mkdir -p /opt/boot-scripts/
		git clone git://github.com/RobertCNelson/boot-scripts.git /opt/boot-scripts/ || true
		chown -R ${user_name}:${user_name} /opt/boot-scripts/
	}

	cleanup () {
		mkdir -p /boot/uboot/

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

		#left over from init/upstart scripts running in chroot...
		if [ -d /var/run/ ] ; then
			rm -rf /var/run/* || true
		fi
	}

	#cat /chroot_script.sh

	install_chroot_pkgs
	stop_init

	install_pkg_updates
	install_pkgs
	set_locale

	if [ "x${chroot_ENABLE_DEB_SRC}" = "xenable" ] ; then
		dl_pkg_src
	fi

	if [ "${chroot_KERNEL_HTTP_DIR}" ] ; then
		for kernel_url in ${chroot_KERNEL_HTTP_DIR} ; do dl_kernel ; done
	fi

	add_user
	startup_script
	cleanup
	rm -f /chroot_script.sh || true
__EOF__

sudo mv ${DIR}/chroot_script.sh ${tempdir}/chroot_script.sh

if [ ! -d ${tempdir}/lib/firmware/ ] ; then
	sudo mkdir -p ${tempdir}/lib/firmware/ || true
fi

if [ -d ${DIR}/git/linux-firmware/brcm/ ] ; then
	sudo mkdir -p ${tempdir}/lib/firmware/brcm
	sudo cp -v ${DIR}/git/linux-firmware/LICENCE.broadcom_bcm43xx ${tempdir}/lib/firmware/
	sudo cp -v ${DIR}/git/linux-firmware/brcm/* ${tempdir}/lib/firmware/brcm
fi

if [ -f ${DIR}/git/linux-firmware/carl9170-1.fw ] ; then
	sudo cp -v ${DIR}/git/linux-firmware/carl9170-1.fw ${tempdir}/lib/firmware/
fi

if [ -f ${DIR}/git/linux-firmware/htc_9271.fw ] ; then
	sudo cp -v ${DIR}/git/linux-firmware/LICENCE.atheros_firmware ${tempdir}/lib/firmware/
	sudo cp -v ${DIR}/git/linux-firmware/htc_9271.fw ${tempdir}/lib/firmware/
fi

if [ -d ${DIR}/git/linux-firmware/rtlwifi/ ] ; then
	sudo mkdir -p ${tempdir}/lib/firmware/rtlwifi
	sudo cp -v ${DIR}/git/linux-firmware/LICENCE.rtlwifi_firmware.txt ${tempdir}/lib/firmware/
	sudo cp -v ${DIR}/git/linux-firmware/rtlwifi/* ${tempdir}/lib/firmware/rtlwifi
fi

if [ -d ${DIR}/git/linux-firmware/ti-connectivity/ ] ; then
	sudo mkdir -p ${tempdir}/lib/firmware/ti-connectivity
	sudo cp -v ${DIR}/git/linux-firmware/LICENCE.ti-connectivity ${tempdir}/lib/firmware/
	sudo cp -v ${DIR}/git/linux-firmware/ti-connectivity/* ${tempdir}/lib/firmware/ti-connectivity
fi

if [ -f ${DIR}/git/am33x-cm3/bin/am335x-pm-firmware.bin ] ; then
	sudo cp -v ${DIR}/git/am33x-cm3/bin/am335x-pm-firmware.bin ${tempdir}/lib/firmware/am335x-pm-firmware.bin
fi

chroot_mount
sudo chroot ${tempdir} /bin/sh chroot_script.sh
echo "Log: Complete: [sudo chroot ${tempdir} /bin/sh chroot_script.sh]"

mkdir -p ${DIR}/deploy/${export_filename}/ || true

if [ -n "${chroot_hook}" -a -r "${DIR}/${chroot_hook}" ] ; then
	report_size
	echo "Calling chroot_hook script: ${chroot_hook}"
	. "${DIR}/${chroot_hook}"
	chroot_hook=""
fi

if [ -f ${tempdir}/usr/bin/qemu-arm-static ] ; then
	sudo rm -f ${tempdir}/usr/bin/qemu-arm-static || true
fi

if ls ${tempdir}/boot/vmlinuz-* >/dev/null 2>&1 ; then
	sudo mv -v ${tempdir}/boot/vmlinuz-* ${DIR}/deploy/${export_filename}/
fi

if ls ${tempdir}/boot/initrd.img-* >/dev/null 2>&1 ; then
	sudo mv -v ${tempdir}/boot/initrd.img-* ${DIR}/deploy/${export_filename}/
fi

if ls ${tempdir}/boot/uInitrd-* >/dev/null 2>&1 ; then
	sudo mv -v ${tempdir}/boot/uInitrd-* ${DIR}/deploy/${export_filename}/
fi

if ls ${tempdir}/boot/*dtbs.tar.gz >/dev/null 2>&1 ; then
	sudo mv -v ${tempdir}/boot/*dtbs.tar.gz ${DIR}/deploy/${export_filename}/
fi

echo "${user_name}:${password}" | sudo tee ${DIR}/deploy/${export_filename}/user_password.list >/dev/null

report_size
chroot_umount

if [ "x${chroot_COPY_SETUP_SDCARD}" = "xenable" ] ; then
	sudo cp -v ${DIR}/tools/setup_sdcard.sh ${DIR}/deploy/${export_filename}/
	sudo mkdir -p ${DIR}/deploy/${export_filename}/hwpack/
	sudo cp -v ${DIR}/tools/hwpack/*.conf ${DIR}/deploy/${export_filename}/hwpack/
	#FIXME: copy uEnv.txt here... ?? Do we want to cat to a file from a variable, or just copy a file stored in the repo?
fi

if [ "x${chroot_ENABLE_DEB_SRC}" = "xenable" ] ; then
	cd ${tempdir}/tmp/pkg_src/
	sudo LANG=C tar --numeric-owner -cf ${DIR}/deploy/${dpkg_arch}-rootfs-${distro}-${release}-${time}-src.tar .
	cd ${tempdir}
	ls -lh ${DIR}/deploy/${dpkg_arch}-rootfs-${distro}-${release}-${time}-src.tar
	sudo rm -rf ${tempdir}/tmp/pkg_src/ || true
	report_size
fi

cd ${tempdir}
sudo LANG=C tar --numeric-owner -cf ${DIR}/deploy/${export_filename}/${dpkg_arch}-rootfs-${distro}-${release}.tar .
cd ${DIR}/
ls -lh ${DIR}/deploy/${export_filename}/${dpkg_arch}-rootfs-${distro}-${release}.tar

sudo chown -R ${USER}:${USER} ${DIR}/deploy/${export_filename}/
#
