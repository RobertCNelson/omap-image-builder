#!/bin/sh -e
export LC_ALL=C

#chroot_cloud9_git_tag="v2.0.93"
#chroot_node_release="v0.8.26"
#chroot_node_build_options="--without-snapshot --shared-openssl --shared-zlib --prefix=/usr/local/"
chroot_node_release="v0.10.24"
chroot_node_build_options="--without-snapshot --shared-cares --shared-openssl --shared-zlib --prefix=/usr/local/"

. /.project

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

setup_xorg () {
	echo "Section \"Monitor\"" > /etc/X11/xorg.conf
	echo "        Identifier      "Builtin Default Monitor"" >> /etc/X11/xorg.conf
	echo "EndSection" >> /etc/X11/xorg.conf
	echo "" >> /etc/X11/xorg.conf
	echo "Section \"Device\"" >> /etc/X11/xorg.conf
	echo "        Identifier      \"Builtin Default fbdev Device 0\"" >> /etc/X11/xorg.conf
	echo "        Driver          \"modesetting\"" >> /etc/X11/xorg.conf
	echo "        Option          \"SWCursor\"      "true"" >> /etc/X11/xorg.conf
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
}

setup_autologin () {
	if [ -f /etc/lightdm/lightdm.conf ] ; then
		sed -i -e 's:#autologin-user=:autologin-user=${user_name}:g' /etc/lightdm/lightdm.conf
		sed -i -e 's:#autologin-session=:autologin-session=LXDE:g' /etc/lightdm/lightdm.conf
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
}

dogtag () {
	echo "BeagleBoard.org BeagleBone Debian Image ${time}" > /etc/dogtag
}

install_cloud9 () {
	mount -t tmpfs shmfs -o size=256M /dev/shm
	#df -Th

	cd /opt/source
	wget http://nodejs.org/dist/${chroot_node_release}/node-${chroot_node_release}.tar.gz
	tar xf node-${chroot_node_release}.tar.gz
	cd node-${chroot_node_release}
	./configure ${chroot_node_build_options} && make -j5 && make install
	cd /
	rm -rf /opt/source/node-${chroot_node_release}/ || true

	echo "debug: node: [`node --version`]"
	echo "debug: npm: [`npm --version`]"

	mkdir -p /opt/cloud9/ || true
	if [ "x${chroot_cloud9_git_tag}" = "x" ] ; then
		qemu_command="git clone --depth 1 https://github.com/ajaxorg/cloud9.git /opt/cloud9/ || true"
		qemu_warning
		git clone --depth 1 https://github.com/ajaxorg/cloud9.git /opt/cloud9/ || true
		sync
		echo "/opt/cloud9/ : https://github.com/ajaxorg/cloud9.git" >> /opt/source/list.txt
	else
		qemu_command="git clone --depth 1 -b ${chroot_cloud9_git_tag} https://github.com/ajaxorg/cloud9.git /opt/cloud9/ || true"
		qemu_warning
		git clone --depth 1 -b ${chroot_cloud9_git_tag} https://github.com/ajaxorg/cloud9.git /opt/cloud9/ || true
		sync
		echo "/opt/cloud9/ : https://github.com/ajaxorg/cloud9.git" >> /opt/source/list.txt
	fi
	chown -R ${user_name}:${user_name} /opt/cloud9/

	if [ -f /usr/local/bin/sm ] ; then
		echo "debug: sm: [`sm --version`]"
		cd /opt/cloud9
		qemu_command="sm install"
		qemu_warning
		sm install
	#else
		#cd /opt/cloud9
		#npm install --arch=armhf
	fi

	git_repo="https://github.com/beagleboard/bonescript"
	git_target_dir="/var/lib/cloud9"
	git_clone
	chown -R ${user_name}:${user_name} ${git_target_dir}

	if [ -f /var/www/index.html ] ; then
		rm -rf /var/www/index.html || true
	fi
	git_repo="https://github.com/beagleboard/bone101"
	git_target_dir="/var/www/"
	git_clone

	sync
	umount -l /dev/shm || true
}

unseure_root () {
	root_password=$(cat /etc/shadow | grep root | awk -F ':' '{print $2}')
	sed -i -e 's:'$root_password'::g' /etc/shadow

	#Make ssh root@beaglebone work..
	sed -i -e 's:PermitEmptyPasswords no:PermitEmptyPasswords yes:g' /etc/ssh/sshd_config
	sed -i -e 's:UsePAM yes:UsePAM no:g' /etc/ssh/sshd_config
}

setup_xorg
setup_autologin
install_desktop_branding
dogtag
install_cloud9
unsecure_root
