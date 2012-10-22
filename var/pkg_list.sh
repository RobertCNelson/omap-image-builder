#!/bin/bash

MINIMAL_APT="git-core,nano,pastebinit,wget"
MINIMAL_APT="${MINIMAL_APT},i2c-tools,bsdmainutils"
MINIMAL_APT="${MINIMAL_APT},usb-modeswitch,usbutils"
MINIMAL_APT="${MINIMAL_APT},wireless-tools,wpasupplicant"
MINIMAL_APT="${MINIMAL_APT},openssh-server,apache2,ntpdate,ppp"
MINIMAL_APT="${MINIMAL_APT},btrfs-tools,cpufrequtils,fbset"
MINIMAL_APT="${MINIMAL_APT},initramfs-tools,lsb-release"

#not in squeeze/oneiric
precise_wheezy_plus=",wvdial"

DEBIAN_FW="atmel-firmware,firmware-ralink,libertas-firmware,zd1211-firmware"

