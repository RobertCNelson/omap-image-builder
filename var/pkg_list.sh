#!/bin/bash

#Note: These will be auto installed by chroot.sh script:
#lsb-release initramfs-tools sudo wget

#Base
base_pkgs="git-core nano pastebinit"

#Tools
base_pkgs="${base_pkgs} bsdmainutils i2c-tools fbset hexedit"

#OS
base_pkgs="${base_pkgs} dosfstools btrfs-tools cpufrequtils ntpdate"

#USB Dongles
base_pkgs="${base_pkgs} ppp usb-modeswitch usbutils"

#Server
base_pkgs="${base_pkgs} apache2 openssh-server"

#Wireless
base_pkgs="${base_pkgs} wireless-tools wpasupplicant"

