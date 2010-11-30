#!/bin/bash -e
#
# Copyright (c) 2009-2010 Robert Nelson <robertcnelson@gmail.com>
# Copyright (c) 2010 Mario Di Francesco <mdf-code@digitalexile.it>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Latest can be found at:
# http://github.com/RobertCNelson/omap-image-builder/blob/master/tools/setup_sdcard.sh

#Notes: need to check for: parted, fdisk, wget, mkfs.*, mkimage, md5sum

#Debug Tips
#oem-config username/password
#add: "debug-oem-config" to bootargs

unset MMC
unset SWAP_BOOT_USER
unset DEFAULT_USER
unset DEBUG

#Defaults
RFS=ext4
BOOT_LABEL=boot
RFS_LABEL=rootfs
PARTITION_PREFIX=""

DIR=$PWD
TEMPDIR=$(mktemp -d)

function detect_software {

#Currently only Ubuntu and Debian..
#Working on Fedora...
unset PACKAGE
unset APT

if [ ! $(which mkimage) ];then
 echo "Missing uboot-mkimage"
 PACKAGE="uboot-mkimage "
 APT=1
fi

if [ ! $(which wget) ];then
 echo "Missing wget"
 PACKAGE+="wget "
 APT=1
fi

if [ ! $(which pv) ];then
 echo "Missing pv"
 PACKAGE+="pv "
 APT=1
fi

if [ "${APT}" ];then
 echo "Installing Dependencies"
 sudo aptitude install $PACKAGE
fi
}

function beagle_debug_scripts {

cat > /tmp/boot.cmd <<beagle_debug_cmd
echo "Full Debug"
setenv dvimode 1280x720MR-16@60
setenv vram 12MB
setenv bootcmd 'mmc init; fatload mmc 0:1 0x80300000 uImage; fatload mmc 0:1 0x81600000 uInitrd; bootm 0x80300000 0x81600000'
setenv bootargs earlyprintk debug-oem-config console=ttyS2,115200n8 console=tty0 root=/dev/mmcblk0p2 rootwait ro vram=\${vram} omapfb.mode=dvi:\${dvimode} fixrtc buddy=\${buddy}
boot

beagle_debug_cmd

rm -f /tmp/user.cmd || true
cp /tmp/boot.cmd /tmp/user.cmd

}

function beagle_boot_scripts {

cat > /tmp/boot.cmd <<beagle_boot_cmd
echo "Debug: Demo Image Install"
if test "\${beaglerev}" = "xMA"; then
echo "Kernel is not ready for 1Ghz limiting to 800Mhz"
setenv mpurate 800
fi
if test "\${beaglerev}" = "xMB"; then
echo "Kernel is not ready for 1Ghz limiting to 800Mhz"
setenv mpurate 800
fi
setenv dvimode 1280x720MR-16@60
setenv vram 12MB
setenv bootcmd 'mmc init; fatload mmc 0:1 0x80300000 uImage; fatload mmc 0:1 0x81600000 uInitrd; bootm 0x80300000 0x81600000'
setenv bootargs console=ttyS2,115200n8 console=tty0 root=/dev/mmcblk0p2 rootwait ro vram=\${vram} omapfb.mode=dvi:\${dvimode} fixrtc buddy=\${buddy} mpurate=\${mpurate}
boot

beagle_boot_cmd

 if test "-$ADDON-" = "-pico-"
 then

cat > /tmp/boot.cmd <<beagle_pico_boot_cmd
echo "Debug: Demo Image Install"
if test "\${beaglerev}" = "xMA"; then
echo "Kernel is not ready for 1Ghz limiting to 800Mhz"
setenv mpurate 800
fi
if test "\${beaglerev}" = "xMB"; then
echo "Kernel is not ready for 1Ghz limiting to 800Mhz"
setenv mpurate 800
fi
setenv dvimode 800x600MR-16@60
setenv vram 12MB
setenv bootcmd 'mmc init; fatload mmc 0:1 0x80300000 uImage; fatload mmc 0:1 0x81600000 uInitrd; bootm 0x80300000 0x81600000'
setenv bootargs console=ttyS2,115200n8 console=tty0 root=/dev/mmcblk0p2 rootwait ro vram=\${vram} omapfb.mode=dvi:\${dvimode} fixrtc buddy=\${buddy} mpurate=\${mpurate}
boot

beagle_pico_boot_cmd

 fi

cat > /tmp/user.cmd <<beagle_user_cmd

if test "\${beaglerev}" = "xMA"; then
echo "xMA doesnt have NAND"
exit
else if test "\${beaglerev}" = "xMB"; then
echo "xMB doesnt have NAND"
exit
else
echo "Starting NAND UPGRADE, do not REMOVE SD CARD or POWER till Complete"
fatload mmc 0:1 0x80200000 MLO
nandecc hw
nand erase 0 80000
nand write 0x80200000 0 20000
nand write 0x80200000 20000 20000
nand write 0x80200000 40000 20000
nand write 0x80200000 60000 20000

fatload mmc 0:1 0x80300000 u-boot.bin
nandecc sw
nand erase 80000 160000
nand write 0x80300000 80000 160000
nand erase 260000 20000
echo "UPGRADE Complete, REMOVE SD CARD and DELETE this boot.scr"
exit
fi
fi

beagle_user_cmd

}

