#!/bin/bash -e
#
# Copyright (c) 2009-2014 Robert Nelson <robertcnelson@gmail.com>
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
# https://github.com/RobertCNelson/omap-image-builder/blob/master/tools/setup_sdcard.sh

#REQUIREMENTS:
#uEnv.txt bootscript support

BOOT_LABEL="boot"

unset USE_BETA_BOOTLOADER
unset USE_LOCAL_BOOT
unset LOCAL_BOOTLOADER

#Defaults
ROOTFS_TYPE=ext4
ROOTFS_LABEL=rootfs

DIR="$PWD"
TEMPDIR=$(mktemp -d)

is_element_of () {
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

is_valid_rootfs_type () {
	if is_element_of $1 "${VALID_ROOTFS_TYPES}" ] ; then
		return 0
	else
		return 1
	fi
}

check_root () {
	if ! [ $(id -u) = 0 ] ; then
		echo "$0 must be run as sudo user or root"
		exit 1
	fi
}

find_issue () {
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

	unset has_uenvtxt
	unset check
	check=$(ls "${DIR}/" | grep uEnv.txt | head -n 1)
	if [ "x${check}" != "x" ] ; then
		echo "Debug: image has pre-generated uEnv.txt file"
		has_uenvtxt=1
	fi
}

check_for_command () {
	if ! which "$1" > /dev/null ; then
		echo -n "You're missing command $1"
		NEEDS_COMMAND=1
		if [ -n "$2" ] ; then
			echo -n " (consider installing package $2)"
		fi
		echo
	fi
}

detect_software () {
	unset NEEDS_COMMAND

	check_for_command mkfs.vfat dosfstools
	check_for_command wget wget
	check_for_command git git
	check_for_command partprobe parted
	check_for_command mkimage u-boot-tools

	if [ "${build_img_file}" ] ; then
		check_for_command kpartx kpartx
	fi

	if [ "${NEEDS_COMMAND}" ] ; then
		echo ""
		echo "Your system is missing some dependencies"
		echo "Debian/Ubuntu: sudo apt-get install dosfstools git-core kpartx u-boot-tools wget parted"
		echo "Fedora: yum install dosfstools dosfstools git-core uboot-tools wget"
		echo "Gentoo: emerge dosfstools git u-boot-tools wget"
		echo ""
		exit
	fi

	unset test_sfdisk
	test_sfdisk=$(LC_ALL=C sfdisk -v 2>/dev/null | grep 2.17.2 | awk '{print $1}')
	if [ "x${test_sdfdisk}" = "xsfdisk" ] ; then
		echo ""
		echo "Detected known broken sfdisk:"
		echo "See: https://github.com/RobertCNelson/netinstall/issues/20"
		echo ""
		exit
	fi
}

local_bootloader () {
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

dl_bootloader () {
	echo ""
	echo "Downloading Device's Bootloader"
	echo "-----------------------------"
	minimal_boot="1"

	mkdir -p ${TEMPDIR}/dl/${DIST}
	mkdir -p "${DIR}/dl/${DIST}"

	wget --no-verbose --directory-prefix="${TEMPDIR}/dl/" ${conf_bl_http}/${conf_bl_listfile}

	if [ ! -f ${TEMPDIR}/dl/${conf_bl_listfile} ] ; then
		echo "error: can't connect to rcn-ee.net, retry in a few minutes..."
		exit
	fi

	boot_version=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "VERSION:" | awk -F":" '{print $2}')
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
		MLO=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:SPL" | awk '{print $2}')
		wget --no-verbose --directory-prefix="${TEMPDIR}/dl/" ${MLO}
		MLO=${MLO##*/}
		echo "SPL Bootloader: ${MLO}"
	else
		unset MLO
	fi

	if [ "${boot_name}" ] ; then
		UBOOT=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:BOOT" | awk '{print $2}')
		wget --directory-prefix="${TEMPDIR}/dl/" ${UBOOT}
		UBOOT=${UBOOT##*/}
		echo "UBOOT Bootloader: ${UBOOT}"
	else
		unset UBOOT
	fi
}

boot_uenv_txt_template () {
	cat > ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
		kernel_file=${conf_normal_kernel_file}
		initrd_file=${conf_normal_initrd_file}
	__EOF__

	cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
		initrd_high=0xffffffff
		fdt_high=0xffffffff

	__EOF__

	if [ ! "${uboot_fdt_auto_detection}" ] ; then
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			fdtfile=${conf_fdtfile}

		__EOF__
	fi

	if [ ! "${USE_KMS}" ] ; then
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			#Video: Uncomment to override U-Boots value:
			UENV_FB
			UENV_TIMING

		__EOF__
	fi

	if [ "${drm_device_identifier}" ] ; then
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			##Video: [ls /sys/class/drm/]
			##Docs: https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/Documentation/fb/modedb.txt
			##Uncomment to override:
			#kms_force_mode=video=${drm_device_identifier}:1024x768@60e

		__EOF__
	fi

	if [ "x${drm_read_edid_broken}" = "xenable" ] ; then
		sed -i -e 's:#kms_force_mode:kms_force_mode:g' ${TEMPDIR}/bootscripts/normal.cmd
	fi

	if [ "x${enable_systemd}" = "xenabled" ] ; then
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			##Enable systemd
			systemd=quiet init=/lib/systemd/systemd

		__EOF__
	else
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			##Enable systemd
			#systemd=quiet init=/lib/systemd/systemd

		__EOF__
	fi

	case "${SYSTEM}" in
	bone|bone_dtb)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			##BeagleBone Cape Overrides
			##Note: On the BeagleBone Black, there is also an uEnv.txt in the eMMC, so if these changes do not seem to be makeing a difference...

			##BeagleBone Black:
			##Disable HDMI/eMMC
			#optargs=capemgr.disable_partno=BB-BONELT-HDMI,BB-BONELT-HDMIN,BB-BONE-EMMC-2G

		__EOF__
		;;
	beagle)
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
			#Camera:
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
	panda)
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

		loadkernel=${conf_fileload} mmc \${mmcdev}:\${mmcpart} ${conf_loadaddr} \${kernel_file}
		loadinitrd=${conf_fileload} mmc \${mmcdev}:\${mmcpart} ${conf_initrdaddr} \${initrd_file}; setenv initrd_size \${filesize}
		loadfdt=${conf_fileload} mmc \${mmcdev}:\${mmcpart} ${conf_fdtaddr} /dtbs/\${fdtfile}

		boot_ftd=run loadkernel; run loadinitrd; run loadfdt

	__EOF__

	if [ ! "${USE_KMS}" ] ; then
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			video_args=setenv video VIDEO_DISPLAY
			device_args=run video_args; run expansion_args; run mmcargs
			mmcargs=setenv bootargs console=\${console} \${optargs} \${video} root=\${mmcroot} rootfstype=\${mmcrootfstype} \${expansion} \${systemd}

		__EOF__
	else
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			device_args=run expansion_args; run mmcargs
			mmcargs=setenv bootargs console=\${console} \${optargs} \${kms_force_mode} root=\${mmcroot} rootfstype=\${mmcrootfstype} \${expansion} \${systemd}

		__EOF__
	fi

	case "${SYSTEM}" in
	beagle)
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
	mx51evk|mx53loco)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			optargs=VIDEO_CONSOLE
			expansion_args=setenv expansion
		__EOF__
		;;
	panda)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			optargs=VIDEO_CONSOLE
			expansion_args=setenv expansion buddy=\${buddy}
		__EOF__
		;;
	bone)
		cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
			expansion_args=setenv expansion ip=\${ip_method}
		__EOF__
		;;
	esac

	cat >> ${TEMPDIR}/bootscripts/normal.cmd <<-__EOF__
		${conf_entrypt}=run boot_ftd; run device_args; ${conf_bootcmd} ${conf_loadaddr} ${conf_initrdaddr}:\${initrd_size} ${conf_fdtaddr}
		#
	__EOF__
}

