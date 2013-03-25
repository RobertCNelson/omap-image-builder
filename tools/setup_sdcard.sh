#!/bin/bash -e
#
# Copyright (c) 2009-2013 Robert Nelson <robertcnelson@gmail.com>
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
unset USE_LOCAL_BOOT
unset LOCAL_BOOTLOADER
unset ADDON

unset SVIDEO_NTSC
unset SVIDEO_PAL

#Defaults
ROOTFS_TYPE=ext4
ROOTFS_LABEL=rootfs

DIR="$PWD"
TEMPDIR=$(mktemp -d)

# non-GNU fdisk is included with Debian Wheezy (and possibly other versions of debian)
# but it has a slightly different name "fdisk.distrib" calling fdisk with a variable
# allows us to specify this alternate name easily.
# to specify an alternate path to fdisk use:
# --fdisk /path/to/alt/fdisk
FDISK_EXEC=`which fdisk`

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

VALID_ADDONS="pico"

function is_valid_addon {
	if is_element_of $1 "${VALID_ADDONS}" ] ; then
		return 0
	else
		return 1
	fi
}

function check_root {
	if [[ ${UID} -ne 0 ]] ; then
		echo "$0 must be run as sudo user or root"
		exit
	fi
}

function find_issue {
	check_root

	ROOTFS=$(ls "${DIR}/" | grep rootfs)
	if [ "x${ROOTFS}" != "x" ] ; then
		echo "Debug: ARM rootfs: ${ROOTFS}"
	else
		echo "Error: no armel-rootfs-* file"
		echo "Make sure your in the right dir..."
		exit
	fi

	unset HAS_INITRD
	unset check
	check=$(ls "${DIR}/" | grep initrd.img | head -n 1)
	if [ "x${check}" != "x" ] ; then
		echo "Debug: image has initrd.img:"
		HAS_INITRD=1
	fi

	unset HAS_DTBS
	unset check
	check=$(ls "${DIR}/" | grep dtbs | head -n 1)
	if [ "x${check}" != "x" ] ; then
		echo "Debug: image has device tree:"
		HAS_DTBS=1
	fi

	echo "Debug: $FDISK_EXEC version:"
	LC_ALL=C $FDISK_EXEC -v
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
	check_for_command git git

	if [ "${NEEDS_COMMAND}" ] ; then
		echo ""
		echo "Your system is missing some dependencies"
		echo "Ubuntu/Debian: sudo apt-get install wget pv dosfstools parted git-core"
		echo "Fedora: as root: yum install wget pv dosfstools parted git-core"
		echo "Gentoo: emerge wget pv dosfstools parted git"
		echo ""
		exit
	fi

	#Check for gnu-fdisk
	#FIXME: GNU Fdisk seems to halt at "Using /dev/xx" when trying to script it..
	if $FDISK_EXEC -v | grep "GNU Fdisk" >/dev/null ; then
		echo "Sorry, this script currently doesn't work with GNU Fdisk."
		echo "Install the version of fdisk from your distribution's util-linux package."
      echo "Or specify a non-GNU Fdisk using the --fdisk option."
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
	mkdir -p ${TEMPDIR}/dl/

	if [ "${spl_name}" ] ; then
		cp ${LOCAL_SPL} ${TEMPDIR}/dl/
		MLO=${LOCAL_SPL##*/}
		echo "SPL Bootloader: ${MLO}"
	fi

	if [ "${boot_name}" ] ; then
		cp ${LOCAL_BOOTLOADER} ${TEMPDIR}/dl/
		UBOOT=${LOCAL_BOOTLOADER##*/}
		echo "UBOOT Bootloader: ${UBOOT}"
	fi
}

function dl_bootloader {
	echo ""
	echo "Downloading Device's Bootloader"
	echo "-----------------------------"
	bootlist="bootloader-ng"
	minimal_boot="1"
	unset disable_mirror

	mkdir -p ${TEMPDIR}/dl/${DIST}
	mkdir -p "${DIR}/dl/${DIST}"

	unset RCNEEDOWN
	if [ "${disable_mirror}" ] ; then
		wget --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}/tools/latest/${bootlist}
	else
		echo "attempting to use rcn-ee.net for dl files [10 second time out]..."
		wget -T 10 -t 1 --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}/tools/latest/${bootlist}
	fi

	if [ ! -f ${TEMPDIR}/dl/${bootlist} ] ; then
		if [ "${disable_mirror}" ] ; then
			echo "error: can't connect to rcn-ee.net, retry in a few minutes (backup mirror down)"
			exit
		else
			rcn-ee_down_use_mirror
			wget --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}/tools/latest/${bootlist}
		fi
	fi

	if [ "${RCNEEDOWN}" ] ; then
		sed -i -e "s/rcn-ee.net/rcn-ee.homeip.net:81/g" ${TEMPDIR}/dl/${bootlist}
		sed -i -e 's:81/deb/:81/dl/mirrors/deb/:g' ${TEMPDIR}/dl/${bootlist}
	fi

	boot_version=$(cat ${TEMPDIR}/dl/${bootlist} | grep "VERSION:" | awk -F":" '{print $2}')
	if [ "x${boot_version}" != "x${minimal_boot}" ] ; then
		echo "Error: This script is out of date and unsupported..."
		echo "Please Visit: https://github.com/RobertCNelson to find updates..."
		exit
	fi

	if [ "${USE_BETA_BOOTLOADER}" ] ; then
		ABI="ABX2"
	else
		ABI="ABI2"
	fi

	if [ "${spl_name}" ] ; then
		MLO=$(cat ${TEMPDIR}/dl/${bootlist} | grep "${ABI}:${BOOTLOADER}:SPL" | awk '{print $2}')
		wget --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MLO}
		MLO=${MLO##*/}
		echo "SPL Bootloader: ${MLO}"
	else
		unset MLO
	fi

	if [ "${boot_name}" ] ; then
		UBOOT=$(cat ${TEMPDIR}/dl/${bootlist} | grep "${ABI}:${BOOTLOADER}:BOOT" | awk '{print $2}')
		wget --directory-prefix=${TEMPDIR}/dl/ ${UBOOT}
		UBOOT=${UBOOT##*/}
		echo "UBOOT Bootloader: ${UBOOT}"
	else
		unset UBOOT
	fi
}

function boot_uenv_txt_template {
	if [ "${USE_UIMAGE}" ] ; then
		cat > ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			kernel_file=uImage
			initrd_file=uInitrd

		__EOF__
	else
		cat > ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			kernel_file=zImage
			initrd_file=initrd.img

		__EOF__
	fi

	if [ "${need_dtbs}" ] ; then
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			initrd_high=0xffffffff
			fdt_high=0xffffffff

		__EOF__
	fi

	if [ ! "${USE_KMS}" ] ; then
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			#Video: Uncomment to override U-Boots value:
			UENV_FB
			UENV_TIMING
			UENV_VRAM

		__EOF__
	fi

	case "${SYSTEM}" in
	beagle_bx|beagle_cx)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			#SPI: enable for userspace spi access on expansion header
			#buddy=spidev

			#LSR COM6L Adapter Board
			#http://eewiki.net/display/linuxonarm/LSR+COM6L+Adapter+Board
			#First production run has unprogramed eeprom:
			#buddy=lsr-com6l-adpt

			#LSR COM6L Adapter Board + TiWi5
			#wl12xx_clk=wl12xx_26mhz

		__EOF__
		;;
	beagle_xm)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			#Camera: Uncomment to enable:
			#http://shop.leopardimaging.com/product.sc?productId=17
			#camera=li5m03

			#SPI: enable for userspace spi access on expansion header
			#buddy=spidev

			#LSR COM6L Adapter Board
			#http://eewiki.net/display/linuxonarm/LSR+COM6L+Adapter+Board
			#First production run has unprogramed eeprom:
			#buddy=lsr-com6l-adpt

			#LSR COM6L Adapter Board + TiWi5
			#wl12xx_clk=wl12xx_26mhz

		__EOF__
		;;
	panda|panda_es)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			#SPI: enable for userspace spi access on expansion header
			#buddy=spidev

		__EOF__
		;;
	esac

	cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
		console=SERIAL_CONSOLE

		mmcroot=/dev/mmcblk0p2 ro
		mmcrootfstype=FINAL_FSTYPE rootwait fixrtc

		boot_fstype=${boot_fstype}
		xyz_load_image=\${boot_fstype}load mmc 0:1 ${kernel_addr} \${kernel_file}
		xyz_load_initrd=\${boot_fstype}load mmc 0:1 ${initrd_addr} \${initrd_file}; setenv initrd_size \${filesize}
		xyz_load_dtb=\${boot_fstype}load mmc 0:1 ${dtb_addr} /dtbs/\${dtb_file}

	__EOF__

	if [ ! "${need_dtbs}" ] ; then
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			xyz_mmcboot=run xyz_load_image; run xyz_load_initrd; echo Booting from mmc ...

		__EOF__
	else
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			xyz_mmcboot=run xyz_load_image; run xyz_load_initrd; run xyz_load_dtb; echo Booting from mmc ...

		__EOF__
	fi

	cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
		video_args=setenv video VIDEO_DISPLAY
		device_args=run video_args; run expansion_args; run mmcargs
		mmcargs=setenv bootargs console=\${console} \${optargs} \${video} root=\${mmcroot} rootfstype=\${mmcrootfstype} \${expansion}

	__EOF__

	case "${SYSTEM}" in
	beagle_bx|beagle_cx)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			optargs=VIDEO_CONSOLE
			expansion_args=setenv expansion buddy=\${buddy} buddy2=\${buddy2} musb_hdrc.fifo_mode=5 wl12xx_clk=\${wl12xx_clk}
		__EOF__
		;;
	beagle_xm)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			optargs=VIDEO_CONSOLE
			expansion_args=setenv expansion buddy=\${buddy} buddy2=\${buddy2} camera=\${camera} wl12xx_clk=\${wl12xx_clk}
		__EOF__
		;;
	crane|igepv2|mx53loco)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			optargs=VIDEO_CONSOLE
			expansion_args=setenv expansion
		__EOF__
		;;
	panda|panda_es)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			optargs=VIDEO_CONSOLE
			expansion_args=setenv expansion buddy=\${buddy} buddy2=\${buddy2}
		__EOF__
		;;
	panda_dtb|panda_es_dtb)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			optargs=VIDEO_CONSOLE
			expansion_args=setenv expansion buddy=\${buddy}
		__EOF__
		;;
	mx51evk|mx53loco_dtb)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			optargs=VIDEO_CONSOLE
			expansion_args=setenv expansion
		__EOF__
		;;
	bone)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			optargs=
			expansion_args=setenv expansion ip=\${ip_method}
		__EOF__
		;;
	mx6qsabrelite)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			optargs=VIDEO_CONSOLE
			expansion_args=setenv expansion
		__EOF__
		;;
	esac

	if [ ! "${need_dtbs}" ] ; then
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			loaduimage=run xyz_mmcboot; run device_args; ${boot} ${kernel_addr} ${initrd_addr}:\${initrd_size}

		__EOF__
	else
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			loaduimage=run xyz_mmcboot; run device_args; ${boot} ${kernel_addr} ${initrd_addr}:\${initrd_size} ${dtb_addr}

		__EOF__
	fi
}

