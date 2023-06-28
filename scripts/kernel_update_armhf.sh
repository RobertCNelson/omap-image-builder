#!/bin/bash

current_kernel () {
	if [ -f /tmp/LATEST-${var} ] ; then
		rm -rf /tmp/LATEST-${var} | true
	fi
	wget --quiet --directory-prefix=/tmp/ ${server}${var}
	unset latest_kernel
	latest_kernel=$(cat "/tmp/LATEST-${var}" | grep "ABI:1 ${ver}" | awk '{print $3}')
	#echo "latest_kernel=[${latest_kernel}]"
	unset old_kernel
	if [ "x${filter1}" = "x" ] ; then
		old_kernel=$(cat "configs/kernel.data" | grep "${var}" | grep "${ver}" | awk '{print $3}')
		#echo "old_kernel=[${old_kernel}]"
	else
		old_kernel=$(cat "configs/kernel.data" | grep -v "${filter1}" | grep -v "${filter2}" | grep "${var}" | grep "${ver}" | awk '{print $3}')
		unset filter1
		unset filter2
		#echo "old_kernel=[${old_kernel}]"
	fi
	if [ ! "x${latest_kernel}" = "x${old_kernel}" ] ; then
		echo "kernel bump: ${git_msg}: ($latest_kernel)"
		echo "[sed -i -e 's:'$old_kernel':'$latest_kernel':g']"
		sed -i -e 's:'$old_kernel':'$latest_kernel':g' configs/*.conf
		sed -i -e 's:'$old_kernel':'$latest_kernel':g' configs/legacy/*.conf
		sed -i -e 's:'$old_kernel':'$latest_kernel':g' configs/kernel.data
		git commit -a -m "kernel bump: ${git_msg}: ($latest_kernel)" -s
	else
		echo "x${latest_kernel} = x${old_kernel}"
	fi
}

if [ -f configs/kernel.data ] ; then
	server="https://rcn-ee.us/repos/latest/bullseye-armhf/LATEST-"
	git_msg="5.4.x-xM"
	var="armv7"      ; ver="LTS54"       ; current_kernel

	git_msg="5.10.x-xM"
	var="armv7"      ; ver="LTS510"       ; current_kernel

	git_msg="4.19.x-bone-rt"
	var="bone-rt"    ; ver="LTS419" ; current_kernel

	git_msg="5.14.x-bone"
	var="omap-psp"   ; ver="V514X" ; current_kernel

	git_msg="5.15.x-bone"
	var="omap-psp"   ; ver="LTS515" ; current_kernel

	git_msg="4.14.x-ti"
	filter1="rt"
	filter2="arm64"
	var="ti"         ; ver="LTS414"  ; current_kernel

	git_msg="4.14.x-ti-rt"
	var="ti-rt"      ; ver="LTS414"  ; current_kernel

	git_msg="4.19.x-ti"
	filter1="rt"
	filter2="arm64"
	var="ti"         ; ver="LTS419"  ; current_kernel

	git_msg="4.19.x-ti-rt"
	var="ti-rt"      ; ver="LTS419"  ; current_kernel

	git_msg="5.4.x-ti"
	filter1="rt"
	filter2="arm64"
	var="ti"         ; ver="LTS54"  ; current_kernel

	git_msg="5.4.x-ti-rt"
	var="ti-rt"      ; ver="LTS54"  ; current_kernel

	git_msg="5.10.x-ti"
	filter1="rt"
	filter2="arm64"
	var="ti"         ; ver="LTS510"  ; current_kernel

	git_msg="5.10.x-ti-rt"
	var="ti-rt"      ; ver="LTS510"  ; current_kernel
fi