tweak_boot_scripts () {
	unset KMS_OVERRIDE

	ALL="*.cmd"
	#Set the Serial Console
	sed -i -e 's:SERIAL_CONSOLE:'$SERIAL_CONSOLE':g' ${TEMPDIR}/bootscripts/${ALL}

	#Set filesystem type
	sed -i -e 's:FINAL_FSTYPE:'$ROOTFS_TYPE':g' ${TEMPDIR}/bootscripts/${ALL}

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
			sed -i -e 's:UENV_FB::g' ${TEMPDIR}/bootscripts/${ALL}
			sed -i -e 's:UENV_TIMING::g' ${TEMPDIR}/bootscripts/${ALL}
		fi
		sed -i -e 's:VIDEO_DISPLAY ::g' ${TEMPDIR}/bootscripts/${ALL}

		#optargs=VIDEO_CONSOLE -> optargs=
		sed -i -e 's:VIDEO_CONSOLE::g' ${TEMPDIR}/bootscripts/${ALL}
	fi
}

setup_bootscripts () {
	mkdir -p ${TEMPDIR}/bootscripts/
	boot_uenv_txt_template
	tweak_boot_scripts
}

drive_error_ro () {
	echo "-----------------------------"
	echo "Error: for some reason your SD card is not writable..."
	echo "Check: is the write protect lever set the locked position?"
	echo "Check: do you have another SD card reader?"
	echo "-----------------------------"
	echo "Script gave up..."

	exit
}

unmount_all_drive_partitions () {
	echo ""
	echo "Unmounting Partitions"
	echo "-----------------------------"

	NUM_MOUNTS=$(mount | grep -v none | grep "${media}" | wc -l)

##	for (i=1;i<=${NUM_MOUNTS};i++)
	for ((i=1;i<=${NUM_MOUNTS};i++))
	do
		DRIVE=$(mount | grep -v none | grep "${media}" | tail -1 | awk '{print $1}')
		umount ${DRIVE} >/dev/null 2>&1 || true
	done

	echo "Zeroing out Partition Table"
	dd if=/dev/zero of=${media} bs=1M count=16 || drive_error_ro
	sync
}

sfdisk_partition_layout () {
	#Generic boot partition created by sfdisk
	echo ""
	echo "Using sfdisk to create partition layout"
	echo "-----------------------------"

	LC_ALL=C sfdisk --force --in-order --Linux --unit M "${media}" <<-__EOF__
		${conf_boot_startmb},${conf_boot_endmb},${sfdisk_fstype},*
		,,,-
	__EOF__

	sync
}

dd_uboot_boot () {
	#For: Freescale: i.mx5/6 Devices
	echo ""
	echo "Using dd to place bootloader on drive"
	echo "-----------------------------"
	dd if=${TEMPDIR}/dl/${UBOOT} of=${media} seek=${dd_uboot_seek} bs=${dd_uboot_bs}
}

dd_spl_uboot_boot () {
	#For: Samsung: Exynos 4 Devices
	echo ""
	echo "Using dd to place bootloader on drive"
	echo "-----------------------------"
	dd if=${TEMPDIR}/dl/${UBOOT} of=${media} seek=${dd_spl_uboot_seek} bs=${dd_spl_uboot_bs}
	dd if=${TEMPDIR}/dl/${UBOOT} of=${media} seek=${dd_uboot_seek} bs=${dd_uboot_bs}
	bootloader_installed=1
}

format_partition_error () {
	echo "LC_ALL=C ${mkfs} ${media_prefix}1 ${mkfs_label}"
	echo "LC_ALL=C mkfs.${ROOTFS_TYPE} ${media_prefix}2 ${ROOTFS_LABEL}"
	echo "Failure: formating partition"
	exit
}

format_boot_partition () {
	echo "Formating Boot Partition"
	echo "-----------------------------"
	LC_ALL=C ${mkfs} ${media_prefix}1 ${mkfs_label} || format_partition_error
	sync
}

