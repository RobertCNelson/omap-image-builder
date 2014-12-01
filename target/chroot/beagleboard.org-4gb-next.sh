#!/bin/sh -e
#
# Copyright (c) 2014 Robert Nelson <robertcnelson@gmail.com>
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

chromium_release="chromium-33.0.1750.117"
u_boot_release="v2014.10"
cloud9_pkg="c9v3-beaglebone-build-2-20140414.tar.gz"

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

	if [ -f /opt/scripts/mods/jessie-systemd-poweroff.diff ] ; then
		if [ -f /usr/bin/patch ] ; then
			echo "Patching: /lib/udev/rules.d/70-power-switch.rules"
			patch -p1 < /opt/scripts/mods/jessie-systemd-poweroff.diff
		fi
	fi

	if [ -f /opt/scripts/boot/am335x_evm.sh ] ; then
		if [ -f /lib/systemd/system/serial-getty@.service ] ; then
			cp /lib/systemd/system/serial-getty@.service /etc/systemd/system/serial-getty@ttyGS0.service
			ln -s /etc/systemd/system/serial-getty@ttyGS0.service /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service

			echo "" >> /etc/securetty
			echo "#USB Gadget Serial Port" >> /etc/securetty
			echo "ttyGS0" >> /etc/securetty
		fi
	fi
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
#		if [ -f /opt/scripts/3rdparty/xinput_calibrator_pointercal.sh ] ; then
#			sed -i -e 's:#display-setup-script=:display-setup-script=/opt/scripts/3rdparty/xinput_calibrator_pointercal.sh:g' ${wfile}
#		fi
	fi

	if [ ! "x${rfs_desktop_background}" = "x" ] ; then
		mkdir -p /home/${rfs_username}/.config/ || true
		if [ -d /opt/scripts/desktop-defaults/jessie/lxqt/ ] ; then
			cp -rv /opt/scripts/desktop-defaults/jessie/lxqt/* /home/${rfs_username}/.config
		fi
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

#	#Disable LXDE's screensaver on autostart
#	if [ -f /etc/xdg/lxsession/LXDE/autostart ] ; then
#		cat /etc/xdg/lxsession/LXDE/autostart | grep -v xscreensaver > /tmp/autostart
#		mv /tmp/autostart /etc/xdg/lxsession/LXDE/autostart
#		rm -rf /tmp/autostart || true
#	fi

	echo "BeagleBoard.org BeagleBone Debian Image ${release_date}" > /etc/dogtag

	#echo "CAPE=cape-bone-proto" >> /etc/default/capemgr

#	#root password is blank, so remove useless application as it requires a password.
#	if [ -f /usr/share/applications/gksu.desktop ] ; then
#		rm -f /usr/share/applications/gksu.desktop || true
#	fi

	#Add Website for Help:
	echo "Support/FAQ: http://elinux.org/Beagleboard:BeagleBoneBlack_Debian" >> /etc/issue
	echo "" >> /etc/issue

	echo "" >> /etc/issue.net
	cat /etc/dogtag >> /etc/issue.net
	echo "" >> /etc/issue.net
	echo "Support/FAQ: http://elinux.org/Beagleboard:BeagleBoneBlack_Debian" >> /etc/issue.net
	echo "" >> /etc/issue.net
	echo "password for: [$rfs_username] = [$rfs_password]" >> /etc/issue.net
	echo "" >> /etc/issue.net

	if [ -f /etc/ssh/sshd_config ] ; then
		sed -i -e 's:#Banner:Banner:g' /etc/ssh/sshd_config
	fi

#	#lxterminal doesnt reference .profile by default, so call via loginshell and start bash
#	if [ -f /usr/bin/lxterminal ] ; then
#		if [ -f /usr/share/applications/lxterminal.desktop ] ; then
#			sed -i -e 's:Exec=lxterminal:Exec=lxterminal -l -e bash:g' /usr/share/applications/lxterminal.desktop
#			sed -i -e 's:TryExec=lxterminal -l -e bash:TryExec=lxterminal:g' /usr/share/applications/lxterminal.desktop
#		fi
#	fi

	#ti: firewall blocks pastebin.com
	if [ -f /usr/bin/pastebinit ] ; then
		wfile="/home/${rfs_username}/.pastebinit.xml"
		echo "<pastebinit>" > ${wfile}
		echo "    <pastebin>http://paste.debian.net</pastebin>" >> ${wfile}
		echo "    <author>anonymous</author>" >> ${wfile}
		echo "    <jabberid>author@example.net</jabberid>" >> ${wfile}
		echo "    <format>text</format>" >> ${wfile}
		echo "</pastebinit>" >> ${wfile}
	fi

	#fix Ping:
	#ping: icmp open socket: Operation not permitted
	if [ -f /bin/ping ] ; then
		chmod u+x /bin/ping
	fi

	if [ -f /etc/dnsmasq.conf ] ; then
		wfile="/etc/dnsmasq.d/usb0-dhcp"
		echo "#disable DNS by setting port to 0" > ${wfile}
		echo "port=0" >> ${wfile}
		echo "" >> ${wfile}
		echo "interface=usb0" >> ${wfile}
		echo "#one address range" >> ${wfile}
		echo "dhcp-range=192.168.7.1,192.168.7.1" >> ${wfile}
		echo "" >> ${wfile}
		echo "dhcp-option=3" >> ${wfile}
	fi
}

cleanup_npm_cache () {
	if [ -d /root/tmp/ ] ; then
		rm -rf /root/tmp/ || true
	fi

	if [ -d /root/.npm ] ; then
		rm -rf /root/.npm || true
	fi
}

install_node_pkgs () {
	if [ -f /usr/bin/npm ] ; then
		echo "Installing npm packages"
		echo "debug: node: [`node --version`]"
		echo "debug: npm: [`npm --version`]"

		echo "NODE_PATH=/usr/local/lib/node_modules" > /etc/default/node
		echo "export NODE_PATH=/usr/local/lib/node_modules" > /etc/profile.d/node.sh
		chmod 755 /etc/profile.d/node.sh

		#debug
		#echo "debug: npm config ls -l (before)"
		#echo "--------------------------------"
		#npm config ls -l
		#echo "--------------------------------"

		#fix npm in chroot.. (did i mention i hate npm...)
		if [ ! -d /root/.npm ] ; then
			mkdir -p /root/.npm
		fi
		npm config set cache /root/.npm
		npm config set group 0
		npm config set init-module /root/.npm-init.js

		if [ ! -d /root/tmp ] ; then
			mkdir -p /root/tmp
		fi
		npm config set tmp /root/tmp
		npm config set user 0
		npm config set userconfig /root/.npmrc

		#http://blog.npmjs.org/post/78085451721/npms-self-signed-certificate-is-no-more
		#The cause: npm no longer supports its self-signed certificates.
		#npm config set ca ""

		#echo "debug: npm config ls -l (after)"
		#echo "--------------------------------"
		#npm config ls -l
		#echo "--------------------------------"

		if [ -f /usr/bin/make ] ; then
			echo "Installing bonescript"
			TERM=dumb npm install -g bonescript --arch=armhf
			if [ -f /usr/local/lib/node_modules/bonescript/server.js ] ; then
				sed -i -e 's:/usr/share/bone101:/var/lib/cloud9:g' /usr/local/lib/node_modules/bonescript/server.js
			fi
		fi

#		#Cloud9:
#		if [ -f /usr/bin/make ] ; then
#			echo "Installing winston"
#			TERM=dumb npm install -g winston --arch=armhf
#		fi

		cleanup_npm_cache
		sync

		cd /opt/
		mkdir -p /opt/cloud9/
		wget https://rcn-ee.net/pkgs/c9v3/${cloud9_pkg}
		if [ -f /opt/${cloud9_pkg} ] ; then
			tar xf ${cloud9_pkg} -C /opt/cloud9/
			rm -rf ${cloud9_pkg} || true

			#Fixme: archive structure changed in c9v3-beaglebone-build-2-20140414...
			if [ -d /opt/cloud9/c9v3-beaglebone-build-2-20140414 ] ; then
				mv /opt/cloud9/c9v3-beaglebone-build-2-20140414/* /opt/cloud9/
				rm -rf /opt/cloud9/c9v3-beaglebone-build-2-20140414 || true
			fi

			chown -R ${rfs_username}:${rfs_username} /opt/cloud9/

			if [ -f /opt/cloud9/install.sh ] ; then
				cd /opt/cloud9/
				/bin/sh ./install.sh || true
				echo "cloud9: jessie"
				systemctl enable cloud9.socket || true
				cd /opt/
			fi
		fi

		git_repo="https://github.com/beagleboard/bone101"
		git_target_dir="/var/lib/cloud9"

	if [ -f /usr/local/bin/jekyll ] ; then
		git_clone
	else
		git_clone_full
	fi
		if [ -f ${git_target_dir}/.git/config ] ; then
			chown -R ${rfs_username}:${rfs_username} ${git_target_dir}
			cd ${git_target_dir}/

		if [ -f /usr/local/bin/jekyll ] ; then
			echo "jekyll pre-building bone101"
			/usr/local/bin/jekyll build
		else
			git checkout 15ad28c7e8a5d57e133f1ac8dce63a237313f6ad -b tmp
		fi

			wfile="/lib/systemd/system/bonescript.socket"
			echo "[Socket]" > ${wfile}
			echo "ListenStream=80" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Install]" >> ${wfile}
			echo "WantedBy=sockets.target" >> ${wfile}

			wfile="/lib/systemd/system/bonescript.service"
			echo "[Unit]" > ${wfile}
			echo "Description=Bonescript server" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Service]" >> ${wfile}
			echo "WorkingDirectory=/usr/local/lib/node_modules/bonescript" >> ${wfile}
			echo "ExecStart=/usr/bin/node server.js" >> ${wfile}
			echo "SyslogIdentifier=bonescript" >> ${wfile}

			systemctl enable bonescript.socket || true

		if [ -f /usr/local/bin/jekyll ] ; then
			wfile="/lib/systemd/system/jekyll-autorun.service"
			echo "[Unit]" > ${wfile}
			echo "Description=jekyll autorun" >> ${wfile}
			echo "ConditionPathExists=|/var/lib/cloud9" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Service]" >> ${wfile}
			echo "WorkingDirectory=/var/lib/cloud9" >> ${wfile}
			echo "ExecStart=/usr/local/bin/jekyll build --watch" >> ${wfile}
			echo "SyslogIdentifier=jekyll-autorun" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Install]" >> ${wfile}
			echo "WantedBy=multi-user.target" >> ${wfile}

			systemctl enable jekyll-autorun.service || true
		fi

			wfile="/lib/systemd/system/bonescript-autorun.service"
			echo "[Unit]" > ${wfile}
			echo "Description=Bonescript autorun" >> ${wfile}
			echo "ConditionPathExists=|/var/lib/cloud9" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Service]" >> ${wfile}
			echo "WorkingDirectory=/usr/local/lib/node_modules/bonescript" >> ${wfile}
			echo "EnvironmentFile=/etc/default/node" >> ${wfile}
			echo "ExecStart=/usr/bin/node autorun.js" >> ${wfile}
			echo "SyslogIdentifier=bonescript-autorun" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Install]" >> ${wfile}
			echo "WantedBy=multi-user.target" >> ${wfile}

			systemctl enable bonescript-autorun.service || true

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
	fi
}

install_pip_pkgs () {
	if [ -f /usr/bin/pip ] ; then
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
	fi
}

install_gem_pkgs () {
	if [ -f /usr/bin/gem ] ; then
		echo "Installing gem packages"
		echo "debug: gem: [`gem --version`]"
		gem_wheezy="--no-rdoc --no-ri"
		gem_jessie="--no-document"

		echo "gem: [beaglebone]"
		gem install beaglebone

		echo "gem: [jekyll ${gem_jessie}]"
		gem install jekyll ${gem_jessie}
	fi
}

install_git_repos () {
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
	fi

	git_repo="https://github.com/biocode3D/prufh.git"
	git_target_dir="/opt/source/prufh"
	git_clone
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		if [ -f /usr/bin/make ] ; then
			make LIBDIR_APP_LOADER=/usr/lib/ INCDIR_APP_LOADER=/usr/include
		fi
	fi

	git_repo="https://github.com/alexanderhiam/PyBBIO.git"
	git_target_dir="/opt/source/PyBBIO"
	git_clone
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		if [ -f /usr/bin/dtc ] ; then
			sed -i "s/PLATFORM = ''/PLATFORM = 'BeagleBone >=3.8'/g" setup.py
			python setup.py install
		fi
	fi

	git_repo="https://github.com/RobertCNelson/dtb-rebuilder.git"
	git_branch="3.14-ti"
	git_target_dir="/opt/source/dtb-${git_branch}"
	git_clone_branch

	git_repo="git://git.ti.com/pru-software-support-package/pru-software-support-package.git"
	git_target_dir="/opt/source/pru-software-support-package"
	git_clone
}

install_build_pkgs () {
	cd /opt/
	if [ -f /usr/bin/xz ] ; then
		wget https://rcn-ee.net/pkgs/chromium/${chromium_release}-armhf.tar.xz
		if [ -f /opt/${chromium_release}-armhf.tar.xz ] ; then
			tar xf ${chromium_release}-armhf.tar.xz -C /
			rm -rf ${chromium_release}-armhf.tar.xz || true
			echo "${chromium_release} : https://rcn-ee.net/pkgs/chromium/${chromium_release}.tar.xz" >> /opt/source/list.txt

			#link Chromium to /usr/bin/x-www-browser
			update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/chromium 200
		fi
	fi
}

other_source_links () {
	rcn_https="https://raw.githubusercontent.com/RobertCNelson/Bootloader-Builder/master/patches"

	mkdir -p /opt/source/u-boot_${u_boot_release}/
	wget --directory-prefix="/opt/source/u-boot_${u_boot_release}/" ${rcn_https}/${u_boot_release}/0001-am335x_evm-uEnv.txt-bootz-n-fixes.patch

	echo "u-boot_${u_boot_release} : /opt/source/u-boot_${u_boot_release}" >> /opt/source/list.txt
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

todo () {
	#stuff i need to package in repos.rcn-ee.net
	#
	cd /
	if [ ! -f /etc/Wireless/RT2870STA/RT2870STA.dat ] ; then
		mkdir -p /etc/Wireless/RT2870STA/
		cd /etc/Wireless/RT2870STA/
		wget https://raw.githubusercontent.com/rcn-ee/mt7601u/master/src/RT2870STA.dat
		cd /
	fi
	if [ ! -f /etc/modules-load.d/mt7601.conf ] ; then
		echo "mt7601Usta" > /etc/modules-load.d/mt7601.conf
	fi

	if [ ! -f /opt/source/x15/ducati_full_jacinto6evm.tgz ] ; then
		mkdir -p /opt/source/x15/
		cd /opt/source/x15/
		wget https://raw.githubusercontent.com/rcn-ee/ti-proprietary-open/d-lollipop-release/jacinto6/ducati_full_jacinto6evm.tgz

		#v3.14.x: sadly:
		#[   24.965781] omap-rproc 55020000.ipu: omap rproc 55020000.ipu crashed
		#[   24.972528]  remoteproc1: crash detected in 55020000.ipu: type device exception
		#[   24.980372]  remoteproc1: handling crash #13 in 55020000.ipu
		#[   24.986338]  remoteproc1: recovering 55020000.ipu

		#tar xf ducati_full_jacinto6evm.tgz
		#cp -v dra7-ipu2-fw.xem4 /lib/firmware/
		cd /
	fi
}

is_this_qemu

setup_system
setup_desktop

install_gem_pkgs
install_node_pkgs
install_pip_pkgs
if [ -f /usr/bin/git ] ; then
	install_git_repos
fi
#install_build_pkgs
other_source_links
unsecure_root
todo
#
