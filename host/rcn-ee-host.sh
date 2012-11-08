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


