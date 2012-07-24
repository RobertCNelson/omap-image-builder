#!/bin/bash
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
# http://github.com/RobertCNelson/omap-image-builder/blob/master/tools/setup_sdcard.sh

#REQUIREMENTS:
#uEnv.txt bootscript support

MIRROR="http://rcn-ee.net/deb"
BACKUP_MIRROR="http://rcn-ee.homeip.net:81/dl/mirrors/deb"

BOOT_LABEL="boot"
PARTITION_PREFIX=""

unset MMC
unset USE_BETA_BOOTLOADER
unset ADDON

unset FDISK_DEBUG

unset SVIDEO_NTSC
unset SVIDEO_PAL

unset LOCAL_SPL
unset LOCAL_BOOTLOADER
unset USE_LOCAL_BOOT

#Defaults
ROOTFS_TYPE=ext4
ROOTFS_LABEL=rootfs

DIR="$PWD"
TEMPDIR=$(mktemp -d)

function is_element_of {
	testelt=$1
	for validelt in $2 ; do
		[ $testelt = $validelt ] && return 0
	done
	return 1
}

#########################################################################
#
#  Define valid "--rootfs" root filesystem types.
#
#########################################################################

VALID_ROOTFS_TYPES="ext2 ext3 ext4 btrfs"

function is_valid_rootfs_type {
	if is_element_of $1 "${VALID_ROOTFS_TYPES}" ] ; then
		return 0
	else
		return 1
	fi
}

#########################################################################
#
#  Define valid "--addon" values.
#
#########################################################################

VALID_ADDONS="pico ulcd"

function is_valid_addon {
	if is_element_of $1 "${VALID_ADDONS}" ] ; then
		return 0
	else
		return 1
	fi
}

function check_root {
	if [[ $UID -ne 0 ]]; then
		echo "$0 must be run as sudo user or root"
		exit
	fi
}

function find_issue {

check_root

ROOTFS=$(ls "${DIR}/" | grep rootfs)
if [ "-${ROOTFS}-" != "--" ] ; then
 echo "Debug: ARM rootfs: ${ROOTFS}"
else
 echo "Error: no armel-rootfs-* file"
 echo "Make sure your in the right dir..."
 exit
fi

	unset HAS_INITRD
	INITRD=$(ls "${DIR}/" | grep initrd.img | head -n 1)
	if [ "-${INITRD}-" != "--" ] ; then
		echo "Debug: image has initrd.img: HAS_INITRD=1"
		HAS_INITRD=1
	fi

#Software Qwerks

if [ "$FDISK_DEBUG" ];then
 echo "Debug: fdisk version:"
 fdisk -v
fi

}

function check_for_command {
	if ! which "$1" > /dev/null ; then
		echo -n "You're missing command $1"
		NEEDS_COMMAND=1
		if [ -n "$2" ] ; then
			echo -n " (consider installing package $2)"
		fi
		echo
	fi
}

function detect_software {
	unset NEEDS_COMMAND

	check_for_command mkfs.vfat dosfstools
	check_for_command wget wget
	check_for_command pv pv
	check_for_command parted parted
	check_for_command partprobe parted

	if [ "${NEEDS_COMMAND}" ] ; then
		echo ""
		echo "Your system is missing some dependencies"
		echo "Ubuntu/Debian: sudo apt-get install wget pv dosfstools parted"
		echo "Fedora: as root: yum install wget pv dosfstools parted"
		echo "Gentoo: emerge wget pv dosfstools parted"
		echo ""
		exit
	fi

	#Check for gnu-fdisk
	#FIXME: GNU Fdisk seems to halt at "Using /dev/xx" when trying to script it..
	if fdisk -v | grep "GNU Fdisk" >/dev/null ; then
		echo "Sorry, this script currently doesn't work with GNU Fdisk."
		echo "Install the version of fdisk from your distribution's util-linux package."
		exit
	fi

	unset PARTED_ALIGN
	if parted -v | grep parted | grep 2.[1-3] >/dev/null ; then
		PARTED_ALIGN="--align cylinder"
	fi
}

function rcn-ee_down_use_mirror {
	echo "rcn-ee.net down, switching to slower backup mirror"
	echo "-----------------------------"
	MIRROR=${BACKUP_MIRROR}
	RCNEEDOWN=1
}

function local_bootloader {
 echo ""
 echo "Using Locally Stored Device Bootloader"
 echo "-----------------------------"

 if [ "${SPL_BOOT}" ] ; then
  MLO=${LOCAL_SPL}
  echo "SPL Bootloader: ${MLO}"
 fi

 UBOOT=${LOCAL_BOOTLOADER}
 echo "Bootloader: ${UBOOT}"
}