format_rootfs_partition () {
	echo "Formating rootfs Partition as ${ROOTFS_TYPE}"
	echo "-----------------------------"
	LC_ALL=C mkfs.${ROOTFS_TYPE} ${media_prefix}2 -L ${ROOTFS_LABEL} || format_partition_error
	sync
}

create_partitions () {
	unset bootloader_installed

	if [ "x${conf_boot_fstype}" = "xfat" ] ; then
		mount_partition_format="vfat"
		mkfs="mkfs.vfat -F 16"
		mkfs_label="-n ${BOOT_LABEL}"
	else
		mount_partition_format="${conf_boot_fstype}"
		mkfs="mkfs.${conf_boot_fstype}"
		mkfs_label="-L ${BOOT_LABEL}"
	fi

	case "${bootloader_location}" in
	fatfs_boot)
		sfdisk_partition_layout
		;;
	dd_uboot_boot)
		dd_uboot_boot
		sfdisk_partition_layout
		;;
	dd_spl_uboot_boot)
		dd_spl_uboot_boot
		sfdisk_partition_layout
		;;
	*)
		sfdisk_partition_layout
		;;
	esac

	echo "Partition Setup:"
	echo "-----------------------------"
	LC_ALL=C fdisk -l "${media}"
	echo "-----------------------------"

	if [ "${build_img_file}" ] ; then
		media_loop=$(losetup -f || true)
		if [ ! "${media_loop}" ] ; then
			echo "losetup -f failed"
			echo "Unmount some via: [sudo losetup -a]"
			echo "-----------------------------"
			losetup -a
			echo "sudo kpartx -d /dev/loopX ; sudo losetup -d /dev/loopX"
			echo "-----------------------------"
			exit
		fi

		losetup ${media_loop} "${media}"
		kpartx -av ${media_loop}
		sleep 1
		sync
		test_loop=$(echo ${media_loop} | awk -F'/' '{print $3}')
		if [ -e /dev/mapper/${test_loop}p1 ] && [ -e /dev/mapper/${test_loop}p2 ] ; then
			media_prefix="/dev/mapper/${test_loop}p"
		else
			ls -lh /dev/mapper/
			echo "Error: not sure what to do (new feature)."
			exit
		fi
	else
		partprobe ${media}
	fi

	format_boot_partition
	format_rootfs_partition
}

boot_git_tools () {
	if [ ! "${offline}" ] && [ ! "${bborg_production}" ] ; then
		echo "Debug: Adding Useful scripts from: https://github.com/RobertCNelson/tools"
		echo "-----------------------------"
		mkdir -p ${TEMPDIR}/disk/tools
		git clone git://github.com/RobertCNelson/tools.git ${TEMPDIR}/disk/tools || true
		if [ ! -f ${TEMPDIR}/disk/tools/.git/config ] ; then
			echo "Trying via http:"
			git clone https://github.com/RobertCNelson/tools.git ${TEMPDIR}/disk/tools || true
		fi
	fi

	if [ ! "${offline}" ] && [ "${bborg_production}" ] ; then
		case "${SYSTEM}" in
		bone|bone_dtb)
			echo "Debug: Adding BeagleBone drivers from: https://github.com/beagleboard/beaglebone-getting-started"
			#Not planning to change these too often, once pulled, remove .git stuff...
			mkdir -p ${TEMPDIR}/drivers/
			git clone git://github.com/beagleboard/beaglebone-getting-started.git ${TEMPDIR}/drivers/ --depth 1
			if [ ! -f ${TEMPDIR}/drivers/.git/config ] ; then
				git clone https://github.com/beagleboard/beaglebone-getting-started.git ${TEMPDIR}/drivers/ --depth 1
			fi
			if [ -f ${TEMPDIR}/drivers/.git/config ] ; then
				rm -rf ${TEMPDIR}/drivers/.git/ || true
			fi

			if [ -d ${TEMPDIR}/drivers/App ] ; then
				mv ${TEMPDIR}/drivers/App ${TEMPDIR}/disk/
			fi
			if [ -d ${TEMPDIR}/drivers/Drivers ] ; then
				mv ${TEMPDIR}/drivers/Drivers ${TEMPDIR}/disk/
			fi
			if [ -d ${TEMPDIR}/drivers/Docs ] ; then
				mv ${TEMPDIR}/drivers/Docs ${TEMPDIR}/disk/
			fi
			if [ -d ${TEMPDIR}/drivers/scripts ] ; then
				mv ${TEMPDIR}/drivers/scripts ${TEMPDIR}/disk/
			fi
			if [ -f ${TEMPDIR}/drivers/autorun.inf ] ; then
				mv ${TEMPDIR}/drivers/autorun.inf ${TEMPDIR}/disk/
			fi
			if [ -f ${TEMPDIR}/drivers/LICENSE.txt ] ; then
				mv ${TEMPDIR}/drivers/LICENSE.txt ${TEMPDIR}/disk/
			fi
			if [ -f ${TEMPDIR}/drivers/README.htm ] ; then
				mv ${TEMPDIR}/drivers/README.htm ${TEMPDIR}/disk/
			fi
			if [ -f ${TEMPDIR}/drivers/README.md ] ; then
				mv ${TEMPDIR}/drivers/README.md ${TEMPDIR}/disk/
			fi
			if [ -f ${TEMPDIR}/drivers/START.htm ] ; then
				mv ${TEMPDIR}/drivers/START.htm ${TEMPDIR}/disk/
			fi
		;;
		esac

		if [ ! -f ${TEMPDIR}/disk/START.htm ] ; then
			wfile=START.htm
			echo "<!DOCTYPE html>" > ${TEMPDIR}/disk/${wfile}
			echo "<html>" >> ${TEMPDIR}/disk/${wfile}
			echo "<body>" >> ${TEMPDIR}/disk/${wfile}
			echo "" >> ${TEMPDIR}/disk/${wfile}
			echo "<script>" >> ${TEMPDIR}/disk/${wfile}
			echo "  window.location = \"http://192.168.7.2\";" >> ${TEMPDIR}/disk/${wfile}
			echo "</script>" >> ${TEMPDIR}/disk/${wfile}
			echo "" >> ${TEMPDIR}/disk/${wfile}
			echo "</body>" >> ${TEMPDIR}/disk/${wfile}
			echo "</html>" >> ${TEMPDIR}/disk/${wfile}
			echo "" >> ${TEMPDIR}/disk/${wfile}
		fi
		sync
		echo "-----------------------------"
	fi
}

