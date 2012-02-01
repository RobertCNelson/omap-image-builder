#!/bin/bash -e
#
# Copyright (c) 2009-2012 Robert Nelson <robertcnelson@gmail.com>
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
# http://github.com/RobertCNelson/omap-image-builder/blob/master/tools/setup_boot.sh

#Notes: need to check for: parted, fdisk, wget, mkfs.*, mkimage, md5sum

#Debug Tips
#oem-config username/password
#add: "debug-oem-config" to bootargs

unset MMC
unset DEFAULT_USER
unset DEBUG
unset USE_BETA_BOOTLOADER
unset FDISK_DEBUG
unset BTRFS_FSTAB
unset SPL_BOOT
unset BOOTLOADER
unset HAS_INITRD
unset DD_UBOOT
unset SECONDARY_KERNEL
unset USE_UENV

unset SVIDEO_NTSC
unset SVIDEO_PAL

MIRROR="http://rcn-ee.net/deb/"
BACKUP_MIRROR="http://rcn-ee.homeip.net:81/dl/mirrors/deb/"
unset RCNEEDOWN

#Defaults
RFS=ext4
BOOT_LABEL=boot
RFS_LABEL=rootfs
PARTITION_PREFIX=""

DIR=$PWD
TEMPDIR=$(mktemp -d)

function check_root {
if [[ $UID -ne 0 ]]; then
 echo "$0 must be run as sudo user or root"
 exit
fi
}

function find_issue {

check_root

#Software Qwerks

if [ "$FDISK_DEBUG" ];then
 echo "Debug: fdisk version:"
 fdisk -v
fi

#Check for gnu-fdisk
#FIXME: GNU Fdisk seems to halt at "Using /dev/xx" when trying to script it..
if fdisk -v | grep "GNU Fdisk" >/dev/null ; then
 echo "Sorry, this script currently doesn't work with GNU Fdisk"
 exit
fi

unset PARTED_ALIGN
if parted -v | grep parted | grep 2.[1-3] >/dev/null ; then
 PARTED_ALIGN="--align cylinder"
fi
}

function detect_software {

unset NEEDS_PACKAGE

if [ ! $(which mkimage) ];then
 echo "Missing uboot-mkimage"
 NEEDS_PACKAGE=1
fi

if [ ! $(which wget) ];then
 echo "Missing wget"
 NEEDS_PACKAGE=1
fi

if [ ! $(which pv) ];then
 echo "Missing pv"
 NEEDS_PACKAGE=1
fi

if [ ! $(which mkfs.vfat) ];then
 echo "Missing mkfs.vfat"
 NEEDS_PACKAGE=1
fi

if [ ! $(which mkfs.btrfs) ];then
 echo "Missing btrfs tools"
 NEEDS_PACKAGE=1
fi

if [ ! $(which partprobe) ];then
 echo "Missing partprobe"
 NEEDS_PACKAGE=1
fi

if [ "${NEEDS_PACKAGE}" ];then
 echo ""
 echo "Your System is Missing some dependencies"
 echo "Ubuntu/Debian: sudo apt-get install uboot-mkimage wget pv dosfstools btrfs-tools parted"
 echo "Fedora: as root: yum install uboot-tools wget pv dosfstools btrfs-progs parted"
 echo "Gentoo: emerge u-boot-tools wget pv dosfstools btrfs-progs parted"
 echo ""
 exit
fi

}

function rcn-ee_down_use_mirror {
 echo ""
 echo "rcn-ee.net down, using mirror"
 echo "-----------------------------"
 MIRROR=${BACKUP_MIRROR}
 RCNEEDOWN=1
}