function tweak_boot_scripts {
	unset KMS_OVERRIDE

	if [ "x${ADDON}" == "xpico" ] ; then
		VIDEO_TIMING="640x480MR-16@60"
		KMS_OVERRIDE=1
		KMS_VIDEOA="video=DVI-D-1"
		KMS_VIDEO_RESOLUTION="640x480"
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
		sed -i -e 's:UENV_VRAM:#vram=VIDEO_OMAP_RAM:g' ${TEMPDIR}/bootscripts/${ALL}
		sed -i -e 's:VIDEO_OMAP_RAM:'$VIDEO_OMAP_RAM':g' ${TEMPDIR}/bootscripts/${ALL}

		#UENV_FB -> defaultdisplay=dvi
		sed -i -e 's:UENV_FB:#defaultdisplay=VIDEO_OMAPFB_MODE:g' ${TEMPDIR}/bootscripts/${ALL}
		sed -i -e 's:VIDEO_OMAPFB_MODE:'$VIDEO_OMAPFB_MODE':g' ${TEMPDIR}/bootscripts/${ALL}

		#UENV_TIMING -> dvimode=1280x720MR-16@60
		if [ "x${ADDON}" == "xpico" ] ; then
			sed -i -e 's:UENV_TIMING:dvimode=VIDEO_TIMING:g' ${TEMPDIR}/bootscripts/${ALL}
		else
			sed -i -e 's:UENV_TIMING:#dvimode=VIDEO_TIMING:g' ${TEMPDIR}/bootscripts/${ALL}
		fi
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
			sed -i -e 's:VIDEO_DISPLAY::g' ${TEMPDIR}/bootscripts/${ALL}
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
	echo "Error: [LC_ALL=C parted --script ${MMC} mklabel msdos] failed..."
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

	echo "Zeroing out Partition Table"
	dd if=/dev/zero of=${MMC} bs=1024 count=1024
	sync
	LC_ALL=C parted --script ${MMC} mklabel msdos || drive_error_ro
}

