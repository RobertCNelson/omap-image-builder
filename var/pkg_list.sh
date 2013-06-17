#!/bin/sh -e

#Note: These will be auto installed by chroot.sh script:
#lsb-release initramfs-tools sudo wget

#Base
base_pkgs="nano pastebinit"

#Tools
base_pkgs="${base_pkgs} bsdmainutils i2c-tools fbset hexedit memtester parted read-edid"

#OS
base_pkgs="${base_pkgs} dosfstools btrfs-tools cpufrequtils ntpdate"

#USB Dongles
base_pkgs="${base_pkgs} ppp usb-modeswitch usbutils"

#Server
base_pkgs="${base_pkgs} apache2 openssh-server udhcpd"

#Wireless
base_pkgs="${base_pkgs} wireless-tools wpasupplicant lowpan-tools wvdial lshw"

#Gateone:
base_pkgs="${base_pkgs} python-tornado"

#broken:
#shellinabox
#possible replacment:
#Ajaxterm