populate_boot () {
	echo "Populating Boot Partition"
	echo "-----------------------------"

	if [ ! -d ${TEMPDIR}/disk ] ; then
		mkdir -p ${TEMPDIR}/disk
	fi

	partprobe ${media}
	if ! mount -t ${mount_partition_format} ${media_prefix}1 ${TEMPDIR}/disk; then
		echo "-----------------------------"
		echo "Unable to mount ${media_prefix}1 at ${TEMPDIR}/disk to complete populating Boot Partition"
		echo "Please retry running the script, sometimes rebooting your system helps."
		echo "-----------------------------"
		exit
	fi

	mkdir -p ${TEMPDIR}/disk/debug || true
	mkdir -p ${TEMPDIR}/disk/dtbs || true

	if [ ! "${bootloader_installed}" ] ; then
		if [ "${spl_name}" ] ; then
			if [ -f ${TEMPDIR}/dl/${MLO} ] ; then
				cp -v ${TEMPDIR}/dl/${MLO} ${TEMPDIR}/disk/${spl_name}
				echo "-----------------------------"
			fi
		fi

		if [ "${boot_name}" ] ; then
			if [ -f ${TEMPDIR}/dl/${UBOOT} ] ; then
				cp -v ${TEMPDIR}/dl/${UBOOT} ${TEMPDIR}/disk/${boot_name}
				echo "-----------------------------"
			fi
		fi
	fi

	VMLINUZ_FILE=$(ls "${DIR}/" | grep "${select_kernel}" | grep vmlinuz- | head -n 1)
	if [ "x${VMLINUZ_FILE}" != "x" ] ; then
		if [ "${USE_UIMAGE}" ] ; then
			echo "Using mkimage to create uImage"
			mkimage -A arm -O linux -T kernel -C none -a ${conf_zreladdr} -e ${conf_zreladdr} -n ${select_kernel} -d "${DIR}/${VMLINUZ_FILE}" ${TEMPDIR}/disk/uImage
			echo "-----------------------------"
		else
			echo "Copying Kernel image:"
			cp -v "${DIR}/${VMLINUZ_FILE}" ${TEMPDIR}/disk/zImage
			echo "-----------------------------"
		fi
	fi

	INITRD_FILE=$(ls "${DIR}/" | grep "${select_kernel}" | grep initrd.img- | head -n 1)
	if [ "x${INITRD_FILE}" != "x" ] ; then
		echo "Copying Kernel initrd/uInitrd:"
		if [ "${conf_uboot_CONFIG_SUPPORT_RAW_INITRD}" ] ; then
			cp -v "${DIR}/${INITRD_FILE}" ${TEMPDIR}/disk/initrd.img
		else
			mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d "${DIR}/${INITRD_FILE}" ${TEMPDIR}/disk/uInitrd
		fi
		echo "-----------------------------"
	fi

#	uInitrd_FILE=$(ls "${DIR}/" | grep "${select_kernel}" | grep uInitrd- | head -n 1)
#	if [ "x${uInitrd_FILE}" != "x" ] ; then
#		echo "Copying Kernel uInitrd:"
#		cp -v "${DIR}/${uInitrd_FILE}" ${TEMPDIR}/disk/uInitrd
#		echo "-----------------------------"
#	fi

	DTBS_FILE=$(ls "${DIR}/" | grep "${select_kernel}" | grep dtbs | head -n 1)
	if [ "x${DTBS_FILE}" != "x" ] ; then
		echo "Copying Device Tree Files:"
		if [ "x${conf_boot_fstype}" = "xfat" ] ; then
			tar xfvo "${DIR}/${DTBS_FILE}" -C ${TEMPDIR}/disk/dtbs
		else
			tar xfv "${DIR}/${DTBS_FILE}" -C ${TEMPDIR}/disk/dtbs
		fi
		echo "-----------------------------"
	fi

	if [ "${boot_scr_wrapper}" ] ; then
		cat > ${TEMPDIR}/bootscripts/loader.cmd <<-__EOF__
			echo "boot.scr -> uEnv.txt wrapper..."
			setenv conf_boot_fstype ${conf_boot_fstype}
			\${conf_boot_fstype}load mmc \${mmcdev}:\${mmcpart} \${loadaddr} uEnv.txt
			env import -t \${loadaddr} \${filesize}
			run loaduimage
		__EOF__
		mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "wrapper" -d ${TEMPDIR}/bootscripts/loader.cmd ${TEMPDIR}/disk/boot.scr
	fi

	echo "Copying uEnv.txt based boot scripts to Boot Partition"
	echo "-----------------------------"
	if [ ${has_uenvtxt} ] ; then
		cp -v "${DIR}/uEnv.txt" ${TEMPDIR}/disk/uEnv.txt
		echo "-----------------------------"
		cat "${DIR}/uEnv.txt"
	else
		cp -v ${TEMPDIR}/bootscripts/normal.cmd ${TEMPDIR}/disk/uEnv.txt
		echo "-----------------------------"
		cat ${TEMPDIR}/bootscripts/normal.cmd
	fi
	echo "-----------------------------"

	if [ -f "${DIR}/ID.txt" ] ; then
		cp -v "${DIR}/ID.txt" ${TEMPDIR}/disk/ID.txt
	fi

	#am335x_boneblack is a custom u-boot to ignore empty factory eeproms...
	if [ "x${conf_board}" = "xam335x_boneblack" ] ; then
		board="am335x_evm"
	else
		board=${conf_board}
	fi

	#This should be compatible with hwpacks variable names..
	#https://code.launchpad.net/~linaro-maintainers/linaro-images/
	cat > ${TEMPDIR}/disk/SOC.sh <<-__EOF__
		#!/bin/sh
		format=1.0
		board=${board}

		bootloader_location=${bootloader_location}
		dd_spl_uboot_seek=${dd_spl_uboot_seek}
		dd_spl_uboot_bs=${dd_spl_uboot_bs}
		dd_uboot_seek=${dd_uboot_seek}
		dd_uboot_bs=${dd_uboot_bs}

		conf_bootcmd=${conf_bootcmd}
		boot_script=${boot_script}
		boot_fstype=${conf_boot_fstype}

		serial_tty=${SERIAL}
		loadaddr=${conf_loadaddr}
		initrdaddr=${conf_initrdaddr}
		zreladdr=${conf_zreladdr}
		fdtaddr=${conf_fdtaddr}
		fdtfile=${conf_fdtfile}

		usbnet_mem=${usbnet_mem}

	__EOF__

	if [ "${bbb_flasher}" ] ; then
		touch ${TEMPDIR}/disk/flash-eMMC.txt
	fi

	echo "Debug:"
	cat ${TEMPDIR}/disk/SOC.sh

	boot_git_tools

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
}