function dl_bootloader {
	echo ""
	echo "Downloading Device's Bootloader"
	echo "-----------------------------"

	mkdir -p ${TEMPDIR}/dl/${DIST}
	mkdir -p "${DIR}/dl/${DIST}"

	unset RCNEEDOWN
	echo "attempting to use rcn-ee.net for dl files [10 second time out]..."
	wget -T 10 -t 1 --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}/tools/latest/bootloader

	if [ ! -f ${TEMPDIR}/dl/bootloader ] ; then
		rcn-ee_down_use_mirror
		wget --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}/tools/latest/bootloader
	fi

	if [ ! -f ${TEMPDIR}/dl/bootloader ] ; then
		echo "ERROR: Network Failure, are you connected to the internet?"
		echo "Unable to download bootloader from main and backup server."
		exit
	fi

	if [ "${RCNEEDOWN}" ] ; then
		sed -i -e "s/rcn-ee.net/rcn-ee.homeip.net:81/g" ${TEMPDIR}/dl/bootloader
		sed -i -e 's:81/deb/:81/dl/mirrors/deb/:g' ${TEMPDIR}/dl/bootloader
	fi

	if [ "${USE_BETA_BOOTLOADER}" ] ; then
		ABI="ABX2"
	else
		ABI="ABI2"
	fi

	if [ "${spl_name}" ] ; then
		MLO=$(cat ${TEMPDIR}/dl/bootloader | grep "${ABI}:${BOOTLOADER}:SPL" | awk '{print $2}')
		wget --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MLO}
		MLO=${MLO##*/}
		echo "SPL Bootloader: ${MLO}"
	else
		unset MLO
	fi

	if [ "${boot_name}" ] ; then
		UBOOT=$(cat ${TEMPDIR}/dl/bootloader | grep "${ABI}:${BOOTLOADER}:BOOT" | awk '{print $2}')
		wget --directory-prefix=${TEMPDIR}/dl/ ${UBOOT}
		UBOOT=${UBOOT##*/}
		echo "UBOOT Bootloader: ${UBOOT}"
	else
		unset UBOOT
	fi
}

function boot_uenv_txt_template {
	#(rcn-ee)in a way these are better then boot.scr
	#but each target is going to have a slightly different entry point..

	if [ ! "${USE_KMS}" ] ; then
		cat > ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			UENV_VRAM
			UENV_FB
			UENV_TIMING
		__EOF__
	fi

	if [ ! "${USE_ZIMAGE}" ] ; then
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			kernel_file=uImage
			initrd_file=uInitrd
			boot=bootm
		__EOF__
	else
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			kernel_file=zImage
			initrd_file=initrd.img
			boot=bootz
		__EOF__
	fi

	cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
		dtb_file=${dtb_file}

		console=SERIAL_CONSOLE

		mmcroot=/dev/mmcblk0p2 ro
		mmcrootfstype=FINAL_FSTYPE rootwait fixrtc

		xyz_load_image=fatload mmc 0:1 ${kernel_addr} \${kernel_file}
		xyz_load_initrd=fatload mmc 0:1 ${initrd_addr} \${initrd_file}; setenv initrd_size \${filesize}
		xyz_load_dtb=fatload mmc 0:1 ${dtb_addr} \${dtb_file}

		mmcargs=setenv bootargs console=\${console} \${optargs} VIDEO_DISPLAY root=\${mmcroot} rootfstype=\${mmcrootfstype} \${device_args}
	__EOF__

	case "${SYSTEM}" in
	beagle_bx|beagle_cx)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			xyz_mmcboot=run xyz_load_image; run xyz_load_initrd; echo Booting from mmc ...

			optargs=VIDEO_CONSOLE
			deviceargs=setenv device_args buddy=\${buddy} buddy2=\${buddy2} musb_hdrc.fifo_mode=5
			loaduimage=run xyz_mmcboot; run deviceargs; run mmcargs; \${boot} ${kernel_addr} ${initrd_addr}:\${initrd_size}

		__EOF__
		;;
	beagle_xm)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			xyz_mmcboot=run xyz_load_image; run xyz_load_initrd; echo Booting from mmc ...

			optargs=VIDEO_CONSOLE
			deviceargs=setenv device_args buddy=\${buddy} buddy2=\${buddy2}
			loaduimage=run xyz_mmcboot; run deviceargs; run mmcargs; \${boot} ${kernel_addr} ${initrd_addr}:\${initrd_size}

		__EOF__
		;;
	crane|igepv2|mx51evk|mx53loco|panda|panda_es)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			xyz_mmcboot=run xyz_load_image; run xyz_load_initrd; echo Booting from mmc ...

			optargs=VIDEO_CONSOLE
			deviceargs=setenv device_args
			loaduimage=run xyz_mmcboot; run deviceargs; run mmcargs; \${boot} ${kernel_addr} ${initrd_addr}:\${initrd_size}

		__EOF__
		;;
	mx51evk_dtb|mx53loco_dtb)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			initrd_high=0xffffffff
			fdt_high=0xffffffff

			xyz_mmcboot=run xyz_load_image; run xyz_load_initrd; run xyz_load_dtb; echo Booting from mmc ...

			optargs=VIDEO_CONSOLE
			deviceargs=setenv device_args
			loaduimage=run xyz_mmcboot; run deviceargs; run mmcargs; \${boot} ${kernel_addr} ${initrd_addr}:\${initrd_size} ${dtb_addr}

		__EOF__
		;;
	bone)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			xyz_mmcboot=run xyz_load_image; run xyz_load_initrd; echo Booting from mmc ...

			deviceargs=setenv device_args ip=\${ip_method}
			mmc_load_uimage=run xyz_mmcboot; run bootargs_defaults; run deviceargs; run mmcargs; \${boot} ${kernel_addr} ${initrd_addr}

		__EOF__
		;;
	bone_zimage)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			xyz_mmcboot=run xyz_load_image; run xyz_load_initrd; echo Booting from mmc ...

			deviceargs=setenv device_args ip=\${ip_method}
			mmc_load_uimage=run xyz_mmcboot; run bootargs_defaults; run deviceargs; run mmcargs; \${boot} ${kernel_addr} ${initrd_addr}
			loaduimage=run xyz_mmcboot; run deviceargs; run mmcargs; \${boot} ${kernel_addr} ${initrd_addr}:\${initrd_size}

		__EOF__
		;;

	esac
}

