#!/bin/sh -e

if [ ! -d /boot/uboot/debug/ ] ; then
	mkdir -p /boot/uboot/debug/ || true
fi

if [ -e /sys/class/drm/card1/card1-DVI-D-1/edid ] ; then
	if which fbset > /dev/null ; then
		echo "fbset:" > /boot/uboot/debug/edid.txt
		fbset >> /boot/uboot/debug/edid.txt
	fi
	if which parse-edid > /dev/null ; then
		echo "edid:" >> /boot/uboot/debug/edid.txt
		parse-edid /sys/class/drm/card1/card1-DVI-D-1/edid >> /boot/uboot/debug/edid.txt
	fi
fi