function fatfs_boot_error {
	echo "Failure: [parted --script ${MMC} set 1 boot on]"
	exit
}

function fatfs_boot {
	#For: TI: Omap/Sitara Devices
	echo ""
	echo "Using fdisk to create an omap compatible fatfs BOOT partition"
	echo "-----------------------------"

	$FDISK_EXEC ${MMC} <<-__EOF__
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
	LC_ALL=C parted --script ${MMC} set 1 boot on || fatfs_boot_error
}

function dd_uboot_boot {
	#For: Freescale: i.mx5/6 Devices
	echo ""
	echo "Using dd to place bootloader on drive"
	echo "-----------------------------"
	dd if=${TEMPDIR}/dl/${UBOOT} of=${MMC} seek=${dd_uboot_seek} bs=${dd_uboot_bs}
	bootloader_installed=1
}

function dd_spl_uboot_boot {
	#For: Samsung: Exynos 4 Devices
	echo ""
	echo "Using dd to place bootloader on drive"
	echo "-----------------------------"
	dd if=${TEMPDIR}/dl/${UBOOT} of=${MMC} seek=${dd_spl_uboot_seek} bs=${dd_spl_uboot_bs}
	dd if=${TEMPDIR}/dl/${UBOOT} of=${MMC} seek=${dd_uboot_seek} bs=${dd_uboot_bs}
	bootloader_installed=1
}

function format_partition_error {
	echo "Failure: formating partition"
	exit
}

function format_boot_partition {
	echo "Formating Boot Partition"
	echo "-----------------------------"
	partprobe ${MMC}
	LC_ALL=C ${mkfs} ${MMC}${PARTITION_PREFIX}1 ${mkfs_label} || format_partition_error
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
}

function format_rootfs_partition {
	echo "Formating rootfs Partition as ${ROOTFS_TYPE}"
	echo "-----------------------------"
	partprobe ${MMC}
	LC_ALL=C mkfs.${ROOTFS_TYPE} ${MMC}${PARTITION_PREFIX}2 -L ${ROOTFS_LABEL} || format_partition_error
}

