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
		sed -i -e 's:'$old_kernel':'$latest_kernel':g' configs/kernel.data
		git commit -a -m "kernel bump: ${git_msg}: ($latest_kernel)" -s
	else
		echo "x${latest_kernel} = x${old_kernel}"
	fi
}

if [ -f configs/kernel.data ] ; then
	server="https://rcn-ee.us/repos/latest/bullseye-arm64/LATEST-"
	git_msg="5.10.x-ti-arm64"
	var="ti-arm64"    ; ver="LTS510"  ; current_kernel
fi
