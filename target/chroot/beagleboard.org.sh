#!/bin/sh -e
export LC_ALL=C

chromium_release="chromium-32.0.1700.76"

#chroot_cloud9_git_tag="v2.0.93"
node_prefix="/usr"
#node_release="0.8.26"
#node_build_options="--without-snapshot --shared-openssl --shared-zlib --prefix=${node_prefix}"
node_release="0.10.24"
node_build_options="--without-snapshot --shared-cares --shared-openssl --shared-zlib --prefix=${node_prefix}"

user_name="debian"

. /.project

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

system_patches () {
	#For when sed/grep/etc just gets way to complex...
	cd /
	if [ -f /opt/scripts/mods/debian-add-sbin-usr-sbin-to-default-path.diff ] ; then
		patch -p1 < /opt/scripts/mods/debian-add-sbin-usr-sbin-to-default-path.diff
	fi
}

setup_xorg () {
	if [ -d /etc/X11/ ] ; then
		echo "Section \"Monitor\"" > /etc/X11/xorg.conf
		echo "        Identifier      \"Builtin Default Monitor\"" >> /etc/X11/xorg.conf
		echo "EndSection" >> /etc/X11/xorg.conf
		echo "" >> /etc/X11/xorg.conf
		echo "Section \"Device\"" >> /etc/X11/xorg.conf
		echo "        Identifier      \"Builtin Default fbdev Device 0\"" >> /etc/X11/xorg.conf
		echo "        Driver          \"modesetting\"" >> /etc/X11/xorg.conf
		echo "        Option          \"SWCursor\"      \"true\"" >> /etc/X11/xorg.conf
		echo "EndSection" >> /etc/X11/xorg.conf
		echo "" >> /etc/X11/xorg.conf
		echo "Section \"Screen\"" >> /etc/X11/xorg.conf
		echo "        Identifier      \"Builtin Default fbdev Screen 0\"" >> /etc/X11/xorg.conf
		echo "        Device          \"Builtin Default fbdev Device 0\"" >> /etc/X11/xorg.conf
		echo "        Monitor         \"Builtin Default Monitor\"" >> /etc/X11/xorg.conf
		echo "        DefaultDepth    16" >> /etc/X11/xorg.conf
		echo "EndSection" >> /etc/X11/xorg.conf
		echo "" >> /etc/X11/xorg.conf
		echo "Section \"ServerLayout\"" >> /etc/X11/xorg.conf
		echo "        Identifier      \"Builtin Default Layout\"" >> /etc/X11/xorg.conf
		echo "        Screen          \"Builtin Default fbdev Screen 0\"" >> /etc/X11/xorg.conf
		echo "EndSection" >> /etc/X11/xorg.conf
	fi
}

setup_autologin () {
	if [ -f /etc/lightdm/lightdm.conf ] ; then
		sed -i -e 's:#autologin-user=:autologin-user='$user_name':g' /etc/lightdm/lightdm.conf
		sed -i -e 's:#autologin-session=UNIMPLEMENTED:autologin-session=LXDE:g' /etc/lightdm/lightdm.conf
	fi

	if [ -f /etc/slim.conf ] ; then
		echo "#!/bin/sh" > /home/${user_name}/.xinitrc
		echo "" >> /home/${user_name}/.xinitrc
		echo "exec startlxde" >> /home/${user_name}/.xinitrc
		chmod +x /home/${user_name}/.xinitrc

		#/etc/slim.conf modfications:
		sed -i -e 's:default,start:startlxde,default,start:g' /etc/slim.conf
		echo "default_user        ${user_name}" >> /etc/slim.conf
		echo "auto_login        yes" >> /etc/slim.conf
	fi
}

install_desktop_branding () {
	#FixMe: move to github beagleboard repo...
	wget --no-verbose --directory-prefix=/opt/ http://rcn-ee.net/deb/testing/beaglebg.jpg
	chown -R ${user_name}:${user_name} /opt/beaglebg.jpg

	mkdir -p /home/${user_name}/.config/pcmanfm/LXDE/ || true
	echo "[desktop]" > /home/${user_name}/.config/pcmanfm/LXDE/pcmanfm.conf
	echo "wallpaper_mode=1" >> /home/${user_name}/.config/pcmanfm/LXDE/pcmanfm.conf
	echo "wallpaper=/opt/beaglebg.jpg" >> /home/${user_name}/.config/pcmanfm/LXDE/pcmanfm.conf
	chown -R ${user_name}:${user_name} /home/${user_name}/.config/

	#Disable LXDE's screensaver on autostart
	if [ -f /etc/xdg/lxsession/LXDE/autostart ] ; then
		cat /etc/xdg/lxsession/LXDE/autostart | grep -v xscreensaver > /tmp/autostart
		mv /tmp/autostart /etc/xdg/lxsession/LXDE/autostart
		rm -rf /tmp/autostart || true
	fi
}