function create_partitions {
	unset bootloader_installed

	if [ "x${boot_fstype}" == "xfat" ] ; then
		parted_format="fat16"
		mount_partition_format="vfat"
		mkfs="mkfs.vfat -F 16"
		mkfs_label="-n ${BOOT_LABEL}"
	else
		parted_format="ext2"
		mount_partition_format="ext2"
		mkfs="mkfs.ext2"
		mkfs_label="-L ${BOOT_LABEL}"
	fi

	if [ "${boot_startmb}" ] ; then
		let boot_endmb=${boot_startmb}+${boot_partition_size}
	fi

	case "${bootloader_location}" in
	fatfs_boot)
		fatfs_boot
		;;
	dd_uboot_boot)
		dd_uboot_boot
		LC_ALL=C parted --script ${PARTED_ALIGN} ${MMC} mkpart primary ${parted_format} ${boot_startmb} ${boot_endmb}
		;;
	dd_spl_uboot_boot)
		dd_spl_uboot_boot
		LC_ALL=C parted --script ${PARTED_ALIGN} ${MMC} mkpart primary ${parted_format} ${boot_startmb} ${boot_endmb}
		;;
	*)
		LC_ALL=C parted --script ${PARTED_ALIGN} ${MMC} mkpart primary ${parted_format} ${boot_startmb} ${boot_endmb}
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

	if mount -t ${mount_partition_format} ${MMC}${PARTITION_PREFIX}1 ${TEMPDIR}/disk; then
		mkdir -p ${TEMPDIR}/disk/backup
		mkdir -p ${TEMPDIR}/disk/dtbs

		if [ ! "${bootloader_installed}" ] ; then
			if [ "${spl_name}" ] ; then
				if [ -f ${TEMPDIR}/dl/${MLO} ] ; then
					cp -v ${TEMPDIR}/dl/${MLO} ${TEMPDIR}/disk/${spl_name}
					cp -v ${TEMPDIR}/dl/${MLO} ${TEMPDIR}/disk/backup/${spl_name}
					echo "-----------------------------"
				fi
			fi

			if [ "${boot_name}" ] && [ ! "${IS_IMX}" ] ; then
				if [ -f ${TEMPDIR}/dl/${UBOOT} ] ; then
					cp -v ${TEMPDIR}/dl/${UBOOT} ${TEMPDIR}/disk/${boot_name}
				fi
			fi

			if [ "${boot_name}" ] ; then
				if [ -f ${TEMPDIR}/dl/${UBOOT} ] ; then
					cp -v ${TEMPDIR}/dl/${UBOOT} ${TEMPDIR}/disk/backup/${boot_name}
					echo "-----------------------------"
				fi
			fi
		fi

		VMLINUZ_FILE=$(ls "${DIR}/" | grep "${select_kernel}" | grep vmlinuz- | head -n 1)
		if [ "x${VMLINUZ_FILE}" != "x" ] ; then
			if [ "${USE_UIMAGE}" ] ; then
				echo "Using mkimage to create uImage"
				mkimage -A arm -O linux -T kernel -C none -a ${load_addr} -e ${load_addr} -n ${select_kernel} -d "${DIR}/${VMLINUZ_FILE}" ${TEMPDIR}/disk/uImage
				echo "-----------------------------"
			else
				echo "Copying Kernel image:"
				cp -v "${DIR}/${VMLINUZ_FILE}" ${TEMPDIR}/disk/zImage
				echo "-----------------------------"
			fi
		fi

		INITRD_FILE=$(ls "${DIR}/" | grep "${select_kernel}" | grep initrd.img- | head -n 1)
		if [ "x${INITRD_FILE}" != "x" ] ; then
			if [ "${USE_UIMAGE}" ] ; then
				echo "Using mkimage to create uInitrd"
				mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d "${DIR}/${INITRD_FILE}" ${TEMPDIR}/disk/uInitrd
				echo "-----------------------------"
			else
				echo "Copying Kernel initrd:"
				cp -v "${DIR}/${INITRD_FILE}" ${TEMPDIR}/disk/initrd.img
				echo "-----------------------------"
			fi
		fi

		DTBS_FILE=$(ls "${DIR}/" | grep "${select_kernel}" | grep dtbs | head -n 1)
		if [ "x${DTBS_FILE}" != "x" ] ; then
			echo "Copying Device Tree Files:"
			if [ "x${boot_fstype}" == "xfat" ] ; then
				tar xfvo "${DIR}/${DTBS_FILE}" -C ${TEMPDIR}/disk/dtbs
			else
				tar xfv "${DIR}/${DTBS_FILE}" -C ${TEMPDIR}/disk/dtbs
			fi
			echo "-----------------------------"
		fi

		if [ "${boot_scr_wrapper}" ] ; then
			cat > ${TEMPDIR}/bootscripts/loader.cmd <<-__EOF__
				echo "boot.scr -> uEnv.txt wrapper..."
				setenv boot_fstype ${boot_fstype}
				\${boot_fstype}load mmc \${mmcdev}:\${mmcpart} \${loadaddr} uEnv.txt
				env import -t \${loadaddr} \${filesize}
				run loaduimage
			__EOF__
			mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "wrapper" -d ${TEMPDIR}/bootscripts/loader.cmd ${TEMPDIR}/disk/boot.scr
			cp -v ${TEMPDIR}/disk/boot.scr ${TEMPDIR}/disk/backup/boot.scr
		fi

		echo "Copying uEnv.txt based boot scripts to Boot Partition"
		echo "-----------------------------"
		cp -v ${TEMPDIR}/bootscripts/normal.cmd ${TEMPDIR}/disk/uEnv.txt
		echo "-----------------------------"
		cat  ${TEMPDIR}/bootscripts/normal.cmd
		echo "-----------------------------"

		#This should be compatible with hwpacks variable names..
		#https://code.launchpad.net/~linaro-maintainers/linaro-images/
		cat > ${TEMPDIR}/disk/SOC.sh <<-__EOF__
			#!/bin/sh
			format=1.0
			board=${BOOTLOADER}

			bootloader_location=${bootloader_location}
			dd_spl_uboot_seek=${dd_spl_uboot_seek}
			dd_spl_uboot_bs=${dd_spl_uboot_bs}
			dd_uboot_seek=${dd_uboot_seek}
			dd_uboot_bs=${dd_uboot_bs}

			boot_image=${boot}
			boot_script=${boot_script}
			boot_fstype=${boot_fstype}

			serial_tty=${SERIAL}
			kernel_addr=${kernel_addr}
			initrd_addr=${initrd_addr}
			load_addr=${load_addr}
			dtb_addr=${dtb_addr}
			dtb_file=${dtb_file}

			usbnet_mem=${usbnet_mem}

		__EOF__

		echo "Debug:"
		cat ${TEMPDIR}/disk/SOC.sh

		echo "Debug: Adding Useful scripts from: https://github.com/RobertCNelson/tools"
		echo "-----------------------------"
		mkdir -p ${TEMPDIR}/disk/tools
		git clone git://github.com/RobertCNelson/tools.git ${TEMPDIR}/disk/tools || true
		echo "-----------------------------"

		cd ${TEMPDIR}/disk
		sync
		cd "${DIR}"/

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

		#RootStock-NG
		if [ -f ${TEMPDIR}/disk/etc/rcn-ee.conf ] ; then
			source ${TEMPDIR}/disk/etc/rcn-ee.conf

			mkdir -p ${TEMPDIR}/disk/boot/uboot || true
			echo "# /etc/fstab: static file system information." > ${TEMPDIR}/disk/etc/fstab
			echo "#" >> ${TEMPDIR}/disk/etc/fstab
			echo "# Auto generated by RootStock-NG: setup_sdcard.sh" >> ${TEMPDIR}/disk/etc/fstab
			echo "#" >> ${TEMPDIR}/disk/etc/fstab
			if [ "${BTRFS_FSTAB}" ] ; then
				echo "/dev/mmcblk0p2  /            btrfs  defaults  0  1" >> ${TEMPDIR}/disk/etc/fstab
			else
				echo "/dev/mmcblk0p2  /            ${ROOTFS_TYPE}  noatime,errors=remount-ro  0  1" >> ${TEMPDIR}/disk/etc/fstab
			fi
			echo "/dev/mmcblk0p1  /boot/uboot  auto  defaults                   0  0" >> ${TEMPDIR}/disk/etc/fstab

			if [ "x${distro}" = "xDebian" ] ; then
				serial_num=$(echo -n "${SERIAL}"| tail -c -1)
				echo "" >> ${TEMPDIR}/disk/etc/inittab
				echo "T${serial_num}:23:respawn:/sbin/getty -L ${SERIAL} 115200 vt102" >> ${TEMPDIR}/disk/etc/inittab
				echo "" >> ${TEMPDIR}/disk/etc/inittab
			fi

			if [ "x${distro}" = "xUbuntu" ] ; then
				echo "start on stopped rc RUNLEVEL=[2345]" > ${TEMPDIR}/disk/etc/init/serial.conf
				echo "stop on runlevel [!2345]" >> ${TEMPDIR}/disk/etc/init/serial.conf
				echo "" >> ${TEMPDIR}/disk/etc/init/serial.conf
				echo "respawn" >> ${TEMPDIR}/disk/etc/init/serial.conf
				echo "exec /sbin/getty 115200 ${SERIAL}" >> ${TEMPDIR}/disk/etc/init/serial.conf
			fi

			echo "# This file describes the network interfaces available on your system" > ${TEMPDIR}/disk/etc/network/interfaces
			echo "# and how to activate them. For more information, see interfaces(5)." >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "# The loopback network interface" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "auto lo" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "iface lo inet loopback" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "# The primary network interface" >> ${TEMPDIR}/disk/etc/network/interfaces
			if [ "${DISABLE_ETH}" ] ; then
				echo "#auto eth0" >> ${TEMPDIR}/disk/etc/network/interfaces
				echo "#iface eth0 inet dhcp" >> ${TEMPDIR}/disk/etc/network/interfaces
			else
				echo "auto eth0"  >> ${TEMPDIR}/disk/etc/network/interfaces
				echo "iface eth0 inet dhcp" >> ${TEMPDIR}/disk/etc/network/interfaces
			fi
			echo "# Example to keep MAC address between reboots" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "#hwaddress ether DE:AD:BE:EF:CA:FE" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "# WiFi Example" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "#auto wlan0" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "#iface wlan0 inet dhcp" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "#    wpa-ssid \"essid\"" >> ${TEMPDIR}/disk/etc/network/interfaces
			echo "#    wpa-psk  \"password\"" >> ${TEMPDIR}/disk/etc/network/interfaces

		else

		if [ "${BTRFS_FSTAB}" ] ; then
			echo "btrfs selected as rootfs type, modifing /etc/fstab..."
			sed -i 's/auto   errors=remount-ro/btrfs   defaults/g' ${TEMPDIR}/disk/etc/fstab
			echo "-----------------------------"
		fi

		if [ "${DISABLE_ETH}" ] ; then
			echo "Board Tweak: There is no guarantee eth0 is connected or even exists, modifing /etc/network/interfaces..."
			sed -i 's/auto eth0/#auto eth0/g' ${TEMPDIR}/disk/etc/network/interfaces
			sed -i 's/allow-hotplug eth0/#allow-hotplug eth0/g' ${TEMPDIR}/disk/etc/network/interfaces
			sed -i 's/iface eth0 inet dhcp/#iface eth0 inet dhcp/g' ${TEMPDIR}/disk/etc/network/interfaces
			echo "-----------------------------"
		fi

		#So most of the Published Demostration images use ttyO2 by default, but devices like the BeagleBone, mx53loco do not..
		if [ "x${SERIAL}" != "xttyO2" ] ; then
			if [ -f ${TEMPDIR}/disk/etc/init/ttyO2.conf ] ; then
				echo "Ubuntu: Serial Login: fixing /etc/init/ttyO2.conf to use ${SERIAL}"
				echo "-----------------------------"
				mv ${TEMPDIR}/disk/etc/init/ttyO2.conf ${TEMPDIR}/disk/etc/init/${SERIAL}.conf
				sed -i -e 's:ttyO2:'$SERIAL':g' ${TEMPDIR}/disk/etc/init/${SERIAL}.conf
			elif [ -f ${TEMPDIR}/disk/etc/inittab ] ; then
				echo "Debian: Serial Login: fixing /etc/inittab to use ${SERIAL}"
				echo "-----------------------------"
				sed -i -e 's:ttyO2:'$SERIAL':g' ${TEMPDIR}/disk/etc/inittab
			fi
		fi

		fi #RootStock-NG

		case "${SYSTEM}" in
		bone|bone_dtb)
			cat >> ${TEMPDIR}/disk/etc/modules <<-__EOF__
			fbcon
			ti_tscadc

			__EOF__
			;;
		esac

		if [ "${usbnet_mem}" ] ; then
			echo "vm.min_free_kbytes = ${usbnet_mem}" >> ${TEMPDIR}/disk/etc/sysctl.conf
		fi

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

		if [ "${CREATE_SWAP}" ] ; then
			echo "-----------------------------"
			echo "Extra: Creating SWAP File"
			echo "-----------------------------"
			echo "SWAP BUG creation note:"
			echo "IF this takes a long time(>= 5mins) open another terminal and run dmesg"
			echo "if theres a nasty error, ctrl-c/reboot and try again... its an annoying bug.."
			echo "Background: usually occured in days before Ubuntu Lucid.."
			echo "-----------------------------"

			SPACE_LEFT=$(df ${TEMPDIR}/disk/ | grep ${MMC}${PARTITION_PREFIX}2 | awk '{print $4}')
			let SIZE=${SWAP_SIZE}*1024

			if [ ${SPACE_LEFT} -ge ${SIZE} ] ; then
				dd if=/dev/zero of=${TEMPDIR}/disk/mnt/SWAP.swap bs=1M count=${SWAP_SIZE}
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
	if [ -f "${DIR}/user_password.list" ] ; then
		echo "-----------------------------"
		echo "The default user:password for this image:"
		cat "${DIR}/user_password.list"
		echo "-----------------------------"
	fi
}