populate_rootfs () {
	echo "Populating rootfs Partition"
	echo "Please be patient, this may take a few minutes, as its transfering a lot of data.."
	echo "-----------------------------"

	if [ ! -d ${TEMPDIR}/disk ] ; then
		mkdir -p ${TEMPDIR}/disk
	fi

	partprobe ${media}
	if ! mount -t ${ROOTFS_TYPE} ${media_prefix}2 ${TEMPDIR}/disk; then
		echo "-----------------------------"
		echo "Unable to mount ${media_prefix}2 at ${TEMPDIR}/disk to complete populating rootfs Partition"
		echo "Please retry running the script, sometimes rebooting your system helps."
		echo "-----------------------------"
		exit
	fi

	if [ -f "${DIR}/${ROOTFS}" ] ; then

		echo "${DIR}/${ROOTFS}" | grep ".tgz" && DECOM="xzf"
		echo "${DIR}/${ROOTFS}" | grep ".tar" && DECOM="xf"

		if which pv > /dev/null ; then
			pv "${DIR}/${ROOTFS}" | tar --numeric-owner --preserve-permissions -${DECOM} - -C ${TEMPDIR}/disk/
		else
			echo "pv: not installed, using tar verbose to show progress"
			tar --numeric-owner --preserve-permissions --verbose -${DECOM} "${DIR}/${ROOTFS}" -C ${TEMPDIR}/disk/
		fi

		echo "Transfer of data is Complete, now syncing data to disk..."
		sync
		sync
		echo "-----------------------------"
	fi

	#RootStock-NG
	if [ -f ${TEMPDIR}/disk/etc/rcn-ee.conf ] ; then
		. ${TEMPDIR}/disk/etc/rcn-ee.conf

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
		echo "debugfs         /sys/kernel/debug  debugfs  defaults          0  0" >> ${TEMPDIR}/disk/etc/fstab

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

		#if we have systemd & wicd-gtk, diable eth0 in /etc/network/interfaces
		if [ -f ${TEMPDIR}/disk/lib/systemd/systemd ] ; then
			if [ -f ${TEMPDIR}/disk/usr/bin/wicd-gtk ] ; then
				sed -i 's/auto eth0/#auto eth0/g' ${TEMPDIR}/disk/etc/network/interfaces
				sed -i 's/iface eth0 inet dhcp/#iface eth0 inet dhcp/g' ${TEMPDIR}/disk/etc/network/interfaces
			fi
		fi

		echo "# Example to keep MAC address between reboots" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "#hwaddress ether DE:AD:BE:EF:CA:FE" >> ${TEMPDIR}/disk/etc/network/interfaces

		echo "" >> ${TEMPDIR}/disk/etc/network/interfaces

		echo "# WiFi Example" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "#auto wlan0" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "#iface wlan0 inet dhcp" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "#    wpa-ssid \"essid\"" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "#    wpa-psk  \"password\"" >> ${TEMPDIR}/disk/etc/network/interfaces

		echo "" >> ${TEMPDIR}/disk/etc/network/interfaces

		echo "# Ethernet/RNDIS gadget (g_ether)" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "# ... or on host side, usbnet and random hwaddr" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "# Note on some boards, usb0 is automaticly setup with an init script" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "# in that case, to completely disable remove file [run_boot-scripts] from the boot partition" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "iface usb0 inet static" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "    address 192.168.7.2" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "    netmask 255.255.255.0" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "    network 192.168.7.0" >> ${TEMPDIR}/disk/etc/network/interfaces
		echo "    gateway 192.168.7.1" >> ${TEMPDIR}/disk/etc/network/interfaces

		if [ ! "${bborg_production}" ] ; then
			rm -f ${TEMPDIR}/disk/var/www/index.html || true
		fi

		if [ "${bbb_flasher}" ] ; then
			if [ -f ${TEMPDIR}/disk/opt/scripts/images/beaglebg-eMMC.jpg ] ; then
				if [ -f ${TEMPDIR}/disk/opt/desktop-background.jpg ] ; then
					rm -f ${TEMPDIR}/disk/opt/desktop-background.jpg || true
				fi
				cp -v ${TEMPDIR}/disk/opt/scripts/images/beaglebg-eMMC.jpg ${TEMPDIR}/disk/opt/desktop-background.jpg
			fi
		fi

#		wfile=var/www/AJAX_terminal.html
#		echo "<!DOCTYPE html>" > ${TEMPDIR}/disk/${wfile}
#		echo "<html>" >> ${TEMPDIR}/disk/${wfile}
#		echo "<body>" >> ${TEMPDIR}/disk/${wfile}
#		echo "" >> ${TEMPDIR}/disk/${wfile}
#		echo "<script>" >> ${TEMPDIR}/disk/${wfile}
#		echo "  var ipaddress = location.hostname;" >> ${TEMPDIR}/disk/${wfile}
#		echo "  window.location = \"https://\" + ipaddress + \":4200\";" >> ${TEMPDIR}/disk/${wfile}
#		echo "</script>" >> ${TEMPDIR}/disk/${wfile}
#		echo "" >> ${TEMPDIR}/disk/${wfile}
#		echo "</body>" >> ${TEMPDIR}/disk/${wfile}
#		echo "</html>" >> ${TEMPDIR}/disk/${wfile}
#		echo "" >> ${TEMPDIR}/disk/${wfile}
		sync

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
		file="/etc/udev/rules.d/70-persistent-net.rules"
		echo "" > ${TEMPDIR}/disk${file}
		echo "# Auto generated by RootStock-NG: setup_sdcard.sh" >> ${TEMPDIR}/disk${file}
		echo "# udevadm info -q all -p /sys/class/net/eth0 --attribute-walk" >> ${TEMPDIR}/disk${file}
		echo "" >> ${TEMPDIR}/disk${file}
		echo "# BeagleBone: net device ()" >> ${TEMPDIR}/disk${file}
		echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"eth0\"" >> ${TEMPDIR}/disk${file}
		echo "" >> ${TEMPDIR}/disk${file}

		;;
	esac

	if [ "${usbnet_mem}" ] ; then
		echo "vm.min_free_kbytes = ${usbnet_mem}" >> ${TEMPDIR}/disk/etc/sysctl.conf
	fi

	if [ "${need_wandboard_firmware}" ] ; then
		wget --no-verbose --directory-prefix="${TEMPDIR}/disk/lib/firmware/brcm/" https://rcn-ee.net/firmware/wandboard/brcmfmac-sdio.txt || true
		if [ -f "${TEMPDIR}/disk/lib/firmware/brcm/brcmfmac-sdio.txt" ] ; then
			cp -v "${TEMPDIR}/disk/lib/firmware/brcm/brcmfmac-sdio.txt" "${TEMPDIR}/disk/lib/firmware/brcm/brcmfmac4329-sdio.txt"
		fi
		if [ -f "${TEMPDIR}/disk/lib/firmware/brcm/brcmfmac4329-sdio.bin" ] ; then
			cp -v "${TEMPDIR}/disk/lib/firmware/brcm/brcmfmac4329-sdio.bin" ${TEMPDIR}/disk/lib/firmware/brcm/brcmfmac-sdio.bin
		fi
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

		SPACE_LEFT=$(df ${TEMPDIR}/disk/ | grep ${media_prefix}2 | awk '{print $4}')
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
	if [ "${build_img_file}" ] ; then
		sync
		kpartx -d ${media_loop} || true
		losetup -d ${media_loop} || true
	fi

	echo "Finished populating rootfs Partition"
	echo "-----------------------------"

	echo "setup_sdcard.sh script complete"
	if [ -f "${DIR}/user_password.list" ] ; then
		echo "-----------------------------"
		echo "The default user:password for this image:"
		cat "${DIR}/user_password.list"
		echo "-----------------------------"
	fi
	if [ "${build_img_file}" ] ; then
		echo "Image file: ${media}"
		echo "Compress via: xz -z -7 -v -k ${media}"
		echo "-----------------------------"
	fi
}