function touchbook_boot_scripts {

cat > /tmp/boot.cmd <<touchbook_boot_cmd
setenv dvimode 1024x600MR-16@60
setenv vram 12MB
setenv bootcmd 'mmc init; fatload mmc 0:1 0x80300000 uImage; fatload mmc 0:1 0x81600000 uInitrd; bootm 0x80300000 0x81600000'
setenv bootargs console=tty1 root=/dev/mmcblk0p2 rootwait ro vram=\${vram} omapfb.mode=dvi:\${dvimode} fixrtc mpurate=600
boot

touchbook_boot_cmd

}

function panda_boot_scripts {

cat > /tmp/boot.cmd <<panda_boot_cmd
setenv dvimode 1024x600MR-16@60
setenv vram 16MB
setenv bootcmd 'mmc init; fatload mmc 0:1 0x80300000 uImage; fatload mmc 0:1 0x81600000 uInitrd; bootm 0x80300000 0x81600000'
setenv bootargs console=ttyO2,115200n8 console=tty0 root=/dev/mmcblk0p2 rootwait ro vram=\${vram} omapfb.mode=dvi:\${dvimode} fixrtc mpurate=600
boot

panda_boot_cmd

}
function dl_xload_uboot {
 mkdir -p ${TEMPDIR}/dl/${DIST}
 mkdir -p ${DIR}/dl/${DIST}

case "$SYSTEM" in
    beagle)

if [ "$DEBUG" ];then
 beagle_debug_scripts
else
 beagle_boot_scripts
fi

 #beagle
 MIRROR="http://rcn-ee.net/deb/"

 echo ""
 echo "1 / 7: Downloading X-loader and Uboot"
 echo ""

 wget -c --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}tools/latest/bootloader

 MLO=$(cat ${TEMPDIR}/dl/bootloader | grep "ABI:1 MLO" | awk '{print $3}')
 UBOOT=$(cat ${TEMPDIR}/dl/bootloader | grep "ABI:1 UBOOT" | awk '{print $3}')

 wget -c --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MLO}
 wget -c --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${UBOOT}

 MLO=${MLO##*/}
 UBOOT=${UBOOT##*/}

        ;;
    igepv2)

 #MLO=${MLO##*/}
 #UBOOT=${UBOOT##*/}
 MLO=NA
 UBOOT=NA
        ;;
    touchbook)

