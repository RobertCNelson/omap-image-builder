#!/bin/bash

RELEASE_HOST="panda-es-1gb-a3"

#Debootstrap, there was no sense tagging releases, when the external debootstrap
#could disappear, so lets use my mirror..

DEBOOT_VER="1.0.44"
DEBOOT_HTTP="http://rcn-ee.net/mirror/debootstrap/"

#Latest versions:
#DEBOOT_HTTP="http://ports.ubuntu.com/pool/main/d/debootstrap"
#DEBOOT_HTTP="http://ftp.us.debian.org/debian/pool/main/d/debootstrap"

#1.0.42ubuntu1 addes raring 13.04 support

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