function tweak_boot_scripts {
	unset KMS_OVERRIDE

	if [ "x${ADDON}" == "xpico" ] ; then
		VIDEO_TIMING="640x480MR-16@60"
		KMS_OVERRIDE=1
		KMS_VIDEOA="video=DVI-D-1"
		KMS_VIDEO_RESOLUTION="640x480"
	fi

	if [ "x${ADDON}" == "xulcd" ] ; then
		VIDEO_TIMING="800x480MR-16@60"
		KMS_OVERRIDE=1
		KMS_VIDEOA="video=DVI-D-1"
		KMS_VIDEO_RESOLUTION="800x480"
	fi

	if [ "${SVIDEO_NTSC}" ] ; then
		VIDEO_TIMING="ntsc"
		VIDEO_OMAPFB_MODE="tv"
		##FIXME need to figure out KMS Options
	fi

	if [ "${SVIDEO_PAL}" ] ; then
		VIDEO_TIMING="pal"
		VIDEO_OMAPFB_MODE="tv"
		##FIXME need to figure out KMS Options
	fi

	ALL="*.cmd"
	#Set the Serial Console
	sed -i -e 's:SERIAL_CONSOLE:'$SERIAL_CONSOLE':g' ${TEMPDIR}/bootscripts/${ALL}

	#Set filesystem type
	sed -i -e 's:FINAL_FSTYPE:'$ROOTFS_TYPE':g' ${TEMPDIR}/bootscripts/${ALL}

	if [ "${HAS_OMAPFB_DSS2}" ] && [ ! "${SERIAL_MODE}" ] ; then
		#UENV_VRAM -> vram=12MB
		sed -i -e 's:UENV_VRAM:vram=VIDEO_OMAP_RAM:g' ${TEMPDIR}/bootscripts/${ALL}
		sed -i -e 's:VIDEO_OMAP_RAM:'$VIDEO_OMAP_RAM':g' ${TEMPDIR}/bootscripts/${ALL}

		#UENV_FB -> defaultdisplay=dvi
		sed -i -e 's:UENV_FB:defaultdisplay=VIDEO_OMAPFB_MODE:g' ${TEMPDIR}/bootscripts/${ALL}
		sed -i -e 's:VIDEO_OMAPFB_MODE:'$VIDEO_OMAPFB_MODE':g' ${TEMPDIR}/bootscripts/${ALL}

		#UENV_TIMING -> dvimode=1280x720MR-16@60
		sed -i -e 's:UENV_TIMING:dvimode=VIDEO_TIMING:g' ${TEMPDIR}/bootscripts/${ALL}
		sed -i -e 's:VIDEO_TIMING:'$VIDEO_TIMING':g' ${TEMPDIR}/bootscripts/${ALL}

		#optargs=VIDEO_CONSOLE -> optargs=console=tty0
		sed -i -e 's:VIDEO_CONSOLE:console=tty0:g' ${TEMPDIR}/bootscripts/${ALL}

		#Setting up:
		#vram=\${vram} omapfb.mode=\${defaultdisplay}:\${dvimode} omapdss.def_disp=\${defaultdisplay}
		sed -i -e 's:VIDEO_DISPLAY:TMP_VRAM TMP_OMAPFB TMP_OMAPDSS:g' ${TEMPDIR}/bootscripts/${ALL}
		sed -i -e 's:TMP_VRAM:'vram=\${vram}':g' ${TEMPDIR}/bootscripts/${ALL}
		sed -i -e 's/TMP_OMAPFB/'omapfb.mode=\${defaultdisplay}:\${dvimode}'/g' ${TEMPDIR}/bootscripts/${ALL}
		sed -i -e 's:TMP_OMAPDSS:'omapdss.def_disp=\${defaultdisplay}':g' ${TEMPDIR}/bootscripts/${ALL}
	fi

	if [ "${HAS_IMX_BLOB}" ] && [ ! "${SERIAL_MODE}" ] ; then
		#not used:
		sed -i -e 's:UENV_VRAM::g' ${TEMPDIR}/bootscripts/${ALL}

		#framebuffer=VIDEO_FB
		sed -i -e 's:UENV_FB:framebuffer=VIDEO_FB:g' ${TEMPDIR}/bootscripts/${ALL}
		sed -i -e 's:VIDEO_FB:'$VIDEO_FB':g' ${TEMPDIR}/bootscripts/${ALL}

		#dvimode=VIDEO_TIMING
		sed -i -e 's:UENV_TIMING:dvimode=VIDEO_TIMING:g' ${TEMPDIR}/bootscripts/${ALL}
		sed -i -e 's:VIDEO_TIMING:'$VIDEO_TIMING':g' ${TEMPDIR}/bootscripts/${ALL}

		#optargs=VIDEO_CONSOLE -> optargs=console=tty0
		sed -i -e 's:VIDEO_CONSOLE:console=tty0:g' ${TEMPDIR}/bootscripts/${ALL}

		#video=\${framebuffer}:${dvimode}
		sed -i -e 's/VIDEO_DISPLAY/'video=\${framebuffer}:\${dvimode}'/g' ${TEMPDIR}/bootscripts/${ALL}
	fi

	if [ "${USE_KMS}" ] && [ ! "${SERIAL_MODE}" ] ; then
		#optargs=VIDEO_CONSOLE
		sed -i -e 's:VIDEO_CONSOLE:console=tty0:g' ${TEMPDIR}/bootscripts/${ALL}

		if [ "${KMS_OVERRIDE}" ] ; then
			sed -i -e 's/VIDEO_DISPLAY/'${KMS_VIDEOA}:${KMS_VIDEO_RESOLUTION}'/g' ${TEMPDIR}/bootscripts/${ALL}
		else
			sed -i -e 's:VIDEO_DISPLAY ::g' ${TEMPDIR}/bootscripts/${ALL}
		fi
	fi

	if [ "${SERIAL_MODE}" ] ; then
		#In pure serial mode, remove all traces of VIDEO
		if [ ! "${USE_KMS}" ] ; then
			sed -i -e 's:UENV_VRAM::g' ${TEMPDIR}/bootscripts/${ALL}
			sed -i -e 's:UENV_FB::g' ${TEMPDIR}/bootscripts/${ALL}
			sed -i -e 's:UENV_TIMING::g' ${TEMPDIR}/bootscripts/${ALL}
		fi
		sed -i -e 's:VIDEO_DISPLAY ::g' ${TEMPDIR}/bootscripts/${ALL}

		#optargs=VIDEO_CONSOLE -> optargs=
		sed -i -e 's:VIDEO_CONSOLE::g' ${TEMPDIR}/bootscripts/${ALL}
	fi
}

function setup_bootscripts {
	mkdir -p ${TEMPDIR}/bootscripts/
	boot_uenv_txt_template
	tweak_boot_scripts
}

function drive_error_ro {
	echo "-----------------------------"
	echo "Error: for some reason your SD card is not writable..."
	echo "Check: is the write protect lever set the locked position?"
	echo "Check: do you have another SD card reader?"
	echo "-----------------------------"
	echo "Script gave up..."

	exit
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

	LC_ALL=C parted --script ${MMC} mklabel msdos | grep "Error:" && drive_error_ro
}

