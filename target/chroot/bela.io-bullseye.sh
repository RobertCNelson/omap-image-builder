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
	if [ -f /etc/bela/templates/bela-motd ] ; then
		cp -v /etc/bela/templates/bela-motd /etc/motd
	fi
}

install_git_repos () {
	git_repo="https://github.com/RobertCNelson/ti-linux-kernel-dev"
	git_target_dir="/opt/source/ti-linux-kernel-dev"
	git_branch="ti-linux-xenomai-bela-4.14.y"
	git_clone_branch

	git_repo="git://git.xenomai.org/xenomai-3.git"
	git_target_dir="/opt/source/xenomai-3"
	git_branch="stable/v3.0.x"
	git_clone_branch

	git_repo="https://github.com/mattgodbolt/seasocks.git"
	git_target_dir="/opt/source/seasocks"
	git_branch="v1.4.4"
	git_clone_branch
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		echo "~~~~ Building Seasocks ~~~~"
			mkdir build
			cd build
			cmake .. -DDEFLATE_SUPPORT=OFF -DUNITTESTS=OFF -DSEASOCKS_SHARED=ON
			make -j${CORES} seasocks
			/usr/bin/cmake -P cmake_install.cmake
			cd /root
			rm -rf /opt/seasocks/build
			ldconfig
	fi

	git_repo="https://github.com/giuliomoro/am335x_pru_package.git"
	git_target_dir="/opt/source/am335x_pru_package"
	git_branch="master"
	git_clone_branch
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		echo "~~~~ Building PRU utils ~~~~"
			make -j${CORES}
			make install
	fi

	###FIXME, bela git assumes xeno-config is under xenomai...
	if [ ! -d /usr/xenomai/bin/ ] ; then
		mkdir -p /usr/xenomai/bin/
	fi
	if [ -f /usr/bin/xeno-config ] ; then
		ln -s /usr/bin/xeno-config /usr/xenomai/bin/xeno-config
	fi

	git_repo="https://github.com/BelaPlatform/Bela.git"
	git_target_dir="/root/Bela"
	git_branch="master"
	git_clone_branch
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		echo "~~~~ Install .deb files ~~~~"
		cd resources/stretch/deb/
			dpkg -i *.deb
			ldconfig
		cd ${git_target_dir}/
		echo "~~~~ Installing Bela ~~~~"
			for DIR in resources/tools/*; do
				[ -d "$DIR" ] && { make -j${CORES} -C "$DIR" install || exit 1; }
			done

			make nostartup
			make idestartup

			mkdir -p /root/Bela/projects
			cp -rv /root/Bela/IDE/templates/basic /root/Bela/projects/
			make -j${CORES} all PROJECT=basic AT=
			make -j${CORES} lib
			make -j${CORES} -f Makefile.libraries all
			ldconfig
	fi

	git_repo="https://github.com/giuliomoro/prudebug.git"
	git_target_dir="/opt/source/prudebug"
	git_branch="master"
	git_clone_branch
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		echo "~~~~ Building prudebug ~~~~"
		make -j${CORES}
		cp -v ./prudebug /usr/bin/
	fi

	git_repo="https://github.com/giuliomoro/Bootloader-Builder.git"
	git_target_dir="/opt/source/Bootloader-Builder"
	git_branch="master"
	git_clone_branch

	git_repo="https://github.com/BelaPlatform/bb.org-overlays.git"
	git_target_dir="/opt/source/bb.org-overlays"
	git_branch="master"
	git_clone_branch
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		echo "~~~~ Building bb.org-overlays ~~~~"
	make clean
	make -j${CORES}
	make install
	cp -v ./tools/beaglebone-universal-io/config-pin /usr/local/bin/
	make clean
	fi

	git_repo="https://github.com/BelaPlatform/rtdm_pruss_irq"
	git_target_dir="/opt/source/rtdm_pruss_irq"
	git_branch="master"
	git_clone_branch

	git_repo="https://github.com/Wasted-Audio/hvcc.git"
	git_target_dir="/opt/source/hvcc"
	git_branch="develop"
	git_clone_branch
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		echo "~~~~ Building hvcc ~~~~"
		pip3 install -e .
	fi

	git_repo="https://github.com/mvduin/overlay-utils"
	git_target_dir="/opt/source/overlay-utils"
	git_clone
}

other_source_links () {
	chown -R ${rfs_username}:${rfs_username} /opt/source/
}

is_this_qemu

setup_system
#setup_desktop

if [ -f /usr/bin/git ] ; then
	git config --global user.email "${rfs_username}@example.com"
	git config --global user.name "${rfs_username}"
	install_git_repos
	git config --global --unset-all user.email
	git config --global --unset-all user.name
	chown ${rfs_username}:${rfs_username} /home/${rfs_username}/.gitconfig
fi
#other_source_links
#
