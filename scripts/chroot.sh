#!/bin/sh -e
#
# Copyright (c) 2012-2014 Robert Nelson <robertcnelson@gmail.com>
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

	if [ ! "${deb_distribution}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: deb_distribution undefined"
		exit 1
	fi

	if [ ! "${deb_codename}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: deb_codename undefined"
		exit 1
	fi

	if [ ! "${deb_arch}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: deb_arch undefined"
		exit 1
	fi

	if [ ! "${apt_proxy}" ] ; then
		apt_proxy=""
	fi

	case "${deb_distribution}" in
	debian)
		deb_components=${deb_components:-"main contrib non-free"}
		deb_mirror=${deb_mirror:-"ftp.us.debian.org/debian/"}
		;;
	ubuntu)
		deb_components=${deb_components:-"main universe multiverse"}
		deb_mirror=${deb_mirror:-"ports.ubuntu.com/ubuntu-ports/"}
		;;
	esac

	if [ ! "${rfs_username}" ] ; then
		##Backwards compat pre variables.txt doc
		if [ "${user_name}" ] ; then
			rfs_username="${user_name}"
		else
			rfs_username="${deb_distribution}"
			echo "rfs_username: undefined using: [${rfs_username}]"
		fi
	fi

	if [ ! "${rfs_fullname}" ] ; then
		##Backwards compat pre variables.txt doc
		if [ "${full_name}" ] ; then
			rfs_fullname="${full_name}"
		else
			rfs_fullname="Demo User"
			echo "rfs_fullname: undefined using: [${rfs_fullname}]"
		fi
	fi

	if [ ! "${rfs_password}" ] ; then
		##Backwards compat pre variables.txt doc
		if [ "${password}" ] ; then
			rfs_password="${password}"
		else
			rfs_password="temppwd"
			echo "rfs_password: undefined using: [${rfs_password}]"
		fi
	fi

	if [ ! "${rfs_hostname}" ] ; then
		##Backwards compat pre variables.txt doc
		if [ "${image_hostname}" ] ; then
			rfs_hostname="${image_hostname}"
		else
			rfs_hostname="arm"
			echo "rfs_hostname: undefined using: [${rfs_hostname}]"
		fi
	fi

	if [ "x${deb_additional_pkgs}" = "x" ] ; then
		##Backwards compat pre configs
		if [ ! "x${base_pkg_list}" = "x" ] ; then
			deb_additional_pkgs="$(echo ${base_pkg_list} | sed 's/,/ /g')"
		fi
	else
		deb_additional_pkgs="$(echo ${deb_additional_pkgs} | sed 's/,/ /g')"
	fi

	if [ "x${repo_rcnee}" = "xenable" ] ; then
		if [ ! "x${repo_rcnee_pkg_list}" = "x" ] ; then
			deb_additional_pkgs="${deb_additional_pkgs} ${repo_rcnee_pkg_list}"
		fi
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

if [ "x${chroot_very_small_image}" = "xenable" ] ; then
	#so debootstrap just extracts the *.deb's, so lets clean this up hackish now,
	#but then allow dpkg to delete these extra files when installed later..
	sudo rm -rf ${tempdir}/usr/share/locale/* || true
	sudo rm -rf ${tempdir}/usr/share/man/* || true
	sudo rm -rf ${tempdir}/usr/share/doc/* || true

	#dpkg 1.15.8++, No Docs...
	sudo mkdir -p ${tempdir}/etc/dpkg/dpkg.cfg.d/ || true
	echo "# Delete locales" > /tmp/01_nodoc
	echo "path-exclude=/usr/share/locale/*" >> /tmp/01_nodoc

	if [ "x${rfs_default_locale}" = "xen_US.UTF-8" ] ; then
		echo "path-include=/usr/share/locale/en*" >> /tmp/01_nodoc
	fi
	echo ""  >> /tmp/01_nodoc

	echo "# Delete man pages" >> /tmp/01_nodoc
	echo "path-exclude=/usr/share/man/*" >> /tmp/01_nodoc
	echo "" >> /tmp/01_nodoc

	echo "# Delete docs" >> /tmp/01_nodoc
	echo "path-exclude=/usr/share/doc/*" >> /tmp/01_nodoc
	echo "path-include=/usr/share/doc/*/copyright" >> /tmp/01_nodoc
	echo "" >> /tmp/01_nodoc

	sudo mv /tmp/01_nodoc ${tempdir}/etc/dpkg/dpkg.cfg.d/01_nodoc

	sudo mkdir -p ${tempdir}/etc/apt/apt.conf.d/ || true

	#apt: no local cache
	echo "Dir::Cache {" > /tmp/02nocache
	echo "  srcpkgcache \"\";" >> /tmp/02nocache
	echo "  pkgcache \"\";" >> /tmp/02nocache
	echo "}" >> /tmp/02nocache
	sudo mv  /tmp/02nocache ${tempdir}/etc/apt/apt.conf.d/02nocache

	#apt: drop translations...
	echo "Acquire::Languages \"none\";" > /tmp/02translations
	sudo mv /tmp/02translations ${tempdir}/etc/apt/apt.conf.d/02translations

	echo "Log: after locale/man purge"
	report_size
fi

if [ "x${rfs_locale_purge}" = "xenable" ] ; then
	if [ ! "x${rfs_locale_save_dir}" = "x" ] ; then
		ls -lh ${tempdir}/usr/share/locale/
		sudo mv ${tempdir}/usr/share/locale/${rfs_locale_save_dir}/ ${tempdir}/
		sudo rm -rf ${tempdir}/usr/share/locale/*
		sudo mv ${tempdir}/${rfs_locale_save_dir}/ ${tempdir}/usr/share/locale/
		ls -lh ${tempdir}/usr/share/locale/
	else
		sudo rm -rf ${tempdir}/usr/share/locale/*
	fi

	if [ ! -f ${tempdir}/etc/dpkg/dpkg.cfg.d/01_nodoc ] ; then
		sudo mkdir -p ${tempdir}/etc/dpkg/dpkg.cfg.d/ || true
		#FIXME: en only, ping me for enabling other locales by default
		echo "# Delete locales" > /tmp/01_nodoc
		echo "path-exclude=/usr/share/locale/*" >> /tmp/01_nodoc
		if [ ! "x${rfs_locale_save_dir}" = "x" ] ; then
			echo "path-include=/usr/share/locale/${rfs_locale_save_dir}" >> /tmp/01_nodoc
		fi
		sudo mv /tmp/01_nodoc ${tempdir}/etc/dpkg/dpkg.cfg.d/01_nodoc
	fi
fi

if [ "x${rfs_strip_locales}" = "xenable" ] && [ "x${rfs_default_locale}" = "xen_US.UTF-8" ] ; then
	#dpkg: strip some files
	if [ ! -f ${tempdir}/etc/dpkg/dpkg.cfg.d/01_nodoc ] ; then
		sudo mkdir -p ${tempdir}/etc/dpkg/dpkg.cfg.d/ || true
		#FIXME: en only, ping me for enabling other locales by default
		echo "# Delete locales" > /tmp/01_nodoc
		echo "path-exclude=/usr/share/locale/*" >> /tmp/01_nodoc
		echo "path-include=/usr/share/locale/en*" >> /tmp/01_nodoc
		sudo mv /tmp/01_nodoc ${tempdir}/etc/dpkg/dpkg.cfg.d/01_nodoc
	fi
fi

#generic apt.conf tweaks for flash/mmc devices to save on wasted space...
sudo mkdir -p ${tempdir}/etc/apt/apt.conf.d/ || true

#apt: /var/lib/apt/lists/, store compressed only
echo "Acquire::GzipIndexes \"true\";" > /tmp/02compress-indexes
echo "Acquire::CompressionTypes::Order:: \"gz\";" >> /tmp/02compress-indexes
sudo mv /tmp/02compress-indexes ${tempdir}/etc/apt/apt.conf.d/02compress-indexes

#set initial 'seed' time...
sudo sh -c "date --utc \"+%4Y%2m%2d%2H%2M\" > ${tempdir}/etc/timestamp"

case "${deb_codename}" in
wheezy)
	echo "deb http://${deb_mirror} ${deb_codename} ${deb_components}" > /tmp/sources.list
	echo "#deb-src http://${deb_mirror} ${deb_codename} ${deb_components}" >> /tmp/sources.list
	echo "" >> /tmp/sources.list
	echo "deb http://${deb_mirror} ${deb_codename}-updates ${deb_components}" >> /tmp/sources.list
	echo "#deb-src http://${deb_mirror} ${deb_codename}-updates ${deb_components}" >> /tmp/sources.list
	echo "" >> /tmp/sources.list
	echo "deb http://security.debian.org/ ${deb_codename}/updates ${deb_components}" >> /tmp/sources.list
	echo "#deb-src http://security.debian.org/ ${deb_codename}/updates ${deb_components}" >> /tmp/sources.list
	echo "" >> /tmp/sources.list
	if [ "x${chroot_enable_debian_backports}" = "xenable" ] ; then
		echo "deb http://ftp.debian.org/debian ${deb_codename}-backports ${deb_components}" >> /tmp/sources.list
		echo "#deb-src http://ftp.debian.org/debian ${deb_codename}-backports ${deb_components}" >> /tmp/sources.list
	else
		echo "#deb http://ftp.debian.org/debian ${deb_codename}-backports ${deb_components}" >> /tmp/sources.list
		echo "##deb-src http://ftp.debian.org/debian ${deb_codename}-backports ${deb_components}" >> /tmp/sources.list
	fi
	if [ "x${repo_rcnee}" = "xenable" ] ; then
		echo "" >> /tmp/sources.list
		echo "#Kernel source: https://github.com/RobertCNelson" >> /tmp/sources.list
		echo "deb [arch=armhf] http://repos.rcn-ee.net/debian/ ${deb_codename} main" >> /tmp/sources.list
	fi
	if [ "x${repo_external}" = "xenable" ] ; then
		echo "" >> /tmp/sources.list
		echo "deb [arch=${repo_external_arch}] ${repo_external_server} ${repo_external_dist} ${repo_external_components}" >> /tmp/sources.list
		echo "#deb-src [arch=${repo_external_arch}] ${repo_external_server} ${repo_external_dist} ${repo_external_components}" >> /tmp/sources.list
	fi
	;;
precise|quantal|raring|saucy)
	echo "deb http://${deb_mirror} ${deb_codename} ${deb_components}" > /tmp/sources.list
	echo "#deb-src http://${deb_mirror} ${deb_codename} ${deb_components}" >> /tmp/sources.list
	echo "" >> /tmp/sources.list
	echo "deb http://${deb_mirror} ${deb_codename}-updates ${deb_components}" >> /tmp/sources.list
	echo "#deb-src http://${deb_mirror} ${deb_codename}-updates ${deb_components}" >> /tmp/sources.list
	;;
trusty|utopic)
	echo "deb http://${deb_mirror} ${deb_codename} ${deb_components}" > /tmp/sources.list
	echo "#deb-src http://${deb_mirror} ${deb_codename} ${deb_components}" >> /tmp/sources.list
	echo "" >> /tmp/sources.list
	echo "deb http://${deb_mirror} ${deb_codename}-updates ${deb_components}" >> /tmp/sources.list
	echo "#deb-src http://${deb_mirror} ${deb_codename}-updates ${deb_components}" >> /tmp/sources.list
	if [ "x${repo_rcnee}" = "xenable" ] ; then
		echo "" >> /tmp/sources.list
		echo "#Kernel source: https://github.com/RobertCNelson" >> /tmp/sources.list
		echo "deb [arch=armhf] http://repos.rcn-ee.net/ubuntu/ ${deb_codename} main" >> /tmp/sources.list
	fi
	;;
jessie|sid)
	echo "deb http://${deb_mirror} ${deb_codename} ${deb_components}" > /tmp/sources.list
	echo "#deb-src http://${deb_mirror} ${deb_codename} ${deb_components}" >> /tmp/sources.list
	echo "" >> /tmp/sources.list
	echo "#deb http://${deb_mirror} ${deb_codename}-updates ${deb_components}" >> /tmp/sources.list
	echo "##deb-src http://${deb_mirror} ${deb_codename}-updates ${deb_components}" >> /tmp/sources.list
	if [ "x${repo_rcnee}" = "xenable" ] ; then
		echo "" >> /tmp/sources.list
		echo "#Kernel source: https://github.com/RobertCNelson" >> /tmp/sources.list
		echo "deb [arch=armhf] http://repos.rcn-ee.net/debian/ ${deb_codename} main" >> /tmp/sources.list
	fi
	;;
esac

if [ "x${repo_rcnee}" = "xenable" ] ; then
	sudo cp -v ${DIR}/target/keyring/repos.rcn-ee.net-archive-keyring.asc ${tempdir}/tmp/repos.rcn-ee.net-archive-keyring.asc
fi

if [ "x${repo_external}" = "xenable" ] ; then
	if [ ! "x${repo_external_key}" = "x" ] ; then
		sudo cp -v ${DIR}/target/keyring/${repo_external_key} ${tempdir}/tmp/${repo_external_key}
	fi
fi

if [ -f /tmp/sources.list ] ; then
	sudo mv /tmp/sources.list ${tempdir}/etc/apt/sources.list
fi

if [ "${apt_proxy}" ] ; then
	echo "Acquire::http::Proxy \"http://${apt_proxy}\";" > /tmp/apt.conf
	sudo mv /tmp/apt.conf ${tempdir}/etc/apt/apt.conf
fi

echo "127.0.0.1       localhost" > /tmp/hosts
echo "127.0.1.1       ${rfs_hostname}" >> /tmp/hosts
sudo mv /tmp/hosts ${tempdir}/etc/hosts

echo "${rfs_hostname}" > /tmp/hostname
sudo mv /tmp/hostname ${tempdir}/etc/hostname

case "${deb_distribution}" in
debian)
	sudo cp ${DIR}/target/init_scripts/generic-debian.sh ${tempdir}/etc/init.d/generic-boot-script.sh
	sudo cp ${DIR}/target/init_scripts/capemgr-debian.sh ${tempdir}/etc/init.d/capemgr.sh
	sudo cp ${DIR}/target/init_scripts/capemgr ${tempdir}/etc/default/

	#Backward compatibility, as setup_sdcard.sh expects [lsb_release -si > /etc/rcn-ee.conf]
	echo "distro=Debian" > /tmp/rcn-ee.conf
	echo "deb_distribution=Debian" >> /tmp/rcn-ee.conf
	echo "rfs_username=${rfs_username}" >> /tmp/rcn-ee.conf
	echo "release_date=${time}" >> /tmp/rcn-ee.conf
	echo "third_party_modules=${third_party_modules}" >> /tmp/rcn-ee.conf
	sudo mv /tmp/rcn-ee.conf ${tempdir}/etc/rcn-ee.conf

	;;
ubuntu)
	sudo cp ${DIR}/target/init_scripts/generic-ubuntu.conf ${tempdir}/etc/init/generic-boot-script.conf
	sudo cp ${DIR}/target/init_scripts/capemgr-ubuntu.sh ${tempdir}/etc/init/capemgr.sh
	sudo cp ${DIR}/target/init_scripts/capemgr ${tempdir}/etc/default/

	wfile="flash-kernel.conf"
	cat > /tmp/${wfile} <<-__EOF__
		#!/bin/sh -e
		UBOOT_PART=/dev/mmcblk0p1

		echo "flash-kernel stopped by: /etc/${wfile}"
		USE_CUSTOM_KERNEL=1

		if [ "\${USE_CUSTOM_KERNEL}" ] ; then
		        FLASH_KERNEL_SKIP=yes
		fi

	__EOF__

	sudo mv /tmp/${wfile} ${tempdir}/etc/${wfile}

	if [ -f ${tempdir}/etc/init/failsafe.conf ] ; then
		#Ubuntu: with no ethernet cable connected it can take up to 2 mins to login, removing upstart sleep calls..."
		sudo sed -i -e 's:sleep 20:#sleep 20:g' ${tempdir}/etc/init/failsafe.conf
		sudo sed -i -e 's:sleep 40:#sleep 40:g' ${tempdir}/etc/init/failsafe.conf
		sudo sed -i -e 's:sleep 59:#sleep 59:g' ${tempdir}/etc/init/failsafe.conf
	fi

	#Backward compatibility, as setup_sdcard.sh expects [lsb_release -si > /etc/rcn-ee.conf]
	echo "distro=Ubuntu" > /tmp/rcn-ee.conf
	echo "deb_distribution=Ubuntu" >> /tmp/rcn-ee.conf
	echo "rfs_username=${rfs_username}" >> /tmp/rcn-ee.conf
	echo "release_date=${time}" >> /tmp/rcn-ee.conf
	echo "third_party_modules=${third_party_modules}" >> /tmp/rcn-ee.conf
	sudo mv /tmp/rcn-ee.conf ${tempdir}/etc/rcn-ee.conf

	;;
esac

cat > ${DIR}/chroot_script.sh <<-__EOF__
	#!/bin/sh -e
	export LC_ALL=C
	export DEBIAN_FRONTEND=noninteractive

	dpkg_check () {
		unset pkg_is_not_installed
		LC_ALL=C dpkg --list | awk '{print \$2}' | grep "^\${pkg}$" >/dev/null || pkg_is_not_installed="true"
	}

	dpkg_package_missing () {
		echo "Log: (chroot) package [\${pkg}] was not installed... (add to deb_include if functionality is really needed)"
	}

	is_this_qemu () {
		unset warn_qemu_will_fail
		if [ -f /usr/bin/qemu-arm-static ] ; then
			warn_qemu_will_fail=1
		fi
	}

	qemu_warning () {
		if [ "\${warn_qemu_will_fail}" ] ; then
			echo "Log: (chroot) Warning, qemu can fail here... (run on real armv7l hardware for production images)"
			echo "Log: (chroot): [\${qemu_command}]"
		fi
	}

	stop_init () {
		cat > /usr/sbin/policy-rc.d <<EOF
		#!/bin/sh
		exit 101
		EOF
		chmod +x /usr/sbin/policy-rc.d

		#set deb_distribution:
		. /etc/rcn-ee.conf

		if [ "x\${deb_distribution}" = "xUbuntu" ] ; then
			dpkg-divert --local --rename --add /sbin/initctl
			ln -s /bin/true /sbin/initctl
		fi
	}

	install_pkg_updates () {
		if [ "x${repo_rcnee}" = "xenable" ] ; then
			apt-key add /tmp/repos.rcn-ee.net-archive-keyring.asc
			rm -f /tmp/repos.rcn-ee.net-archive-keyring.asc || true
		fi
		if [ "x${repo_external}" = "xenable" ] ; then
			apt-key add /tmp/${repo_external_key}
			rm -f /tmp/${repo_external_key} || true
		fi

		apt-get update
		apt-get upgrade -y --force-yes
	}

	install_pkgs () {
		if [ ! "x${deb_additional_pkgs}" = "x" ] ; then
			#Install the user choosen list.
			echo "Log: (chroot) Installing: ${deb_additional_pkgs}"
			apt-get -y --force-yes install ${deb_additional_pkgs}
		fi

		if [ "x${chroot_enable_debian_backports}" = "xenable" ] ; then
			if [ ! "x${chroot_debian_backports_pkg_list}" = "x" ] ; then
				echo "Log: (chroot) Installing (from backports): ${chroot_debian_backports_pkg_list}"
				sudo apt-get -y --force-yes install ${chroot_debian_backports_pkg_list}
			fi
		fi

		if [ ! "x${repo_external_pkg_list}" = "x" ] ; then
			echo "Log: (chroot) Installing (from external repo): ${repo_external_pkg_list}"
			apt-get -y --force-yes install ${repo_external_pkg_list}
		fi
	}

	system_tweaks () {
		echo "[options]" > /etc/e2fsck.conf
		echo "broken_system_clock = true" >> /etc/e2fsck.conf

		if [ -f /etc/systemd/systemd-journald.conf ] ; then
			sed -i -e 's:#SystemMaxUse=:SystemMaxUse=8M:g' /etc/systemd/systemd-journald.conf
		fi
	}

	set_locale () {
		pkg="locales"
		dpkg_check

		if [ "x\${pkg_is_not_installed}" = "x" ] ; then

			if [ ! "x${rfs_default_locale}" = "x" ] ; then

				case "\${deb_distribution}" in
				Debian)
					echo "Log: (chroot) Debian: setting up locales: [${rfs_default_locale}]"
					sed -i -e 's:# ${rfs_default_locale} UTF-8:${rfs_default_locale} UTF-8:g' /etc/locale.gen
					locale-gen
					;;
				Ubuntu)
					echo "Log: (chroot) Ubuntu: setting up locales: [${rfs_default_locale}]"
					locale-gen ${rfs_default_locale}
					;;
				esac

				echo "LANG=${rfs_default_locale}" > /etc/default/locale

			fi
		else
			dpkg_package_missing
		fi
	}

	run_deborphan () {
		apt-get -y --force-yes install deborphan

		deborphan | xargs apt-get -y remove --purge

		#FIXME, only tested on wheezy...
		apt-get -y remove deborphan dialog gettext-base libasprintf0c2 --purge
		apt-get clean
	}

	dl_pkg_src () {
		sed -i -e 's:#deb-src:deb-src:g' /etc/apt/sources.list
		apt-get update
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

		dpkg -x /tmp/\${deb_file} /

		if [ "x\${third_party_modules}" = "xenable" ] ; then
			unset thirdparty_file
			thirdparty_file=\$(cat /tmp/index.html | grep thirdparty)
			thirdparty_file=\$(echo \${thirdparty_file} | awk -F "\"" '{print \$2}')
			if [ "\${thirdparty_file}" ] ; then
				wget --directory-prefix=/tmp/ \${kernel_url}\${thirdparty_file}

				if [ -f /tmp/thirdparty ] ; then
					/bin/sh /tmp/thirdparty
				fi
			fi
		fi

		pkg="initramfs-tools"
		dpkg_check

		if [ "x\${pkg_is_not_installed}" = "x" ] ; then
			depmod \${kernel_version} -a
			update-initramfs -c -k \${kernel_version}
		else
			dpkg_package_missing
		fi

		unset source_file
		source_file=\$(cat /tmp/index.html | grep .diff.gz | head -n 1)
		source_file=\$(echo \${source_file} | awk -F "\"" '{print \$2}')

		if [ "\${source_file}" ] ; then
			wget --directory-prefix=/opt/source/ \${kernel_url}\${source_file}
		fi

		rm -f /tmp/index.html || true
		rm -f /tmp/temp.html || true
		rm -f /tmp/\${deb_file} || true
		rm -f /boot/System.map-\${kernel_version} || true
		mv /boot/config-\${kernel_version} /opt/source || true
		rm -rf /usr/src/linux-headers* || true
	}

	add_user () {
		groupadd -r admin || true
		groupadd -r spi || true

		cat /etc/group | grep ^i2c || groupadd -r i2c || true
		cat /etc/group | grep ^netdev || groupadd -r netdev || true
		cat /etc/group | grep ^systemd-journal || groupadd -r systemd-journal || true
		cat /etc/group | grep ^weston-launch || groupadd -r weston-launch || true

		echo "KERNEL==\"spidev*\", GROUP=\"spi\", MODE=\"0660\"" > /etc/udev/rules.d/50-spi.rules

		default_groups="admin,adm,dialout,i2c,spi,cdrom,floppy,audio,dip,video,netdev,plugdev,users,systemd-journal,weston-launch"

		pkg="sudo"
		dpkg_check

		if [ "x\${pkg_is_not_installed}" = "x" ] ; then
			echo "Log: (chroot) adding admin group to /etc/sudoers"
			echo "%admin  ALL=(ALL) ALL" >>/etc/sudoers
		else
			dpkg_package_missing
			if [ "x${rfs_disable_root}" = "xenable" ] ; then
				echo "Log: (Chroot) WARNING: sudo not installed and no root user"
			fi
		fi

		pass_crypt=\$(perl -e 'print crypt(\$ARGV[0], "rcn-ee-salt")' ${rfs_password})

		useradd -G "\${default_groups}" -s /bin/bash -m -p \${pass_crypt} -c "${rfs_fullname}" ${rfs_username}
		grep ${rfs_username} /etc/passwd

		mkdir -p /home/${rfs_username}/bin
		chown ${rfs_username}:${rfs_username} /home/${rfs_username}/bin

		echo "default username:password is [${rfs_username}:${rfs_password}]" >> /etc/issue
		echo "" >> /etc/issue

		case "\${deb_distribution}" in
		Debian)

			if [ "x${rfs_disable_root}" = "xenable" ] ; then
				passwd -l root || true
			else
				passwd <<-EOF
				root
				root
				EOF
			fi

			sed -i -e 's:#EXTRA_GROUPS:EXTRA_GROUPS:g' /etc/adduser.conf
			sed -i -e 's:dialout:dialout i2c spi:g' /etc/adduser.conf
			sed -i -e 's:#ADD_EXTRA_GROUPS:ADD_EXTRA_GROUPS:g' /etc/adduser.conf

			;;
		Ubuntu)
			passwd -l root || true
			;;
		esac
	}

	debian_startup_script () {
		if [ "x${rfs_startup_scripts}" = "xenable" ] ; then
			if [ -f /etc/init.d/generic-boot-script.sh ] ; then
				chown root:root /etc/init.d/generic-boot-script.sh
				chmod +x /etc/init.d/generic-boot-script.sh
				insserv generic-boot-script.sh || true
			fi

			if [ -f /etc/init.d/capemgr.sh ] ; then
				chown root:root /etc/init.d/capemgr.sh
				chown root:root /etc/default/capemgr
				chmod +x /etc/init.d/capemgr.sh
				insserv capemgr.sh || true
			fi
		fi
	}

	ubuntu_startup_script () {
		if [ "x${rfs_startup_scripts}" = "xenable" ] ; then
			if [ -f /etc/init/generic-boot-script.conf ] ; then
				chown root:root /etc/init/generic-boot-script.conf
			fi
		fi

		#Not Optional...
		#(protects your kernel, from Ubuntu repo which may try to take over your system on an upgrade)...
		if [ -f /etc/flash-kernel.conf ] ; then
			chown root:root /etc/flash-kernel.conf
		fi
	}

	startup_script () {
		case "\${deb_distribution}" in
		Debian)
			debian_startup_script
			;;
		Ubuntu)
			ubuntu_startup_script
			;;
		esac

		if [ ! "x${rfs_opt_scripts}" = "x" ] ; then

			if [ -f /usr/bin/git ] ; then
				mkdir -p /opt/scripts/ || true
				qemu_command="git clone ${rfs_opt_scripts} /opt/scripts/ --depth 1 || true"
				qemu_warning
				git clone ${rfs_opt_scripts} /opt/scripts/ --depth 1 || true
				sync
				if [ -f /opt/scripts/.git/config ] ; then
					echo "/opt/scripts/ : ${rfs_opt_scripts}" >> /opt/source/list.txt
					chown -R ${rfs_username}:${rfs_username} /opt/scripts/
				fi
			fi

		fi
	}

	cleanup () {
		mkdir -p /boot/uboot/

		if [ -f /etc/apt/apt.conf ] ; then
			rm -rf /etc/apt/apt.conf || true
		fi
		if [ "x${chroot_very_small_image}" = "xenable" ] ; then
			#if your flash is already small, the apt cache might overfill it so drop src...
			sed -i -e 's:deb-src:#deb-src:g' /etc/apt/sources.list
			apt-get update
		fi
		apt-get clean

		rm -f /usr/sbin/policy-rc.d

		if [ "x\${deb_distribution}" = "xUbuntu" ] ; then
			rm -f /sbin/initctl || true
			dpkg-divert --local --rename --remove /sbin/initctl
		fi

		#left over from init/upstart scripts running in chroot...
		if [ -d /var/run/ ] ; then
			rm -rf /var/run/* || true
		fi
	}

	#cat /chroot_script.sh
	is_this_qemu
	stop_init

	install_pkg_updates
	install_pkgs
	system_tweaks
	set_locale
	if [ "x${chroot_very_small_image}" = "xenable" ] ; then
		run_deborphan
	fi
	add_user

	mkdir -p /opt/source || true
	touch /opt/source/list.txt

	startup_script

	if [ "x${chroot_ENABLE_DEB_SRC}" = "xenable" ] ; then
		dl_pkg_src
	fi

	pkg="wget"
	dpkg_check

	if [ "x\${pkg_is_not_installed}" = "x" ] ; then
		if [ "${rfs_kernel}" ] ; then
			for kernel_url in ${rfs_kernel} ; do dl_kernel ; done
		fi
	else
		dpkg_package_missing
	fi

	cleanup
	rm -f /chroot_script.sh || true
__EOF__

sudo mv ${DIR}/chroot_script.sh ${tempdir}/chroot_script.sh

if [ "x${include_firmware}" = "xenable" ] ; then
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
fi

chroot_mount
sudo chroot ${tempdir} /bin/sh chroot_script.sh
echo "Log: Complete: [sudo chroot ${tempdir} /bin/sh chroot_script.sh]"

if [ ! "x${rfs_opt_scripts}" = "x" ] ; then
	if [ ! -f ${tempdir}/opt/scripts/.git/config ] ; then
		echo "Log: ERROR: git clone of ${rfs_opt_scripts} failed.."
		exit 1
	fi
fi

if [ -n "${chroot_script}" -a -r "${DIR}/target/chroot/${chroot_script}" ] ; then
	report_size
	echo "Calling chroot_script script: ${chroot_script}"
	sudo cp -v ${DIR}/.project ${tempdir}/.project
	sudo cp -v ${DIR}/target/chroot/${chroot_script} ${tempdir}/final.sh
	sudo chroot ${tempdir} /bin/sh final.sh
	sudo rm -f ${tempdir}/final.sh || true
	sudo rm -f ${tempdir}/.project || true
	chroot_script=""
	if [ -f ${tempdir}/npm-debug.log ] ; then
		echo "Log: ERROR: npm error in script, review log [cat ${tempdir}/npm-debug.log]..."
		exit 1
	fi
fi

##Building final tar file...

if [ -d ${DIR}/deploy/${export_filename}/ ] ; then
	rm -rf ${DIR}/deploy/${export_filename}/ || true
fi
mkdir -p ${DIR}/deploy/${export_filename}/ || true
cp -v ${DIR}/.project ${DIR}/deploy/${export_filename}/image-builder.project

if [ -n "${chroot_hook}" -a -r "${DIR}/${chroot_hook}" ] ; then
	report_size
	echo "Calling chroot_hook script: ${chroot_hook}"
	. "${DIR}/${chroot_hook}"
	chroot_hook=""
fi

if [ -f ${tempdir}/usr/bin/qemu-arm-static ] ; then
	sudo rm -f ${tempdir}/usr/bin/qemu-arm-static || true
fi

if [ "${rfs_kernel}" ] ; then
	if ls ${tempdir}/boot/vmlinuz-* >/dev/null 2>&1 ; then
		sudo cp -v ${tempdir}/boot/vmlinuz-* ${DIR}/deploy/${export_filename}/
	else
		if [ "${rfs_kernel}" ] ; then
			echo "Log: ERROR: kernel install failure..."
			exit 1
		fi
	fi

	if ls ${tempdir}/boot/initrd.img-* >/dev/null 2>&1 ; then
		sudo cp -v ${tempdir}/boot/initrd.img-* ${DIR}/deploy/${export_filename}/
	fi

	if ls ${tempdir}/boot/*dtbs.tar.gz >/dev/null 2>&1 ; then
		sudo cp -v ${tempdir}/boot/*dtbs.tar.gz ${DIR}/deploy/${export_filename}/
	fi
fi

echo "${rfs_username}:${rfs_password}" > /tmp/user_password.list
sudo mv /tmp/user_password.list ${DIR}/deploy/${export_filename}/user_password.list

#Fixes:
if [ -d ${tempdir}/etc/ssh/ ] ; then
	#Remove pre-generated ssh keys, these will be regenerated on first bootup...
	sudo rm -rf ${tempdir}/etc/ssh/ssh_host_* || true
	sudo touch ${tempdir}/etc/ssh/ssh.regenerate || true
fi

#extra home, from chroot machine when running npm install xyz:
unset extra_home
extra_home=$(ls -lh ${tempdir}/home/ | grep -v ${rfs_username} | awk '{print $9}' | tail -1 || true)
if [ ! "x${extra_home}" = "x" ] ; then
	if [ -d ${tempdir}/home/${extra_home}/ ] ; then
		sudo rm -rf ${tempdir}/home/${extra_home}/ || true
	fi
fi

#ID.txt:
if [ -f ${tempdir}/etc/dogtag ] ; then
	sudo cp ${tempdir}/etc/dogtag ${DIR}/deploy/${export_filename}/ID.txt
fi

report_size
chroot_umount

if [ "x${chroot_COPY_SETUP_SDCARD}" = "xenable" ] ; then
	echo "Log: copying setup_sdcard.sh related files"
	sudo cp ${DIR}/tools/setup_sdcard.sh ${DIR}/deploy/${export_filename}/
	sudo mkdir -p ${DIR}/deploy/${export_filename}/hwpack/
	sudo cp ${DIR}/tools/hwpack/*.conf ${DIR}/deploy/${export_filename}/hwpack/

	if [ "x${rfs_kernel}" = "x" ] ; then
		#Not supported yet with microSD 2.0
		sudo rm -f ${DIR}/deploy/${export_filename}/hwpack/wandboard-*.conf
		sudo rm -f ${DIR}/deploy/${export_filename}/hwpack/imx*.conf
	fi

	if [ -n "${chroot_uenv_txt}" -a -r "${DIR}/target/boot/${chroot_uenv_txt}" ] ; then
		sudo cp "${DIR}/target/boot/${chroot_uenv_txt}" ${DIR}/deploy/${export_filename}/uEnv.txt
	fi

	if [ -n "${chroot_flasher_uenv_txt}" -a -r "${DIR}/target/boot/${chroot_flasher_uenv_txt}" ] ; then
		sudo cp "${DIR}/target/boot/${chroot_flasher_uenv_txt}" ${DIR}/deploy/${export_filename}/eMMC-flasher.txt
	fi
fi

if [ "x${chroot_ENABLE_DEB_SRC}" = "xenable" ] ; then
	echo "Log: packaging src files: [${deb_arch}-rootfs-${deb_distribution}-${deb_codename}-${time}-src.tar]"
	cd ${tempdir}/tmp/pkg_src/
	sudo LANG=C tar --numeric-owner -cf ${DIR}/deploy/${deb_arch}-rootfs-${deb_distribution}-${deb_codename}-${time}-src.tar .
	cd ${tempdir}
	ls -lh ${DIR}/deploy/${deb_arch}-rootfs-${deb_distribution}-${deb_codename}-${time}-src.tar
	sudo rm -rf ${tempdir}/tmp/pkg_src/ || true
	report_size
fi

cd ${tempdir}
echo "Log: packaging rootfs: [${deb_arch}-rootfs-${deb_distribution}-${deb_codename}.tar]"
sudo LANG=C tar --numeric-owner -cf ${DIR}/deploy/${export_filename}/${deb_arch}-rootfs-${deb_distribution}-${deb_codename}.tar .
cd ${DIR}/
ls -lh ${DIR}/deploy/${export_filename}/${deb_arch}-rootfs-${deb_distribution}-${deb_codename}.tar

sudo chown -R ${USER}:${USER} ${DIR}/deploy/${export_filename}/

if [ "x${chroot_tarball}" = "xenable" ] ; then
	echo "Compressing ${export_filename}"
	cd ${DIR}/deploy/
	tar cvf ${export_filename}.tar ./${export_filename}
	cd ${DIR}/
fi
#
