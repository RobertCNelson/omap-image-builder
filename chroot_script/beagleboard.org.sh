#!/bin/sh -e
export LC_ALL=C

#chroot_cloud9_git_tag="v2.0.93"
#chroot_node_release="v0.8.26"
#chroot_node_build_options="--without-snapshot --shared-openssl --shared-zlib --prefix=/usr/local/"
chroot_node_release="v0.10.24"
chroot_node_build_options="--without-snapshot --shared-cares --shared-openssl --shared-zlib --prefix=/usr/local/"

user_name="debian"

qemu_warning () {
	if [ "${warn_qemu_will_fail}" ] ; then
		echo "Log: (chroot) Warning, qemu can fail here... (run on real armv7l hardware for production images)"
		echo "Log: (chroot): [${qemu_command}]"
	fi
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

	mkdir -p /var/lib/cloud9 || true
	qemu_command="git clone https://github.com/beagleboard/bonescript /var/lib/cloud9 --depth 1 || true"
	qemu_warning
	git clone https://github.com/beagleboard/bonescript /var/lib/cloud9 --depth 1 || true
	sync
	chown -R ${user_name}:${user_name} /var/lib/cloud9
	echo "/var/lib/cloud9 : https://github.com/beagleboard/bonescript" >> /opt/source/list.txt

	if [ -f /var/www/index.html ] ; then
		rm -rf /var/www/index.html || true
	fi
	qemu_command="git clone https://github.com/beagleboard/bone101 /var/www/ --depth 1 || true"
	qemu_warning
	git clone https://github.com/beagleboard/bone101 /var/www/ --depth 1 || true
	sync
	echo "/var/www/ : https://github.com/beagleboard/bone101" >> /opt/source/list.txt

	sync
	umount -l /dev/shm || true
}

install_cloud9
