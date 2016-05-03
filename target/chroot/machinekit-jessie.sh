#!/bin/sh -e
#
# Copyright (c) 2014-2016 Robert Nelson <robertcnelson@gmail.com>
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

export LC_ALL=C

u_boot_release="v2016.03"
u_boot_release_x15="v2015.07"
#bone101_git_sha="50e01966e438ddc43b9177ad4e119e5274a0130d"

#contains: rfs_username, release_date
if [ -f /etc/rcn-ee.conf ] ; then
	. /etc/rcn-ee.conf
fi

if [ -f /etc/oib.project ] ; then
	. /etc/oib.project
fi

export HOME=/home/${rfs_username}
export USER=${rfs_username}
export USERNAME=${rfs_username}

echo "env: [`env`]"

is_this_qemu () {
	unset warn_qemu_will_fail
	if [ -f /usr/bin/qemu-arm-static ] ; then
		warn_qemu_will_fail=1
	fi
}

qemu_warning () {
	if [ "${warn_qemu_will_fail}" ] ; then
		echo "Log: (chroot) Warning, qemu can fail here... (run on real armv7l hardware for production images)"
		echo "Log: (chroot): [${qemu_command}]"
	fi
}

git_clone () {
	mkdir -p ${git_target_dir} || true
	qemu_command="git clone ${git_repo} ${git_target_dir} --depth 1 || true"
	qemu_warning
	git clone ${git_repo} ${git_target_dir} --depth 1 || true
	sync
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

git_clone_branch () {
	mkdir -p ${git_target_dir} || true
	qemu_command="git clone -b ${git_branch} ${git_repo} ${git_target_dir} --depth 1 || true"
	qemu_warning
	git clone -b ${git_branch} ${git_repo} ${git_target_dir} --depth 1 || true
	sync
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

git_clone_full () {
	mkdir -p ${git_target_dir} || true
	qemu_command="git clone ${git_repo} ${git_target_dir} || true"
	qemu_warning
	git clone ${git_repo} ${git_target_dir} || true
	sync
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

setup_system () {
	#For when sed/grep/etc just gets way to complex...
	cd /
	if [ -f /opt/scripts/mods/debian-add-sbin-usr-sbin-to-default-path.diff ] ; then
		if [ -f /usr/bin/patch ] ; then
			echo "Patching: /etc/profile"
			patch -p1 < /opt/scripts/mods/debian-add-sbin-usr-sbin-to-default-path.diff
		fi
	fi

	echo "" >> /etc/securetty
	echo "#USB Gadget Serial Port" >> /etc/securetty
	echo "ttyGS0" >> /etc/securetty

#	this is now done in the choot, need to double check the mode..
#	# Enable all users to read hidraw devices
#	cat <<- EOF > /etc/udev/rules.d/99-hdiraw.rules
#		SUBSYSTEM=="hidraw", MODE="0644"
#	EOF

	# Enable PAM for ssh links
	# Fixes an issue where users cannot change ulimits when logged in via
	# ssh, which causes some Machinekit functions to fail
	sed -i 's/^UsePAM.*$/UsePam yes/' /etc/ssh/sshd_config

}

setup_desktop () {
	if [ -d /etc/X11/ ] ; then
		wfile="/etc/X11/xorg.conf"
		echo "Patching: ${wfile}"
		echo "Section \"Monitor\"" > ${wfile}
		echo "        Identifier      \"Builtin Default Monitor\"" >> ${wfile}
		echo "EndSection" >> ${wfile}
		echo "" >> ${wfile}
		echo "Section \"Device\"" >> ${wfile}
		echo "        Identifier      \"Builtin Default fbdev Device 0\"" >> ${wfile}

#		echo "        Driver          \"modesetting\"" >> ${wfile}
		echo "        Driver          \"fbdev\"" >> ${wfile}

		echo "#HWcursor_false        Option          \"HWcursor\"          \"false\"" >> ${wfile}

		echo "EndSection" >> ${wfile}
		echo "" >> ${wfile}
		echo "Section \"Screen\"" >> ${wfile}
		echo "        Identifier      \"Builtin Default fbdev Screen 0\"" >> ${wfile}
		echo "        Device          \"Builtin Default fbdev Device 0\"" >> ${wfile}
		echo "        Monitor         \"Builtin Default Monitor\"" >> ${wfile}
		echo "        DefaultDepth    16" >> ${wfile}
		echo "EndSection" >> ${wfile}
		echo "" >> ${wfile}
		echo "Section \"ServerLayout\"" >> ${wfile}
		echo "        Identifier      \"Builtin Default Layout\"" >> ${wfile}
		echo "        Screen          \"Builtin Default fbdev Screen 0\"" >> ${wfile}
		echo "EndSection" >> ${wfile}
	fi

	wfile="/etc/lightdm/lightdm.conf"
	if [ -f ${wfile} ] ; then
		echo "Patching: ${wfile}"
		sed -i -e 's:#autologin-user=:autologin-user='$rfs_username':g' ${wfile}
		sed -i -e 's:#autologin-session=UNIMPLEMENTED:autologin-session='$rfs_default_desktop':g' ${wfile}
		if [ -f /opt/scripts/3rdparty/xinput_calibrator_pointercal.sh ] ; then
			sed -i -e 's:#display-setup-script=:display-setup-script=/opt/scripts/3rdparty/xinput_calibrator_pointercal.sh:g' ${wfile}
		fi
	fi

	if [ ! "x${rfs_desktop_background}" = "x" ] ; then
		ext="${rfs_desktop_background##*.}"
		cp -v "${rfs_desktop_background}" /opt/desktop-background.${ext}

		mkdir -p /home/${rfs_username}/.config/pcmanfm/LXDE/ || true
		wfile="/home/${rfs_username}/.config/pcmanfm/LXDE/pcmanfm.conf"
		echo "[desktop]" > ${wfile}
		echo "wallpaper_mode=1" >> ${wfile}
		echo "wallpaper=/opt/desktop-background.${ext}" >> ${wfile}
		chown -R ${rfs_username}:${rfs_username} /home/${rfs_username}/.config/
	fi

	#Disable dpms mode and screen blanking
	#Better fix for missing cursor
	wfile="/home/${rfs_username}/.xsessionrc"
	echo "#!/bin/sh" > ${wfile}
	echo "" >> ${wfile}
	echo "xset -dpms" >> ${wfile}
	echo "xset s off" >> ${wfile}
	echo "xsetroot -cursor_name left_ptr" >> ${wfile}
	chown -R ${rfs_username}:${rfs_username} ${wfile}

	#Disable LXDE's screensaver on autostart
	if [ -f /etc/xdg/lxsession/LXDE/autostart ] ; then
		sed -i '/xscreensaver/s/^/#/' /etc/xdg/lxsession/LXDE/autostart
	fi

	#echo "CAPE=cape-bone-proto" >> /etc/default/capemgr

	#lxterminal doesnt reference .profile by default, so call via loginshell and start bash
	if [ -f /usr/bin/lxterminal ] ; then
		if [ -f /usr/share/applications/lxterminal.desktop ] ; then
			sed -i -e 's:Exec=lxterminal:Exec=lxterminal -l -e bash:g' /usr/share/applications/lxterminal.desktop
			sed -i -e 's:TryExec=lxterminal -l -e bash:TryExec=lxterminal:g' /usr/share/applications/lxterminal.desktop
		fi
	fi
}

install_pip_pkgs () {
	if [ -f /usr/bin/python ] ; then
		wget https://bootstrap.pypa.io/get-pip.py || true
		if [ -f get-pip.py ] ; then
			python get-pip.py
			rm -f get-pip.py || true

			if [ -f /usr/local/bin/pip ] ; then
				echo "Installing pip packages"
				#Fixed in git, however not pushed to pip yet...(use git and install)
				#libpython2.7-dev
				#pip install Adafruit_BBIO

				git_repo="https://github.com/adafruit/adafruit-beaglebone-io-python.git"
				git_target_dir="/opt/source/adafruit-beaglebone-io-python"
				git_clone
				if [ -f ${git_target_dir}/.git/config ] ; then
					cd ${git_target_dir}/
					python setup.py install
				fi
				pip install --upgrade PyBBIO
				pip install iw_parse
			fi
		fi
	fi
}

early_git_repos () {
	git_repo="https://github.com/cdsteinkuehler/machinekit-beaglebone-extras"
	git_target_dir="opt/source/machinekit-extras"
	git_clone
}

install_git_repos () {
	if [ -f /usr/bin/jekyll ] ; then
		if [ -d /etc/apache2/ ] ; then
			#bone101 takes over port 80, so shove apache/etc to 8080:
			if [ -f /etc/apache2/ports.conf ] ; then
				sed -i -e 's:80:8080:g' /etc/apache2/ports.conf
			fi
			if [ -f /etc/apache2/sites-enabled/000-default ] ; then
				sed -i -e 's:80:8080:g' /etc/apache2/sites-enabled/000-default
			fi
			if [ -f /var/www/html/index.html ] ; then
				rm -rf /var/www/html/index.html || true
			fi
		fi
	fi

	git_repo="https://github.com/prpplague/Userspace-Arduino"
	git_target_dir="/opt/source/Userspace-Arduino"
	git_clone

	git_repo="https://github.com/cdsteinkuehler/beaglebone-universal-io.git"
	git_target_dir="/opt/source/beaglebone-universal-io"
	git_clone
	if [ -f ${git_target_dir}/.git/config ] ; then
		if [ -f ${git_target_dir}/config-pin ] ; then
			ln -s ${git_target_dir}/config-pin /usr/local/bin/
		fi
	fi

	git_repo="https://github.com/strahlex/BBIOConfig.git"
	git_target_dir="/opt/source/BBIOConfig"
	git_clone

	git_repo="https://github.com/prpplague/fb-test-app.git"
	git_target_dir="/opt/source/fb-test-app"
	git_clone
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		if [ -f /usr/bin/make ] ; then
			make
		fi
		cd /
	fi

	#am335x-pru-package
	if [ -f /usr/include/prussdrv.h ] ; then
		git_repo="https://github.com/biocode3D/prufh.git"
		git_target_dir="/opt/source/prufh"
		git_clone
		if [ -f ${git_target_dir}/.git/config ] ; then
			cd ${git_target_dir}/
			if [ -f /usr/bin/make ] ; then
				make LIBDIR_APP_LOADER=/usr/lib/ INCDIR_APP_LOADER=/usr/include
			fi
			cd /
		fi
	fi

	is_kernel=$(echo ${repo_rcnee_pkg_version} | grep 4.1. || true)
	if [ ! "x${is_kernel}" = "x" ] ; then
		git_branch="4.1-ti"
	else
		is_kernel=$(echo ${repo_rcnee_pkg_version} | grep 4.4. || true)
		if [ ! "x${is_kernel}" = "x" ] ; then
			git_branch="4.4-ti"
		fi
	fi
	git_repo="https://github.com/RobertCNelson/dtb-rebuilder.git"
	git_target_dir="/opt/source/dtb-${git_branch}"
	git_clone_branch

	git_repo="https://github.com/beagleboard/bb.org-overlays"
	git_target_dir="/opt/source/bb.org-overlays"
	git_clone
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		if [ ! "x${repo_rcnee_pkg_version}" = "x" ] ; then
			is_kernel=$(echo ${repo_rcnee_pkg_version} | grep 3.8.13 || true)
			if [ "x${is_kernel}" = "x" ] ; then
				if [ -f /usr/bin/make ] ; then
					make
					make install
					update-initramfs -u -k ${repo_rcnee_pkg_version}
					make clean
				fi
			fi
		fi
	fi

	git_repo="https://github.com/ungureanuvladvictor/BBBlfs"
	git_target_dir="/opt/source/BBBlfs"
	git_clone
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		if [ -f /usr/bin/make ] ; then
			./autogen.sh
			./configure
			make
		fi
	fi

	#am335x-pru-package
	if [ -f /usr/include/prussdrv.h ] ; then
		git_repo="git://git.ti.com/pru-software-support-package/pru-software-support-package.git"
		git_target_dir="/opt/source/pru-software-support-package"
		git_clone
	fi
}

install_build_pkgs () {
	cd /opt/
	cd /
}

other_source_links () {
	rcn_https="https://rcn-ee.com/repos/git/u-boot-patches"

	mkdir -p /opt/source/u-boot_${u_boot_release}/
	wget --directory-prefix="/opt/source/u-boot_${u_boot_release}/" ${rcn_https}/${u_boot_release}/0001-omap3_beagle-uEnv.txt-bootz-n-fixes.patch
	wget --directory-prefix="/opt/source/u-boot_${u_boot_release}/" ${rcn_https}/${u_boot_release}/0001-am335x_evm-uEnv.txt-bootz-n-fixes.patch
	mkdir -p /opt/source/u-boot_${u_boot_release_x15}/
	wget --directory-prefix="/opt/source/u-boot_${u_boot_release_x15}/" ${rcn_https}/${u_boot_release_x15}/0001-beagle_x15-uEnv.txt-bootz-n-fixes.patch

	echo "u-boot_${u_boot_release} : /opt/source/u-boot_${u_boot_release}" >> /opt/source/list.txt
	echo "u-boot_${u_boot_release_x15} : /opt/source/u-boot_${u_boot_release_x15}" >> /opt/source/list.txt

	chown -R ${rfs_username}:${rfs_username} /opt/source/
}

unsecure_root () {
	root_password=$(cat /etc/shadow | grep root | awk -F ':' '{print $2}')
	sed -i -e 's:'$root_password'::g' /etc/shadow

	if [ -f /etc/ssh/sshd_config ] ; then
		#Make ssh root@beaglebone work..
		sed -i -e 's:PermitEmptyPasswords no:PermitEmptyPasswords yes:g' /etc/ssh/sshd_config
		sed -i -e 's:UsePAM yes:UsePAM no:g' /etc/ssh/sshd_config
		#Starting with Jessie:
		sed -i -e 's:PermitRootLogin without-password:PermitRootLogin yes:g' /etc/ssh/sshd_config
	fi

	if [ -f /etc/sudoers ] ; then
		#Don't require password for sudo access
		echo "${rfs_username}  ALL=NOPASSWD: ALL" >>/etc/sudoers
	fi
}

is_this_qemu

early_git_repos
setup_system
setup_desktop

install_pip_pkgs
if [ -f /usr/bin/git ] ; then
	git config --global user.email "${rfs_username}@example.com"
	git config --global user.name "${rfs_username}"
	install_git_repos
	git config --global --unset-all user.email
	git config --global --unset-all user.name
fi
#install_build_pkgs
other_source_links
unsecure_root
#