function dl_bootloader {
 echo ""
 echo "Downloading Device's Bootloader"
 echo "-----------------------------"

 mkdir -p ${TEMPDIR}/dl/${DIST}
 mkdir -p ${DIR}/dl/${DIST}

 ping -c 1 -w 10 www.rcn-ee.net | grep "ttl=" || rcn-ee_down_use_mirror

 wget --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}tools/latest/bootloader

 if [ "$RCNEEDOWN" ];then
  sed -i -e "s/rcn-ee.net/rcn-ee.homeip.net:81/g" ${TEMPDIR}/dl/bootloader
  sed -i -e 's:81/deb/:81/dl/mirrors/deb/:g' ${TEMPDIR}/dl/bootloader
 fi

 if [ "$USE_BETA_BOOTLOADER" ];then
  ABI="ABX2"
 else
  ABI="ABI2"
 fi

 if [ "${SPL_BOOT}" ] ; then
  MLO=$(cat ${TEMPDIR}/dl/bootloader | grep "${ABI}:${BOOTLOADER}:SPL" | awk '{print $2}')
  wget --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MLO}
  MLO=${MLO##*/}
  echo "SPL Bootloader: ${MLO}"
 fi

 UBOOT=$(cat ${TEMPDIR}/dl/bootloader | grep "${ABI}:${BOOTLOADER}:BOOT" | awk '{print $2}')
 wget --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${UBOOT}
 UBOOT=${UBOOT##*/}
 echo "UBOOT Bootloader: ${UBOOT}"
}

function boot_files_template {

cat > ${TEMPDIR}/bootscripts/boot.cmd <<boot_cmd
SCR_FB
SCR_TIMING
SCR_VRAM
setenv console SERIAL_CONSOLE
setenv optargs VIDEO_CONSOLE
setenv mmcroot /dev/mmcblk0p2 ro
setenv mmcrootfstype FINAL_FSTYPE rootwait fixrtc
setenv bootcmd 'fatload mmc 0:1 UIMAGE_ADDR uImage; fatload mmc 0:1 UINITRD_ADDR uInitrd; bootm UIMAGE_ADDR UINITRD_ADDR'
setenv bootargs console=\${console} \${optargs} root=\${mmcroot} rootfstype=\${mmcrootfstype} VIDEO_DISPLAY
boot
boot_cmd

}

function boot_scr_to_uenv_txt {

cat > ${TEMPDIR}/bootscripts/uEnv.cmd <<uenv_boot_cmd
bootenv=boot.scr
loaduimage=fatload mmc \${mmcdev} \${loadaddr} \${bootenv}
mmcboot=echo Running boot.scr script from mmc ...; source \${loadaddr}
uenv_boot_cmd

}

function boot_uenv_txt_template {
#(rcn-ee)in a way these are better then boot.scr, but each target is going to have a slightly different entry point..

cat > ${TEMPDIR}/bootscripts/normal.cmd <<uenv_generic_normalboot_cmd
bootfile=uImage
bootinitrd=uInitrd
address_uimage=UIMAGE_ADDR
address_uinitrd=UINITRD_ADDR

UENV_VRAM

console=SERIAL_CONSOLE

UENV_FB
UENV_TIMING

mmcroot=/dev/mmcblk0p2 ro
mmcrootfstype=FINAL_FSTYPE rootwait fixrtc
uenv_generic_normalboot_cmd

if test "-$ADDON-" = "-ulcd-"
then
cat >> ${TEMPDIR}/bootscripts/normal.cmd <<ulcd_uenv_normalboot_cmd

lcd1=i2c mw 40 00 00; i2c mw 40 04 80; i2c mw 40 0d 05
uenvcmd=i2c dev 1; run lcd1; i2c dev 0

ulcd_uenv_normalboot_cmd
fi

case "$SYSTEM" in
    beagle_bx)

cat >> ${TEMPDIR}/bootscripts/normal.cmd <<uenv_normalboot_cmd
optargs=VIDEO_CONSOLE

mmc_load_uimage=fatload mmc 0:1 \${address_uimage} \${bootfile}
mmc_load_uinitrd=fatload mmc 0:1 \${address_uinitrd} \${bootinitrd}

mmcargs=setenv bootargs console=\${console} \${optargs} mpurate=\${mpurate} buddy=\${buddy} buddy2=\${buddy2} camera=\${camera} VIDEO_DISPLAY root=\${mmcroot} rootfstype=\${mmcrootfstype} musb_hdrc.fifo_mode=5

loaduimage=run mmc_load_uimage; run mmc_load_uinitrd; echo Booting from mmc ...; run mmcargs; bootm \${address_uimage} \${address_uinitrd}
uenv_normalboot_cmd
        ;;
    beagle_cx)

cat >> ${TEMPDIR}/bootscripts/normal.cmd <<uenv_normalboot_cmd
optargs=VIDEO_CONSOLE