function omap_fatfs_boot_part {
	echo ""
	echo "Using fdisk to create an omap compatible fatfs BOOT partition"
	echo "-----------------------------"

	fdisk ${MMC} <<-__EOF__
		n
		p
		1

		+64M
		t
		e
		p
		w
	__EOF__

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

function dd_to_drive {
	echo ""
	echo "Using dd to place bootloader on drive"
	echo "-----------------------------"
	if [ ! "${LOCAL_BOOTLOADER}" ] ; then
		dd if=${TEMPDIR}/dl/${UBOOT} of=${MMC} seek=1 bs=1024
	else
		dd if=${UBOOT} of=${MMC} seek=1 bs=1024
	fi
	bootloader_installed=1

	#For now, lets default to fat16, but this could be ext2/3/4
	echo "Using parted to create BOOT Partition"
	echo "-----------------------------"
	parted --script ${PARTED_ALIGN} ${MMC} mkpart primary fat16 10 100
	#parted --script ${PARTED_ALIGN} ${MMC} mkpart primary ext3 10 100
}

function calculate_rootfs_partition {
 echo "Creating rootfs ${ROOTFS_TYPE} Partition"
 echo "-----------------------------"

 unset END_BOOT
 END_BOOT=$(LC_ALL=C parted -s ${MMC} unit mb print free | grep primary | awk '{print $3}' | cut -d "M" -f1)

 unset END_DEVICE
 END_DEVICE=$(LC_ALL=C parted -s ${MMC} unit mb print free | grep Free | tail -n 1 | awk '{print $2}' | cut -d "M" -f1)

 parted --script ${PARTED_ALIGN} ${MMC} mkpart primary ${ROOTFS_TYPE} ${END_BOOT} ${END_DEVICE}
 sync

 if [ "$FDISK_DEBUG" ];then
  echo "Debug: ${ROOTFS_TYPE} Partition"
  echo "-----------------------------"
  echo "parted --script ${PARTED_ALIGN} ${MMC} mkpart primary ${ROOTFS_TYPE} ${END_BOOT} ${END_DEVICE}"
  fdisk -l ${MMC}
 fi
}

function format_boot_partition {
	echo "Formating Boot Partition"
	echo "-----------------------------"
	mkfs.vfat -F 16 ${MMC}${PARTITION_PREFIX}1 -n ${BOOT_LABEL}
}

function format_rootfs_partition {
 echo "Formating rootfs Partition as ${ROOTFS_TYPE}"
 echo "-----------------------------"
 mkfs.${ROOTFS_TYPE} ${MMC}${PARTITION_PREFIX}2 -L ${ROOTFS_LABEL}
}

function create_partitions {
	unset bootloader_installed
	case "${bootloader_location}" in
	omap_fatfs_boot_part)
		omap_fatfs_boot_part
		;;
	dd_to_drive)
		dd_to_drive
		;;
	esac
	calculate_rootfs_partition
	format_boot_partition
	format_rootfs_partition
}

