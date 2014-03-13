#!/bin/sh -e
#
# Copyright (c) 2012-2013 Robert Nelson <robertcnelson@gmail.com>
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

DIR=$PWD

. ${DIR}/.project

check_defines () {
	if [ ! "${tempdir}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: tempdir undefined"
		exit 1
	fi

	if [ ! "${deb_distribution}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: deb_distribution undefined"
		exit 1
	fi

	if [ ! "${deb_codename}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: deb_codename undefined"
		exit 1
	fi

	if [ ! "${deb_arch}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: deb_arch undefined"
		exit 1
	fi

	if [ ! "${apt_proxy}" ] ; then
		apt_proxy=""
	fi

	if [ ! "${deb_mirror}" ] ; then
		case "${deb_distribution}" in
		debian)
			deb_mirror="ftp.us.debian.org/debian/"
			;;
		ubuntu)
			deb_mirror="ports.ubuntu.com/ubuntu-ports/"
			;;
		esac
	fi

	if [ "${deb_include}" ] ; then
		include="--include ${deb_include}"
	else
		include=""
	fi

	if [ "${exclude_pkgs_list}" ] ; then
		exclude="--exclude ${exclude_pkgs_list}"
	else
		exclude=""
	fi
}

report_size () {
	echo "Log: Size of: [${tempdir}]: `du -sh ${tempdir} 2>/dev/null | awk '{print $1}'`"
}

check_defines

echo "Log: Creating: [${deb_distribution}] [${deb_codename}] image for: [${deb_arch}]"

if [ "${apt_proxy}" ] ; then
	echo "Log: using apt proxy: [${apt_proxy}]"
fi

echo "Log: Running: debootstrap in [${tempdir}]"
echo "Log: [sudo debootstrap ${include} ${exclude} --foreign --arch ${deb_arch} ${deb_codename} ${tempdir} http://${apt_proxy}${deb_mirror}]"
sudo debootstrap ${include} ${exclude} --foreign --arch ${deb_arch} ${deb_codename} ${tempdir} http://${apt_proxy}${deb_mirror}
report_size
#
