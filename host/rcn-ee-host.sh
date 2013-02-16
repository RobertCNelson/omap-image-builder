#!/bin/bash

SYST=$(uname -n)

if [ "x${SYST}" == "xhades" ] || [ "x${SYST}" == "xwork-e6400" ] ; then
	MIRROR_UBU="--mirror http://192.168.0.10:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.0.10:3142/ftp.us.debian.org/debian/"
fi

if [ "x${SYST}" == "xposeidon" ] || [ "x${SYST}" == "x${RELEASE_HOST}" ] ; then
	MIRROR_UBU="--mirror http://192.168.1.95:3142/ports.ubuntu.com/ubuntu-ports"
	MIRROR_DEB="--mirror http://192.168.1.95:3142/ftp.us.debian.org/debian/"
	DEB_MIRROR="http://192.168.1.95:81/dl/mirrors/deb"
fi

system=$(uname -n)
mirror="http://rcn-ee.net/deb"
#FIXME: just temp...
case "${system}" in
hades|work-e6400)
	apt_proxy="192.168.0.10:3142/"
	;;
a53t|zeus|hestia|poseidon|panda-es-1gb-a3|imx6q-sabrelite-1gb)
	apt_proxy="rcn-ee.homeip.net:3142/"
	mirror="http://rcn-ee.homeip.net:81/dl/mirrors/deb"
	;;
*)
	apt_proxy=""
	;;
esac