check_mmc () {
	FDISK=$(LC_ALL=C fdisk -l 2>/dev/null | grep "Disk ${media}" | awk '{print $2}')

	if [ "x${FDISK}" = "x${media}:" ] ; then
		echo ""
		echo "I see..."
		echo "fdisk -l:"
		LC_ALL=C fdisk -l 2>/dev/null | grep "Disk /dev/" --color=never
		echo ""
		if which lsblk > /dev/null ; then
			echo "lsblk:"
			lsblk | grep -v sr0
		else
			echo "mount:"
			mount | grep -v none | grep "/dev/" --color=never
		fi
		echo ""
		unset response
		echo -n "Are you 100% sure, on selecting [${media}] (y/n)? "
		read response
		if [ "x${response}" != "xy" ] ; then
			exit
		fi
		echo ""
	else
		echo ""
		echo "Are you sure? I Don't see [${media}], here is what I do see..."
		echo ""
		echo "fdisk -l:"
		LC_ALL=C fdisk -l 2>/dev/null | grep "Disk /dev/" --color=never
		echo ""
		if which lsblk > /dev/null ; then
			echo "lsblk:"
			lsblk | grep -v sr0
		else
			echo "mount:"
			mount | grep -v none | grep "/dev/" --color=never
		fi
		echo ""
		exit
	fi
}

kernel_detection () {
	unset HAS_MULTI_ARMV7_KERNEL
	unset check
	check=$(ls "${DIR}/" | grep vmlinuz- | grep armv7 | head -n 1)
	if [ "x${check}" != "x" ] ; then
		armv7_kernel=$(ls "${DIR}/" | grep vmlinuz- | grep armv7 | awk -F'vmlinuz-' '{print $2}')
		echo "Debug: image has armv7 multi arch kernel support: v${armv7_kernel}"
		HAS_MULTI_ARMV7_KERNEL=1
	fi

	unset HAS_BONE_DT_KERNEL
	unset check
	check=$(ls "${DIR}/" | grep vmlinuz- | grep bone | head -n 1)
	if [ "x${check}" != "x" ] ; then
		bone_dt_kernel=$(ls "${DIR}/" | grep vmlinuz- | grep bone | awk -F'vmlinuz-' '{print $2}')
		echo "Debug: image has bone device tree kernel support: v${bone_dt_kernel}"
		HAS_BONE_DT_KERNEL=1
	fi
}