dogtag () {
	echo "BeagleBoard.org BeagleBone Debian Image ${time}" > /etc/dogtag
}

build_node () {
	mount -t tmpfs shmfs -o size=256M /dev/shm
	#df -Th

	cd /opt/source
	wget http://nodejs.org/dist/v${node_release}/node-v${node_release}.tar.gz
	tar xf node-v${node_release}.tar.gz
	cd node-v${node_release}
	./configure ${node_build_options} && make -j5 && make install
	cd /
	rm -rf /opt/source/node-v${node_release}/ || true
	rm -rf /opt/source/node-v${node_release}.tar.gz || true
	echo "node-v${node_release} : http://rcn-ee.net/pkgs/nodejs/node-v${node_release}.tar.gz" >> /opt/source/list.txt

	echo "debug: node: [`node --version`]"
	echo "debug: npm: [`npm --version`]"

	echo "debug: npm config ls -l"
	npm config ls -l

	#echo "Installing bonescript"
	#NODE_PATH=${node_prefix}/lib/node_modules/ npm install -g bonescript --arch=armhf

	sync
	umount -l /dev/shm || true
}

install_builds () {
	cd /opt/
	wget http://rcn-ee.net/pkgs/chromium/${chromium_release}-armhf.tar.xz
	tar xf ${chromium_release}-armhf.tar.xz -C /
	rm -rf ${chromium_release}-armhf.tar.xz || true
	echo "${chromium_release} : http://rcn-ee.net/pkgs/chromium/${chromium_release}.tar.xz" >> /opt/source/list.txt

	#link Chromium to /usr/bin/x-www-browser
	update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/chromium 200
}

install_repos () {
	git_repo="git://github.com/ajaxorg/cloud9.git"
	git_target_dir="/opt/cloud9"
	if [ "x${chroot_cloud9_git_tag}" = "x" ] ; then
		git_clone
	else
		mkdir -p /opt/cloud9/ || true
		qemu_command="git clone --depth 1 -b ${chroot_cloud9_git_tag} ${git_repo} ${git_target_dir} || true"
		qemu_warning
		git clone --depth 1 -b ${chroot_cloud9_git_tag} ${git_repo} ${git_target_dir} || true
		sync
		echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
	fi
	if [ -f ${git_target_dir}/.git/config ] ; then
		chown -R ${user_name}:${user_name} ${git_target_dir}
	fi

	#cd /opt/cloud9
	#npm install --arch=armhf

	if [ -f /var/www/index.html ] ; then
		rm -rf /var/www/index.html || true
	fi
	git_repo="git://github.com/beagleboard/bone101"
	git_target_dir="/var/www/"
	git_clone

	git_repo="git://github.com/beagleboard/bonescript"
	git_target_dir="/var/lib/cloud9"
	git_clone
	if [ -f ${git_target_dir}/.git/config ] ; then
#		if [ -d ${git_target_dir}/node_modules/bonescript/ ] ; then
#			cd ${git_target_dir}/node_modules/bonescript/
#			npm install -d --arch=armhf
#			if [ -d /root/.node-gyp/${node_release}/ ] ; then
#				rm -rf /root/.node-gyp/${node_release}/ || true
#			fi
#		fi
		chown -R ${user_name}:${user_name} ${git_target_dir}
	fi

	git_repo="git://github.com/jackmitch/libsoc"
	git_target_dir="/opt/source/libsoc"
	git_clone
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		./autogen.sh
		./configure --enable-debug
		make
		make install
		make distclean
	fi

	git_repo="git://github.com/prpplague/Userspace-Arduino"
	git_target_dir="/opt/source/Userspace-Arduino"
	git_clone
}

unsecure_root () {
	root_password=$(cat /etc/shadow | grep root | awk -F ':' '{print $2}')
	sed -i -e 's:'$root_password'::g' /etc/shadow

	#Make ssh root@beaglebone work..
	sed -i -e 's:PermitEmptyPasswords no:PermitEmptyPasswords yes:g' /etc/ssh/sshd_config
	sed -i -e 's:UsePAM yes:UsePAM no:g' /etc/ssh/sshd_config
}

is_this_qemu
system_patches
setup_xorg
setup_autologin
install_desktop_branding
dogtag
build_node
install_builds
install_repos
unsecure_root
#
