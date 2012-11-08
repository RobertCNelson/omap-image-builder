#!/bin/bash

RELEASE_HOST="panda-es-1gb-a3"

#1.0.42ubuntu1 addes raring 13.04 support
#DEBOOT_VER="1.0.42ubuntu1"
DEBOOT_VER="1.0.43"
DEBOOT_HTTP="http://ports.ubuntu.com/pool/main/d/debootstrap"

#DEBOOT_VER="1.0.42"
#DEBOOT_HTTP="http://ftp.us.debian.org/debian/pool/main/d/debootstrap"

DEB_MIRROR="http://rcn-ee.net/deb"

DEB_COMPONENTS="main,contrib,non-free"
UBU_COMPONENTS="main,universe,multiverse"

MIRROR_UBU="--mirror http://ports.ubuntu.com/ubuntu-ports/"
MIRROR_DEB="--mirror http://ftp.us.debian.org/debian/"

PRECISE_CURRENT="ubuntu-12.04"
QUANTAL_CURRENT="ubuntu-12.10"
RARING_CURRENT="ubuntu-13.04"
SQUEEZE_CURRENT="debian-6.0.6"
WHEEZY_CURRENT="debian-wheezy"