process_dtb_conf () {
	if [ "${conf_warning}" ] ; then
		show_board_warning
	fi

	echo "-----------------------------"

	#defaults, if not set...
	if [ ! "${conf_boot_startmb}" ] ; then
		conf_boot_startmb="1"
		echo "info: [conf_boot_startmb] undefined using default value: ${conf_boot_startmb}"
	fi

	if [ ! "${conf_boot_endmb}" ] ; then
		conf_boot_endmb="96"
		echo "info: [conf_boot_endmb] undefined using default value: ${conf_boot_endmb}"
	fi

	#error checking...
	if [ ! "${conf_boot_fstype}" ] ; then
		echo "Error: [conf_boot_fstype] not defined, stopping..."
		exit
	else
		case "${conf_boot_fstype}" in
		fat)
			sfdisk_fstype="0xE"
			;;
		ext2|ext3|ext4)
			sfdisk_fstype="0x83"
			;;
		*)
			echo "Error: [conf_boot_fstype] not recognized, stopping..."
			exit
			;;
		esac
	fi

	if [ "${conf_uboot_CONFIG_CMD_BOOTZ}" ] ; then
		conf_bootcmd="bootz"
		conf_normal_kernel_file=zImage
	else
		conf_bootcmd="bootm"
		conf_normal_kernel_file=uImage
	fi

	if [ "${conf_uboot_CONFIG_SUPPORT_RAW_INITRD}" ] ; then
		conf_normal_initrd_file=initrd.img
	else
		conf_normal_initrd_file=uInitrd
	fi

	if [ "${conf_uboot_CONFIG_CMD_FS_GENERIC}" ] ; then
		conf_fileload="load"
	else
		if [ "x${conf_boot_fstype}" = "xfat" ] ; then
			conf_fileload="fatload"
		else
			conf_fileload="ext2load"
		fi
	fi

	if [ "${conf_uboot_use_uenvcmd}" ] ; then
		conf_entrypt="uenvcmd"
	else
		if [ ! "x${conf_uboot_no_uenvcmd}" = "x" ] ; then
			conf_entrypt="${conf_uboot_no_uenvcmd}"
		else
			echo "Error: [conf_uboot_no_uenvcmd] not defined, stopping..."
			exit
		fi
	fi
}

