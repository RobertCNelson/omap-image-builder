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
	#For when sed/grep/etc just gets way to complex...
	cd /
	#make the sound card work by default
	if [ -f /etc/alsa/tlv320aic3104.state.txt ] ; then
		if [ -d /var/lib/alsa/ ] ; then
			cp -v /etc/alsa/tlv320aic3104.state.txt /var/lib/alsa/asound.state
			cp -v /etc/alsa/tlv320aic3104.conf.txt /etc/asound.conf
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
		echo "        Driver          \"fbdev\"" >> ${wfile}
		echo "#HWcursor_false        Option          \"HWcursor\"          \"false\"" >> ${wfile}
		echo "EndSection" >> ${wfile}
		echo "" >> ${wfile}
		echo "Section \"Screen\"" >> ${wfile}
		echo "        Identifier      \"Builtin Default fbdev Screen 0\"" >> ${wfile}
		echo "        Device          \"Builtin Default fbdev Device 0\"" >> ${wfile}
		echo "        Monitor         \"Builtin Default Monitor\"" >> ${wfile}
		echo "#DefaultDepth        DefaultDepth    16" >> ${wfile}
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
		sed -i -e 's:#autologin-session=:autologin-session='$rfs_default_desktop':g' ${wfile}
	fi

	if [ -f /etc/bbb.io/templates/xfce4/xfce4-desktop.xml ] ; then
		mkdir -p /home/${rfs_username}/.config/xfce4/xfconf/xfce-perchannel-xml/ || true
		cp -v /etc/bbb.io/templates/xfce4/xfce4-desktop.xml /home/${rfs_username}/.config/xfce4/xfconf/xfce-perchannel-xml/
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
}

install_git_repos () {
	if [ -f /usr/bin/make ] ; then
		echo "Installing pip packages"
		git_repo="https://github.com/adafruit/adafruit-beaglebone-io-python.git"
		git_target_dir="/opt/source/adafruit-beaglebone-io-python"
		git_clone
		if [ -f ${git_target_dir}/.git/config ] ; then
			cd ${git_target_dir}/
			sed -i -e 's:4.1.0:3.4.0:g' setup.py || true
			if [ -f /usr/bin/python3 ] ; then
				python3 setup.py install || true
			fi
			git reset HEAD --hard || true
		fi
	fi

	if [ -f /var/www/html/index.nginx-debian.html ] ; then
		rm -rf /var/www/html/index.nginx-debian.html || true
	fi

	git_repo="https://github.com/beagleboard/BeagleBoard-DeviceTrees"
	git_target_dir="/opt/source/dtb-5.4-ti"
	git_branch="v5.4.x-ti-overlays"
	git_clone_branch

	git_repo="https://github.com/beagleboard/BeagleBoard-DeviceTrees"
	git_target_dir="/opt/source/dtb-5.10-ti"
	git_branch="v5.10.x-ti"
	git_clone_branch

	git_repo="https://github.com/beagleboard/BeagleBoard-DeviceTrees"
	git_target_dir="/opt/source/dtb-5.15"
	git_branch="v5.15.x"
	git_clone_branch

	git_repo="https://github.com/beagleboard/bb.org-overlays"
	git_target_dir="/opt/source/bb.org-overlays"
	git_clone

	git_repo="https://github.com/mvduin/bbb-pin-utils"
	git_target_dir="/opt/source/bbb-pin-utils"
	git_clone
	if [ -d /opt/source/bbb-pin-utils/ ] ; then
		ln -s /opt/source/bbb-pin-utils/show-pins /usr/local/sbin/
	fi

	git_repo="https://github.com/mvduin/py-uio"
	git_target_dir="/opt/source/py-uio"
	git_clone

	git_repo="https://github.com/mvduin/overlay-utils"
	git_target_dir="/opt/source/overlay-utils"
	git_clone

	git_repo="https://github.com/jadonk/msp430F55xx_usb_uart_bridge"
	git_target_dir="/opt/source/usb_uart_bridge"
	git_clone
}

install_zephyr () {
	if [ -f /usr/local/bin/west ] ; then
		echo "Installing zephyr"
		cd /opt/source/
		echo "west init -m https://github.com/jadonk/zephyr --mr bcf-sdk-0.0.4 bcf-zephyr"
		west init -m https://github.com/jadonk/zephyr --mr bcf-sdk-0.0.4 bcf-zephyr

		if [ -d /opt/source/bcf-zephyr/ ] ; then
			cd /opt/source/bcf-zephyr/
			echo "west update"
			west update
			echo "west zephyr-export"
			west zephyr-export
			echo "pip3 install -r zephyr/scripts/requirements-base.txt"
			pip3 install -r zephyr/scripts/requirements-base.txt

			export ZEPHYR_TOOLCHAIN_VAIRANT=cross-compile
			export CROSS_COMPILE=/usr/bin/arm-none-eabi-
			export ZEPHYR_BASE=/opt/source/bcf-zephyr/zephyr
			export PATH=/opt/source/bcf-zephyr/zephyr/scripts:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

			echo "source /opt/source/bcf-zephyr/zephyr/zephyr-env.sh" >> /root/.bashrc
			export BOARD=beagleconnect_freedom

			echo "west build -d build/sensortest zephyr/samples/boards/beagle_bcf/sensortest -- -DOVERLAY_CONFIG=overlay-subghz.conf"
			west build -d build/sensortest zephyr/samples/boards/beagle_bcf/sensortest -- -DOVERLAY_CONFIG=overlay-subghz.conf
			echo "west build -d build/wpanusb modules/lib/wpanusb_bc -- -DOVERLAY_CONFIG=overlay-subghz.conf"
			west build -d build/wpanusb modules/lib/wpanusb_bc -- -DOVERLAY_CONFIG=overlay-subghz.conf
			echo "west build -d build/bcfserial modules/lib/wpanusb_bc -- -DOVERLAY_CONFIG=overlay-bcfserial.conf -DDTC_OVERLAY_FILE=bcfserial.overlay"
			west build -d build/bcfserial modules/lib/wpanusb_bc -- -DOVERLAY_CONFIG=overlay-bcfserial.conf -DDTC_OVERLAY_FILE=bcfserial.overlay
			echo "west build -d build/greybus modules/lib/greybus/samples/subsys/greybus/net -- -DOVERLAY_CONFIG=overlay-802154-subg.conf"
			west build -d build/greybus modules/lib/greybus/samples/subsys/greybus/net -- -DOVERLAY_CONFIG=overlay-802154-subg.conf
		fi
	fi
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
	install_zephyr
	git config --global --unset-all user.email
	git config --global --unset-all user.name
	chown ${rfs_username}:${rfs_username} /home/${rfs_username}/.gitconfig
fi
other_source_links
#