mmc_load_uimage=fatload mmc 0:1 \${address_uimage} \${bootfile}
mmc_load_uinitrd=fatload mmc 0:1 \${address_uinitrd} \${bootinitrd}

mmcargs=setenv bootargs console=\${console} \${optargs} mpurate=\${mpurate} buddy=\${buddy} buddy2=\${buddy2} camera=\${camera} VIDEO_DISPLAY root=\${mmcroot} rootfstype=\${mmcrootfstype} musb_hdrc.fifo_mode=5

loaduimage=run mmc_load_uimage; run mmc_load_uinitrd; echo Booting from mmc ...; run mmcargs; bootm \${address_uimage} \${address_uinitrd}
uenv_normalboot_cmd
        ;;
    beagle_xm)

cat >> ${TEMPDIR}/bootscripts/normal.cmd <<uenv_normalboot_cmd
optargs=VIDEO_CONSOLE

mmc_load_uimage=fatload mmc 0:1 \${address_uimage} \${bootfile}
mmc_load_uinitrd=fatload mmc 0:1 \${address_uinitrd} \${bootinitrd}

mmcargs=setenv bootargs console=\${console} \${optargs} mpurate=\${mpurate} buddy=\${buddy} buddy2=\${buddy2} camera=\${camera} VIDEO_DISPLAY root=\${mmcroot} rootfstype=\${mmcrootfstype}

loaduimage=run mmc_load_uimage; run mmc_load_uinitrd; echo Booting from mmc ...; run mmcargs; bootm \${address_uimage} \${address_uinitrd}
uenv_normalboot_cmd
        ;;
    bone)

cat >> ${TEMPDIR}/bootscripts/normal.cmd <<uenv_normalboot_cmd
rcn_mmcloaduimage=fatload mmc 0:1 \${address_uimage} \${bootfile}
mmc_load_uinitrd=fatload mmc 0:1 \${address_uinitrd} \${bootinitrd}

mmc_args=run bootargs_defaults;setenv bootargs \${bootargs} root=\${mmcroot} rootfstype=\${mmcrootfstype} ip=\${ip_method}

mmc_load_uimage=run rcn_mmcloaduimage; run mmc_load_uinitrd; echo Booting from mmc ...; run mmc_args; bootm \${address_uimage} \${address_uinitrd}
uenv_normalboot_cmd
        ;;
esac

}