function populate_boot {
	echo "Populating Boot Partition"
	echo "-----------------------------"

	partprobe ${MMC}

	if [ ! -d ${TEMPDIR}/disk ] ; then
		mkdir -p ${TEMPDIR}/disk
	fi

	if mount -t vfat ${MMC}${PARTITION_PREFIX}1 ${TEMPDIR}/disk; then
		mkdir -p ${TEMPDIR}/disk/backup

		if [ ! "${bootloader_installed}" ] ; then
			if [ "${spl_name}" ] ; then
				if [ -f ${TEMPDIR}/dl/${MLO} ]; then
					cp -v ${TEMPDIR}/dl/${MLO} ${TEMPDIR}/disk/${spl_name}
					cp -v ${TEMPDIR}/dl/${MLO} ${TEMPDIR}/disk/backup/${spl_name}
					echo "-----------------------------"
				fi
			fi

			if [ "${boot_name}" ] ; then
				if [ -f ${TEMPDIR}/dl/${UBOOT} ]; then
					cp -v ${TEMPDIR}/dl/${UBOOT} ${TEMPDIR}/disk/${boot_name}
					cp -v ${TEMPDIR}/dl/${UBOOT} ${TEMPDIR}/disk/backup/${boot_name}
					echo "-----------------------------"
				fi
			fi
		fi

		VER=${primary_id}

		UIMAGE="uImage"
		VMLINUZ_FILE=$(ls "${DIR}/" | grep vmlinuz- | grep ${VER})
		if [ "-${VMLINUZ_FILE}-" != "--" ] ; then
			LINUX_VER=$(ls "${DIR}/" | grep vmlinuz- | grep ${VER} | awk -F'vmlinuz-' '{print $2}')
			if [ ! "${USE_ZIMAGE}" ] ; then
				echo "Using mkimage to create uImage"
				mkimage -A arm -O linux -T kernel -C none -a ${load_addr} -e ${load_addr} -n ${LINUX_VER} -d "${DIR}/${VMLINUZ_FILE}" ${TEMPDIR}/disk/${UIMAGE}
				echo "-----------------------------"
			fi
			echo "Copying Kernel image:"
			cp -v "${DIR}/${VMLINUZ_FILE}" ${TEMPDIR}/disk/zImage
			echo "-----------------------------"
		fi

		UINITRD="uInitrd"
		INITRD_FILE=$(ls "${DIR}/" | grep initrd.img- | grep ${VER})
		if [ "-${INITRD_FILE}-" != "--" ] ; then
			if [ ! "${USE_ZIMAGE}" ] ; then
				echo "Using mkimage to create uInitrd"
				mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d "${DIR}/${INITRD_FILE}" ${TEMPDIR}/disk/${UINITRD}
				echo "-----------------------------"
			fi
			echo "Copying Kernel initrd:"
			cp -v "${DIR}/${INITRD_FILE}" ${TEMPDIR}/disk/initrd.img
			echo "-----------------------------"
		fi

		echo "Copying uEnv.txt based boot scripts to Boot Partition"
		echo "-----------------------------"
		cp -v ${TEMPDIR}/bootscripts/normal.cmd ${TEMPDIR}/disk/uEnv.txt
		cat  ${TEMPDIR}/bootscripts/normal.cmd
		echo "-----------------------------"

		cat > ${TEMPDIR}/disk/SOC.sh <<-__EOF__
			#!/bin/sh
			format=1.0
			board=${BOOTLOADER}
			kernel_addr=${kernel_addr}
			initrd_addr=${initrd_addr}
			load_addr=${load_addr}
			dtb_addr=${dtb_addr}
			dtb_file=${dtb_file}

		__EOF__

		echo "Debug:"
		cat ${TEMPDIR}/disk/SOC.sh

cat > ${TEMPDIR}/readme.txt <<script_readme

These can be run from anywhere, but just in case change to "cd /boot/uboot"

Tools:

 "./tools/update_boot_files.sh"

Updated with a custom uImage and modules or modified the boot.cmd/user.com files with new boot args? Run "./tools/update_boot_files.sh" to regenerate all boot files...

Applications:

 "./tools/minimal_lxde.sh"

Install minimal lxde shell, make sure to have network setup: "sudo ifconfig -a" then "sudo dhclient usb1" or "eth0/etc"

Drivers:
 "./build_omapdrm_drivers.sh"

omapdrm kms video driver, at some point this will be packaged by default for newer distro's at that time this script wont be needed...

script_readme

	cat > ${TEMPDIR}/update_boot_files.sh <<-__EOF__
		#!/bin/sh

		if ! id | grep -q root; then
		        echo "must be run as root"
		        exit
		fi

		cd /boot/uboot
		mount -o remount,rw /boot/uboot

		if [ ! -f /boot/initrd.img-\$(uname -r) ] ; then
		        update-initramfs -c -k \$(uname -r)
		else
		        update-initramfs -u -k \$(uname -r)
		fi

		if [ -f /boot/initrd.img-\$(uname -r) ] ; then
		        cp -v /boot/initrd.img-\$(uname -r) /boot/uboot/initrd.img
		fi

		#legacy uImage support:
		if [ -f /boot/uboot/uImage ] ; then
		        if [ -f /boot/initrd.img-\$(uname -r) ] ; then
		                mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d /boot/initrd.img-\$(uname -r) /boot/uboot/uInitrd
		        fi
		        if [ -f /boot/uboot/boot.cmd ] ; then
		                mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d /boot/uboot/boot.cmd /boot/uboot/boot.scr
		                cp -v /boot/uboot/boot.scr /boot/uboot/boot.ini
		        fi
		        if [ -f /boot/uboot/serial.cmd ] ; then
		                mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d /boot/uboot/serial.cmd /boot/uboot/boot.scr
		        fi
		        if [ -f /boot/uboot/user.cmd ] ; then
		                mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Reset Nand" -d /boot/uboot/user.cmd /boot/uboot/user.scr
		        fi
		fi

	__EOF__

	cat > ${TEMPDIR}/minimal_lxde.sh <<-__EOF__
		#!/bin/sh

		sudo apt-get update
		sudo apt-get -y install lxde lxde-core lxde-icon-theme

	__EOF__

	cat > ${TEMPDIR}/xorg.conf <<-__EOF__
		Section "Device"
		        Identifier      "omap"
		        Driver          "omap"
		EndSection

	__EOF__

	cat > ${TEMPDIR}/build_omapdrm_drivers.sh <<-__EOF__
		#!/bin/bash

		#package list from:
		#http://anonscm.debian.org/gitweb/?p=collab-maint/xf86-video-omap.git;a=blob;f=debian/control;hb=HEAD

		sudo apt-get update ; sudo apt-get -y install debhelper dh-autoreconf libdrm-dev libudev-dev libxext-dev pkg-config x11proto-core-dev x11proto-fonts-dev x11proto-gl-dev x11proto-xf86dri-dev xutils-dev xserver-xorg-dev

		if [ ! -f /home/\${USER}/git/xf86-video-omap/.git/config ] ; then
		        git clone git://anongit.freedesktop.org/xorg/driver/xf86-video-omap /home/\${USER}/git/xf86-video-omap/
		fi

		if [ ! -f /home/\${USER}/git/libdrm/.git/config ] ; then
		        git clone git://anongit.freedesktop.org/mesa/drm /home/\${USER}/git/libdrm/
		fi

		DPKG_ARCH=\$(dpkg --print-architecture | grep arm)
		case "\${DPKG_ARCH}" in
		armel)
		        gnu="gnueabi"
		        ;;
		armhf)
		        gnu="gnueabihf"
		        ;;
		esac

		echo ""
		echo "Building omap libdrm"
		echo ""

		cd /home/\${USER}/git/libdrm/
		make distclean &> /dev/null
		git checkout master -f
		git pull
		git branch libdrm-build -D || true
		git checkout 2.4.37 -b libdrm-build

		./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-\${gnu} --disable-libkms --disable-intel --disable-radeon --disable-nouveau --enable-omap-experimental-api

		make
		sudo make install

		echo ""
		echo "Building omap DDX"
		echo ""

		cd /home/\${USER}/git/xf86-video-omap/
		make distclean &> /dev/null
		git checkout master -f
		git pull
		git branch omap-build -D || true
		git checkout origin/HEAD -b omap-build

		./autogen.sh --prefix=/usr
		make
		sudo make install

		sudo cp /boot/uboot/tools/xorg.conf /etc/X11/xorg.conf

	__EOF__

	cat > ${TEMPDIR}/suspend_mount_debug.sh <<-__EOF__
		#!/bin/bash

		if ! id | grep -q root; then
		        echo "must be run as root"
		        exit
		fi

		mkdir -p /debug
		mount -t debugfs debugfs /debug

	__EOF__

	cat > ${TEMPDIR}/suspend.sh <<-__EOF__
		#!/bin/bash

		if ! id | grep -q root; then
		        echo "must be run as root"
		        exit
		fi

		echo mem > /sys/power/state

	__EOF__

	mkdir -p ${TEMPDIR}/disk/tools
	cp -v ${TEMPDIR}/readme.txt ${TEMPDIR}/disk/tools/readme.txt

	cp -v ${TEMPDIR}/update_boot_files.sh ${TEMPDIR}/disk/tools/update_boot_files.sh
	chmod +x ${TEMPDIR}/disk/tools/update_boot_files.sh

	cp -v ${TEMPDIR}/minimal_lxde.sh ${TEMPDIR}/disk/tools/minimal_lxde.sh
	chmod +x ${TEMPDIR}/disk/tools/minimal_lxde.sh

	cp -v ${TEMPDIR}/xorg.conf ${TEMPDIR}/disk/tools/xorg.conf
	cp -v ${TEMPDIR}/build_omapdrm_drivers.sh ${TEMPDIR}/disk/tools/build_omapdrm_drivers.sh
	chmod +x ${TEMPDIR}/disk/tools/build_omapdrm_drivers.sh

	cp -v ${TEMPDIR}/suspend_mount_debug.sh ${TEMPDIR}/disk/tools/
	chmod +x ${TEMPDIR}/disk/tools/suspend_mount_debug.sh

	cp -v ${TEMPDIR}/suspend.sh ${TEMPDIR}/disk/tools/
	chmod +x ${TEMPDIR}/disk/tools/suspend.sh