check_dtb_board () {
	error_invalid_dtb=1

	#/hwpack/${dtb_board}.conf
	unset leading_slash
	leading_slash=$(echo ${dtb_board} | grep "/" || unset leading_slash)
	if [ "${leading_slash}" ] ; then
		dtb_board=$(echo "${leading_slash##*/}")
	fi

	#${dtb_board}.conf
	dtb_board=$(echo ${dtb_board} | awk -F ".conf" '{print $1}')
	if [ -f "${DIR}"/hwpack/${dtb_board}.conf ] ; then
		. "${DIR}"/hwpack/${dtb_board}.conf

		boot=${boot_image}
		unset error_invalid_dtb
		process_dtb_conf
	else
		cat <<-__EOF__
			-----------------------------
			ERROR: This script does not currently recognize the selected: [--dtb ${dtb_board}] option..
			Please rerun $(basename $0) with a valid [--dtb <device>] option from the list below:
			-----------------------------
		__EOF__
		cat "${DIR}"/hwpack/*.conf | grep supported
		echo "-----------------------------"
		exit
	fi
}

is_omap () {
	IS_OMAP=1

	bootloader_location="fatfs_boot"
	spl_name="MLO"
	boot_name="u-boot.img"

	SUBARCH="omap"

	boot_script="uEnv.txt"

	SERIAL="ttyO2"
	SERIAL_CONSOLE="${SERIAL},115200n8"

	VIDEO_CONSOLE="console=tty0"

	#KMS Video Options (overrides when edid fails)
	# From: ls /sys/class/drm/
	KMS_VIDEO_RESOLUTION="1280x720"
	KMS_VIDEOA="video=DVI-D-1"
	unset KMS_VIDEOB
}

check_uboot_type () {
	#New defines for hwpack:
	conf_bl_http="https://rcn-ee.net/deb/tools/latest"
	conf_bl_listfile="bootloader-ng"

	unset IN_VALID_UBOOT
	unset DISABLE_ETH
	unset USE_UIMAGE
	unset USE_KMS
	unset conf_fdtfile

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

	unset drm_device_identifier

	case "${UBOOT_TYPE}" in
	beagle|beagle_bx|beagle_cx)
		echo "Note: [--dtb omap3-beagle] now replaces [--uboot beagle]"
		. "${DIR}"/hwpack/omap3-beagle.conf
		process_dtb_conf
		;;
	beagle_xm)
		echo "Note: [--dtb omap3-beagle-xm] now replaces [--uboot beagle_xm]"
		. "${DIR}"/hwpack/omap3-beagle-xm.conf
		process_dtb_conf
		;;
	dt-beagle-xm)
		echo "Note: [--dtb dt-beagle-xm] now replaces [--uboot dt-beagle-xm]"
		. "${DIR}"/hwpack/dt-beagle-xm.conf
		process_dtb_conf
		;;
	bone|bone_dtb)
		SYSTEM="bone"
		is_omap
		SERIAL="ttyO0"
		SERIAL_CONSOLE="${SERIAL},115200n8"

		unset KMS_VIDEOA

		#just to disable the omapfb stuff..
		USE_KMS=1
		drm_device_identifier="HDMI-A-1"

		. "${DIR}"/hwpack/beaglebone.conf
		process_dtb_conf

		select_kernel="${bone_dt_kernel}"
		;;
	boneblack_flasher)
		SYSTEM="bone"
		is_omap
		SERIAL="ttyO0"
		SERIAL_CONSOLE="${SERIAL},115200n8"

		unset KMS_VIDEOA

		#just to disable the omapfb stuff..
		USE_KMS=1
		drm_device_identifier="HDMI-A-1"

		. "${DIR}"/hwpack/beaglebone.conf
		process_dtb_conf

		conf_board="am335x_boneblack"
		select_kernel="${bone_dt_kernel}"
		;;
	panda)
		echo "Note: [--dtb omap4-panda] now replaces [--uboot panda]"
		. "${DIR}"/hwpack/omap4-panda.conf
		process_dtb_conf
		;;
	panda_es)
		echo "Note: [--dtb omap4-panda-es] now replaces [--uboot panda_es]"
		. "${DIR}"/hwpack/omap4-panda-es.conf
		process_dtb_conf
		;;
	mx51evk)
		echo "Note: [--dtb imx51-babbage] now replaces [--uboot mx51evk]"
		. "${DIR}"/hwpack/imx51-babbage.conf
		process_dtb_conf
		;;
	mx53loco)
		echo "Note: [--dtb imx53-qsb] now replaces [--uboot mx53loco]"
		. "${DIR}"/hwpack/imx53-qsb.conf
		process_dtb_conf
		;;
	*)
		IN_VALID_UBOOT=1
		cat <<-__EOF__
			-----------------------------
			ERROR: This script does not currently recognize the selected: [--uboot ${UBOOT_TYPE}] option..
			-----------------------------
		__EOF__
		exit
		;;
	esac
}

usage () {
	echo "usage: sudo $(basename $0) --mmc /dev/sdX --dtb <dev board>"
	#tabed to match 
		cat <<-__EOF__
			-----------------------------
			Bugs email: "bugs at rcn-ee.com"

			Required Options:
			--mmc </dev/sdX> or --img <filename.img>

			--dtb <dev board>

			Additional Options:
			        -h --help

			--probe-mmc
			        <list all partitions: sudo ./setup_sdcard.sh --probe-mmc>

			__EOF__
	exit
}

checkparm () {
	if [ "$(echo $1|grep ^'\-')" ] ; then
		echo "E: Need an argument"
		usage
	fi
}

IN_VALID_UBOOT=1
error_invalid_dtb=1

# parse commandline options
while [ ! -z "$1" ] ; do
	case $1 in
	-h|--help)
		usage
		media=1
		;;
	--probe-mmc)
		media="/dev/idontknow"
		check_root
		check_mmc
		;;
	--mmc)
		checkparm $2
		media="$2"
		media_prefix="${media}"
		echo ${media} | grep mmcblk >/dev/null && media_prefix="${media}p"
		check_root
		check_mmc
		;;
	--img-1gb)
		checkparm $2
		imagename="$2"
		if [ "x${imagename}" = "x" ] ; then
			imagename=image.img
		fi
		name=$(echo ${imagename} | awk -F '.img' '{print $1}')
		imagename="${name}-1gb.img"
		media="${DIR}/${imagename}"
		build_img_file=1
		check_root
		if [ -f "${media}" ] ; then
			rm -rf "${media}" || true
		fi
		#FIXME: 700Mb initial size... (should fit most 1Gb microSD cards)
		dd if=/dev/zero of="${media}" bs=1024 count=0 seek=$[1024*700]
		;;
	--img|--img-2gb)
		checkparm $2
		imagename="$2"
		if [ "x${imagename}" = "x" ] ; then
			imagename=image.img
		fi
		name=$(echo ${imagename} | awk -F '.img' '{print $1}')
		imagename="${name}-2gb.img"
		media="${DIR}/${imagename}"
		build_img_file=1
		check_root
		if [ -f "${media}" ] ; then
			rm -rf "${media}" || true
		fi
		#FIXME: 1,700Mb initial size... (should fit most 2Gb microSD cards)
		dd if=/dev/zero of="${media}" bs=1024 count=0 seek=$[1024*1700]
		;;
	--img-4gb)
		checkparm $2
		imagename="$2"
		if [ "x${imagename}" = "x" ] ; then
			imagename=image.img
		fi
		name=$(echo ${imagename} | awk -F '.img' '{print $1}')
		imagename="${name}-4gb.img"
		media="${DIR}/${imagename}"
		build_img_file=1
		check_root
		if [ -f "${media}" ] ; then
			rm -rf "${media}" || true
		fi
		#FIXME: (should fit most 4Gb microSD cards)
		dd if=/dev/zero of="${media}" bs=1024 count=0 seek=$[1024*3700]
		;;
	--uboot)
		checkparm $2
		UBOOT_TYPE="$2"
		kernel_detection
		check_uboot_type
		;;
	--dtb)
		checkparm $2
		dtb_board="$2"
		kernel_detection
		check_dtb_board
		;;
	--rootfs)
		checkparm $2
		ROOTFS_TYPE="$2"
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
	--bbb-flasher)
		bbb_flasher=1
		;;
	--beagleboard.org-production)
		bborg_production=1
		;;
	--enable-systemd)
		enable_systemd="enabled"
		;;
	--offline)
		offline=1
		;;
	esac
	shift
done

if [ ! "${media}" ] ; then
	echo "ERROR: --mmc undefined"
	usage
fi

if [ "${error_invalid_dtb}" ] ; then
	if [ "${IN_VALID_UBOOT}" ] ; then
		echo "-----------------------------"
		echo "ERROR: --uboot/--dtb undefined"
		echo "-----------------------------"
		usage
	fi
fi

if ! is_valid_rootfs_type ${ROOTFS_TYPE} ; then
	echo "ERROR: ${ROOTFS_TYPE} is not a valid root filesystem type"
	echo "Valid types: ${VALID_ROOTFS_TYPES}"
	exit
fi

unset BTRFS_FSTAB
if [ "x${ROOTFS_TYPE}" = "xbtrfs" ] ; then
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
if [ ! "${build_img_file}" ] ; then
	unmount_all_drive_partitions
fi
create_partitions
populate_boot
populate_rootfs
