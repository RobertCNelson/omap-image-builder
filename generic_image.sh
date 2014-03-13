#!/bin/sh -e
#
# Copyright (c) 2014 Robert Nelson <robertcnelson@gmail.com>
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

SYST=$(uname -n)
time=$(date +%Y-%m-%d)

DIR=$PWD
if [ ! -d ${DIR}/deploy ] ; then
	mkdir -p ${DIR}/deploy
fi
if [ ! -d ${DIR}/ignore ] ; then
	mkdir -p ${DIR}/ignore
fi
tempdir=$(mktemp -d -p ${DIR}/ignore)

. ${DIR}/lib/distro.sh

run_rootstock () {
	if [ -f "${DIR}/.project" ] ; then
		rm -f "${DIR}/.project" || true
	fi

	tempdir=$(mktemp -d -p ${DIR}/ignore)

	cat > ${DIR}/.project <<-__EOF__
		tempdir="${tempdir}"
		export_filename="${export_filename}"

		deb_distribution="${deb_distribution}"
		deb_codename="${deb_codename}"
		deb_arch="${deb_arch}"
		deb_include="${deb_include}"
		deb_exclude="${deb_exclude}"
		deb_components="${deb_components}"

		time="${time}"

		apt_proxy="${apt_proxy}"

		rfs_hostname="${rfs_hostname}"

		rfs_username="${rfs_username}"
		rfs_fullname="${rfs_fullname}"
		rfs_password="${rfs_password}"

	__EOF__

	cat ${DIR}/.project
	/bin/sh -e "${DIR}/RootStock-NG.sh" || { exit 1 ; }

	cd ${DIR}/deploy/
	tar cvf ${export_filename}.tar ./${export_filename}
	cd -
}

if [ ! "${apt_proxy}" ] ; then
	apt_proxy=""
fi
if [ ! "${mirror}" ] ; then
	mirror="https://rcn-ee.net/deb"
fi

#FIXME: (something simple)
if [ -f ${DIR}/rcn-ee.host ] ; then
	. ${DIR}/host/rcn-ee-host.sh
fi
if [ -f ${DIR}/circuitco.host ] ; then
	. ${DIR}/host/circuitco-host.sh
fi

if [ ! "${deb_distribution}" ] ; then
	##Selects which base deb_distribution
	deb_distribution="debian"
	#deb_distribution="ubuntu"
fi
if [ ! "${deb_codename}" ] ; then
	if [ "x${deb_distribution}" = "xdebian" ] ; then
		deb_codename="wheezy"
		#deb_codename="jessie"
		#deb_codename="sid"
	fi
	if [ "x${deb_distribution}" = "xubuntu" ] ; then
		#deb_codename="precise"
		#deb_codename="quantal"
		#deb_codename="raring"
		deb_codename="saucy"
		#deb_codename="trusty"
	fi
fi
if [ ! "${deb_arch}" ] ; then
	##Selects which base archtecture
	if [ "x${deb_distribution}" = "xdebian" ] ; then
		deb_arch="armhf"
		#deb_arch="armel"
	fi
	if [ "x${deb_distribution}" = "xubuntu" ] ; then
		deb_arch="armhf"
	fi
fi
if [ ! "${deb_components}" ] ; then
	##Selects which base archtecture
	if [ "x${deb_distribution}" = "xdebian" ] ; then
		deb_components="main contrib non-free"
	fi
	if [ "x${deb_distribution}" = "xubuntu" ] ; then
		deb_components="main universe multiverse"
	fi
fi
if [ ! "${image_name}" ] ; then
	##Generic description
	image_name="demo"
fi
if [ ! "${export_filename}" ] ; then
	##Generic file name
	export_filename="${deb_distribution}-${deb_codename}-${image_name}-${deb_arch}-${time}"
fi
rfs_hostname=${rfs_hostname:-"arm"}
rfs_username=${rfs_username:-"${deb_distribution}"}
rfs_password=${rfs_password:-"temppwd"}
rfs_fullname=${rfs_fullname:-"Demo User"}

run_rootstock

rm -rf ${tempdir} || true

echo "done"