touchbook_boot_scripts

 MIRROR="http://rcn-ee.net/deb/"

 echo ""
 echo "1 / 7: Downloading X-loader and Uboot"
 echo ""

 wget -c --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}tools/latest/bootloader

 MLO=$(cat ${TEMPDIR}/dl/bootloader | grep "ABI:5 MLO" | awk '{print $3}')
 UBOOT=$(cat ${TEMPDIR}/dl/bootloader | grep "ABI:5 UBOOT" | awk '{print $3}')

 wget -c --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MLO}
 wget -c --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${UBOOT}

 MLO=${MLO##*/}
 UBOOT=${UBOOT##*/}

        ;;
    panda)

panda_boot_scripts

 MIRROR="http://rcn-ee.net/deb/"

 echo ""
 echo "1 / 7: Downloading X-loader and Uboot"
 echo ""

 wget -c --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}tools/latest/bootloader

 MLO=$(cat ${TEMPDIR}/dl/bootloader | grep "ABI:2 MLO" | awk '{print $3}')
 UBOOT=$(cat ${TEMPDIR}/dl/bootloader | grep "ABI:2 UBOOT" | awk '{print $3}')

 wget -c --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MLO}
 wget -c --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${UBOOT}

 MLO=${MLO##*/}
 UBOOT=${UBOOT##*/}

        ;;
esac

}

function cleanup_sd {

 echo ""
 echo "2 / 7: Unmountting Partitions"
 echo ""

 NUM_MOUNTS=$(mount | grep -v none | grep "$MMC" | wc -l)

 for (( c=1; c<=$NUM_MOUNTS; c++ ))
 do
  DRIVE=$(mount | grep -v none | grep "$MMC" | tail -1 | awk '{print $1}')
  sudo umount ${DRIVE} &> /dev/null || true
 done

 sudo parted -s ${MMC} mklabel msdos
}

function create_partitions {

sudo fdisk -H 255 -S 63 ${MMC} << END
n
p
1
1
+64M
a
1
t
e
p
w
END

sync
sudo partprobe ${MMC}

echo ""
echo "3 / 7: Formatting Boot Partition"
echo ""

sudo mkfs.vfat -F 16 ${MMC}${PARTITION_PREFIX}1 -n ${BOOT_LABEL} &> ${DIR}/sd.log

mkdir ${TEMPDIR}/disk
sudo partprobe ${MMC}
sudo mount ${MMC}${PARTITION_PREFIX}1 ${TEMPDIR}/disk

if [ "$DO_UBOOT" ];then
 if ls ${TEMPDIR}/dl/${MLO} >/dev/null 2>&1;then
 sudo cp -v ${TEMPDIR}/dl/${MLO} ${TEMPDIR}/disk/MLO
 fi

 if ls ${TEMPDIR}/dl/${UBOOT} >/dev/null 2>&1;then
 sudo cp -v ${TEMPDIR}/dl/${UBOOT} ${TEMPDIR}/disk/u-boot.bin
 fi
fi

cd ${TEMPDIR}/disk
sync
cd ${DIR}/
sudo umount ${TEMPDIR}/disk || true
echo "done"

sudo fdisk ${MMC} << ROOTFS
n
p
2


p
w
ROOTFS

sync
sudo partprobe ${MMC}

echo ""
echo "4 / 7: Formating ${RFS} Partition"
echo ""
sudo mkfs.${RFS} ${MMC}${PARTITION_PREFIX}2 -L ${RFS_LABEL} &>> ${DIR}/sd.log

}

function populate_boot {
 echo ""
 echo "5 / 7: Populating Boot Partition"
 echo ""
 sudo partprobe ${MMC}
 sudo mount ${MMC}${PARTITION_PREFIX}1 ${TEMPDIR}/disk

 if ls ${DIR}/vmlinuz-* >/dev/null 2>&1;then
  LINUX_VER=$(ls ${DIR}/vmlinuz-* | awk -F'vmlinuz-' '{print $2}')
  echo "uImage"
  sudo mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000 -n ${LINUX_VER} -d ${DIR}/vmlinuz-* ${TEMPDIR}/disk/uImage
 fi

 if ls ${DIR}/initrd.img-* >/dev/null 2>&1;then
  echo "uInitrd"
  sudo mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d ${DIR}/initrd.img-* ${TEMPDIR}/disk/uInitrd
 fi

if [ "$DO_UBOOT" ];then

#Some boards, like my xM Prototype have the user button polarity reversed
#in that case user.scr gets loaded over boot.scr
if [ "$SWAP_BOOT_USER" ] ; then
 if ls /tmp/boot.cmd >/dev/null 2>&1;then
  sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d /tmp/boot.cmd ${TEMPDIR}/disk/user.scr
  sudo cp /tmp/boot.cmd ${TEMPDIR}/disk/user.cmd
  rm -f /tmp/user.cmd || true
 fi
fi

 if ls /tmp/boot.cmd >/dev/null 2>&1;then
 sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d /tmp/boot.cmd ${TEMPDIR}/disk/boot.scr
 sudo cp /tmp/boot.cmd ${TEMPDIR}/disk/boot.cmd
 rm -f /tmp/boot.cmd || true
 fi

 if ls /tmp/user.cmd >/dev/null 2>&1;then
 sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Reset Nand" -d /tmp/user.cmd ${TEMPDIR}/disk/user.scr
 sudo cp /tmp/user.cmd ${TEMPDIR}/disk/user.cmd
 rm -f /tmp/user.cmd || true
 fi

 #for igepv2 users
 if ls ${TEMPDIR}/disk/boot.scr >/dev/null 2>&1;then
 sudo cp -v ${TEMPDIR}/disk/boot.scr ${TEMPDIR}/disk/boot.ini
 fi

fi

cat > /tmp/readme.txt <<script_readme

These can be run from anywhere, but just in case change to "cd /boot/uboot"

Tools:

 /tools/rebuild_uinitrd.sh

Updated with a custom uImage and modules? Run "./tools/rebuild_uinitrd.sh" to regenerate the uInitrd used on boot...

 /tools/rebuild_uinitrd.sh

Modified boot.cmd or user.cmd and want to run your new boot args? Run "./tools/rebuild_uinitrd.sh" to regenerate boot.scr/user.scr...

 /tools/fix_zippy2.sh

Early zippy2 boards had the wrong id in eeprom (zippy1).. Put a jumper on eeprom pin and run "./tools/fix_zippy2.sh" to update the eeprom contents for zippy2.

Kernel:

 "./tools/latest_kernel.sh"

Update to the latest rcn-ee.net kernel.. still some bugs in running from /boot/uboot..

Applications:

 "./tools/minimal_xfce.sh"

Install minimal xfce shell, make sure to have network setup: "sudo ifconfig -a" then "sudo dhclient usb1" or "eth0/etc"

 "./tools/get_chrome.sh"

Install Google's Chrome web browswer.

DSP work in progress.

 /tools/dsp/*

script_readme

cat > /tmp/rebuild_uinitrd.sh <<rebuild_uinitrd
#!/bin/sh

cd /boot/uboot
sudo mount -o remount,rw /boot/uboot
sudo update-initramfs -u -k \$(uname -r)
sudo mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d /boot/initrd.img-\$(uname -r) /boot/uboot/uInitrd

rebuild_uinitrd

cat > /tmp/boot_scripts.sh <<rebuild_scripts
#!/bin/sh

cd /boot/uboot
sudo mount -o remount,rw /boot/uboot
if ls /boot/uboot/boot.cmd >/dev/null 2>&1;then
sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d /boot/uboot/boot.cmd /boot/uboot/boot.scr
fi
if ls /boot/uboot/serial.cmd >/dev/null 2>&1;then
sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d /boot/uboot/serial.cmd /boot/uboot/boot.scr
fi
sudo cp /boot/uboot/boot.scr /boot/uboot/boot.ini
if ls /boot/uboot/user.cmd >/dev/null 2>&1;then
sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Reset Nand" -d /boot/uboot/user.cmd /boot/uboot/user.scr
fi

rebuild_scripts

cat > /tmp/fix_zippy2.sh <<fix_zippy2
#!/bin/sh
#based off a script from cwillu
#make sure to have a jumper on JP1 (write protect)

if sudo i2cdump -y 2 0x50 | grep "00: 00 01 00 01 01 00 00 00"; then
    sudo i2cset -y 2 0x50 0x03 0x02
fi

fix_zippy2

cat > /tmp/latest_kernel.sh <<latest_kernel
#!/bin/bash
DIST=\$(lsb_release -cs)

#enable testing
#TESTING=1

function run_upgrade {

 wget --no-verbose --directory-prefix=/tmp/ \${KERNEL_DL}

 if [ -f /tmp/install-me.sh ] ; then
  mv /tmp/install-me.sh ~/
 fi

echo "switch to home directory and run"
echo "cd ~/"
echo ". install-me.sh"

}

function check_latest {

 if [ -f /tmp/LATEST ] ; then
  rm -f /tmp/LATEST &> /dev/null
 fi

 wget --no-verbose --directory-prefix=/tmp/ http://rcn-ee.net/deb/\${DIST}/LATEST

 KERNEL_DL=\$(cat /tmp/LATEST | grep "ABI:1 STABLE" | awk '{print \$3}')

 if [ "\$TESTING" ] ; then
  KERNEL_DL=\$(cat /tmp/LATEST | grep "ABI:1 TESTING" | awk '{print \$3}')
 fi

 KERNEL_DL_VER=\$(echo \${KERNEL_DL} | awk -F'/' '{print \$6}')

 CURRENT_KER="v\$(uname -r)"

 if [ \${CURRENT_KER} != \${KERNEL_DL_VER} ]; then
  run_upgrade
 fi
}

check_latest

latest_kernel

cat > /tmp/minimal_xfce.sh <<basic_xfce
#!/bin/sh

sudo aptitude -y install xfce4 gdm xubuntu-gdm-theme xubuntu-artwork xserver-xorg-video-omap3

basic_xfce

cat > /tmp/get_chrome.sh <<latest_chrome
#!/bin/sh

#setup libs

sudo apt-get -y install libnss3-1d unzip libxss1

sudo ln -sf /usr/lib/libsmime3.so /usr/lib/libsmime3.so.12
sudo ln -sf /usr/lib/libnssutil3.so /usr/lib/libnssutil3.so.12
sudo ln -sf /usr/lib/libnss3.so /usr/lib/libnss3.so.12

sudo ln -sf /usr/lib/libplds4.so /usr/lib/libplds4.so.8
sudo ln -sf /usr/lib/libplc4.so /usr/lib/libplc4.so.8
sudo ln -sf /usr/lib/libnspr4.so /usr/lib/libnspr4.so.8

if [ -f /tmp/LATEST ] ; then
 rm -f /tmp/LATEST &> /dev/null
fi

if [ -f /tmp/chrome-linux.zip ] ; then
 rm -f /tmp/chrome-linux.zip &> /dev/null
fi

wget --no-verbose --directory-prefix=/tmp/ http://build.chromium.org/buildbot/snapshots/chromium-rel-arm/LATEST

CHROME_VER=\$(cat /tmp/LATEST)

wget --directory-prefix=/tmp/ http://build.chromium.org/buildbot/snapshots/chromium-rel-arm/\${CHROME_VER}/chrome-linux.zip

sudo mkdir -p /opt/chrome-linux/
sudo chown -R \$USER:\$USER /opt/chrome-linux/

if [ -f /tmp/chrome-linux.zip ] ; then
 unzip -o /tmp/chrome-linux.zip -d /opt/
fi

cat > /tmp/chrome.desktop <<chrome_launcher
[Desktop Entry]
Version=1.0
Type=Application
Encoding=UTF-8
Exec=/opt/chrome-linux/chrome %u
Icon=web-browser
StartupNotify=false
Terminal=false
Categories=X-XFCE;X-Xfce-Toplevel;
OnlyShowIn=XFCE;
Name=Chromium

chrome_launcher

sudo mv /tmp/chrome.desktop /usr/share/applications/chrome.desktop

latest_chrome

cat > /tmp/gst-dsp.sh <<gst_dsp
#!/bin/sh

sudo apt-get -y install git-core pkg-config build-essential gstreamer-tools libgstreamer0.10-dev

git clone git://github.com/felipec/gst-dsp.git
cd gst-dsp
make CROSS_COMPILE= 
sudo make install

cd ..

gst_dsp

cat > /tmp/gst-omapfb.sh <<gst_omapfb
#!/bin/sh

git clone git://github.com/felipec/gst-omapfb.git
cd gst-omapfb
make CROSS_COMPILE= 
sudo make install
cd ..

gst_omapfb

 sudo mkdir -p ${TEMPDIR}/disk/tools/dsp
 sudo cp -v /tmp/readme.txt ${TEMPDIR}/disk/tools/readme.txt
 sudo cp -v /tmp/rebuild_uinitrd.sh ${TEMPDIR}/disk/tools/rebuild_uinitrd.sh
 sudo chmod +x ${TEMPDIR}/disk/tools/rebuild_uinitrd.sh

 sudo cp -v /tmp/boot_scripts.sh ${TEMPDIR}/disk/tools/boot_scripts.sh
 sudo chmod +x ${TEMPDIR}/disk/tools/boot_scripts.sh

 sudo cp -v /tmp/fix_zippy2.sh ${TEMPDIR}/disk/tools/fix_zippy2.sh
 sudo chmod +x ${TEMPDIR}/disk/tools/fix_zippy2.sh

 sudo cp -v /tmp/latest_kernel.sh ${TEMPDIR}/disk/tools/latest_kernel.sh
 sudo chmod +x ${TEMPDIR}/disk/tools/latest_kernel.sh

 sudo cp -v /tmp/minimal_xfce.sh ${TEMPDIR}/disk/tools/minimal_xfce.sh
 sudo chmod +x ${TEMPDIR}/disk/tools/minimal_xfce.sh

 sudo cp -v /tmp/get_chrome.sh ${TEMPDIR}/disk/tools/get_chrome.sh
 sudo chmod +x ${TEMPDIR}/disk/tools/get_chrome.sh

 sudo cp -v /tmp/gst-dsp.sh  ${TEMPDIR}/disk/tools/dsp/gst-dsp.sh
 sudo chmod +x ${TEMPDIR}/disk/tools/dsp/gst-dsp.sh

 sudo cp -v /tmp/gst-omapfb.sh ${TEMPDIR}/disk/tools/dsp/gst-omapfb.sh
 sudo chmod +x ${TEMPDIR}/disk/tools/dsp/gst-omapfb.sh

cd ${TEMPDIR}/disk
sync
cd ${DIR}/
sudo umount ${TEMPDIR}/disk || true

}

function populate_rootfs {
 echo ""
 echo "6 / 7: Populating rootfs Partition"
 echo "Be patient, this may take a few minutes"
 echo ""
 sudo partprobe ${MMC}
 sudo mount ${MMC}${PARTITION_PREFIX}2 ${TEMPDIR}/disk

 if ls ${DIR}/armel-rootfs-*.tgz >/dev/null 2>&1;then
   pv ${DIR}/armel-rootfs-*.tgz | sudo tar --numeric-owner --preserve-permissions -xzf - -C ${TEMPDIR}/disk/
 fi

 if ls ${DIR}/armel-rootfs-*.tar >/dev/null 2>&1;then
   pv ${DIR}/armel-rootfs-*.tar | sudo tar --numeric-owner --preserve-permissions -xf - -C ${TEMPDIR}/disk/
 fi

if [ "$DEFAULT_USER" ] ; then
 sudo rm -f ${TEMPDIR}/disk/var/lib/oem-config/run || true
fi

 if [ "$CREATE_SWAP" ] ; then

  echo ""
  echo "Extra: Creating SWAP File"
  echo ""

  SPACE_LEFT=$(df ${TEMPDIR}/disk/ | grep ${MMC}${PARTITION_PREFIX}2 | awk '{print $4}')

  let SIZE=$SWAP_SIZE*1024

  if [ $SPACE_LEFT -ge $SIZE ] ; then
   sudo dd if=/dev/zero of=${TEMPDIR}/disk/mnt/SWAP.swap bs=1M count=$SWAP_SIZE
   sudo mkswap ${TEMPDIR}/disk/mnt/SWAP.swap
   echo "/mnt/SWAP.swap  none  swap  sw  0 0" | sudo tee -a ${TEMPDIR}/disk/etc/fstab
   else
   echo "FIXME Recovery after user selects SWAP file bigger then whats left not implemented"
  fi
 fi

 cd ${TEMPDIR}/disk/
 sync
 sync
 cd ${DIR}/

 sudo umount ${TEMPDIR}/disk || true

 echo ""
 echo "7 / 7: setup_sdcard.sh script complete"
 echo ""
}

function check_mmc {
 FDISK=$(sudo LC_ALL=C sfdisk -l 2>/dev/null | grep "[Disk] ${MMC}" | awk '{print $2}')

 if test "-$FDISK-" = "-$MMC:-"
 then
  echo ""
  echo "I see..."
  echo "sudo sfdisk -l:"
  sudo LC_ALL=C sfdisk -l 2>/dev/null | grep "[Disk] /dev/" --color=never
  echo ""
  echo "mount:"
  mount | grep -v none | grep "/dev/" --color=never
  echo ""
  read -p "Are you 100% sure, on selecting [${MMC}] (y/n)? "
  [ "$REPLY" == "y" ] || exit
  echo ""
 else
  echo ""
  echo "Are you sure? I Don't see [${MMC}], here is what I do see..."
  echo ""
  echo "sudo sfdisk -l:"
  sudo LC_ALL=C sfdisk -l 2>/dev/null | grep "[Disk] /dev/" --color=never
  echo ""
  echo "mount:"
  mount | grep -v none | grep "/dev/" --color=never
  echo ""
  exit
 fi
}

function check_uboot_type {
 IN_VALID_UBOOT=1
 unset DO_UBOOT

case "$UBOOT_TYPE" in
    beagle)

 SYSTEM=beagle
 unset IN_VALID_UBOOT
 DO_UBOOT=1

        ;;
    beagle-proto)
#hidden: proto button bug

 SYSTEM=beagle
 SWAP_BOOT_USER=1
 unset IN_VALID_UBOOT
 DO_UBOOT=1

        ;;
    igepv2)

 SYSTEM=igepv2
 unset IN_VALID_UBOOT
 DO_UBOOT=1

        ;;
    touchbook)

 SYSTEM=touchbook
 unset IN_VALID_UBOOT
 DO_UBOOT=1

        ;;
    panda)

 SYSTEM=panda
 unset IN_VALID_UBOOT
 DO_UBOOT=1

        ;;
esac

 if [ "$IN_VALID_UBOOT" ] ; then
   usage
 fi
}

function check_addon_type {
 IN_VALID_ADDON=1

 if test "-$ADDON_TYPE-" = "-pico-"
 then
 ADDON=pico
 unset IN_VALID_ADDON
 fi

 if [ "$IN_VALID_ADDON" ] ; then
   usage
 fi
}


function check_fs_type {
 IN_VALID_FS=1

case "$FS_TYPE" in
    ext2)

 RFS=ext2
 unset IN_VALID_FS

        ;;
    ext3)

 RFS=ext3
 unset IN_VALID_FS

        ;;
    ext4)

 RFS=ext4
 unset IN_VALID_FS

        ;;
    btrfs)

  if [ ! $(which mkfs.btrfs) ];then
   echo "Missing btrfs tools"
   sudo aptitude install btrfs-tools
  fi

 RFS=btrfs
 unset IN_VALID_FS

        ;;
esac

 if [ "$IN_VALID_FS" ] ; then
   usage
 fi
}

function usage {
    echo "usage: $(basename $0) --mmc /dev/sdX --uboot <dev board> --swap_file <50Mb mininum>"
cat <<EOF

required options:
--mmc </dev/sdX>
    Unformated MMC Card

Additional/Optional options:
-h --help
    this help

--uboot <dev board>
    beagle - <Bx, C2/C3/C4, xMA, xMB>
    igepv2 - <no u-boot or MLO yet>
    panda - <A1>

--addon <device>
    pico

--use-default-user
    (useful for serial only modes and when oem-config is broken)

--rootfs <fs_type>
    ext3
    ext4 - <set as default>
    btrfs

--boot_label <boot_label>
    boot partition label

--rfs_label <rfs_label>
    rootfs partition label

--swap_file <xxx>
    Creats a Swap file of (xxx)MB's

--debug
    enable all debug options for troubleshooting

EOF
exit
}

function checkparm {
    if [ "$(echo $1|grep ^'\-')" ];then
        echo "E: Need an argument"
        usage
    fi
}

# parse commandline options
while [ ! -z "$1" ]; do
    case $1 in
        -h|--help)
            usage
            MMC=1
            ;;
        --mmc)
            checkparm $2
            MMC="$2"
	    if [[ "${MMC}" =~ "mmcblk" ]]
            then
	        PARTITION_PREFIX="p"
            fi
            check_mmc 
            ;;
        --uboot)
            checkparm $2
            UBOOT_TYPE="$2"
            check_uboot_type 
            ;;
        --addon)
            checkparm $2
            ADDON_TYPE="$2"
            check_addon_type 
            ;;
        --rootfs)
            checkparm $2
            FS_TYPE="$2"
            check_fs_type 
            ;;
        --use-default-user)
            DEFAULT_USER=1
            ;;
        --boot_label)
            checkparm $2
            BOOT_LABEL="$2"
            ;;
        --rfs_label)
            checkparm $2
            RFS_LABEL="$2"
            ;;
        --swap_file)
            checkparm $2
            SWAP_SIZE="$2"
            CREATE_SWAP=1
            ;;
        --debug)
            DEBUG=1
            ;;
    esac
    shift
done

if [ ! "${MMC}" ];then
    usage
fi

 detect_software

if [ "$DO_UBOOT" ];then
 dl_xload_uboot
fi
 cleanup_sd
 create_partitions
 populate_boot
 populate_rootfs


