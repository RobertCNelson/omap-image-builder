set -eo pipefail
set -x
export LC_ALL=C

CORES=$(getconf _NPROCESSORS_ONLN)

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
	if [ -f /var/www/html/index.nginx-debian.html ] ; then
		if [ -f /etc/bbb.io/templates/nginx/nginx-autoindex ] ; then
			rm -f /etc/nginx/sites-enabled/default || true
			cp -v /etc/bbb.io/templates/nginx/nginx-autoindex /etc/nginx/sites-enabled/default
			cp -v /etc/bbb.io/templates/nginx/*.html /var/www/html/
			rm -f /var/www/html/index.nginx-debian.html || true
		fi
	fi
}

setup_desktop () {
	#From: xfce4-settings
	if [ -f /usr/share/xfce4/settings/appearance-install-theme ] ; then
		if [ -f /etc/bbb.io/templates/xfce4/xfce4-desktop.xml ] ; then
			mkdir -p /home/${rfs_username}/.config/xfce4/xfconf/xfce-perchannel-xml/ || true
			cp -v /etc/bbb.io/templates/xfce4/xfce4-*.xml /home/${rfs_username}/.config/xfce4/xfconf/xfce-perchannel-xml/
			chown -R ${rfs_username}:${rfs_username} /home/${rfs_username}/.config/
		fi
	fi

#	if [ -f /etc/bbb.io/templates/beagleboard-logo.svg ] ; then
#		update-alternatives --install /usr/share/images/desktop-base/desktop-background desktop-background /etc/bbb.io/templates/beagleboard-logo.svg 100
#	fi

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
	git_repo="https://github.com/beagleboard/BeagleBoard-DeviceTrees.git"
	git_target_dir="/opt/source/dtb-6.12-Beagle"
	git_branch="v6.12.x-Beagle"
	git_clone_branch

	git_repo="https://github.com/TexasInstruments/open-pru.git"
	git_target_dir="/opt/source/open-pru"
	git_clone
}

other_source_links () {
	chown -R ${rfs_username}:${rfs_username} /opt/source/
}

#is_this_qemu

#setup_system
#setup_desktop

if [ -f /usr/bin/git ] ; then
	git config --global user.email "${rfs_username}@example.com"
	git config --global user.name "${rfs_username}"
	install_git_repos
	git config --global --unset-all user.email
	git config --global --unset-all user.name
fi
#other_source_links

### bela customisation proper starts here

### fixup users and hostname

# delete user
if [ ! x"${USER}" = xroot ]; then
	#copy personalised . files to the root user
	GLOBIGNORE=".:.." cp ${HOME}/.bashrc ${HOME}/.profile /root/
	deluser --remove-home ${USER}
fi
USER=root
USERNAME=${USER}
HOME=/root

# clear root password
passwd -d root

# allow ssh login by root
cat << 'HEREDOC' > /etc/ssh/sshd_config.d/bela.conf
PermitRootLogin yes
PasswordAuthentication yes
PermitEmptyPasswords yes
UsePAM no
X11Forwarding yes
PrintMotd yes
PrintLastLog no
AcceptEnv LANG LC_*
HEREDOC

echo 'PINS="/sys/kernel/debug/pinctrl/4084000.pinctrl-pinctrl-single/pins /sys/kernel/debug/pinctrl/f4000.pinctrl-pinctrl-single/pins"' >> ~/.bashrc
echo "export HISTIGNORE='reset:fg:bg:clear:exit:ls:reboot:poweroff:shutdown'" >> ~/.bashrc

echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

### add more apt repos and install more stuff
# get more repos
mkdir -p /etc/sources.list.d
wget https://deb.nodesource.com/setup_22.x
bash -x setup_22.x # includes apt-get update

# apt-get update not needed because it's already performed by node's setup_*.x above
apt-get install -y \
	bela-all \
	bela-utils \
	bela-ide \
	nodejs \
	apt-offline=1.8.6-bela \
	# this line left blank

#fixup for bela-supercollider, which requires libfftw3 but is not explicit about it
apt-get install -y libfftw3-dev

systemctl enable bela-usb-gadgets

#fixups for libevl
echo "/usr/evl/lib/aarch64-linux-gnu/" > /etc/ld.so.conf.d/evl.conf
ln -s /usr/evl/bin/evl /usr/local/bin

# use clang 15 because 14 is buggy
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-15 100
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-15 100
sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-15 100

# dependencies for the IDE
# don't know why we need to resintall libc6-dev, but without it the build of node-pty fails
sudo apt install --reinstall libc6-dev:arm64
npm install --global @parcel/watcher-linux-arm64-glibc@2.5.1 @parcel/watcher@2.5.1 node-pty@1.0.0

# undo the chown done by chroot
chown -R root /opt/

### manually download and install programs
cd /opt
git clone --depth=1 --branch v1.4.4 https://github.com/mattgodbolt/seasocks.git
mkdir -p seasocks/build
cd seasocks/build
cmake .. -DDEFLATE_SUPPORT=OFF -DUNITTESTS=OFF -DSEASOCKS_SHARED=ON
make -j${CORES} seasocks
cmake -P cmake_install.cmake
ldconfig

cd /opt
git clone --depth=1 https://github.com/giuliomoro/am335x_pru_package.git
cd am335x_pru_package/pru_sw/utils/pasm_source
./linuxbuild
cp -v ../../utils/pasm /usr/local/bin

cd /opt
git clone --depth=1 https://github.com/giuliomoro/prudebug.git
cd prudebug
make -j${CORES}
make -j${CORES} prudis
cp -v prudis prudebug /usr/local/bin


cd /opt/source/dtb-6.12-Beagle
git remote add bela https://github.com/BelaPlatform/BeagleBoard-DeviceTrees.git
git fetch bela v6.12.x-Beagle
git checkout v6.12.x-Beagle
git reset --hard bela/v6.12.x-Beagle
# build overlays
./build_n_install.sh # despite the name, it doesn't install when in chroot

### System customisation

# the rtc module resets the date to 1/1/1970 by touching /var/lib/systemd/timesync/clock.
# Fix it by blacklisting it:
echo blacklist rtc_ti_k3 >> /etc/modprobe.d/blacklist.conf

### stop and disable services. Some of these may not be installed, hence the || true
# BB IDE running on :3000
systemctl disable code-server@debian.service || true
# node-red (some dataflow language for IoT)
systemctl disable  nodered  || true
# OTA update client
systemctl disable mender-client || true
# Debian auto updates
systemctl disable unattended-upgrades || true

# disable swap
echo 0 | sudo tee /proc/sys/vm/swappiness # right now
echo vm.swappiness=0 | sudo tee -a /etc/sysctl.conf # after reboot

### Build Bela
echo "~~~~ building Bela ~~~~"
cd /root/Bela
mkdir -p projects
cp -rv templates/basic projects/
export BELA_RT_BACKEND=evl
export IS_AM62_PB2=1
make -C resources/tools/bela-extract-dependencies bela-extract-dependencies install || true
make -j${CORES} all PROJECT=basic AT= || true

# fixup : the above may have failed because of parallelism, (hence the || true) so we retry without -j
make all PROJECT=basic AT=

# prebuild as much stuff as we can think of
make PROJECT=basic build/core/default_libpd_render.o
make -j${CORES} libraries LIBRARIES_ARGS=all
make -j${CORES} lib
#note : doxygen comes prebuilt

#setup repo for future operation
git init .
git remote add origin https://github.com/BelaPlatform/Bela.git
git fetch --depth=1 origin master
git reset --soft origin/master

echo "~~~~ Setting up distcc shorthands ~~~~"
cat << 'HEREDOC' > /usr/local/bin/clang-15-arm64
#!/bin/bash
clang-15 $@
HEREDOC

cat << 'HEREDOC' > /usr/local/bin/clang++-15-arm64
#!/bin/bash
clang++-15 $@ -stdlib=libstdc++
HEREDOC

cat << 'HEREDOC' > /usr/local/bin/distcc-clang
#!/bin/bash
export DISTCC_HOSTS=192.168.7.1
export DISTCC_VERBOSE=0
export DISTCC_FALLBACK=0
export DISTCC_BACKOFF_PERIOD=0
distcc clang-15-arm64 $@
HEREDOC

cat << 'HEREDOC' > /usr/local/bin/distcc-clang++
#!/bin/bash
export DISTCC_HOSTS=192.168.7.1
export DISTCC_VERBOSE=0
export DISTCC_FALLBACK=0
export DISTCC_BACKOFF_PERIOD=0
distcc clang++-15-arm64 $@
HEREDOC

chmod +x /usr/local/bin/clang*-*-arm* /usr/local/bin/distcc-clang*

# more user configuration defaults
cat << 'HEREDOC' > ~/.gdbinit
set history save
set history remove-duplicates 0
set history filename ~/.gdb_history
HEREDOC

cat << 'HEREDOC' > /root/.vimrc
source /usr/share/vim/vim90/defaults.vim
source /usr/share/vim/vim90/syntax/syntax.vim
source /usr/share/vim/vim90/syntax/synload.vim
source /usr/share/vim/vim90/syntax/syncolor.vim
source /usr/share/vim/vim90/filetype.vim
source /usr/share/vim/vim90/ftplugin.vim
source /usr/share/vim/vim90/indent.vim
set mouse=
color desert
set shortmess-=S
HEREDOC

cat << 'HEREDOC' > ~/.gitconfig
# This is Git's per-user configuration file.
[merge]
	tool = vimdiff
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
[diff]
	wordregex = [[:alnum:]]+|[^[:space:]]
HEREDOC

### system configuration

cat << 'HEREDOC' > /etc/modules-load.d/bela.conf
# loading drivers needed by bela on boot

libcomposite
# for MIDI
snd_usb_audio
# for MIDI
snd_usbmidi_lib
# for PRU
pru_rproc
spidev
HEREDOC

cat << 'HEREDOC' > /etc/motd

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.

 ____  _____ _        _
| __ )| ____| |      / \
|  _ \|  _| | |     / _ \
| |_) | |___| |___ / ___ \
|____/|_____|_____/_/   \_\

The platform for ultra-low latency audio and sensor processing

http://bela.io

arm64 image for Bela Gem on PocketBeagle 2

HEREDOC

printf "Bela image, v1.0.0, `date "+%e %B %Y"`\n\n" | tee -a /etc/motd
