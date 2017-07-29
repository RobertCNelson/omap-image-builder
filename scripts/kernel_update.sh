#!/bin/bash

server="https://rcn-ee.net/repos/latest/jessie-armhf/LATEST-"

current_kernel () {
	if [ -f /tmp/LATEST-${var} ] ; then
		rm -rf /tmp/LATEST-${var} | true
	fi
	wget --quiet --directory-prefix=/tmp/ ${server}${var}
	latest_kernel=$(cat "/tmp/LATEST-${var}" | grep "ABI:1 ${ver}" | awk '{print $3}')
	if [ "x${filter1}" = "x" ] ; then
		old_kernel=$(cat "configs/kernel.data" | grep "${var}" | grep "${ver}" | awk '{print $3}')
	else
		old_kernel=$(cat "configs/kernel.data" | grep -v "${filter1}" | grep -v "${filter2}" | grep "${var}" | grep "${ver}" | awk '{print $3}')
	fi
	if [ ! "x${latest_kernel}" = "x${old_kernel}" ] ; then
		echo "kernel bump: ${git_msg} ($latest_kernel)"
		echo "[sed -i -e 's:'$old_kernel':'$latest_kernel':g']"
		sed -i -e 's:'$old_kernel':'$latest_kernel':g' configs/*.conf
		sed -i -e 's:'$old_kernel':'$latest_kernel':g' configs/kernel.data
		git commit -a -m "kernel bump: ${git_msg} ($latest_kernel)" -s
	else
		echo "x${latest_kernel} = x${old_kernel}"
	fi
}

if [ -f configs/kernel.data ] ; then
	git_msg="3.8.13"
	var="omap-psp"   ; ver="STABLE" ; current_kernel

	git_msg="3.8.13-xenomai"
	filter1="ti"
	filter2="ti"
	var="xenomai"    ; ver="STABLE" ; current_kernel
	unset filter

	git_msg="4.4.x"
	filter1="xenomai"
	filter2="rt"
	var="ti"         ; ver="LTS44"  ; current_kernel
	unset filter

	exit 2

	git_msg="4.4.x-rt"
	var="ti-rt"      ; ver="LTS44"  ; current_kernel

	git_msg="4.4.x-xenomai"
	var="ti-xenomai" ; ver="LTS44"  ; current_kernel

	git_msg="4.12.x-xM"
#	var="armv7"      ; ver="LTS49"  ; current_kernel
	var="armv7"      ; ver="STABLE"  ; current_kernel
#	var="armv7"      ; ver="TESTING"  ; current_kernel

	git_msg="4.9.x"
	filter1="xenomai"
	filter2="rt"
	var="ti"         ; ver="LTS49"  ; current_kernel
	unset filter
fi