function check_mmc {
	FDISK=$(LC_ALL=C $FDISK_EXEC -l 2>/dev/null | grep "Disk ${MMC}" | awk '{print $2}')

	if [ "x${FDISK}" = "x${MMC}:" ] ; then
		echo ""
		echo "I see..."
		echo "$FDISK_EXEC -l:"
		LC_ALL=C $FDISK_EXEC -l 2>/dev/null | grep "Disk /dev/" --color=never
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
		echo "$FDISK_EXEC -l:"
		LC_ALL=C $FDISK_EXEC -l 2>/dev/null | grep "Disk /dev/" --color=never
		echo ""
		echo "mount:"
		mount | grep -v none | grep "/dev/" --color=never
		echo ""
		exit
	fi
}

function kernel_detection {
	unset HAS_IMX_KERNEL
	unset check
	check=$(ls "${DIR}/" | grep vmlinuz- | grep imx | head -n 1)
	if [ "x${check}" != "x" ] ; then
		imx_kernel=$(ls "${DIR}/" | grep vmlinuz- | grep imx | awk -F'vmlinuz-' '{print $2}')
		echo "Debug: image has imx kernel support: v${imx_kernel}"
		HAS_IMX_KERNEL=1
	fi

	unset HAS_BONE_DT_KERNEL
	unset check
	check=$(ls "${DIR}/" | grep vmlinuz- | grep bone | head -n 1)
	if [ "x${check}" != "x" ] ; then
		bone_dt_kernel=$(ls "${DIR}/" | grep vmlinuz- | grep bone | awk -F'vmlinuz-' '{print $2}')
		echo "Debug: image has bone device tree kernel support: v${bone_dt_kernel}"
		HAS_BONE_DT_KERNEL=1
	fi

	unset HAS_BONE_KERNEL
	unset check
	check=$(ls "${DIR}/" | grep vmlinuz- | grep psp | head -n 1)
	if [ "x${check}" != "x" ] ; then
		bone_kernel=$(ls "${DIR}/" | grep vmlinuz- | grep psp | awk -F'vmlinuz-' '{print $2}')
		echo "Debug: image has bone kernel support: v${bone_kernel}"
		HAS_BONE_KERNEL=1
	fi

	unset HAS_OMAP_KERNEL
	unset check
	check=$(ls "${DIR}/" | grep vmlinuz- | grep x | grep -v vmlinuz-3.2 | head -n 1)
	if [ "x${check}" != "x" ] ; then
		omap_kernel=$(ls "${DIR}/" | grep vmlinuz- | grep x | grep -v vmlinuz-3.2 | awk -F'vmlinuz-' '{print $2}')
		echo "Debug: image has omap kernel support: v${omap_kernel}"
		HAS_OMAP_KERNEL=1
	fi
}

