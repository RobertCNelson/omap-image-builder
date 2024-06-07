#!/bin/sh -e
#
# Copyright (c) 2014-2021 Robert Nelson <robertcnelson@gmail.com>
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
	chown -R 1000:1000 ${git_target_dir}
	sync
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

git_clone_branch () {
	mkdir -p ${git_target_dir} || true
	qemu_command="git clone -b ${git_branch} ${git_repo} ${git_target_dir} --depth 1 || true"
	qemu_warning
	git clone -b ${git_branch} ${git_repo} ${git_target_dir} --depth 1 || true
	chown -R 1000:1000 ${git_target_dir}
	sync
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

git_clone_full () {
	mkdir -p ${git_target_dir} || true
	qemu_command="git clone ${git_repo} ${git_target_dir} || true"
	qemu_warning
	git clone ${git_repo} ${git_target_dir} || true
	chown -R 1000:1000 ${git_target_dir}
	sync
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

setup_system () {
	if [ -f /var/www/html/index.nginx-debian.html ] ; then
		if [ -f /etc/bbb.io/templates/nginx/nginx-autoindex ] ; then
			rm -f /etc/nginx/sites-enabled/default || true
			cp -v /etc/bbb.io/templates/nginx/nginx-autoindex /etc/nginx/sites-enabled/default
			cp -v /etc/bbb.io/templates/nginx/*.html /var/www/html/
			rm -f /var/www/html/index.nginx-debian.html || true

			echo '<!DOCTYPE html>' > /var/www/html/Home-Assistant.html
			echo '<html lang="en">' >> /var/www/html/Home-Assistant.html
			echo '<head>' >> /var/www/html/Home-Assistant.html
			echo '<meta charset="utf-8">' >> /var/www/html/Home-Assistant.html
			echo '</head>' >> /var/www/html/Home-Assistant.html
			echo '<body>' >> /var/www/html/Home-Assistant.html
			echo '    <script>' >> /var/www/html/Home-Assistant.html
			echo '        let newurl = "http://" + location.host + ":8123/";' >> /var/www/html/Home-Assistant.html
			echo '        window.location.href = newurl;' >> /var/www/html/Home-Assistant.html
			echo '    </script>' >> /var/www/html/Home-Assistant.html
			echo '</body>' >> /var/www/html/Home-Assistant.html
			echo '</html>' >> /var/www/html/Home-Assistant.html

		fi
	fi
}

setup_desktop () {
	if [ -f /etc/bbb.io/templates/xfce4/xfce4-desktop.xml ] ; then
		mkdir -p /home/${rfs_username}/.config/xfce4/xfconf/xfce-perchannel-xml/ || true
		cp -v /etc/bbb.io/templates/xfce4/xfce4-*.xml /home/${rfs_username}/.config/xfce4/xfconf/xfce-perchannel-xml/
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

	if [ -f /usr/sbin/wpa_gui ] ; then
		mkdir -p /home/${rfs_username}/Desktop/ || true
		chown -R ${rfs_username}:${rfs_username} /home/${rfs_username}/Desktop/

		wfile="/home/${rfs_username}/Desktop/wpa_gui.desktop"
		echo "[Desktop Entry]" > ${wfile}
		echo "Version=1.0" >> ${wfile}
		echo "Name=wpa_gui" >> ${wfile}
		echo "Comment=Graphical user interface for wpa_supplicant" >> ${wfile}
		echo "Exec=wpa_gui" >> ${wfile}
		echo "Icon=wpa_gui" >> ${wfile}
		echo "GenericName=wpa_supplicant user interface" >> ${wfile}
		echo "Terminal=false" >> ${wfile}
		echo "Type=Application" >> ${wfile}
		echo "Categories=Qt;Network;" >> ${wfile}
		chown -R ${rfs_username}:${rfs_username} ${wfile}
		chmod +x ${wfile}
	fi
}

install_git_repos () {
	git_repo="https://openbeagle.org/beagleboard/BeagleBoard-DeviceTrees.git"
	git_target_dir="/opt/source/dtb-5.10-ti"
	git_branch="v5.10.x-ti-unified"
	git_clone_branch

	git_repo="https://openbeagle.org/beagleboard/BeagleBoard-DeviceTrees.git"
	git_target_dir="/opt/source/dtb-6.1-Beagle"
	git_branch="v6.1.x-Beagle"
	git_clone_branch

	git_repo="https://github.com/mvduin/py-uio"
	git_target_dir="/opt/source/py-uio"
	git_clone

	git_repo="https://github.com/rm-hull/spidev-test"
	git_target_dir="/opt/source/spidev-test"
	git_clone

	git_repo="https://openbeagle.org/RobertCNelson/home-assistant.git"
	git_target_dir="/opt/source/home-assistant"
	git_clone
	dpkg -i /opt/source/home-assistant/os-agent*.deb
	debconf-set-selections <<<'homeassistant-supervised ha/machine-type select qemuarm-64'
	dpkg -i /opt/source/home-assistant/homeassistant-supervised*.deb

	sed -i -e 's:quiet:systemd.unified_cgroup_hierarchy=false quiet:g' /opt/u-boot/bb-u-boot-beagleboneai64/*-extlinux.conf
	sed -i -e 's:quiet:systemd.unified_cgroup_hierarchy=false quiet:g' /opt/u-boot/bb-u-boot-beagleplay/*-extlinux.conf
}

other_source_links () {
	chown -R ${rfs_username}:${rfs_username} /opt/source/
}

is_this_qemu

setup_system
setup_desktop

if [ -f /usr/bin/git ] ; then
	git config --global user.email "${rfs_username}@example.com"
	git config --global user.name "${rfs_username}"
	install_git_repos
	git config --global --unset-all user.email
	git config --global --unset-all user.name
	chown ${rfs_username}:${rfs_username} /home/${rfs_username}/.gitconfig
fi
other_source_links
#