cd ${TEMPDIR}/disk
sync
cd "${DIR}/"

 echo "Debug: Contents of Boot Partition"
 echo "-----------------------------"
 ls -lh ${TEMPDIR}/disk/
 echo "-----------------------------"

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

function populate_rootfs {
	echo "Populating rootfs Partition"
	echo "Please be patient, this may take a few minutes, as its transfering a lot of files.."
	echo "-----------------------------"

	partprobe ${MMC}

	if [ ! -d ${TEMPDIR}/disk ] ; then
		mkdir -p ${TEMPDIR}/disk
	fi

	if mount -t ${ROOTFS_TYPE} ${MMC}${PARTITION_PREFIX}2 ${TEMPDIR}/disk; then

		if [ -f "${DIR}/${ROOTFS}" ] ; then

			echo "${DIR}/${ROOTFS}" | grep ".tgz" && DECOM="xzf"
			echo "${DIR}/${ROOTFS}" | grep ".tar" && DECOM="xf"

			pv "${DIR}/${ROOTFS}" | tar --numeric-owner --preserve-permissions -${DECOM} - -C ${TEMPDIR}/disk/
			echo "Transfer of Base Rootfs is Complete, now syncing to disk..."
			sync
			sync
			echo "-----------------------------"
		fi

 if [ "$BTRFS_FSTAB" ] ; then
  echo "btrfs selected as rootfs type, modifing /etc/fstab..."
  sed -i 's/auto   errors=remount-ro/btrfs   defaults/g' ${TEMPDIR}/disk/etc/fstab
  echo "-----------------------------"
 fi

 if [ "$DISABLE_ETH" ] ; then
  echo "Board Tweak: There is no guarantee eth0 is connected or even exists, modifing /etc/network/interfaces..."
  sed -i 's/auto eth0/#auto eth0/g' ${TEMPDIR}/disk/etc/network/interfaces
  sed -i 's/allow-hotplug eth0/#allow-hotplug eth0/g' ${TEMPDIR}/disk/etc/network/interfaces
  sed -i 's/iface eth0 inet dhcp/#iface eth0 inet dhcp/g' ${TEMPDIR}/disk/etc/network/interfaces
  echo "-----------------------------"
 else
  if [ -f ${TEMPDIR}/disk/etc/init/failsafe.conf ] ; then
   echo "Ubuntu: with no ethernet cable connected it can take up to 2 mins to login, removing upstart sleep calls..."
   echo "-----------------------------"
   echo "Ubuntu: to unfix: sudo sed -i -e 's:#sleep 20:sleep 20:g' /etc/init/failsafe.conf"
   echo "Ubuntu: to unfix: sudo sed -i -e 's:#sleep 40:sleep 40:g' /etc/init/failsafe.conf"
   echo "Ubuntu: to unfix: sudo sed -i -e 's:#sleep 59:sleep 59:g' /etc/init/failsafe.conf"
   echo "-----------------------------"
   sed -i -e 's:sleep 20:#sleep 20:g' ${TEMPDIR}/disk/etc/init/failsafe.conf
   sed -i -e 's:sleep 40:#sleep 40:g' ${TEMPDIR}/disk/etc/init/failsafe.conf
   sed -i -e 's:sleep 59:#sleep 59:g' ${TEMPDIR}/disk/etc/init/failsafe.conf
  fi
 fi

#So most of the Published Demostration images use ttyO2 by default, but devices like the BeagleBone, mx53loco do not..
if test "-$SERIAL-" != "-ttyO2-"
then
 if [ -f ${TEMPDIR}/disk/etc/init/ttyO2.conf ]; then
  echo "Ubuntu: Serial Login: fixing /etc/init/ttyO2.conf to use ${SERIAL}"
  echo "-----------------------------"
  mv ${TEMPDIR}/disk/etc/init/ttyO2.conf ${TEMPDIR}/disk/etc/init/${SERIAL}.conf
  sed -i -e 's:ttyO2:'$SERIAL':g' ${TEMPDIR}/disk/etc/init/${SERIAL}.conf
 elif [ -f ${TEMPDIR}/disk/etc/inittab ]; then
  echo "Debian: Serial Login: fixing /etc/inittab to use ${SERIAL}"
  echo "-----------------------------"
  sed -i -e 's:ttyO2:'$SERIAL':g' ${TEMPDIR}/disk/etc/inittab
 fi
fi

 if [ "$CREATE_SWAP" ] ; then

  echo "-----------------------------"
  echo "Extra: Creating SWAP File"
  echo "-----------------------------"
  echo "SWAP BUG creation note:"
  echo "IF this takes a long time(>= 5mins) open another terminal and run dmesg"
  echo "if theres a nasty error, ctrl-c/reboot and try again... its an annoying bug.."
  echo "Background: usually occured in days before Ubuntu Lucid.."
  echo "-----------------------------"

  SPACE_LEFT=$(df ${TEMPDIR}/disk/ | grep ${MMC}${PARTITION_PREFIX}2 | awk '{print $4}')

  let SIZE=$SWAP_SIZE*1024

  if [ $SPACE_LEFT -ge $SIZE ] ; then
   dd if=/dev/zero of=${TEMPDIR}/disk/mnt/SWAP.swap bs=1M count=$SWAP_SIZE
   mkswap ${TEMPDIR}/disk/mnt/SWAP.swap
   echo "/mnt/SWAP.swap  none  swap  sw  0 0" >> ${TEMPDIR}/disk/etc/fstab
   else
   echo "FIXME Recovery after user selects SWAP file bigger then whats left not implemented"
  fi
 fi

 cd ${TEMPDIR}/disk/
 sync
 sync
 cd "${DIR}/"

 umount ${TEMPDIR}/disk || true

 echo "Finished populating rootfs Partition"
 echo "-----------------------------"
else
 echo "-----------------------------"
 echo "Unable to mount ${MMC}${PARTITION_PREFIX}2 at ${TEMPDIR}/disk to complete populating rootfs Partition"
 echo "Please retry running the script, sometimes rebooting your system helps."
 echo "-----------------------------"
 exit
fi
 echo "setup_sdcard.sh script complete"
}