function tweak_boot_scripts {
 #debug -|-
# echo "NetInstall Boot Script: Generic"
# echo "-----------------------------"
# cat ${TEMPDIR}/bootscripts/netinstall.cmd

 if test "-$ADDON-" = "-pico-"
 then
  VIDEO_TIMING="640x480MR-16@60"
 fi

 if test "-$ADDON-" = "-ulcd-"
 then
  VIDEO_TIMING="800x480MR-16@60"
 fi

 if [ "$SVIDEO_NTSC" ];then
  VIDEO_TIMING="ntsc"
  VIDEO_OMAPFB_MODE=tv
 fi

 if [ "$SVIDEO_PAL" ];then
  VIDEO_TIMING="pal"
  VIDEO_OMAPFB_MODE=tv
 fi

 #Set uImage boot address
 sed -i -e 's:UIMAGE_ADDR:'$UIMAGE_ADDR':g' ${TEMPDIR}/bootscripts/*.cmd

 #Set uInitrd boot address
 sed -i -e 's:UINITRD_ADDR:'$UINITRD_ADDR':g' ${TEMPDIR}/bootscripts/*.cmd

 #Set the Serial Console
 sed -i -e 's:SERIAL_CONSOLE:'$SERIAL_CONSOLE':g' ${TEMPDIR}/bootscripts/*.cmd

 #Set filesystem type
 sed -i -e 's:FINAL_FSTYPE:'$RFS':g' ${TEMPDIR}/bootscripts/*.cmd

 if [ "${IS_OMAP}" ] ; then
  sed -i -e 's/ETH_ADDR //g' ${TEMPDIR}/bootscripts/*.cmd

  #setenv defaultdisplay VIDEO_OMAPFB_MODE
  #setenv dvimode VIDEO_TIMING
  #setenv vram 12MB
  sed -i -e 's:SCR_VRAM:setenv vram 12MB:g' ${TEMPDIR}/bootscripts/*.cmd
  sed -i -e 's:SCR_FB:setenv defaultdisplay VIDEO_OMAPFB_MODE:g' ${TEMPDIR}/bootscripts/*.cmd
  sed -i -e 's:SCR_TIMING:setenv dvimode VIDEO_TIMING:g' ${TEMPDIR}/bootscripts/*.cmd

  #defaultdisplay=VIDEO_OMAPFB_MODE
  #dvimode=VIDEO_TIMING
  #vram=12MB
  sed -i -e 's:UENV_VRAM:vram=12MB:g' ${TEMPDIR}/bootscripts/*.cmd
  sed -i -e 's:UENV_FB:defaultdisplay=VIDEO_OMAPFB_MODE:g' ${TEMPDIR}/bootscripts/*.cmd
  sed -i -e 's:UENV_TIMING:dvimode=VIDEO_TIMING:g' ${TEMPDIR}/bootscripts/*.cmd

  #vram=\${vram} omapfb.mode=\${defaultdisplay}:\${dvimode} omapdss.def_disp=\${defaultdisplay}
  sed -i -e 's:VIDEO_DISPLAY:TMP_VRAM TMP_OMAPFB TMP_OMAPDSS:g' ${TEMPDIR}/bootscripts/*.cmd
  sed -i -e 's:TMP_VRAM:'vram=\${vram}':g' ${TEMPDIR}/bootscripts/*.cmd
  sed -i -e 's/TMP_OMAPFB/'omapfb.mode=\${defaultdisplay}:\${dvimode}'/g' ${TEMPDIR}/bootscripts/*.cmd
  sed -i -e 's:TMP_OMAPDSS:'omapdss.def_disp=\${defaultdisplay}':g' ${TEMPDIR}/bootscripts/*.cmd

  FILE="*.cmd"
  if [ "$SERIAL_MODE" ];then
   #Set the Serial Console: console=CONSOLE
   sed -i -e 's:SERIAL_CONSOLE:'$SERIAL_CONSOLE':g' ${TEMPDIR}/bootscripts/*.cmd

   #omap3/4: In serial mode, NetInstall needs all traces of VIDEO removed..
   #drop: vram=\${vram}
   sed -i -e 's:'vram=\${vram}' ::g' ${TEMPDIR}/bootscripts/${FILE}

   #omapfb.mode=\${defaultdisplay}:\${dvimode} omapdss.def_disp=\${defaultdisplay}
   sed -i -e 's:'\${defaultdisplay}'::g' ${TEMPDIR}/bootscripts/${FILE}
   sed -i -e 's:'\${dvimode}'::g' ${TEMPDIR}/bootscripts/${FILE}
   #omapfb.mode=: omapdss.def_disp=
   sed -i -e "s/omapfb.mode=: //g" ${TEMPDIR}/bootscripts/${FILE}
   #uenv seems to have an extra space (beagle_xm)
   sed -i -e 's:omapdss.def_disp= ::g' ${TEMPDIR}/bootscripts/${FILE}
   sed -i -e 's:omapdss.def_disp=::g' ${TEMPDIR}/bootscripts/${FILE}
  else
   #Set the Video Console
   sed -i -e 's:VIDEO_CONSOLE:console=tty0:g' ${TEMPDIR}/bootscripts/*.cmd

   sed -i -e 's:VIDEO_OMAPFB_MODE:'$VIDEO_OMAPFB_MODE':g' ${TEMPDIR}/bootscripts/${FILE}
   sed -i -e 's:VIDEO_TIMING:'$VIDEO_TIMING':g' ${TEMPDIR}/bootscripts/${FILE}
  fi
 fi

 if [ "${IS_IMX}" ] ; then
  sed -i -e 's/ETH_ADDR //g' ${TEMPDIR}/bootscripts/*.cmd

  #not used:
  sed -i -e 's:SCR_VRAM::g' ${TEMPDIR}/bootscripts/*.cmd
  sed -i -e 's:UENV_VRAM::g' ${TEMPDIR}/bootscripts/*.cmd

  #setenv framebuffer VIDEO_FB
  #setenv dvimode VIDEO_TIMING
  sed -i -e 's:SCR_FB:setenv framebuffer VIDEO_FB:g' ${TEMPDIR}/bootscripts/*.cmd
  sed -i -e 's:SCR_TIMING:setenv dvimode VIDEO_TIMING:g' ${TEMPDIR}/bootscripts/*.cmd

  #framebuffer=VIDEO_FB
  #dvimode=VIDEO_TIMING
  sed -i -e 's:UENV_FB:framebuffer=VIDEO_FB:g' ${TEMPDIR}/bootscripts/*.cmd
  sed -i -e 's:UENV_TIMING:dvimode=VIDEO_TIMING:g' ${TEMPDIR}/bootscripts/*.cmd

  #video=\${framebuffer}:${dvimode}
  sed -i -e 's/VIDEO_DISPLAY/'video=\${framebuffer}:\${dvimode}'/g' ${TEMPDIR}/bootscripts/*.cmd

  FILE="*.cmd"
  if [ "$SERIAL_MODE" ];then
   #Set the Serial Console: console=CONSOLE
   sed -i -e 's:SERIAL_CONSOLE:'$SERIAL_CONSOLE':g' ${TEMPDIR}/bootscripts/*.cmd

   #mx53: In serial mode, NetInstall needs all traces of VIDEO removed..

   #video=\${framebuffer}:\${dvimode}
   sed -i -e 's:'\${framebuffer}'::g' ${TEMPDIR}/bootscripts/${FILE}
   sed -i -e 's:'\${dvimode}'::g' ${TEMPDIR}/bootscripts/${FILE}
   #video=:
   sed -i -e "s/video=: //g" ${TEMPDIR}/bootscripts/${FILE}
   sed -i -e "s/video=://g" ${TEMPDIR}/bootscripts/${FILE}
  else
   #Set the Video Console
   #Set the Video Console
   sed -i -e 's:VIDEO_CONSOLE:console=tty0:g' ${TEMPDIR}/bootscripts/*.cmd

   sed -i -e 's:VIDEO_FB:'$VIDEO_FB':g' ${TEMPDIR}/bootscripts/${FILE}
   sed -i -e 's:VIDEO_TIMING:'$VIDEO_TIMING':g' ${TEMPDIR}/bootscripts/${FILE}
  fi
 fi

 if [ "$PRINTK" ];then
  sed -i 's/bootargs/bootargs earlyprintk/g' ${TEMPDIR}/bootscripts/*.cmd
 fi
}

function setup_bootscripts {
 mkdir -p ${TEMPDIR}/bootscripts/

 if [ "$USE_UENV" ];then
  boot_uenv_txt_template
  tweak_boot_scripts
 else
  boot_files_template
  boot_scr_to_uenv_txt
  tweak_boot_scripts
 fi
}

function unmount_all_drive_partitions {
 echo ""
 echo "Unmounting Partitions"
 echo "-----------------------------"

 NUM_MOUNTS=$(mount | grep -v none | grep "$MMC" | wc -l)

 for (( c=1; c<=$NUM_MOUNTS; c++ ))
 do
  DRIVE=$(mount | grep -v none | grep "$MMC" | tail -1 | awk '{print $1}')
  umount ${DRIVE} &> /dev/null || true
 done

 parted --script ${MMC} mklabel msdos
}

function uboot_in_boot_partition {
 echo ""
 echo "Using fdisk to create BOOT Partition"
 echo "-----------------------------"

 #With util-linux, 2.18.x/2.19.x, fdisk no longer has dos/cylinders mode on by default
 unset FDISK_DOS

 if test $(fdisk -v | grep -o -E '2\.[0-9]+' | cut -d'.' -f2) -ge 18 ; then
  FDISK_DOS="-c=dos -u=cylinders"
 fi

fdisk ${FDISK_DOS} ${MMC} << END
n
p
1
1
+64M
t
e
p
w
END

 sync

 echo "Setting Boot Partition's Boot Flag"
 echo "-----------------------------"
 parted --script ${MMC} set 1 boot on

if [ "$FDISK_DEBUG" ];then
 echo "Debug: Partition 1 layout:"
 echo "-----------------------------"
 fdisk -l ${MMC}
 echo "-----------------------------"
fi
}

function dd_uboot_before_boot_partition {
 echo ""
 echo "Using dd to place bootloader before BOOT Partition"
 echo "-----------------------------"
 dd if=${TEMPDIR}/dl/${UBOOT} of=${MMC} seek=1 bs=1024

 #For now, lets default to fat16, but this could be ext2/3/4
 echo "Using parted to create BOOT Partition"
 echo "-----------------------------"
 parted --script ${PARTED_ALIGN} ${MMC} mkpart primary fat16 10 100
 #parted --script ${PARTED_ALIGN} ${MMC} mkpart primary ext3 10 100
}

function format_boot_partition {
 echo "Formating Boot Partition"
 echo "-----------------------------"
 mkfs.vfat -F 16 ${MMC}${PARTITION_PREFIX}1 -n ${BOOT_LABEL}
}

function create_partitions {

if [ "${DD_UBOOT}" ] ; then
 dd_uboot_before_boot_partition
else
 uboot_in_boot_partition
fi

 format_boot_partition
}

function populate_boot {
 echo "Populating Boot Partition"
 echo "-----------------------------"

 partprobe ${MMC}
 mkdir -p ${TEMPDIR}/disk

 if mount -t vfat ${MMC}${PARTITION_PREFIX}1 ${TEMPDIR}/disk; then

  if [ "${SPL_BOOT}" ] ; then
   if [ -f ${TEMPDIR}/dl/${MLO} ]; then
    cp -v ${TEMPDIR}/dl/${MLO} ${TEMPDIR}/disk/MLO
   fi
  fi

  if [ ! "${DD_UBOOT}" ] ; then
   if [ -f ${TEMPDIR}/dl/${UBOOT} ]; then
    if echo ${UBOOT} | grep img > /dev/null 2>&1;then
     cp -v ${TEMPDIR}/dl/${UBOOT} ${TEMPDIR}/disk/u-boot.img
    else
     cp -v ${TEMPDIR}/dl/${UBOOT} ${TEMPDIR}/disk/u-boot.bin
    fi
   fi
  fi

 VER=${primary_id}

 if [ "$SECONDARY_KERNEL" ] ; then
  VER=${secondary_id}
  if [ ! -f ${DIR}/vmlinuz-*${kernelid}* ] ; then
   VER=${primary_id}
  fi
 fi

 VMLINUZ="vmlinuz-*${VER}*"
 UIMAGE="uImage"

 if [ -f ${DIR}/${VMLINUZ} ]; then
  LINUX_VER=$(ls ${DIR}/${VMLINUZ} | awk -F'vmlinuz-' '{print $2}')
  echo "Using mkimage to create uImage"
  echo "-----------------------------"
  mkimage -A arm -O linux -T kernel -C none -a ${ZRELADD} -e ${ZRELADD} -n ${LINUX_VER} -d ${DIR}/${VMLINUZ} ${TEMPDIR}/disk/${UIMAGE}
 fi

 INITRD="initrd.img-*${VER}*"
 UINITRD="uInitrd"

 if [ -f ${DIR}/${INITRD} ]; then
  echo "Using mkimage to create uInitrd"
  echo "-----------------------------"
  #check_initrd
  mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d ${DIR}/${INITRD} ${TEMPDIR}/disk/${UINITRD}
 fi

if [ "$DO_UBOOT" ];then

if [ "${USE_UENV}" ] ; then
 echo "Copying uEnv.txt based boot scripts to Boot Partition"
 echo "-----------------------------"
 cp -v ${TEMPDIR}/bootscripts/normal.cmd ${TEMPDIR}/disk/uEnv.txt
 cat  ${TEMPDIR}/bootscripts/normal.cmd
 echo "-----------------------------"
else
 echo "Copying boot.scr based boot scripts to Boot Partition"
 echo "-----------------------------"
 cp -v ${TEMPDIR}/bootscripts/uEnv.cmd ${TEMPDIR}/disk/uEnv.txt
 cat ${TEMPDIR}/bootscripts/uEnv.cmd
 echo "-----------------------------"
 mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d ${TEMPDIR}/bootscripts/boot.cmd ${TEMPDIR}/disk/boot.scr
 cp -v ${TEMPDIR}/bootscripts/boot.cmd ${TEMPDIR}/disk/boot.cmd
 cat ${TEMPDIR}/bootscripts/boot.cmd
 echo "-----------------------------"
fi
fi

cd ${TEMPDIR}/disk
sync
cd ${DIR}/
umount ${TEMPDIR}/disk || true

 echo "Finished populating Boot Partition"
 echo "-----------------------------"
else
 echo "-----------------------------"
 echo "Unable to mount ${MMC}${PARTITION_PREFIX}1 at ${TEMPDIR}/disk to complete populating Boot Partition"
 echo "Please retry running the script, sometimes rebooting your system helps."
 echo "-----------------------------"
 exit
fi
}

function check_mmc {

 FDISK=$(LC_ALL=C fdisk -l 2>/dev/null | grep "[Disk] ${MMC}" | awk '{print $2}')

 if test "-$FDISK-" = "-$MMC:-"
 then
  echo ""
  echo "I see..."
  echo "fdisk -l:"
  LC_ALL=C fdisk -l 2>/dev/null | grep "[Disk] /dev/" --color=never
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
  echo "fdisk -l:"
  LC_ALL=C fdisk -l 2>/dev/null | grep "[Disk] /dev/" --color=never
  echo ""
  echo "mount:"
  mount | grep -v none | grep "/dev/" --color=never
  echo ""
  exit
 fi
}

function is_omap {
 IS_OMAP=1
 SPL_BOOT=1
 UIMAGE_ADDR="0x80300000"
 UINITRD_ADDR="0x81600000"
 SERIAL_CONSOLE="${SERIAL},115200n8"
 ZRELADD="0x80008000"
 SUBARCH="omap"
 VIDEO_CONSOLE="console=tty0"
 VIDEO_DRV="omapfb.mode=dvi"
 VIDEO_OMAPFB_MODE="dvi"
 VIDEO_TIMING="1280x720MR-16@60"
 primary_id="x"
 secondary_id="d"
}

function is_imx53 {
 IS_IMX=1
 UIMAGE_ADDR="0x70800000"
 UINITRD_ADDR="0x72100000"
 SERIAL_CONSOLE="${SERIAL},115200"
 ZRELADD="0x70008000"
 SUBARCH="imx"
 VIDEO_CONSOLE="console=tty0"
 VIDEO_FB="mxcdi1fb"
 VIDEO_TIMING="RGB24,1280x720M@60"
 primary_id="imx"
 secondary_id="imx"
}

function check_uboot_type {
 unset DO_UBOOT

case "$UBOOT_TYPE" in
    beagle_bx)

 SYSTEM=beagle_bx
 unset IN_VALID_UBOOT
 DO_UBOOT=1
 BOOTLOADER="BEAGLEBOARD_BX"
 SERIAL="ttyO2"
 USE_UENV=1
 DISABLE_ETH=1
 is_omap

        ;;
    beagle_cx)

 SYSTEM=beagle_cx
 unset IN_VALID_UBOOT
 DO_UBOOT=1
 BOOTLOADER="BEAGLEBOARD_CX"
 SERIAL="ttyO2"
 USE_UENV=1
 DISABLE_ETH=1
 is_omap

        ;;
    beagle_xm)

 SYSTEM=beagle_xm
 unset IN_VALID_UBOOT
 DO_UBOOT=1
 BOOTLOADER="BEAGLEBOARD_XM"
 SERIAL="ttyO2"
 USE_UENV=1
 is_omap

        ;;
    bone)

 SYSTEM=bone
 unset IN_VALID_UBOOT
 DO_UBOOT=1
 BOOTLOADER="BEAGLEBONE_A"
 SERIAL="ttyO0"
 USE_UENV=1
 is_omap
# mmc driver fails to load with this setting
# UIMAGE_ADDR="0x80200000"
# UINITRD_ADDR="0x80A00000"
 primary_id="psp"
 unset VIDEO_OMAPFB_MODE
 unset VIDEO_TIMING

        ;;
    igepv2)

 SYSTEM=igepv2
 unset IN_VALID_UBOOT
 DO_UBOOT=1
 BOOTLOADER="IGEP00X0"
 SERIAL="ttyO2"
 is_omap

        ;;
    panda)

 SYSTEM=panda
 unset IN_VALID_UBOOT
 DO_UBOOT=1
 BOOTLOADER="PANDABOARD"
 SERIAL="ttyO2"
 is_omap

        ;;
    panda_es)

 SYSTEM=panda
 unset IN_VALID_UBOOT
 DO_UBOOT=1
 BOOTLOADER="PANDABOARD_ES"
 SERIAL="ttyO2"
 is_omap

        ;;
    touchbook)

 SYSTEM=touchbook
 unset IN_VALID_UBOOT
 DO_UBOOT=1
 BOOTLOADER="TOUCHBOOK"
 SERIAL="ttyO2"
 is_omap
 VIDEO_TIMING="1024x600MR-16@60"

        ;;
    crane)

 SYSTEM=crane
 unset IN_VALID_UBOOT
 DO_UBOOT=1
 BOOTLOADER="CRANEBOARD"
 SERIAL="ttyO2"
 is_omap

        ;;
    mx53loco)

 SYSTEM=mx53loco
 unset IN_VALID_UBOOT
 DO_UBOOT=1
 DD_UBOOT=1
 BOOTLOADER="MX53LOCO"
 SERIAL="ttymxc0"
 is_imx53

        ;;
esac

 if [ "$IN_VALID_UBOOT" ] ; then
   usage
 fi
}

function check_addon_type {
 IN_VALID_ADDON=1

case "$ADDON_TYPE" in
    pico)

 ADDON=pico
 unset IN_VALID_ADDON

        ;;
    ulcd)

 ADDON=ulcd
 unset IN_VALID_ADDON

        ;;
esac

 if [ "$IN_VALID_ADDON" ] ; then
   usage
 fi
}

function usage {
    echo "usage: sudo $(basename $0) --mmc /dev/sdX --uboot <dev board>"
cat <<EOF

Bugs email: "bugs at rcn-ee.com"

Required Options:
--mmc </dev/sdX>

--uboot <dev board>
    beagle_bx - <BeagleBoard Ax/Bx>
    beagle_cx - <BeagleBoard Cx>
    beagle_xm - <BeagleBoard xMA/B/C>
    bone - <BeagleBone Ax>
    igepv2 - <serial mode only>
    panda - <PandaBoard Ax>
    panda_es - <PandaBoard ES>

--addon <device>
    pico
    ulcd <beagle xm>

--boot_label <boot_label>
    boot partition label

--svideo-ntsc
    force ntsc mode for svideo

--svideo-pal
    force pal mode for svideo

Additional Options:
-h --help
    this help

--probe-mmc
    List all partitions: sudo ./setup_boot.sh --probe-mmc

Debug:
--debug
    enable all debug options for troubleshooting

--fdisk-debug
    debug fdisk/parted/etc..

EOF
exit
}

function checkparm {
    if [ "$(echo $1|grep ^'\-')" ];then
        echo "E: Need an argument"
        usage
    fi
}

IN_VALID_UBOOT=1

# parse commandline options
while [ ! -z "$1" ]; do
    case $1 in
        -h|--help)
            usage
            MMC=1
            ;;
        --probe-mmc)
            MMC="/dev/idontknow"
            check_root
            check_mmc
            ;;
        --mmc)
            checkparm $2
            MMC="$2"
	    if [[ "${MMC}" =~ "mmcblk" ]]
            then
	        PARTITION_PREFIX="p"
            fi
            find_issue
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
        --svideo-ntsc)
            SVIDEO_NTSC=1
            ;;
        --svideo-pal)
            SVIDEO_PAL=1
            ;;
        --boot_label)
            checkparm $2
            BOOT_LABEL="$2"
            ;;
        --earlyprintk)
            PRINTK=1
            ;;
        --use-beta-bootloader)
            USE_BETA_BOOTLOADER=1
            ;;
        --secondary-kernel)
            SECONDARY_KERNEL=1
            ;;
        --debug)
            DEBUG=1
            ;;
        --fdisk-debug)
            FDISK_DEBUG=1
            ;;
    esac
    shift
done

if [ ! "${MMC}" ];then
    echo "ERROR: --mmc undefined"
    usage
fi

if [ "$IN_VALID_UBOOT" ] ; then
    echo "ERROR: --uboot undefined"
    usage
fi

 find_issue
 detect_software
 dl_bootloader

if [ "$DO_UBOOT" ];then
 setup_bootscripts
fi
 unmount_all_drive_partitions
 create_partitions
 populate_boot

