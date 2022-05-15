#!/bin/sh -e
#
# Copyright (c) 2014-2020 Robert Nelson <robertcnelson@gmail.com>
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

#contains: rvfs_username, release_date
if [ -f /etc/riscv.conf ] ; then
	. /etc/riscv.conf
fi

if [ -f /etc/rvb.project ] ; then
	. /etc/rvb.project
fi

export HOME=/home/${rvfs_username}
export USER=${rvfs_username}
export USERNAME=${rvfs_username}

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
		echo "        Driver          \"fbdev\"" >> ${wfile}
		echo "EndSection" >> ${wfile}
		echo "" >> ${wfile}
		echo "Section \"Screen\"" >> ${wfile}
		echo "        Identifier      \"Builtin Default fbdev Screen 0\"" >> ${wfile}
		echo "        Device          \"Builtin Default fbdev Device 0\"" >> ${wfile}
		echo "        Monitor         \"Builtin Default Monitor\"" >> ${wfile}
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
		sed -i -e 's:#autologin-user=:autologin-user='$rvfs_username':g' ${wfile}
		sed -i -e 's:#autologin-session=:autologin-session='$rvfs_default_desktop':g' ${wfile}
		if [ -f /opt/scripts/3rdparty/xinput_calibrator_pointercal.sh ] ; then
			sed -i -e 's:#display-setup-script=:display-setup-script=/opt/scripts/3rdparty/xinput_calibrator_pointercal.sh:g' ${wfile}
		fi
	fi

	if [ ! "x${rvfs_desktop_background}" = "x" ] ; then
		mkdir -p /home/${rvfs_username}/.config/ || true
		if [ -d /opt/scripts/desktop-defaults/buster/lxqt/ ] ; then
			cp -rv /opt/scripts/desktop-defaults/buster/lxqt/* /home/${rvfs_username}/.config
		fi
		chown -R ${rvfs_username}:${rvfs_username} /home/${rvfs_username}/.config/
	fi

	#Disable dpms mode and screen blanking
	#Better fix for missing cursor
	wfile="/home/${rvfs_username}/.xsessionrc"
	echo "#!/bin/sh" > ${wfile}
	echo "" >> ${wfile}
	echo "xset -dpms" >> ${wfile}
	echo "xset s off" >> ${wfile}
	echo "xsetroot -cursor_name left_ptr" >> ${wfile}
	chown -R ${rvfs_username}:${rvfs_username} ${wfile}
}

install_git_repos () {

    git_repo="https://github.com/RichNeese/riscv-os-overlay.git"
    git_target_dir="/opt/source/riscv-os-overlay"
    git_clone

    if [ -f ${git_target_dir}/install_overlay.sh ] ; then
        cd ${git_target_dir}/
        if [ -f install_overlay.sh ] ; then
            chmod +x install_overlay.sh
            ./install_overlay.sh
        fi
    fi

    git_repo="https://github.com/RichNeese/gpio_config_tool.git"
    git_target_dir="/opt/source/gpio_config_tool"
    git_clone
    
    if [ -f ${git_target_dir}/install-gpio.sh ] ; then
        cd ${git_target_dir}/
        if [ -f install-gpio.sh ] ; then
            chmod +x install-gpio.sh
            ./install-gpio.sh
        fi
    fi
}

other_source_links () {
    chown -R ${rvfs_username}:${rvfs_username} /opt/source/
}

is_this_qemu

setup_system
setup_desktop

if [ -f /usr/bin/git ] ; then
	git config --global user.email "${rvfs_username}@example.com"
	git config --global user.name "${rvfs_username}"
	install_git_repos
	git config --global --unset-all user.email
	git config --global --unset-all user.name
	chown ${rvfs_username}:${rvfs_username} /home/${rvfs_username}/.gitconfig
fi
#other_source_links
#