function check_mmc {
	FDISK=$(LC_ALL=C fdisk -l 2>/dev/null | grep "Disk ${MMC}" | awk '{print $2}')

	if [ "x${FDISK}" = "x${MMC}:" ] ; then
		echo ""
		echo "I see..."
		echo "fdisk -l:"
		LC_ALL=C fdisk -l 2>/dev/null | grep "Disk /dev/" --color=never
		echo ""
		echo "mount:"
		mount | grep -v none | grep "/dev/" --color=never
		echo ""
		read -p "Are you 100% sure, on selecting [${MMC}] (y/n)? "
		[ "${REPLY}" == "y" ] || exit
		echo ""
	else
		echo ""
		echo "Are you sure? I Don't see [${MMC}], here is what I do see..."
		echo ""
		echo "fdisk -l:"
		LC_ALL=C fdisk -l 2>/dev/null | grep "Disk /dev/" --color=never
		echo ""
		echo "mount:"
		mount | grep -v none | grep "/dev/" --color=never
		echo ""
		exit
	fi
}

function is_omap {
	IS_OMAP=1

	bootloader_location="omap_fatfs_boot_part"
	spl_name="MLO"
	boot_name="u-boot.img"

	SUBARCH="omap"

	kernel_addr="0x80300000"
	initrd_addr="0x81600000"
	load_addr="0x80008000"
	dtb_addr="0x815f0000"

	SERIAL_CONSOLE="${SERIAL},115200n8"

	VIDEO_CONSOLE="console=tty0"

	#Older DSS2 omapfb framebuffer driver:
	HAS_OMAPFB_DSS2=1
	VIDEO_DRV="omapfb.mode=dvi"
	VIDEO_OMAP_RAM="12MB"
	VIDEO_OMAPFB_MODE="dvi"
	VIDEO_TIMING="1280x720MR-16@60"

	#KMS Video Options (overrides when edid fails)
	# From: ls /sys/class/drm/
	# Unknown-1 might be s-video..
	KMS_VIDEO_RESOLUTION="1280x720"
	KMS_VIDEOA="video=DVI-D-1"
	unset KMS_VIDEOB

	#Kernel Options
	primary_id="x"
}

function is_imx {
	IS_IMX=1

	bootloader_location="dd_to_drive"
	unset spl_name
	boot_name=1

	SERIAL_CONSOLE="${SERIAL},115200"
	SUBARCH="imx"

	VIDEO_CONSOLE="console=tty0"
	HAS_IMX_BLOB=1
	VIDEO_FB="mxcdi1fb"
	VIDEO_TIMING="RGB24,1280x720M@60"
	primary_id="imx"
}

function check_uboot_type {
	unset IN_VALID_UBOOT
	unset DISABLE_ETH
	unset USE_ZIMAGE
	unset USE_KMS
	unset dtb_file

	unset bootloader_location
	unset spl_name
	unset boot_name

	case "${UBOOT_TYPE}" in
	beagle_bx)
		SYSTEM="beagle_bx"
		BOOTLOADER="BEAGLEBOARD_BX"
		SERIAL="ttyO2"
		DISABLE_ETH=1
		is_omap
		USE_ZIMAGE=1
		#dtb_file="omap3-beagle.dtb"
		;;
	beagle_cx)
		SYSTEM="beagle_cx"
		BOOTLOADER="BEAGLEBOARD_CX"
		SERIAL="ttyO2"
		DISABLE_ETH=1
		is_omap
		USE_ZIMAGE=1
		#dtb_file="omap3-beagle.dtb"
		;;
	beagle_xm)
		SYSTEM="beagle_xm"
		BOOTLOADER="BEAGLEBOARD_XM"
		SERIAL="ttyO2"
		is_omap
		USE_ZIMAGE=1
		#dtb_file="omap3-beagle.dtb"
		;;
	beagle_xm_kms)
		SYSTEM="beagle_xm"
		BOOTLOADER="BEAGLEBOARD_XM"
		SERIAL="ttyO2"
		is_omap
		USE_ZIMAGE=1
		#dtb_file="omap3-beagle.dtb"

		USE_KMS=1
		unset HAS_OMAPFB_DSS2
		;;
	bone)
		SYSTEM="bone"
		BOOTLOADER="BEAGLEBONE_A"
		SERIAL="ttyO0"
		is_omap

		primary_id="psp"

		unset HAS_OMAPFB_DSS2
		unset KMS_VIDEOA
		;;
	bone_zimage)
		SYSTEM="bone_zimage"
		BOOTLOADER="BEAGLEBONE_A"
		SERIAL="ttyO0"
		is_omap
		USE_ZIMAGE=1

		USE_BETA_BOOTLOADER=1

		primary_id="psp"

		unset HAS_OMAPFB_DSS2
		unset KMS_VIDEOA
		;;
	igepv2)
		SYSTEM="igepv2"
		BOOTLOADER="IGEP00X0"
		SERIAL="ttyO2"
		is_omap
		USE_ZIMAGE=1
		;;
	panda)
		SYSTEM="panda"
		BOOTLOADER="PANDABOARD"
		SERIAL="ttyO2"
		is_omap
		USE_ZIMAGE=1
		#dtb_file="omap4-panda.dtb"
		VIDEO_OMAP_RAM="16MB"
		KMS_VIDEOB="video=HDMI-A-1"
		;;
	panda_es)
		SYSTEM="panda_es"
		BOOTLOADER="PANDABOARD_ES"
		SERIAL="ttyO2"
		is_omap
		USE_ZIMAGE=1
		#dtb_file="omap4-panda.dtb"
		VIDEO_OMAP_RAM="16MB"
		KMS_VIDEOB="video=HDMI-A-1"
		;;
	panda_kms)
		SYSTEM="panda_es"
		BOOTLOADER="PANDABOARD_ES"
		SERIAL="ttyO2"
		is_omap
		USE_ZIMAGE=1
		#dtb_file="omap4-panda.dtb"

		USE_KMS=1
		unset HAS_OMAPFB_DSS2
		KMS_VIDEOB="video=HDMI-A-1"
		;;
	crane)
		SYSTEM="crane"
		BOOTLOADER="CRANEBOARD"
		SERIAL="ttyO2"
		is_omap
		USE_ZIMAGE=1
		;;
	mx51evk)
		SYSTEM="mx51evk"
		BOOTLOADER="MX51EVK"
		SERIAL="ttymxc0"
		is_imx
		USE_ZIMAGE=1
		#rcn-ee: For some reason 0x90000000 hard locks on boot, with u-boot 2012.04.01
		kernel_addr="0x90010000"
		initrd_addr="0x92000000"
		load_addr="0x90008000"
		dtb_addr="0x91ff0000"
		dtb_file="imx51-babbage.dtb"
		;;
	mx51evk_dtb)
		SYSTEM="mx51evk_dtb"
		BOOTLOADER="MX51EVK"
		SERIAL="ttymxc0"
		is_imx
		USE_ZIMAGE=1
		#rcn-ee: For some reason 0x90000000 hard locks on boot, with u-boot 2012.04.01
		kernel_addr="0x90010000"
		initrd_addr="0x92000000"
		load_addr="0x90008000"
		dtb_addr="0x91ff0000"
		dtb_file="imx51-babbage.dtb"
		;;
	mx53loco)
		SYSTEM="mx53loco"
		BOOTLOADER="MX53LOCO"
		SERIAL="ttymxc0"
		is_imx
		USE_ZIMAGE=1
		#rcn-ee: For some reason 0x70000000 hard locks on boot, with u-boot 2012.04.01
		kernel_addr="0x70010000"
		initrd_addr="0x72000000"
		load_addr="0x70008000"
		dtb_addr="0x71ff0000"
		dtb_file="imx53-qsb.dtb"
		;;
	mx53loco_dtb)
		SYSTEM="mx53loco_dtb"
		BOOTLOADER="MX53LOCO"
		SERIAL="ttymxc0"
		is_imx
		USE_ZIMAGE=1
		#rcn-ee: For some reason 0x70000000 hard locks on boot, with u-boot 2012.04.01
		kernel_addr="0x70010000"
		initrd_addr="0x72000000"
		load_addr="0x70008000"
		dtb_addr="0x71ff0000"
		dtb_file="imx53-qsb.dtb"
		;;
	*)
		IN_VALID_UBOOT=1
		cat <<-__EOF__
			-----------------------------
			ERROR: This script does not currently recognize the selected: [--uboot ${UBOOT_TYPE}] option..
			Please rerun $(basename $0) with a valid [--uboot <device>] option from the list below:
			-----------------------------
			-Supported TI Devices:-------
			beagle_bx - <BeagleBoard Ax/Bx>
			beagle_cx - <BeagleBoard Cx>
			beagle_xm - <BeagleBoard xMA/B/C>
			bone - <BeagleBone Ax>
			igepv2 - <serial mode only>
			panda - <PandaBoard Ax>
			panda_es - <PandaBoard ES>
			-----------------------------
		__EOF__
		exit
		;;
	esac

	if [ ! "${USE_ZIMAGE}" ] ; then
		unset NEEDS_COMMAND
		check_for_command mkimage uboot-mkimage

		if [ "${NEEDS_COMMAND}" ] ; then
			echo ""
			echo "Your system is missing the mkimage dependency needed for this particular target."
			echo "Ubuntu/Debian: sudo apt-get install uboot-mkimage"
			echo "Fedora: as root: yum install uboot-tools"
			echo "Gentoo: emerge u-boot-tools"
			echo ""
			exit
		fi
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