function is_omap {
	IS_OMAP=1

	bootloader_location="fatfs_boot"
	spl_name="MLO"
	boot_name="u-boot.img"

	SUBARCH="omap"

	kernel_addr="0x80300000"
	initrd_addr="0x81600000"
	load_addr="0x80008000"
	dtb_addr="0x815f0000"
	boot_script="uEnv.txt"

	boot_fstype="fat"

	SERIAL="ttyO2"
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
	select_kernel="${omap_kernel}"
}

function is_imx {
	IS_IMX=1

	bootloader_location="dd_uboot_boot"
	unset spl_name
	boot_name="u-boot.imx"
	dd_uboot_seek="1"
	dd_uboot_bs="1024"
	boot_startmb="2"

	SUBARCH="imx"

	SERIAL="ttymxc0"
	SERIAL_CONSOLE="${SERIAL},115200"

	boot_script="uEnv.txt"

	boot_fstype="ext2"

	VIDEO_CONSOLE="console=tty0"
	HAS_IMX_BLOB=1
	VIDEO_FB="mxcdi1fb"
	VIDEO_TIMING="RGB24,1280x720M@60"
	select_kernel="${imx_kernel}"
}

function check_uboot_type {
	kernel_detection
	unset IN_VALID_UBOOT
	unset DISABLE_ETH
	unset USE_UIMAGE
	unset USE_KMS
	unset dtb_file
	unset need_dtbs

	boot="bootz"
	unset bootloader_location
	unset spl_name
	unset boot_name
	unset bootloader_location
	unset dd_spl_uboot_seek
	unset dd_spl_uboot_bs
	unset dd_uboot_seek
	unset dd_uboot_bs

	unset boot_scr_wrapper
	unset usbnet_mem
	boot_partition_size="50"

	case "${UBOOT_TYPE}" in
	beagle_bx)
		SYSTEM="beagle_bx"
		BOOTLOADER="BEAGLEBOARD_BX"
		DISABLE_ETH=1
		is_omap
		#dtb_file="omap3-beagle.dtb"
		usbnet_mem="8192"
		;;
	beagle_cx)
		SYSTEM="beagle_cx"
		BOOTLOADER="BEAGLEBOARD_CX"
		DISABLE_ETH=1
		is_omap
		#dtb_file="omap3-beagle.dtb"
		usbnet_mem="8192"
		;;
	beagle_xm)
		SYSTEM="beagle_xm"
		BOOTLOADER="BEAGLEBOARD_XM"
		is_omap
		usbnet_mem="16384"
		#dtb_file="omap3-beagle.dtb"
		;;
	beagle_xm_kms)
		SYSTEM="beagle_xm"
		BOOTLOADER="BEAGLEBOARD_XM"
		is_omap
		usbnet_mem="16384"
		#dtb_file="omap3-beagle.dtb"

		USE_KMS=1
		unset HAS_OMAPFB_DSS2
		;;
	bone)
		SYSTEM="bone"
		BOOTLOADER="BEAGLEBONE_A"
		is_omap
		SERIAL="ttyO0"
		SERIAL_CONSOLE="${SERIAL},115200n8"

