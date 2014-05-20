#!/bin/sh -e
#
# Copyright (c) 2013 Robert Nelson <robertcnelson@gmail.com>
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

system=$(uname -n)
HOST_ARCH=$(uname -m)
TIME=$(date +%Y-%m-%d)

DIR="$PWD"
mkdir -p ${DIR}/ignore


if [ -f ${DIR}/.project ] ; then
	. ${DIR}/.project
fi

generic_git () {
	if [ ! -f ${DIR}/git/${git_project_name}/.git/config ] ; then
		git clone ${git_clone_address} ${DIR}/git/${git_project_name}
	fi
}

update_git () {
	if [ -f ${DIR}/git/${git_project_name}/.git/config ] ; then
		cd ${DIR}/git/${git_project_name}/
		git pull --rebase || true
		cd -
	fi
}

git_trees () {
	if [ ! -d ${DIR}/git/ ] ; then
		mkdir -p ${DIR}/git/
	fi

	git_project_name="linux-firmware"
	git_clone_address="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git"
	generic_git
	update_git

	git_project_name="am33x-cm3"
	git_clone_address="https://github.com/RobertCNelson/am33x-cm3.git"
	generic_git
	update_git
}

run_roostock_ng () {
	if [ ! -f ${DIR}/.project ] ; then
		echo "error: [.project] file not defined"
		exit 1
	fi

	if [ ! "${tempdir}" ] ; then
		tempdir=$(mktemp -d -p ${DIR}/ignore)
		echo "tempdir=\"${tempdir}\"" >> ${DIR}/.project
	fi

	/bin/bash -e "${DIR}/scripts/install_dependencies.sh" || { exit 1 ; }
	/bin/sh -e "${DIR}/scripts/debootstrap.sh" || { exit 1 ; }
	/bin/sh -e "${DIR}/scripts/chroot.sh" || { exit 1 ; }
	sudo rm -rf ${tempdir}/ || true
}

git_trees

cd ${DIR}/

run_roostock_ng

#