--addon <additional peripheral device>
    pico
    ulcd <beagle xm>

--rootfs <fs_type>
    ext2
    ext3
    ext4 - <set as default>
    btrfs

--boot_label <boot_label>
    boot partition label

--rootfs_label <rootfs_label>
    rootfs partition label

--swap_file <xxx>
    Creats a Swap file of (xxx)MB's

--svideo-ntsc
    force ntsc mode for svideo

--svideo-pal
    force pal mode for svideo

Additional Options:
-h --help
    this help

--probe-mmc
    List all partitions: sudo ./setup_sdcard.sh --probe-mmc

Debug:
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
            check_root
            check_mmc
            ;;
        --uboot)
            checkparm $2
            UBOOT_TYPE="$2"
            check_uboot_type
            ;;
        --addon)
            checkparm $2
            ADDON=$2
            ;;
        --rootfs)
            checkparm $2
            ROOTFS_TYPE="$2"
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
        --rootfs_label)
            checkparm $2
            ROOTFS_LABEL="$2"
            ;;
        --swap_file)
            checkparm $2
            SWAP_SIZE="$2"
            CREATE_SWAP=1
            ;;
        --spl)
            checkparm $2
            LOCAL_SPL="$2"
            SPL_BOOT=1
            USE_LOCAL_BOOT=1
            ;;
        --bootloader)
            checkparm $2
            LOCAL_BOOTLOADER="$2"
            USE_LOCAL_BOOT=1
            ;;
        --use-beta-bootloader)
            USE_BETA_BOOTLOADER=1
            ;;
        --fdisk-debug)
            FDISK_DEBUG=1
            ;;
    esac
    shift
done

if [ ! "${MMC}" ] ; then
	echo "ERROR: --mmc undefined"
	usage
fi

if [ "$IN_VALID_UBOOT" ] ; then
	echo "ERROR: --uboot undefined"
	usage
fi

if ! is_valid_rootfs_type ${ROOTFS_TYPE} ; then
	echo "ERROR: ${ROOTFS_TYPE} is not a valid root filesystem type"
	echo "Valid types: ${VALID_ROOTFS_TYPES}"
	exit
fi

unset BTRFS_FSTAB
if [ "x${ROOTFS_TYPE}" == "xbtrfs" ] ; then
	unset NEEDS_COMMAND
	check_for_command mkfs.btrfs btrfs-tools

	if [ "${NEEDS_COMMAND}" ] ; then
		echo ""
		echo "Your system is missing the btrfs dependency needed for this particular target."
		echo "Ubuntu/Debian: sudo apt-get install btrfs-tools"
		echo "Fedora: as root: yum install btrfs-progs"
		echo "Gentoo: emerge btrfs-progs"
		echo ""
		exit
	fi

	BTRFS_FSTAB=1
fi

if [ -n "${ADDON}" ] ; then
	if ! is_valid_addon ${ADDON} ; then
		echo "ERROR: ${ADDON} is not a valid addon type"
		echo "-----------------------------"
		echo "Supported --addon options:"
		echo "    pico"
		echo "    ulcd <for the beagleboard xm>"
		exit
	fi
fi

 find_issue
 detect_software
if [ "$USE_LOCAL_BOOT" ] ; then
 local_bootloader
else
 dl_bootloader
fi

 setup_bootscripts
 unmount_all_drive_partitions
 create_partitions
 populate_boot
 populate_rootfs