#		if [ "${HAS_BONE_DT_KERNEL}" ] ; then
#			select_kernel="${bone_dt_kernel}"
#			need_dtbs=1
#		else
			select_kernel="${bone_kernel}"
#		fi

		unset HAS_OMAPFB_DSS2
		unset KMS_VIDEOA

		#just to disable the omapfb stuff..
		USE_KMS=1
		;;
	bone_dtb)
		SYSTEM="bone"
		BOOTLOADER="BEAGLEBONE_A"
		is_omap
		SERIAL="ttyO0"
		SERIAL_CONSOLE="${SERIAL},115200n8"

		if [ "${HAS_BONE_DT_KERNEL}" ] ; then
			select_kernel="${bone_dt_kernel}"
			need_dtbs=1
		else
			select_kernel="${bone_kernel}"
			unset need_dtbs
		fi

		unset HAS_OMAPFB_DSS2
		unset KMS_VIDEOA

		#just to disable the omapfb stuff..
		USE_KMS=1
		;;
	igepv2)
		SYSTEM="igepv2"
		BOOTLOADER="IGEP00X0"
		is_omap
		;;
	panda)
		SYSTEM="panda"
		BOOTLOADER="PANDABOARD"
		is_omap
		dtb_file="omap4-panda.dtb"
		VIDEO_OMAP_RAM="16MB"
		KMS_VIDEOB="video=HDMI-A-1"
		usbnet_mem="16384"
		;;
	panda_dtb)
		SYSTEM="panda_dtb"
		BOOTLOADER="PANDABOARD"
		is_omap
		dtb_file="omap4-panda.dtb"
		VIDEO_OMAP_RAM="16MB"
		KMS_VIDEOB="video=HDMI-A-1"
		usbnet_mem="16384"
		need_dtbs=1
		;;
	panda_es)
		SYSTEM="panda_es"
		BOOTLOADER="PANDABOARD_ES"
		is_omap
		dtb_file="omap4-pandaES.dtb"
		VIDEO_OMAP_RAM="16MB"
		KMS_VIDEOB="video=HDMI-A-1"
		usbnet_mem="32768"
		;;
	panda_es_dtb)
		SYSTEM="panda_es_dtb"
		BOOTLOADER="PANDABOARD_ES"
		is_omap
		dtb_file="omap4-pandaES.dtb"
		VIDEO_OMAP_RAM="16MB"
		KMS_VIDEOB="video=HDMI-A-1"
		usbnet_mem="16384"
		need_dtbs=1
		;;
	panda_es_kms)
		SYSTEM="panda_es"
		BOOTLOADER="PANDABOARD_ES"
		is_omap
		dtb_file="omap4-pandaES.dtb"

		USE_KMS=1
		unset HAS_OMAPFB_DSS2
		KMS_VIDEOB="video=HDMI-A-1"
		usbnet_mem="32768"
		;;
	crane)
		SYSTEM="crane"
		BOOTLOADER="CRANEBOARD"
		is_omap
		;;
	mx51evk)
		SYSTEM="mx51evk"
		BOOTLOADER="MX51EVK"
		is_imx
		kernel_addr="0x90010000"
		initrd_addr="0x92000000"
		load_addr="0x90008000"
		dtb_addr="0x91ff0000"
		dtb_file="imx51-babbage.dtb"
		need_dtbs=1
		;;
	mx53loco)
		SYSTEM="mx53loco"
		BOOTLOADER="MX53LOCO"
		is_imx
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
		kernel_addr="0x70010000"
		initrd_addr="0x72000000"
		load_addr="0x70008000"
		dtb_addr="0x71ff0000"
		dtb_file="imx53-qsb.dtb"
		need_dtbs=1
		;;
	mx6qsabrelite)
		SYSTEM="mx6qsabrelite"
		BOOTLOADER="MX6QSABRELITE_D"
		is_imx
		SERIAL="ttymxc1"
		SERIAL_CONSOLE="${SERIAL},115200"
		boot="bootm"
		USE_UIMAGE=1
		dd_uboot_seek="2"
		dd_uboot_bs="512"
		kernel_addr="0x10000000"
		initrd_addr="0x12000000"
		load_addr="0x10008000"
		dtb_addr="0x11ff0000"
		dtb_file="imx6q-sabrelite.dtb"
		need_dtbs=1
		boot_scr_wrapper=1
		;;
	*)
		IN_VALID_UBOOT=1
		cat <<-__EOF__
			-----------------------------
			ERROR: This script does not currently recognize the selected: [--uboot ${UBOOT_TYPE}] option..
			Please rerun $(basename $0) with a valid [--uboot <device>] option from the list below:
			-----------------------------
			        TI:
			                beagle_bx - <BeagleBoard Ax/Bx>
			                beagle_cx - <BeagleBoard Cx>
			                beagle_xm - <BeagleBoard xMA/B/C>
			                bone - <BeagleBone Ax>
			                igepv2 - <serial mode only>
			                panda - <PandaBoard Ax>
			                panda_es - <PandaBoard ES>
			        Freescale:
			                mx51evk - <i.MX51 "Babbage" Development Board>
			                mx53loco - <i.MX53 Quick Start Development Board>
			                mx53loco_dtb - <i.MX53 Quick Start Development Board>
			                mx6qsabrelite - <http://boundarydevices.com/products/sabre-lite-imx6-sbc/>
			-----------------------------
		__EOF__
		exit
		;;
	esac

	if [ "${USE_UIMAGE}" ] ; then
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
	#tabed to match 
		cat <<-__EOF__
			-----------------------------
			Bugs email: "bugs at rcn-ee.com"

			Required Options:
			--mmc </dev/sdX>

			--uboot <dev board>
			        TI:
			                beagle_bx - <BeagleBoard Ax/Bx>
			                beagle_cx - <BeagleBoard Cx>
			                beagle_xm - <BeagleBoard xMA/B/C>
			                bone - <BeagleBone Ax>
			                bone_dtb - <BeagleBone Ax: experimental v3.8-rc>
			                igepv2 - <serial mode only>
			                panda - <PandaBoard Ax>
			                panda_es - <PandaBoard ES>
			        Freescale:
			                mx51evk - <i.MX51 "Babbage" Development Board>
			                mx53loco - <i.MX53 Quick Start Development Board>
			                mx53loco_dtb - <i.MX53 Quick Start Development Board>
			                mx6qsabrelite - <http://boundarydevices.com/products/sabre-lite-imx6-sbc/>

			--addon <additional peripheral device>
			        pico

			--rootfs <fs_type>
			        ext2
			        ext3
			        ext4 - <set as default>
			        btrfs

			--boot_label <boot_label>

			--rootfs_label <rootfs_label>

			--swap_file <xxx>
					<create a swap file of (xxx)MB's>

			--svideo-ntsc
			        <force ntsc mode for S-Video>

			--svideo-pal
			        <force pal mode for S-Video>

			Additional Options:
			        -h --help

			--probe-mmc
			        <list all partitions: sudo ./setup_sdcard.sh --probe-mmc>

			__EOF__
	exit
}

function checkparm {
	if [ "$(echo $1|grep ^'\-')" ] ; then
		echo "E: Need an argument"
		usage
	fi
}

IN_VALID_UBOOT=1

# parse commandline options
while [ ! -z "$1" ] ; do
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
		if [[ "${MMC}" =~ "mmcblk" ]] ; then
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
   --fdisk)
      checkparm $2
      FDISK_EXEC="$2"
      ;;
	esac
	shift
done

if [ ! "${MMC}" ] ; then
	echo "ERROR: --mmc undefined"
	usage
fi

if [ "${IN_VALID_UBOOT}" ] ; then
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
		exit
	fi
fi

find_issue
detect_software

if [ "${spl_name}" ] || [ "${boot_name}" ] ; then
	if [ "${USE_LOCAL_BOOT}" ] ; then
		local_bootloader
	else
		dl_bootloader
	fi
fi

setup_bootscripts
unmount_all_drive_partitions
create_partitions
populate_boot
populate_rootfs
