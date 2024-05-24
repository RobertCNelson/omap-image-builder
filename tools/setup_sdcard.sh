#!/bin/bash -e
#
# Copyright (c) 2009-2024 Robert Nelson <robertcnelson@gmail.com>
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
#sfdisk 2.26.x or greater...

BOOT_LABEL="BOOT"

unset USE_BETA_BOOTLOADER
unset USE_LOCAL_BOOT
unset LOCAL_BOOTLOADER
unset USE_DISTRO_BOOTLOADER
unset bypass_bootup_scripts
unset uboot_disable_pru

#Defaults
ROOTFS_TYPE=ext4
ROOTFS_LABEL=rootfs

DIR="$PWD"
TEMPDIR=$(mktemp -d)

keep_net_alive () {
	while : ; do
		echo "syncing media... $*"
		sleep 300
	done
}
keep_net_alive & KEEP_NET_ALIVE_PID=$!
cleanup_keep_net_alive () {
	[ -e /proc/$KEEP_NET_ALIVE_PID ] && kill $KEEP_NET_ALIVE_PID
}
trap cleanup_keep_net_alive EXIT

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

	unset has_uenvtxt
	unset check
	check=$(ls "${DIR}/" | grep uEnv.txt | grep -v post-uEnv.txt | head -n 1)
	if [ "x${check}" != "x" ] ; then
		echo "Debug: image has pre-generated uEnv.txt file"
		has_uenvtxt=1
	fi

	unset has_post_uenvtxt
	unset check
	check=$(ls "${DIR}/" | grep post-uEnv.txt | head -n 1)
	if [ "x${check}" != "x" ] ; then
		echo "Debug: image has post-uEnv.txt file"
		has_post_uenvtxt="enable"
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
	check_for_command tree tree
	check_for_command sfdisk fdisk

	if [ "x${build_img_file}" = "xenable" ] ; then
		check_for_command kpartx kpartx
	fi

	if [ "${NEEDS_COMMAND}" ] ; then
		echo ""
		echo "Your system is missing some dependencies"
		echo "Debian/Ubuntu: sudo apt-get install dosfstools git kpartx wget tree parted"
		echo "Fedora: yum install dosfstools dosfstools git wget"
		echo "Gentoo: emerge dosfstools git wget"
		echo ""
		exit
	fi

	unset wget_version
	wget_version=$(LC_ALL=C wget --version | grep "GNU Wget" | awk '{print $3}' | awk -F '.' '{print $2}' || true)
	case "${wget_version}" in
	12|13)
		#wget before 1.14 in debian does not support sni
		echo "wget: [`LC_ALL=C wget --version | grep \"GNU Wget\" | awk '{print $3}' || true`]"
		echo "wget: [this version of wget does not support sni, using --no-check-certificate]"
		echo "wget: [http://en.wikipedia.org/wiki/Server_Name_Indication]"
		dl="wget --no-check-certificate"
		;;
	*)
		dl="wget"
		;;
	esac

	dl_continue="${dl} -c"
	dl_quiet="${dl} --no-verbose"
}

local_bootloader () {
	echo ""
	echo "Using Locally Stored Device Bootloader"
	echo "-----------------------------"
	mkdir -p ${TEMPDIR}/dl/oem/

	if [ "${spl_name}" ] ; then
		cp ${LOCAL_SPL} ${TEMPDIR}/dl/
		SPL=${LOCAL_SPL##*/}
		echo "SPL Bootloader: ${SPL}"
	fi

	if [ "${boot_name}" ] ; then
		cp ${LOCAL_BOOTLOADER} ${TEMPDIR}/dl/
		UBOOT=${LOCAL_BOOTLOADER##*/}
		echo "UBOOT Bootloader: ${UBOOT}"
	fi
}

distro_bootloader () {
	echo ""
	echo "Using Distro Bootloader"
	echo "-----------------------------"
	mkdir -p ${TEMPDIR}/dl/oem/

	if [ "${conf_bl_distro_SPL}" ] ; then
		cp -v ./${conf_bl_distro_SPL} ${TEMPDIR}/dl/
		SPL=${spl_name}
		echo "SPL Bootloader: ${conf_bl_distro_SPL}"
	fi

	if [ "${conf_bl_distro_UBOOT}" ] ; then
		cp -v ./${conf_bl_distro_UBOOT} ${TEMPDIR}/dl/
		UBOOT=${boot_name}
		echo "UBOOT Bootloader: ${conf_bl_distro_UBOOT}"
	fi

	if [ "x${oem_blank_eeprom}" = "xenable" ] ; then
		if [ "${conf_bl_distro_blank_SPL}" ] ; then
			if [ -f ${conf_bl_distro_blank_SPL} ] ; then
				cp -v ./${conf_bl_distro_blank_SPL} ${TEMPDIR}/dl/oem/
				blank_SPL=${spl_name}
				echo "blank_SPL Bootloader: ${conf_bl_distro_blank_SPL}"
			else
				if [ "${conf_bl_distro_SPL}" ] ; then
					cp -v ./${conf_bl_distro_SPL} ${TEMPDIR}/dl/oem/
					blank_SPL=${spl_name}
					echo "SPL Bootloader: ${conf_bl_distro_SPL}"
				fi
			fi
		else
			if [ "${conf_bl_distro_SPL}" ] ; then
				cp -v ./${conf_bl_distro_SPL} ${TEMPDIR}/dl/oem/
				blank_SPL=${spl_name}
				echo "SPL Bootloader: ${conf_bl_distro_SPL}"
			fi
		fi

		if [ "${conf_bl_distro_blank_UBOOT}" ] ; then
			if [ -f ${conf_bl_distro_blank_UBOOT} ] ; then
				cp -v ./${conf_bl_distro_blank_UBOOT} ${TEMPDIR}/dl/oem/
				blank_UBOOT=${boot_name}
				echo "blank_UBOOT Bootloader: ${conf_bl_distro_blank_UBOOT}"
			else
				if [ "${conf_bl_distro_UBOOT}" ] ; then
					cp -v ./${conf_bl_distro_UBOOT} ${TEMPDIR}/dl/oem/
					blank_UBOOT=${boot_name}
					echo "UBOOT Bootloader: ${conf_bl_distro_UBOOT}"
				fi
			fi
		else
			if [ "${conf_bl_distro_UBOOT}" ] ; then
				cp -v ./${conf_bl_distro_UBOOT} ${TEMPDIR}/dl/oem/
				blank_UBOOT=${boot_name}
				echo "UBOOT Bootloader: ${conf_bl_distro_UBOOT}"
			fi
		fi
	fi
}

dl_bootloader () {
	echo ""
	echo "Downloading Device's Bootloader"
	echo "-----------------------------"
	minimal_boot="1"

	mkdir -p ${TEMPDIR}/dl/${DIST}
	mkdir -p "${DIR}/dl/${DIST}"

	${dl_quiet} --directory-prefix="${TEMPDIR}/dl/" ${conf_bl_http}/${conf_bl_listfile}

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
		SPL=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:SPL" | awk '{print $2}')
		${dl_quiet} --directory-prefix="${TEMPDIR}/dl/" ${SPL}
		SPL=${SPL##*/}
		echo "SPL Bootloader: ${SPL}"
	else
		unset SPL
	fi

	if [ "${boot_name}" ] ; then
		UBOOT=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:BOOT" | awk '{print $2}')
		${dl} --directory-prefix="${TEMPDIR}/dl/" ${UBOOT}
		UBOOT=${UBOOT##*/}
		echo "UBOOT Bootloader: ${UBOOT}"
	else
		unset UBOOT
	fi

	if [ "x${oem_blank_eeprom}" = "xenable" ] ; then
		if [ "x${conf_board}" = "xam335x_evm" ] ; then
			ABI="ABI2"
			conf_board="am335x_boneblack"

			if [ "${spl_name}" ] ; then
				blank_SPL=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:SPL" | awk '{print $2}')
				${dl_quiet} --directory-prefix="${TEMPDIR}/dl/" ${blank_SPL}
				blank_SPL=${blank_SPL##*/}
				echo "blank_SPL Bootloader: ${blank_SPL}"
			else
				unset blank_SPL
			fi

			if [ "${boot_name}" ] ; then
				blank_UBOOT=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:BOOT" | awk '{print $2}')
				${dl} --directory-prefix="${TEMPDIR}/dl/" ${blank_UBOOT}
				blank_UBOOT=${blank_UBOOT##*/}
				echo "blank_UBOOT Bootloader: ${blank_UBOOT}"
			else
				unset blank_UBOOT
			fi
		fi

		if [ "x${conf_board}" = "xbeagle_x15" ] ; then
			if [ ! "x${flasher_uboot}" = "x" ] ; then
				ABI="ABI2"
				conf_board="${flasher_uboot}"

				if [ "${spl_name}" ] ; then
					blank_SPL=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:SPL" | awk '{print $2}')
					${dl_quiet} --directory-prefix="${TEMPDIR}/dl/" ${blank_SPL}
					blank_SPL=${blank_SPL##*/}
					echo "blank_SPL Bootloader: ${blank_SPL}"
				else
					unset blank_SPL
				fi

				if [ "${boot_name}" ] ; then
					blank_UBOOT=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:BOOT" | awk '{print $2}')
					${dl} --directory-prefix="${TEMPDIR}/dl/" ${blank_UBOOT}
					blank_UBOOT=${blank_UBOOT##*/}
					echo "blank_UBOOT Bootloader: ${blank_UBOOT}"
				else
					unset blank_UBOOT
				fi
			else
				unset oem_blank_eeprom
			fi
		fi
	fi
}

generate_soc () {
	echo "#!/bin/sh" > ${wfile}
	echo "format=1.0" >> ${wfile}
	echo "" >> ${wfile}
	if [ ! "x${conf_bootloader_in_flash}" = "xenable" ] ; then
		echo "board=${board}" >> ${wfile}
		echo "" >> ${wfile}
		echo "bootloader_location=${bootloader_location}" >> ${wfile}
		echo "bootrom_gpt=${bootrom_gpt}" >> ${wfile}
		echo "" >> ${wfile}
		echo "dd_spl_uboot_count=${dd_spl_uboot_count}" >> ${wfile}
		echo "dd_spl_uboot_seek=${dd_spl_uboot_seek}" >> ${wfile}
		if [ "x${build_img_file}" = "xenable" ] ; then
			echo "dd_spl_uboot_conf=notrunc" >> ${wfile}
		else
			echo "dd_spl_uboot_conf=${dd_spl_uboot_conf}" >> ${wfile}
		fi
		echo "dd_spl_uboot_bs=${dd_spl_uboot_bs}" >> ${wfile}
		echo "dd_spl_uboot_backup=/opt/backup/uboot/${spl_uboot_name}" >> ${wfile}
		echo "" >> ${wfile}
		echo "dd_uboot_count=${dd_uboot_count}" >> ${wfile}
		echo "dd_uboot_seek=${dd_uboot_seek}" >> ${wfile}
		if [ "x${build_img_file}" = "xenable" ] ; then
			echo "dd_uboot_conf=notrunc" >> ${wfile}
		else
			echo "dd_uboot_conf=${dd_uboot_conf}" >> ${wfile}
		fi
		echo "dd_uboot_bs=${dd_uboot_bs}" >> ${wfile}
		echo "dd_uboot_backup=/opt/backup/uboot/${uboot_name}" >> ${wfile}
	else
		echo "uboot_CONFIG_CMD_BOOTZ=${uboot_CONFIG_CMD_BOOTZ}" >> ${wfile}
		echo "uboot_CONFIG_SUPPORT_RAW_INITRD=${uboot_CONFIG_SUPPORT_RAW_INITRD}" >> ${wfile}
		echo "uboot_CONFIG_CMD_FS_GENERIC=${uboot_CONFIG_CMD_FS_GENERIC}" >> ${wfile}
		echo "zreladdr=${conf_zreladdr}" >> ${wfile}
	fi
	echo "" >> ${wfile}
	echo "boot_fstype=${conf_boot_fstype}" >> ${wfile}
	echo "conf_boot_startmb=${conf_boot_startmb}" >> ${wfile}
	echo "conf_boot_endmb=${conf_boot_endmb}" >> ${wfile}
	echo "sfdisk_fstype=${partition_one_fstype}" >> ${wfile}
	echo "" >> ${wfile}

	if [ "x${uboot_efi_mode}" = "xenable" ] ; then
		echo "uboot_efi_mode=${uboot_efi_mode}" >> ${wfile}
		echo "" >> ${wfile}
	fi

	echo "boot_label=${BOOT_LABEL}" >> ${wfile}
	echo "rootfs_label=${ROOTFS_LABEL}" >> ${wfile}
	echo "" >> ${wfile}
	echo "#Kernel" >> ${wfile}
	echo "dtb=${dtb}" >> ${wfile}
	echo "serial_tty=${SERIAL}" >> ${wfile}
	echo "usbnet_mem=${usbnet_mem}" >> ${wfile}
	echo "" >> ${wfile}
	echo "#Advanced options" >> ${wfile}
	echo "#disable_ssh_regeneration=true" >> ${wfile}

	echo "" >> ${wfile}
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

	dd_erase_count=${dd_erase_count:-"100"}
	echo "Zeroing out Drive, First ${dd_erase_count}MB"
	echo "-----------------------------"
	dd if=/dev/zero of=${media} bs=1M count=${dd_erase_count} || drive_error_ro
	sync
	dd if=${media} of=/dev/null bs=1M count=${dd_erase_count}
	sync
}

sfdisk_partition_layout () {
	sfdisk_options="--force --wipe-partitions always ${sfdisk_gpt}"
	partition_one_start_mb="${conf_boot_startmb}"
	partition_one_size_mb="${conf_boot_endmb}"
	partition_two_start_mb=$(($partition_one_start_mb + $partition_one_size_mb))

	if [ "x${swap_enable}" = "xenable" ] ; then
		partition_two_size_mb="${conf_swap_sizemb}"
		partition_three_start_mb=$(($partition_one_start_mb + $partition_one_size_mb + $partition_two_size_mb))
	fi

	echo "sfdisk: [$(LC_ALL=C sfdisk --version)]"
	echo "sfdisk: [${sfdisk_options} ${media}]"
	echo "sfdisk: [${partition_one_start_mb}M,${partition_one_size_mb}M,${partition_one_fstype},*]"
	if [ "x${swap_enable}" = "xenable" ] ; then
		echo "sfdisk: [${partition_two_start_mb}M,${partition_two_size_mb}M,0x82,-]"
		echo "sfdisk: [${partition_three_start_mb}M,,,-]"
	else
		echo "sfdisk: [${partition_two_start_mb}M,,,-]"
	fi

	if [ "x${swap_enable}" = "xenable" ] ; then
		LC_ALL=C sfdisk ${sfdisk_options} "${media}" <<-__EOF__
			${partition_one_start_mb}M,${partition_one_size_mb}M,${partition_one_fstype},*
			${partition_two_start_mb}M,${partition_two_size_mb}M,0x82,-
			${partition_three_start_mb}M,,,-
		__EOF__
	else
		LC_ALL=C sfdisk ${sfdisk_options} "${media}" <<-__EOF__
			${partition_one_start_mb}M,${partition_one_size_mb}M,${partition_one_fstype},*
			${partition_two_start_mb}M,,,-
		__EOF__
	fi

	sync
}

sfdisk_single_partition_layout () {
	sfdisk_options="--force --wipe-partitions always ${sfdisk_gpt}"
	partition_one_start_mb="${conf_boot_startmb}"

	echo "sfdisk: [$(LC_ALL=C sfdisk --version)]"
	echo "sfdisk: [${sfdisk_options} ${media}]"
	echo "sfdisk: [${partition_one_start_mb}M,,${partition_one_fstype},*]"

	LC_ALL=C sfdisk ${sfdisk_options} "${media}" <<-__EOF__
		${partition_one_start_mb}M,,${partition_one_fstype},*
	__EOF__

	sync
}

dd_uboot_boot () {
	unset dd_uboot
	if [ ! "x${dd_uboot_count}" = "x" ] ; then
		dd_uboot="${dd_uboot}count=${dd_uboot_count} "
	fi

	if [ ! "x${dd_uboot_seek}" = "x" ] ; then
		dd_uboot="${dd_uboot}seek=${dd_uboot_seek} "
	fi

	if [ "x${build_img_file}" = "xenable" ] ; then
		dd_uboot="${dd_uboot}conv=notrunc "
	else
		if [ ! "x${dd_uboot_conf}" = "x" ] ; then
			dd_uboot="${dd_uboot}conv=${dd_uboot_conf} "
		fi
	fi

	if [ ! "x${dd_uboot_bs}" = "x" ] ; then
		dd_uboot="${dd_uboot}bs=${dd_uboot_bs}"
	fi

	if [ "x${oem_blank_eeprom}" = "xenable" ] ; then
		uboot_blob="${blank_UBOOT}"
	else
		uboot_blob="${UBOOT}"
	fi

	wdir="dl"
	if [ "${USE_DISTRO_BOOTLOADER}" ] ; then
		if [ "x${oem_blank_eeprom}" = "xenable" ] ; then
			wdir="dl/oem"
		fi
	fi

	echo "${uboot_name}: [dd if=..${wdir}/${uboot_blob} of=${media} ${dd_uboot}]"
	echo "-----------------------------"
	dd if=${TEMPDIR}/${wdir}/${uboot_blob} of=${media} ${dd_uboot}
	echo "-----------------------------"
}

dd_spl_uboot_boot () {
	unset dd_spl_uboot
	if [ ! "x${dd_spl_uboot_count}" = "x" ] ; then
		dd_spl_uboot="${dd_spl_uboot}count=${dd_spl_uboot_count} "
	fi

	if [ ! "x${dd_spl_uboot_seek}" = "x" ] ; then
		dd_spl_uboot="${dd_spl_uboot}seek=${dd_spl_uboot_seek} "
	fi

	if [ "x${build_img_file}" = "xenable" ] ; then
			dd_spl_uboot="${dd_spl_uboot}conv=notrunc "
	else
		if [ ! "x${dd_spl_uboot_conf}" = "x" ] ; then
			dd_spl_uboot="${dd_spl_uboot}conv=${dd_spl_uboot_conf} "
		fi
	fi

	if [ ! "x${dd_spl_uboot_bs}" = "x" ] ; then
		dd_spl_uboot="${dd_spl_uboot}bs=${dd_spl_uboot_bs}"
	fi

	if [ "x${oem_blank_eeprom}" = "xenable" ] ; then
		spl_uboot_blob="${blank_SPL}"
	else
		spl_uboot_blob="${SPL}"
	fi

	wdir="dl"
	if [ "${USE_DISTRO_BOOTLOADER}" ] ; then
		if [ "x${oem_blank_eeprom}" = "xenable" ] ; then
			wdir="dl/oem"
		fi
	fi

	echo "${spl_uboot_name}: [dd if=../${wdir}/${spl_uboot_blob} of=${media} ${dd_spl_uboot}]"
	echo "-----------------------------"
	dd if=${TEMPDIR}/${wdir}/${spl_uboot_blob} of=${media} ${dd_spl_uboot}
	echo "-----------------------------"
}

format_partition_error () {
	echo "LC_ALL=C ${mkfs} ${mkfs_partition} ${mkfs_label}"
	echo "Failure: formating partition"
	exit
}

format_partition_try2 () {
	unset mkfs_options
	if [ "x${mkfs}" = "xmkfs.ext4" ] ; then
		mkfs_options="${ext4_options}"
	fi

	echo "-----------------------------"
	echo "BUG: [${mkfs_partition}] was not available so trying [${mkfs}] again in 5 seconds..."
	partprobe ${media}
	sync
	sleep 5
	echo "-----------------------------"

	echo "Formating with: [${mkfs} ${mkfs_options} ${mkfs_partition} ${mkfs_label}]"
	echo "-----------------------------"
	LC_ALL=C ${mkfs} ${mkfs_options} ${mkfs_partition} ${mkfs_label} || format_partition_error
	sync
}

format_partition () {
	unset mkfs_options
	if [ "x${mkfs}" = "xmkfs.ext4" ] ; then
		mkfs_options="${ext4_options}"
	fi

	echo "Formating with: [${mkfs} ${mkfs_options} ${mkfs_partition} ${mkfs_label}]"
	echo "-----------------------------"
	LC_ALL=C ${mkfs} ${mkfs_options} ${mkfs_partition} ${mkfs_label} || format_partition_try2
	sync
}

format_boot_partition () {
	mkfs_partition="${media_prefix}${media_boot_partition}"

	if [ "x${conf_boot_fstype}" = "xfat" ] || [ "x${conf_boot_fstype}" = "xfat16" ]; then
		mount_partition_format="vfat"
		mkfs="mkfs.vfat -F 16"
		mkfs_label="-n ${BOOT_LABEL}"
	elif [ "x${conf_boot_fstype}" = "xfat32" ] ; then
		mount_partition_format="vfat"
		mkfs="mkfs.vfat -F 32"
		mkfs_label="-n ${BOOT_LABEL}"
	else
		mount_partition_format="${conf_boot_fstype}"
		mkfs="mkfs.${conf_boot_fstype}"
		mkfs_label="-L ${BOOT_LABEL}"
	fi

	format_partition

	boot_drive="${conf_root_device}p${media_boot_partition}"
}

format_rootfs_partition () {
	mkfs="mkfs.${ROOTFS_TYPE}"
	mkfs_partition="${media_prefix}${media_rootfs_partition}"
	mkfs_label="-L ${ROOTFS_LABEL}"

	format_partition

	rootfs_drive="${conf_root_device}p${media_rootfs_partition}"
}

create_partitions () {
	unset bootloader_installed
	unset sfdisk_gpt

	if [ "x${swap_enable}" = "xenable" ] ; then
		media_boot_partition=1
		media_swap_partition=2
		media_rootfs_partition=3
	else
		unset media_swap_partition
		media_boot_partition=1
		media_rootfs_partition=2
	fi

	#https://packages.debian.org/source/bookworm/e2fsprogs
	#e2fsprogs (1.47.0) added orphan_file first added in v5.15.x
	unset ext4_options
	unset test_mke2fs
	LC_ALL=C mkfs.ext4 -V &> /tmp/mkfs
	test_mkfs=$(cat /tmp/mkfs | grep mke2fs | grep 1.47 || true)
	if [ "x${test_mkfs}" = "x" ] ; then
		unset ext4_options
	else
		if [ "x${bootloader_location}" = "xdd_spl_uboot_boot" ] ; then
			ext4_options="-O ^metadata_csum,^64bit,^orphan_file"
			echo "log: e2fsprogs (1.47.0) disabling metadata_csum,64bit,orphan_file"
		else
			ext4_options="-O ^orphan_file"
			echo "log: e2fsprogs (1.47.0) disabling orphan_file"
		fi
	fi

	echo ""
	case "${bootloader_location}" in
	fatfs_boot)
		conf_boot_endmb=${conf_boot_endmb:-"12"}

		#mkfs.fat 4.1 (2017-01-24)
		#WARNING: Not enough clusters for a 16 bit FAT! The filesystem will be
		#misinterpreted as having a 12 bit FAT without mount option "fat=16".
		#mkfs.vfat: Attempting to create a too large filesystem
		#LC_ALL=C mkfs.vfat -F 16 /dev/sdg1 -n BOOT
		#Failure: formating partition

		#When using "E" this fails, however "0xE" works fine...

		echo "Using sfdisk to create partition layout"
		echo "Version: `LC_ALL=C sfdisk --version`"
		echo "-----------------------------"
		sfdisk_partition_layout
		;;
	dd_uboot_boot)
		echo "Using dd to place bootloader on drive"
		echo "-----------------------------"
		if [ "x${bootrom_gpt}" = "xenable" ] ; then
			sfdisk_gpt="--label gpt"
		fi
		if [ "x${uboot_efi_mode}" = "xenable" ] ; then
			sfdisk_gpt="--label gpt"
		fi
		dd_uboot_boot
		bootloader_installed=1
		if [ "x${enable_fat_partition}" = "xenable" ] ; then
			conf_boot_endmb=${conf_boot_endmb:-"96"}
			conf_boot_fstype=${conf_boot_fstype:-"fat"}
			partition_one_fstype=${partition_one_fstype:-"0xE"}
			sfdisk_partition_layout
		else
			sfdisk_single_partition_layout
			media_rootfs_partition=1
		fi
		;;
	dd_spl_uboot_boot)
		echo "Using dd to place bootloader on drive"
		echo "-----------------------------"
		if [ "x${bootrom_gpt}" = "xenable" ] ; then
			sfdisk_gpt="--label gpt"
		fi
		if [ "x${uboot_efi_mode}" = "xenable" ] ; then
			sfdisk_gpt="--label gpt"
		fi
		dd_spl_uboot_boot
		dd_uboot_boot
		bootloader_installed=1
		if [ "x${enable_fat_partition}" = "xenable" ] ; then
			conf_boot_endmb=${conf_boot_endmb:-"96"}
			conf_boot_fstype=${conf_boot_fstype:-"fat"}
			partition_one_fstype=${partition_one_fstype:-"0xE"}
			sfdisk_partition_layout
		else
			if [ "x${uboot_efi_mode}" = "xenable" ] ; then
				conf_boot_endmb="16"
				conf_boot_fstype="fat"
				partition_one_fstype="U"
				BOOT_LABEL="EFI"
				sfdisk_partition_layout
			else
				sfdisk_single_partition_layout
				media_rootfs_partition=1
			fi
		fi
		;;
	no_bootloader_single_partition)
		bypass_bootup_scripts="enable"
		echo "No Bootloader, Single Partition"
		echo "-----------------------------"
		if [ "x${bootrom_gpt}" = "xenable" ] ; then
			sfdisk_gpt="--label gpt"
		fi
		if [ "x${uboot_efi_mode}" = "xenable" ] ; then
			sfdisk_gpt="--label gpt"
		fi
		bootloader_installed=1
		sfdisk_single_partition_layout
		media_rootfs_partition=1
		;;
	distro_bootloader_dual_partition)
		bypass_bootup_scripts="enable"
		echo "Distro Bootloader, Dual Partition"
		echo "-----------------------------"
		sfdisk_partition_layout
		;;
	*)
		echo "Using sfdisk to create partition layout"
		echo "Version: `LC_ALL=C sfdisk --version`"
		echo "-----------------------------"
		sfdisk_partition_layout
		;;
	esac

	echo "Partition Setup:"
	echo "-----------------------------"
	LC_ALL=C fdisk -l "${media}"
	echo "-----------------------------"

	if [ "x${build_img_file}" = "xenable" ] ; then
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
		if [ -e /dev/mapper/${test_loop}p${media_boot_partition} ] && [ -e /dev/mapper/${test_loop}p${media_rootfs_partition} ] ; then
			media_prefix="/dev/mapper/${test_loop}p"
		else
			ls -lh /dev/mapper/
			echo "Error: not sure what to do (new feature)."
			exit
		fi
	else
		partprobe ${media}
	fi

	if [ "x${media_boot_partition}" = "x${media_rootfs_partition}" ] ; then
		mount_partition_format="${ROOTFS_TYPE}"
		format_rootfs_partition
	else
		format_boot_partition
		if [ ! "x${conf_swap_sizemb}" = "x" ] ; then
			echo "Log: Generating Swap Partition: [mkswap ${media_prefix}${media_swap_partition}]"
			echo "-----------------------------"
			LC_ALL=C mkswap "${media_prefix}${media_swap_partition}"
			swap_drive="${conf_root_device}p${media_swap_partition}"
			sync
		fi
		format_rootfs_partition
	fi
}

populate_boot () {
	echo "Populating Boot Partition"
	echo "-----------------------------"

	if [ ! -d ${TEMPDIR}/disk ] ; then
		mkdir -p ${TEMPDIR}/disk
	fi

	partprobe ${media}
	if ! mount -t ${mount_partition_format} ${media_prefix}${media_boot_partition} ${TEMPDIR}/disk; then

		echo "-----------------------------"
		echo "BUG: [${media_prefix}${media_boot_partition}] was not available so trying to mount again in 5 seconds..."
		partprobe ${media}
		sync
		sleep 5
		echo "-----------------------------"

		if ! mount -t ${mount_partition_format} ${media_prefix}${media_boot_partition} ${TEMPDIR}/disk; then
			echo "-----------------------------"
			echo "Unable to mount ${media_prefix}${media_boot_partition} at ${TEMPDIR}/disk to complete populating Boot Partition"
			echo "Please retry running the script, sometimes rebooting your system helps."
			echo "-----------------------------"
			exit
		fi
	fi

	lsblk | grep -v sr0
	echo "-----------------------------"

	if [ "${spl_name}" ] ; then
		if [ -f ${TEMPDIR}/dl/${SPL} ] ; then
			if [ ! "${bootloader_installed}" ] ; then
				cp -v ${TEMPDIR}/dl/${SPL} ${TEMPDIR}/disk/${spl_name}
				echo "-----------------------------"
			fi
		fi
	fi


	if [ "${boot_name}" ] ; then
		if [ -f ${TEMPDIR}/dl/${UBOOT} ] ; then
			if [ ! "${bootloader_installed}" ] ; then
				cp -v ${TEMPDIR}/dl/${UBOOT} ${TEMPDIR}/disk/${boot_name}
				echo "-----------------------------"
			fi
		fi
	fi

	if [ "x${uboot_firwmare_dir}" = "xenable" ] ; then
		#cp -rv ./${bootloader_distro_dir}/* "${TEMPDIR}/disk/"
		if [ ! "x${bootloader_distro_mcu}" = "x" ] ; then
			if [ -f ./${bootloader_distro_mcu} ] ; then
				cp -v ./${bootloader_distro_mcu} "${TEMPDIR}/disk/"
			fi
		fi
		if [ ! "x${bootloader_distro_spl}" = "x" ] ; then
			if [ -f ./${bootloader_distro_spl} ] ; then
				cp -v ./${bootloader_distro_spl} "${TEMPDIR}/disk/"
			fi
		fi
		if [ ! "x${bootloader_distro_img}" = "x" ] ; then
			if [ -f ./${bootloader_distro_img} ] ; then
				cp -v ./${bootloader_distro_img} "${TEMPDIR}/disk/"
			fi
		fi
		if [ ! "x${bootloader_distro_sysfw}" = "x" ] ; then
			if [ -f ./${bootloader_distro_sysfw} ] ; then
				cp -v ./${bootloader_distro_sysfw} "${TEMPDIR}/disk/"
			fi
		fi
		if [ ! "x${bootloader_distro_dir_sysfw}" = "x" ] ; then
			if [ -d ./${bootloader_distro_dir_sysfw}/ ] ; then
				cp -v ./${bootloader_distro_dir_sysfw}/* "${TEMPDIR}/disk/"
			fi
		fi
	fi

	if [ "x${distro_defaults}" = "xenable" ] ; then
		${dl_quiet} --directory-prefix="${TEMPDIR}/dl/" https://raw.githubusercontent.com/RobertCNelson/netinstall/master/lib/distro_defaults.scr
		cp -v ${TEMPDIR}/dl/distro_defaults.scr ${TEMPDIR}/disk/boot.scr
	fi

	if [ "x${conf_board}" = "ximx8mqevk_buildroot" ] ; then
		touch ${TEMPDIR}/disk/.imx8mq-evk
	fi

	if [ ${has_uenvtxt} ] ; then
		cp -v "${DIR}/uEnv.txt" ${TEMPDIR}/disk/uEnv.txt
		echo "-----------------------------"
	fi

	if [ -f "${DIR}/ID.txt" ] ; then
		cp -v "${DIR}/ID.txt" ${TEMPDIR}/disk/ID.txt
	fi

	cd ${TEMPDIR}/disk
	sync
	cd "${DIR}"/

	echo "Debug: Contents of Boot Partition"
	echo "-----------------------------"
	ls -lh ${TEMPDIR}/disk/
	du -sh ${TEMPDIR}/disk/
	echo "-----------------------------"

	sync
	sync

	umount ${TEMPDIR}/disk || true

	echo "Finished populating Boot Partition"
	echo "-----------------------------"
}

kernel_select () {
	echo "debug: kernel_select: picking the first available kernel..."
	unset check
	check=$(ls "${dir_check}" | grep vmlinuz- | head -n 1)
	if [ "x${check}" != "x" ] ; then
		select_kernel=$(ls "${dir_check}" | grep vmlinuz- | head -n 1 | awk -F'vmlinuz-' '{print $2}')
		echo "debug: kernel_select: found: [${select_kernel}]"
	else
		echo "Error: no installed kernel"
		exit
	fi
}

populate_rootfs () {
	echo "Populating rootfs Partition"
	echo "Please be patient, this may take a few minutes, as its transfering a lot of data.."
	echo "-----------------------------"

	if [ ! -d ${TEMPDIR}/disk ] ; then
		mkdir -p ${TEMPDIR}/disk
	fi

	partprobe ${media}
	if ! mount -t ${ROOTFS_TYPE} ${media_prefix}${media_rootfs_partition} ${TEMPDIR}/disk; then

		echo "-----------------------------"
		echo "BUG: [${media_prefix}${media_rootfs_partition}] was not available so trying to mount again in 5 seconds..."
		partprobe ${media}
		sync
		sleep 5
		echo "-----------------------------"

		if ! mount -t ${ROOTFS_TYPE} ${media_prefix}${media_rootfs_partition} ${TEMPDIR}/disk; then
			echo "-----------------------------"
			echo "Unable to mount ${media_prefix}${media_rootfs_partition} at ${TEMPDIR}/disk to complete populating rootfs Partition"
			echo "Please retry running the script, sometimes rebooting your system helps."
			echo "-----------------------------"
			exit
		fi
	fi

	if [ "x${uboot_efi_mode}" = "xenable" ] ; then

		if [ ! -d ${TEMPDIR}/disk/boot/efi ] ; then
			mkdir -p ${TEMPDIR}/disk/boot/efi
		fi

		if ! mount -t vfat ${media_prefix}${media_boot_partition} ${TEMPDIR}/disk/boot/efi; then

			echo "-----------------------------"
			echo "BUG: [${media_prefix}${media_boot_partition}] was not available so trying to mount again in 5 seconds..."
			partprobe ${media}
			sync
			sleep 5
			echo "-----------------------------"

			if ! mount -t vfat ${media_prefix}${media_boot_partition} ${TEMPDIR}/disk/boot/efi; then
				echo "-----------------------------"
				echo "Unable to mount ${media_prefix}${media_boot_partition} at ${TEMPDIR}/disk/boot/efi to complete populating rootfs Partition"
				echo "Please retry running the script, sometimes rebooting your system helps."
				echo "-----------------------------"
				exit
			fi
		fi
	fi

	if [ "x${extlinux_firmware_partition}" = "xenable" ] ; then

		if [ ! -d ${TEMPDIR}/disk/boot/firmware ] ; then
			mkdir -p ${TEMPDIR}/disk/boot/firmware
		fi

		if ! mount -t vfat ${media_prefix}${media_boot_partition} ${TEMPDIR}/disk/boot/firmware; then

			echo "-----------------------------"
			echo "BUG: [${media_prefix}${media_boot_partition}] was not available so trying to mount again in 5 seconds..."
			partprobe ${media}
			sync
			sleep 5
			echo "-----------------------------"

			if ! mount -t vfat ${media_prefix}${media_boot_partition} ${TEMPDIR}/disk/boot/firmware; then
				echo "-----------------------------"
				echo "Unable to mount ${media_prefix}${media_boot_partition} at ${TEMPDIR}/disk/boot/firmware to complete populating rootfs Partition"
				echo "Please retry running the script, sometimes rebooting your system helps."
				echo "-----------------------------"
				exit
			fi
		fi
	fi

	lsblk | grep -v sr0
	echo "-----------------------------"

	if [ -f "${DIR}/${ROOTFS}" ] ; then
		if which pv > /dev/null ; then
			pv "${DIR}/${ROOTFS}" | tar --numeric-owner --preserve-permissions --acls --xattrs-include='*' -xf - -C ${TEMPDIR}/disk/
		else
			echo "pv: not installed, using tar verbose to show progress"
			tar --numeric-owner --preserve-permissions --acls --xattrs-include='*' --verbose -xf "${DIR}/${ROOTFS}" -C ${TEMPDIR}/disk/
		fi

		echo "Transfer of data is Complete, now syncing data to disk..."
		echo "Disk Size"
		du -sh ${TEMPDIR}/disk/
		sync
		sync

		#Debug file system permissions...
		#echo "-----------------------------"
		#if [ -f /usr/bin/stat ] ; then
		#	echo "-----------------------------"
		#	echo "Checking [${TEMPDIR}/disk/] permissions"
		#	/usr/bin/stat ${TEMPDIR}/disk/
		#	echo "-----------------------------"
		#fi

		#echo "Setting [${TEMPDIR}/disk/] chown root:root"
		#chown root:root ${TEMPDIR}/disk/
		#echo "Setting [${TEMPDIR}/disk/] chmod 755"
		#chmod 755 ${TEMPDIR}/disk/

		#if [ -f /usr/bin/stat ] ; then
		#	echo "-----------------------------"
		#	echo "Verifying [${TEMPDIR}/disk/] permissions"
		#	/usr/bin/stat ${TEMPDIR}/disk/
		#fi
		echo "-----------------------------"

		if [ ! "x${oem_flasher_img}" = "x" ] ; then
			if [ ! -d "${TEMPDIR}/disk/opt/emmc/" ] ; then
				mkdir -p "${TEMPDIR}/disk/opt/emmc/"
			fi
			cp -v "${oem_flasher_img}" "${TEMPDIR}/disk/opt/emmc/"
			sync
			if [ ! "x${oem_flasher_eeprom}" = "x" ] ; then
				cp -v "${oem_flasher_eeprom}" "${TEMPDIR}/disk/opt/emmc/"
				sync
			fi
			echo "Disk Size, with *.img"
			du -sh ${TEMPDIR}/disk/
		fi

		echo "-----------------------------"
	fi

	dir_check="${TEMPDIR}/disk/boot/"
	kernel_select

	tree ${TEMPDIR}/disk/boot/ || true

	if [ ! "x${uboot_eeprom}" = "x" ] ; then
		echo "board_eeprom_header=${uboot_eeprom}" > "${TEMPDIR}/disk/boot/.eeprom.txt"
	fi

	if [ "x${extlinux}" = "xenable" ] ; then
		if [ "x${extlinux_firmware_partition}" = "xenable" ] ; then
			mkdir -p "${TEMPDIR}/disk/boot/firmware/extlinux/"
			wfile="${TEMPDIR}/disk/boot/firmware/extlinux/extlinux.conf"
			if [ -f "${TEMPDIR}/disk${extlinux_firmware_file}" ] ; then
				cp -v "${TEMPDIR}/disk${extlinux_firmware_file}" ${wfile}

				if [ -f "${TEMPDIR}/disk${extlinux_firmware_microsd}" ] ; then
					cp -v "${TEMPDIR}/disk${extlinux_firmware_microsd}" "${TEMPDIR}/disk/boot/firmware/extlinux/microsd-extlinux.conf"
				fi

				if [ -f "${TEMPDIR}/disk${extlinux_firmware_nvme}" ] ; then
					cp -v "${TEMPDIR}/disk${extlinux_firmware_nvme}" "${TEMPDIR}/disk/boot/firmware/extlinux/nvme-extlinux.conf"
				fi

				if [ "x${extlinux_flasher}" = "xenable" ] ; then
					#sed -i -e 's:quiet:init=/usr/sbin/init-beagle-flasher:g' ${wfile}
					#sed -i -e 's:net.ifnames=0 quiet:net.ifnames=0 quiet init=/usr/sbin/init-beagle-flasher:g' ${wfile}
					#sed -i -e 's:net.ifnames=0 systemd.unified_cgroup_hierarchy=false quiet:net.ifnames=0 systemd.unified_cgroup_hierarchy=false quiet init=/usr/sbin/init-beagle-flasher:g' ${wfile}
					#if [ "x${board_hacks}" = "xbeagleplay" ] ; then
					#	if [ -f "${TEMPDIR}/disk/boot/firmware/overlays/k3-am625-beagleplay-bcfserial-no-firmware.dtbo" ] ; then
					#		echo "    fdtoverlays /overlays/k3-am625-beagleplay-bcfserial-no-firmware.dtbo" | sudo tee -a  ${wfile}
					#	fi
					#fi
					sed -i -e 's:label microSD (default):label microSD:g' ${wfile}
					sed -i -e 's:label copy microSD to eMMC:label copy microSD to eMMC (default):g' ${wfile}
					sed -i -e 's:default microSD (default):default copy microSD to eMMC (default):g' ${wfile}
				fi
				echo "/boot/firmware/extlinux/extlinux.conf-"
			else
				echo "ERROR: not found [${extlinux_firmware_file}]"
			fi
		else
			mkdir -p "${TEMPDIR}/disk/boot/extlinux/"
			wfile="${TEMPDIR}/disk/boot/extlinux/extlinux.conf"

			echo "label Linux ${select_kernel}" > ${wfile}
			echo "    kernel /boot/vmlinuz-${select_kernel}" >> ${wfile}

			if [ ! "x${extlinux_append}" = "x" ] ; then
				echo "    append ${extlinux_append}" >> ${wfile}
			fi

			if [ "x${extlinux_fdtdir}" = "xenable" ] ; then
				if [ ! "x${extlinux_fdtdir_dir}" = "x" ] ; then
					echo "    fdtdir ${extlinux_fdtdir_dir}/" >> ${wfile}
				else
					echo "    fdtdir /boot/dtbs/${select_kernel}/" >> ${wfile}
				fi
			fi

			if [ ! "x${extlinux_devicetree}" = "x" ] ; then
				echo "    devicetree /boot/dtbs/${select_kernel}/${extlinux_devicetree}" >> ${wfile}
			fi

			echo "/boot/extlinux/extlinux.conf-"
		fi
	else
		wfile="${TEMPDIR}/disk/boot/uEnv.txt"
		echo "#Docs: http://elinux.org/Beagleboard:U-boot_partitioning_layout_2.0" > ${wfile}
		echo "" >> ${wfile}

		if [ "x${kernel_override}" = "x" ] ; then
			echo "uname_r=${select_kernel}" >> ${wfile}
		else
			echo "uname_r=${kernel_override}" >> ${wfile}
		fi

		if [ "${BTRFS_FSTAB}" ] ; then
			echo "mmcrootfstype=btrfs rootwait" >> ${wfile}
		fi

		echo "#uuid=" >> ${wfile}

		if [ ! "x${dtb}" = "x" ] ; then
			echo "dtb=${dtb}" >> ${wfile}
		else

			if [ ! "x${forced_dtb}" = "x" ] ; then
				echo "dtb=${forced_dtb}" >> ${wfile}
			else
				echo "#dtb=" >> ${wfile}
			fi

			if [ "x${conf_board}" = "xbeagle_x15" ] ; then
				echo "" >> ${wfile}
				echo "###U-Boot Overlays###" >> ${wfile}
				echo "###Documentation: http://elinux.org/Beagleboard:BeagleBoneBlack_Debian#U-Boot_Overlays" >> ${wfile}
				echo "###Master Enable" >> ${wfile}
				if [ "x${uboot_cape_overlays}" = "xenable" ] ; then
					echo "enable_uboot_overlays=1" >> ${wfile}
				else
					echo "#enable_uboot_overlays=1" >> ${wfile}
				fi
				echo "###" >> ${wfile}
				echo "###Overide capes with eeprom" >> ${wfile}
				echo "#uboot_overlay_addr0=<file0>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr1=<file1>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr2=<file2>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr3=<file3>.dtbo" >> ${wfile}
				echo "###" >> ${wfile}
				echo "###Additional custom capes" >> ${wfile}
				echo "#uboot_overlay_addr4=<file4>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr5=<file5>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr6=<file6>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr7=<file7>.dtbo" >> ${wfile}
				echo "###" >> ${wfile}
				echo "###Custom Cape" >> ${wfile}
				echo "#dtb_overlay=<file8>.dtbo" >> ${wfile}
				echo "###" >> ${wfile}
				echo "###Debug: disable uboot autoload of Cape" >> ${wfile}
				echo "#disable_uboot_overlay_addr0=1" >> ${wfile}
				echo "#disable_uboot_overlay_addr1=1" >> ${wfile}
				echo "#disable_uboot_overlay_addr2=1" >> ${wfile}
				echo "#disable_uboot_overlay_addr3=1" >> ${wfile}
				echo "###" >> ${wfile}
				echo "###U-Boot fdt tweaks... (60000 = 384KB)" >> ${wfile}
				echo "#uboot_fdt_buffer=0x60000" >> ${wfile}
				echo "###U-Boot Overlays###" >> ${wfile}
				echo "" >> ${wfile}
			fi

			if [ "x${conf_board}" = "xam335x_boneblack" ] || [ "x${conf_board}" = "xam335x_evm" ] || [ "x${conf_board}" = "xam335x_blank_bbbw" ] ; then

				echo "" >> ${wfile}
				echo "###U-Boot Overlays###" >> ${wfile}
				echo "###Documentation: http://elinux.org/Beagleboard:BeagleBoneBlack_Debian#U-Boot_Overlays" >> ${wfile}
				echo "###Master Enable" >> ${wfile}
				if [ "x${uboot_cape_overlays}" = "xenable" ] ; then
					echo "enable_uboot_overlays=1" >> ${wfile}
				else
					echo "#enable_uboot_overlays=1" >> ${wfile}
				fi
				echo "###" >> ${wfile}
				echo "###Overide capes with eeprom" >> ${wfile}
				echo "#uboot_overlay_addr0=<file0>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr1=<file1>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr2=<file2>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr3=<file3>.dtbo" >> ${wfile}
				echo "###" >> ${wfile}
				echo "###Additional custom capes" >> ${wfile}
				echo "#uboot_overlay_addr4=<file4>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr5=<file5>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr6=<file6>.dtbo" >> ${wfile}
				echo "#uboot_overlay_addr7=<file7>.dtbo" >> ${wfile}
				echo "###" >> ${wfile}
				echo "###Custom Cape" >> ${wfile}
				echo "#dtb_overlay=<file8>.dtbo" >> ${wfile}
				echo "###" >> ${wfile}
				echo "###Disable auto loading of virtual capes (emmc/video/wireless/adc)" >> ${wfile}
				if [ "x${uboot_disable_emmc}" = "xenable" ] ; then
					echo "disable_uboot_overlay_emmc=1" >> ${wfile}
				else
					echo "#disable_uboot_overlay_emmc=1" >> ${wfile}
				fi
				if [ "x${uboot_disable_video}" = "xenable" ] ; then
					echo "disable_uboot_overlay_video=1" >> ${wfile}
				else
					echo "#disable_uboot_overlay_video=1" >> ${wfile}
				fi
				if [ "x${uboot_disable_audio}" = "xenable" ] ; then
					echo "disable_uboot_overlay_audio=1" >> ${wfile}
				else
					echo "#disable_uboot_overlay_audio=1" >> ${wfile}
				fi
				echo "#disable_uboot_overlay_wireless=1" >> ${wfile}
				echo "#disable_uboot_overlay_adc=1" >> ${wfile}
				if [ "x${uboot_disable_pru}" = "x" ] ; then
					echo "###" >> ${wfile}
					echo "###PRUSS OPTIONS" >> ${wfile}
					unset use_pru_uio
					if [ "x${uboot_pru_rproc_414ti}" = "xenable" ] ; then
						echo "###pru_rproc (4.14.x-ti kernel)" >> ${wfile}
						echo "uboot_overlay_pru=AM335X-PRU-RPROC-4-14-TI-00A0.dtbo" >> ${wfile}
						echo "###pru_rproc (4.19.x-ti kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-RPROC-4-19-TI-00A0.dtbo" >> ${wfile}
						echo "###pru_uio (4.14.x-ti, 4.19.x-ti & mainline/bone kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-UIO-00A0.dtbo" >> ${wfile}
						use_pru_uio="blocked"
					fi
					if [ "x${uboot_pru_rproc_419ti}" = "xenable" ] ; then
						echo "###pru_rproc (4.14.x-ti kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-RPROC-4-14-TI-00A0.dtbo" >> ${wfile}
						echo "###pru_rproc (4.19.x-ti kernel)" >> ${wfile}
						echo "uboot_overlay_pru=AM335X-PRU-RPROC-4-19-TI-00A0.dtbo" >> ${wfile}
						echo "###pru_uio (4.14.x-ti, 4.19.x-ti & mainline/bone kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-UIO-00A0.dtbo" >> ${wfile}
						use_pru_uio="blocked"
					fi
					if [ "x${uboot_pru_rproc_54ti}" = "xenable" ] ; then
						echo "###pru_rproc (4.14.x-ti kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-RPROC-4-14-TI-00A0.dtbo" >> ${wfile}
						echo "###pru_rproc (4.19.x-ti kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-RPROC-4-19-TI-00A0.dtbo" >> ${wfile}
						echo "###pru_uio (4.14.x-ti, 4.19.x-ti & mainline/bone kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-UIO-00A0.dtbo" >> ${wfile}
						use_pru_uio="blocked"
					fi
					if [ "x${mainline_pru_rproc}" = "xenable" ] ; then
						echo "###pru_rproc (4.14.x-ti kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-RPROC-4-14-TI-00A0.dtbo" >> ${wfile}
						echo "###pru_rproc (4.19.x-ti kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-RPROC-4-19-TI-00A0.dtbo" >> ${wfile}
						echo "###pru_uio (4.14.x-ti, 4.19.x-ti & mainline/bone kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-UIO-00A0.dtbo" >> ${wfile}
						use_pru_uio="blocked"
					fi
					if [ "x${optional_mainline_uio}" = "xenable" ] ; then
						echo "###pru_uio (5.4.106-ti-rt-r40 & 5.10.100-ti-r40 newer...)" >> ${wfile}
						echo "###Default is PRU_REMOTEPROC, but classic UIO_PRUSS can be enabled here." >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-UIO-00A0.dtbo" >> ${wfile}
						use_pru_uio="blocked"
					fi
					if [ "x${use_pru_uio}" = "x" ] ; then
						echo "###pru_rproc (4.14.x-ti kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-RPROC-4-14-TI-00A0.dtbo" >> ${wfile}
						echo "###pru_rproc (4.19.x-ti kernel)" >> ${wfile}
						echo "#uboot_overlay_pru=AM335X-PRU-RPROC-4-19-TI-00A0.dtbo" >> ${wfile}
						echo "###pru_uio (4.14.x-ti, 4.19.x-ti & mainline/bone kernel)" >> ${wfile}
						echo "uboot_overlay_pru=AM335X-PRU-UIO-00A0.dtbo" >> ${wfile}
					fi
				fi
				echo "###" >> ${wfile}
				echo "###Cape Universal Enable" >> ${wfile}
				if [ "x${uboot_cape_overlays}" = "xenable" ] && [ "x${enable_cape_universal}" = "xenable" ] ; then
					echo "enable_uboot_cape_universal=1" >> ${wfile}
				else
					echo "#enable_uboot_cape_universal=1" >> ${wfile}
				fi
				echo "###" >> ${wfile}
				echo "###Debug: disable uboot autoload of Cape" >> ${wfile}
				echo "#disable_uboot_overlay_addr0=1" >> ${wfile}
				echo "#disable_uboot_overlay_addr1=1" >> ${wfile}
				echo "#disable_uboot_overlay_addr2=1" >> ${wfile}
				echo "#disable_uboot_overlay_addr3=1" >> ${wfile}
				echo "###" >> ${wfile}
				echo "###U-Boot fdt tweaks... (60000 = 384KB)" >> ${wfile}
				echo "#uboot_fdt_buffer=0x60000" >> ${wfile}
				echo "###U-Boot Overlays###" >> ${wfile}

				echo "" >> ${wfile}

				###Todo: make this more generic so you can specify any overlay...
				if [ "x${load_custom_overlay}" = "xenable" ] ; then
					echo "###" >> ${wfile}
					echo "dtb_overlay=PB-HACKADAY-2021.dtbo" >> ${wfile}
					echo "" >> ${wfile}
				fi
				
				# specified bela device tree overlay
				if [ "x${load_bela_overlay}" = "xenable" ] ; then
					echo "###" >> ${wfile}
					echo "uboot_overlay_addr4=BB-BELA-00A1.dtbo" >> ${wfile}
					echo "uboot_overlay_addr5=BB-BELA-CTAG-SPI-00A0.dtbo" >> ${wfile}
					echo "" >> ${wfile}
				fi
			fi
		fi

		if [ ! "x${extlinux_console}" = "x" ] ; then
			echo "console=${extlinux_console}" >> ${wfile}
		fi

		cmdline="coherent_pool=1M net.ifnames=0"

		if [ ! "x${loops_per_jiffy}" = "x" ] ; then
			cmdline="${cmdline} ${loops_per_jiffy}"
		fi

		if [ ! "x${rng_core}" = "x" ] ; then
			cmdline="${cmdline} ${rng_core}"
		fi

		cmdline="${cmdline} quiet"

		unset kms_video

		drm_device_identifier=${drm_device_identifier:-"HDMI-A-1"}
		drm_device_timing=${drm_device_timing:-"1024x768@60e"}
		if [ "x${drm_read_edid_broken}" = "xenable" ] ; then
			cmdline="${cmdline} video=${drm_device_identifier}:${drm_device_timing}"
			echo "cmdline=${cmdline}" >> ${wfile}
			echo "" >> ${wfile}
		else
			echo "cmdline=${cmdline}" >> ${wfile}
			echo "" >> ${wfile}

			echo "#In the event of edid real failures, uncomment this next line:" >> ${wfile}
			echo "#cmdline=${cmdline} video=${drm_device_identifier}:${drm_device_timing}" >> ${wfile}
			echo "" >> ${wfile}
		fi

		echo "#Use an overlayfs on top of a read-only root filesystem:" >> ${wfile}
		echo "#cmdline=${cmdline} overlayroot=tmpfs" >> ${wfile}
		echo "" >> ${wfile}

		if [ "x${conf_board}" = "xam335x_boneblack" ] || [ "x${conf_board}" = "xam335x_evm" ] || [ "x${conf_board}" = "xam335x_blank_bbbw" ] ; then
			if [ ! "x${has_post_uenvtxt}" = "x" ] ; then
				cat "${DIR}/post-uEnv.txt" >> ${wfile}
				echo "" >> ${wfile}
			fi

			if [ "x${emmc_flasher}" = "xenable" ] ; then
				echo "##enable Generic eMMC Flasher:" >> ${wfile}
				if [ -f ${TEMPDIR}/disk/usr/sbin/init-beagle-flasher ] ; then
					echo "cmdline=init=/usr/sbin/init-beagle-flasher" >> ${wfile}
				else
					echo "cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3.sh" >> ${wfile}
				fi
			elif [ "x${bbg_flasher}" = "xenable" ] ; then
				echo "##enable BBG: eMMC Flasher:" >> ${wfile}
				echo "cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3-bbg.sh" >> ${wfile}
			elif [ "x${bbgw_flasher}" = "xenable" ] ; then
				echo "##enable BBG: eMMC Flasher:" >> ${wfile}
				echo "cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3-bbgw.sh" >> ${wfile}
			elif [ "x${bbbl_flasher}" = "xenable" ] ; then
				echo "##enable bbbl: eMMC Flasher:" >> ${wfile}
				echo "cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3-bbbl.sh" >> ${wfile}
			elif [ "x${bbbw_flasher}" = "xenable" ] ; then
				echo "##enable bbbw: eMMC Flasher:" >> ${wfile}
				echo "cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3-bbbw.sh" >> ${wfile}
			else
				echo "##enable Generic eMMC Flasher:" >> ${wfile}
				if [ -f ${TEMPDIR}/disk/usr/sbin/init-beagle-flasher ] ; then
					echo "#cmdline=init=/usr/sbin/init-beagle-flasher" >> ${wfile}
				else
					echo "#cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3.sh" >> ${wfile}
				fi
			fi
			echo "" >> ${wfile}
		else
			if [ "x${emmc_flasher}" = "xenable" ] ; then
				echo "##enable Generic eMMC Flasher:" >> ${wfile}
				if [ -f ${TEMPDIR}/disk/usr/sbin/init-beagle-flasher ] ; then
					echo "cmdline=init=/usr/sbin/init-beagle-flasher" >> ${wfile}
				else
					echo "cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3-no-eeprom.sh" >> ${wfile}
				fi
			else
				if [ "x${conf_board}" = "xbeagle_x15" ] ; then
					echo "##enable Generic eMMC Flasher:" >> ${wfile}
					if [ -f ${TEMPDIR}/disk/usr/sbin/init-beagle-flasher ] ; then
						echo "#cmdline=init=/usr/sbin/init-beagle-flasher" >> ${wfile}
					else
						echo "#cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3-no-eeprom.sh" >> ${wfile}
					fi
				fi
			fi
		fi

		#am335x_boneblack is a custom u-boot to ignore empty factory eeproms...
		if [ "x${conf_board}" = "xam335x_boneblack" ] ; then
			board="am335x_evm"
		else
			board=${conf_board}
		fi

		echo "/boot/uEnv.txt---------------"

		#Starting in v6.5, overlays/dtbo files get dumped in the same directory as dtb's CONFIG_ARCH_WANT_FLAT_DTB_INSTALL
		#https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/scripts/Makefile.dtbinst?h=v6.5-rc1#n37
		#copy these under /boot/dtbs/${version}/overlays/ for older versions of u-boot.
		if [ "x${kernel_override}" = "x" ] ; then
			if [ -d ${TEMPDIR}/disk/usr/lib/linux-image-${select_kernel}/ ] ; then
				cp ${TEMPDIR}/disk/usr/lib/linux-image-${select_kernel}/*.dtb ${TEMPDIR}/disk/boot/dtbs/${select_kernel}/ || true
				mkdir -p ${TEMPDIR}/disk/boot/dtbs/${select_kernel}/overlays/ || true
				cp ${TEMPDIR}/disk/usr/lib/linux-image-${select_kernel}/*.dtbo ${TEMPDIR}/disk/boot/dtbs/${select_kernel}/overlays/ || true
				cp ${TEMPDIR}/disk/usr/lib/linux-image-${select_kernel}/overlays/*.dtbo ${TEMPDIR}/disk/boot/dtbs/${select_kernel}/overlays/ || true
			fi
		else
			if [ -d ${TEMPDIR}/disk/usr/lib/linux-image-${kernel_override}/ ] ; then
				cp ${TEMPDIR}/disk/usr/lib/linux-image-${kernel_override}/*.dtb ${TEMPDIR}/disk/boot/dtbs/${kernel_override}/ || true
				mkdir -p ${TEMPDIR}/disk/boot/dtbs/${kernel_override}/overlays/ || true
				cp ${TEMPDIR}/disk/usr/lib/linux-image-${kernel_override}/*.dtbo ${TEMPDIR}/disk/boot/dtbs/${kernel_override}/overlays/ || true
				cp ${TEMPDIR}/disk/usr/lib/linux-image-${kernel_override}/overlays/*.dtbo ${TEMPDIR}/disk/boot/dtbs/${kernel_override}/overlays/ || true
			fi
		fi
	fi

	cat ${wfile}
	chown -R 1000:1000 ${wfile} || true
	echo "-----------------------------"

	wfile="${TEMPDIR}/disk/boot/SOC.sh"
	generate_soc

	#RootStock-NG
	if [ -f ${TEMPDIR}/disk/etc/rcn-ee.conf ] ; then
		. ${TEMPDIR}/disk/etc/rcn-ee.conf

		if [ "x${uboot_firwmare_dir}" = "xenable" ] ; then
			mkdir -p ${TEMPDIR}/disk/boot/firmware || true
		else
			mkdir -p ${TEMPDIR}/disk/boot/uboot || true
		fi

		wfile="${TEMPDIR}/disk/etc/fstab"
		echo "# /etc/fstab: static file system information." > ${wfile}
		echo "#" >> ${wfile}
		echo "# Auto generated by RootStock-NG: setup_sdcard.sh" >> ${wfile}
		echo "#" >> ${wfile}
		echo "# The root file system has fs_passno=1 as per fstab(5) for automatic fsck." >> ${wfile}
		if [ "${BTRFS_FSTAB}" ] ; then
			echo "${rootfs_drive}  /  btrfs  defaults,noatime  0  1" >> ${wfile}
		else
			echo "${rootfs_drive}  /  ${ROOTFS_TYPE}  noatime,errors=remount-ro  0  1" >> ${wfile}
		fi

		if [ "x${uboot_efi_mode}" = "xenable" ] ; then
			echo "# All other file systems have fs_passno=2 as per fstab(5) for automatic fsck." >> ${wfile}
			echo "${boot_drive}  /boot/efi vfat user,uid=1000,gid=1000,defaults 0 2" >> ${wfile}
		fi

		if [ "x${uboot_firwmare_dir}" = "xenable" ] ; then
			echo "# All other file systems have fs_passno=2 as per fstab(5) for automatic fsck." >> ${wfile}
			echo "${boot_drive}  /boot/firmware vfat user,uid=1000,gid=1000,defaults 0 2" >> ${wfile}
		fi

		if [ "x${swap_enable}" = "xenable" ] ; then
			echo "${swap_drive}       none    swap    sw      0       0" >> ${wfile}
		fi

		echo "debugfs  /sys/kernel/debug  debugfs  mode=755,uid=root,gid=gpio,defaults  0  0" >> ${wfile}

		if [ -f ${TEMPDIR}/disk/var/www/index.html ] ; then
			rm -f ${TEMPDIR}/disk/var/www/index.html || true
		fi

		if [ -f ${TEMPDIR}/disk/var/www/html/index.html ] ; then
			rm -f ${TEMPDIR}/disk/var/www/html/index.html || true
		fi
		sync

	fi #RootStock-NG

	if [ ! "x${spl_uboot_name}" = "x" ] ; then
		echo "Backup version of u-boot (${spl_uboot_name}): /opt/backup/uboot/"
		mkdir -p ${TEMPDIR}/disk/opt/backup/uboot/
		if [ "${conf_bl_distro_SPL}" ] ; then
			cp -v ./${conf_bl_distro_SPL} ${TEMPDIR}/disk/opt/backup/uboot/${spl_uboot_name}
		else
			cp -v ${TEMPDIR}/dl/${SPL} ${TEMPDIR}/disk/opt/backup/uboot/${spl_uboot_name}
		fi
	fi

	if [ ! "x${uboot_name}" = "x" ] ; then
		echo "Backup version of u-boot (${uboot_name}): /opt/backup/uboot/"
		mkdir -p ${TEMPDIR}/disk/opt/backup/uboot/
		if [ "${conf_bl_distro_UBOOT}" ] ; then
			cp -v ./${conf_bl_distro_UBOOT} ${TEMPDIR}/disk/opt/backup/uboot/${uboot_name}
		else
			cp -v ${TEMPDIR}/dl/${UBOOT} ${TEMPDIR}/disk/opt/backup/uboot/${uboot_name}
		fi
	fi

	if [ -f ${TEMPDIR}/disk/etc/init.d/cpufrequtils ] ; then
		if [ "x${conf_board}" = "xbeagle_x15" ] ; then
			sed -i 's/GOVERNOR="ondemand"/GOVERNOR="powersave"/g' ${TEMPDIR}/disk/etc/init.d/cpufrequtils
		else
			sed -i 's/GOVERNOR="ondemand"/GOVERNOR="performance"/g' ${TEMPDIR}/disk/etc/init.d/cpufrequtils
		fi
	fi

	if [ "x${drm}" = "xomapdrm" ] ; then
		wfile="/etc/X11/xorg.conf"
		if [ -f ${TEMPDIR}/disk${wfile} ] ; then
			sed -i -e 's:modesetting:omap:g' ${TEMPDIR}/disk${wfile}
			sed -i -e 's:fbdev:omap:g' ${TEMPDIR}/disk${wfile}

			if [ "x${conf_board}" = "xomap3_beagle" ] ; then
				sed -i -e 's:#HWcursor_false::g' ${TEMPDIR}/disk${wfile}
				sed -i -e 's:#DefaultDepth::g' ${TEMPDIR}/disk${wfile}
			else
				sed -i -e 's:#HWcursor_false::g' ${TEMPDIR}/disk${wfile}
			fi
		fi
	fi

	if [ "x${drm}" = "xetnaviv" ] ; then
		wfile="/etc/X11/xorg.conf"
		if [ -f ${TEMPDIR}/disk${wfile} ] ; then
			if [ -f ${TEMPDIR}/disk/usr/lib/xorg/modules/drivers/armada_drv.so ] ; then
				sed -i -e 's:modesetting:armada:g' ${TEMPDIR}/disk${wfile}
				sed -i -e 's:fbdev:armada:g' ${TEMPDIR}/disk${wfile}
			fi
		fi
	fi

	if [ "${usbnet_mem}" ] ; then
		echo "vm.min_free_kbytes = ${usbnet_mem}" >> ${TEMPDIR}/disk/etc/sysctl.conf
	fi

	if [ ! "x${new_hostname}" = "x" ] ; then
		echo "Updating Image hostname too: [${new_hostname}]"

		wfile="/etc/hosts"
		echo "127.0.0.1	localhost" > ${TEMPDIR}/disk${wfile}
		echo "127.0.1.1	${new_hostname}.localdomain	${new_hostname}" >> ${TEMPDIR}/disk${wfile}
		echo "" >> ${TEMPDIR}/disk${wfile}
		echo "# The following lines are desirable for IPv6 capable hosts" >> ${TEMPDIR}/disk${wfile}
		echo "::1		localhost ip6-localhost ip6-loopback" >> ${TEMPDIR}/disk${wfile}
		echo "ff02::1		ip6-allnodes" >> ${TEMPDIR}/disk${wfile}
		echo "ff02::2		ip6-allrouters" >> ${TEMPDIR}/disk${wfile}

		wfile="/etc/hostname"
		echo "${new_hostname}" > ${TEMPDIR}/disk${wfile}
	fi

	# setuid root ping+ping6 - capabilities does not survive tar
	if [ -x  ${TEMPDIR}/disk/bin/ping ] ; then
		echo "making ping/ping6 setuid root"
		chmod u+s ${TEMPDIR}/disk/bin/ping ${TEMPDIR}/disk/bin/ping6
	fi

	if [ "x${conf_board}" = "xam335x_boneblack" ] || [ "x${conf_board}" = "xam335x_evm" ] ; then
		if [ -f ${TEMPDIR}/disk/etc/default/generic-sys-mods ] ; then
			sed -i -e 's:generic:am335x:g' ${TEMPDIR}/disk/etc/default/generic-sys-mods
		fi
		if [ -f ${TEMPDIR}/disk/etc/beagle-flasher/beaglebone-black-microsd-to-emmc ] ; then
			cp -v ${TEMPDIR}/disk/etc/beagle-flasher/beaglebone-black-microsd-to-emmc ${TEMPDIR}/disk/etc/default/beagle-flasher
		fi
	fi

	if [ "x${conf_board}" = "xbeagle_x15" ] ; then
		if [ -f ${TEMPDIR}/disk/etc/default/generic-sys-mods ] ; then
			sed -i -e 's:generic:am57xx:g' ${TEMPDIR}/disk/etc/default/generic-sys-mods
		fi
		if [ -f ${TEMPDIR}/disk/etc/beagle-flasher/bbai-microsd-to-emmc ] ; then
			cp -v ${TEMPDIR}/disk/etc/beagle-flasher/bbai-microsd-to-emmc ${TEMPDIR}/disk/etc/default/beagle-flasher
		fi
	fi

	if [ ! "x${flasher_script}" = "x" ] ; then
		if [ -f ${TEMPDIR}/disk${flasher_script} ] ; then
			cp -v ${TEMPDIR}/disk${flasher_script} ${TEMPDIR}/disk/etc/default/beagle-flasher
		fi
	fi

	if [ -f ${TEMPDIR}/disk/etc/default/generic-sys-mods ] ; then
		echo "patching /etc/default/generic-sys-mods"
		if [ "x${board_hacks}" = "xj721e_evm" ] || [ "x${board_hacks}" = "xbbai64_staging" ] ; then
			echo "ARCH_SOC_MODULES=j721e" >> ${TEMPDIR}/disk/etc/default/generic-sys-mods
		fi
		if [ "x${board_hacks}" = "xsk_am62" ] || [ "x${board_hacks}" = "xbeagleplay" ] ; then
			echo "ARCH_SOC_MODULES=am62" >> ${TEMPDIR}/disk/etc/default/generic-sys-mods
		fi
		if [ "x${board_hacks}" = "xbeagley_ai" ] ; then
			echo "ARCH_SOC_MODULES=j722s" >> ${TEMPDIR}/disk/etc/default/generic-sys-mods
		fi
		if [ "x${swap_enable}" = "xenable" ] ; then
			sed -i -e "s:ROOT_PARTITION=2:ROOT_PARTITION=3:g" ${TEMPDIR}/disk/etc/default/generic-sys-mods
		fi
		cat ${TEMPDIR}/disk/etc/default/generic-sys-mods
	fi

	if [ "x${board_hacks}" = "xbeagleplay" ] ; then
		if [ ! -f ${TEMPDIR}/disk/etc/bbb.io/templates/services/SoftAp0.conf ] ; then
			if [ -f ${TEMPDIR}/disk/etc/hostapd/hostapd.conf ] ; then
				sed -i -e "s:BeagleBone-WXYZ:BeaglePlay-WXYZ:g" ${TEMPDIR}/disk/etc/hostapd/hostapd.conf
				sed -i -e "s:passphrase=BeagleBone:passphrase=BeaglePlay:g" ${TEMPDIR}/disk/etc/hostapd/hostapd.conf
			fi
			if [ -f ${TEMPDIR}/disk/etc/hostapd/SoftAp0.conf ] ; then
				sed -i -e "s:BeagleBone-WXYZ:BeaglePlay-WXYZ:g" ${TEMPDIR}/disk/etc/hostapd/SoftAp0.conf
				sed -i -e "s:passphrase=BeagleBone:passphrase=BeaglePlay:g" ${TEMPDIR}/disk/etc/hostapd/SoftAp0.conf
			fi
		fi

		if [ -f ${TEMPDIR}/disk/etc/systemd/network/mlan0.network ] ; then
			rm ${TEMPDIR}/disk/etc/systemd/network/mlan0.network || true
		fi

		if [ -f ${TEMPDIR}/disk/etc/systemd/system/multi-user.target.wants/wpa_supplicant@mlan0.service ] ; then
			rm ${TEMPDIR}/disk/etc/systemd/system/multi-user.target.wants/wpa_supplicant@mlan0.service || true
		fi
	fi

	if [ "x${extlinux_firmware_partition}" = "xenable" ] ; then
		if [ ! "x${extlinux_kernel}" = "x" ] ; then
			echo "Un-Compressed Kernel: [cp -v ${TEMPDIR}/disk/boot/${extlinux_kernel}-${select_kernel} ${TEMPDIR}/disk/boot/firmware/Image]"
			cp -v ${TEMPDIR}/disk/boot/${extlinux_kernel}-${select_kernel} ${TEMPDIR}/disk/boot/firmware/Image
		fi
		if [ ! "x${extlinux_compressed_kernel}" = "x" ] ; then
			echo "Compressed Kernel: [cat ${TEMPDIR}/disk/boot/${extlinux_compressed_kernel}-${select_kernel} | gunzip -d > ${TEMPDIR}/disk/boot/firmware/Image]"
			cat ${TEMPDIR}/disk/boot/${extlinux_compressed_kernel}-${select_kernel} | gunzip -d > ${TEMPDIR}/disk/boot/firmware/Image
		fi
		if [ ! "x${extlinux_dtb_vendor}" = "x" ] ; then
			if [ ! "x${extlinux_dtb_fam}" = "x" ] ; then
				mkdir -p ${TEMPDIR}/disk/boot/firmware/${extlinux_dtb_vendor}/ || true
				cp ${TEMPDIR}/disk/usr/lib/linux-image-${select_kernel}/${extlinux_dtb_vendor}/${extlinux_dtb_fam}*dtb ${TEMPDIR}/disk/boot/firmware/ || true
				cp ${TEMPDIR}/disk/usr/lib/linux-image-${select_kernel}/${extlinux_dtb_vendor}/${extlinux_dtb_fam}*dtb ${TEMPDIR}/disk/boot/firmware/${extlinux_dtb_vendor}/ || true
				mkdir -p ${TEMPDIR}/disk/boot/firmware/overlays/ || true
				cp ${TEMPDIR}/disk/usr/lib/linux-image-${select_kernel}/${extlinux_dtb_vendor}/*.dtbo ${TEMPDIR}/disk/boot/firmware/overlays/ || true
				if [ -d ${TEMPDIR}/disk/usr/lib/linux-image-${select_kernel}/${extlinux_dtb_vendor}/overlays/ ] ; then
					cp ${TEMPDIR}/disk/usr/lib/linux-image-${select_kernel}/${extlinux_dtb_vendor}/overlays/*.dtbo ${TEMPDIR}/disk/boot/firmware/overlays/ || true
				fi
			fi
		fi
		cp -v ${TEMPDIR}/disk/boot/initrd.img-${select_kernel} ${TEMPDIR}/disk/boot/firmware/initrd.img

		if [ -f ${TEMPDIR}/disk/etc/bbb.io/templates/sysconf.txt ] ; then
			cp ${TEMPDIR}/disk/etc/bbb.io/templates/sysconf.txt ${TEMPDIR}/disk/boot/firmware/sysconf.txt
			echo "sysconf: [cat ${TEMPDIR}/disk/boot/firmware/sysconf.txt]"
			cat ${TEMPDIR}/disk/boot/firmware/sysconf.txt
			if [ -d ${TEMPDIR}/disk/etc/bbb.io/templates/services/ ] ; then
				mkdir -p ${TEMPDIR}/disk/boot/firmware/services/enable/
				cp -r ${TEMPDIR}/disk/etc/bbb.io/templates/services/* ${TEMPDIR}/disk/boot/firmware/services/
			fi
		fi
	fi

	if [ "x${emmc_flasher}" = "xenable" ] ; then
		if [ -f ${TEMPDIR}/disk/etc/systemd/system/multi-user.target.wants/grow_partition.service ] ; then
			rm -rf ${TEMPDIR}/disk/etc/systemd/system/multi-user.target.wants/grow_partition.service || true
		fi
	fi

	if [ "x${extlinux_flasher}" = "xenable" ] ; then
		if [ -f ${TEMPDIR}/disk/etc/systemd/system/multi-user.target.wants/grow_partition.service ] ; then
			rm -rf ${TEMPDIR}/disk/etc/systemd/system/multi-user.target.wants/grow_partition.service || true
		fi
	fi

	if [ "x${disable_resize}" = "xenable" ] ; then
		if [ -f ${TEMPDIR}/disk/etc/systemd/system/multi-user.target.wants/grow_partition.service ] ; then
			rm -rf ${TEMPDIR}/disk/etc/systemd/system/multi-user.target.wants/grow_partition.service || true
		fi
	fi

	cd ${TEMPDIR}/disk/
	sync
	sync
	cd "${DIR}/"

	tree ${TEMPDIR}/disk/boot/ || true

	if [ "x${uboot_efi_mode}" = "xenable" ] ; then
		umount ${TEMPDIR}/disk/boot/efi || true
	fi

	if [ "x${extlinux_firmware_partition}" = "xenable" ] ; then
		umount ${TEMPDIR}/disk/boot/firmware || true
	fi

	umount ${TEMPDIR}/disk || true
	if [ "x${build_img_file}" = "xenable" ] ; then
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
	if [ "x${build_img_file}" = "xenable" ] ; then
		echo "Image file: ${imagename}"
		echo "-----------------------------"
	fi
}

check_mmc () {
	FDISK=$(LC_ALL=C fdisk -l 2>/dev/null | grep "Disk ${media}:" | awk '{print $2}')

	if [ "x${FDISK}" = "x${media}:" ] ; then
		echo ""
		echo "I see..."
		echo ""
		echo "lsblk:"
		lsblk | grep -v sr0
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
		echo "lsblk:"
		lsblk | grep -v sr0
		echo ""
		exit
	fi
}

process_dtb_conf () {
	if [ "${conf_warning}" ] ; then
		show_board_warning
	fi

	echo "-----------------------------"

	#defaults, if not set...
	case "${bootloader_location}" in
	fatfs_boot)
		conf_boot_startmb=${conf_boot_startmb:-"1"}
		;;
	dd_uboot_boot|dd_spl_uboot_boot)
		conf_boot_startmb=${conf_boot_startmb:-"4"}
		;;
	*)
		conf_boot_startmb=${conf_boot_startmb:-"4"}
		;;
	esac

	#https://wiki.linaro.org/WorkingGroups/KernelArchived/Projects/FlashCardSurvey
	conf_root_device=${conf_root_device:-"/dev/mmcblk0"}

	#error checking...
	if [ ! "${conf_boot_fstype}" ] ; then
		conf_boot_fstype="${ROOTFS_TYPE}"
	fi

	case "${conf_boot_fstype}" in
	fat|fat16)
		partition_one_fstype=${partition_one_fstype:-"0xE"}
		;;
	fat32)
		partition_one_fstype=${partition_one_fstype:-"0xC"}
		;;
	ext2|ext3|ext4|btrfs)
		partition_one_fstype="L"
		;;
	*)
		echo "Error: [conf_boot_fstype] not recognized, stopping..."
		exit
		;;
	esac

	if [ "x${uboot_cape_overlays}" = "xenable" ] ; then
		echo "U-Boot Overlays Enabled..."
	fi

	if [ ! "x${conf_swap_sizemb}" = "x" ] ; then
		swap_enable="enable"
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

error_invalid_dtb=1

# parse commandline options
while [ ! -z "$1" ] ; do
	case $1 in
	-h|--help)
		usage
		media=1
		;;
	--hostname)
		checkparm $2
		new_hostname="$2"
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
		disable_resize="enable"
		;;
	--img|--img-[1246]gb)
		checkparm $2
		name=${2:-image}
		gsize=$(echo "$1" | sed -ne 's/^--img-\([[:digit:]]\+\)gb$/\1/p')
		# --img defaults to --img-2gb
		gsize=${gsize:-2}
		imagename=${name%.img}-${gsize}gb.img
		media="${DIR}/${imagename}"
		build_img_file="enable"
		check_root
		if [ -f "${media}" ] ; then
			rm -rf "${media}" || true
		fi
		#FIXME: (should fit most microSD cards)
		#eMMC: (dd if=/dev/mmcblk1 of=/dev/null bs=1M #MB)
		#Micron   3744MB (bbb): 3925868544 bytes -> 3925.86 Megabyte
		#Kingston 3688MB (bbb): 3867148288 bytes -> 3867.15 Megabyte
		#Kingston 3648MB (x15): 3825205248 bytes -> 3825.21 Megabyte (3648)
		#
		### seek=$((1024 * (700 + (gsize - 1) * 1000)))
		## 1000 1GB = 700 #2GB = 1700 #4GB = 3700
		##  990 1GB = 700 #2GB = 1690 #4GB = 3670
		#
		### seek=$((1024 * (gsize * 850)))
		## x 850 (85%) #1GB = 850 #2GB = 1700 #4GB = 3400
		#
		### seek=$((1024 * (gsize * 900)))
		## x 900 (90%) #1GB = 900 #2GB = 1800 #4GB = 3600
		#
		dd if=/dev/zero of="${media}" bs=1024 count=0 seek=$((1024 * (gsize * 900)))
		;;
	--img-8gb)
		###FIXME, someone with better sed skills can add this to ^. ;)
		checkparm $2
		name=${2:-image}
		# --img defaults to --img-8gb
		gsize=${gsize:-8}
		imagename=${name%.img}-${gsize}gb.img
		media="${DIR}/${imagename}"
		build_img_file="enable"
		check_root
		if [ -f "${media}" ] ; then
			rm -rf "${media}" || true
		fi

		###For bigger storage let's assume closer to 100% capacity...
		dd if=/dev/zero of="${media}" bs=1024 count=0 seek=$((1024 * (gsize * 960)))
		;;
	--img-10gb)
		###FIXME, someone with better sed skills can add this to ^. ;)
		checkparm $2
		name=${2:-image}
		# --img defaults to --img-10gb
		gsize=${gsize:-10}
		imagename=${name%.img}-${gsize}gb.img
		media="${DIR}/${imagename}"
		build_img_file="enable"
		check_root
		if [ -f "${media}" ] ; then
			rm -rf "${media}" || true
		fi

		###For bigger storage let's assume closer to 100% capacity...
		dd if=/dev/zero of="${media}" bs=1024 count=0 seek=$((1024 * (gsize * 1024)))
		;;
	--img-12gb)
		###FIXME, someone with better sed skills can add this to ^. ;)
		checkparm $2
		name=${2:-image}
		# --img defaults to --img-12gb
		gsize=${gsize:-12}
		imagename=${name%.img}-${gsize}gb.img
		media="${DIR}/${imagename}"
		build_img_file="enable"
		check_root
		if [ -f "${media}" ] ; then
			rm -rf "${media}" || true
		fi

		###For bigger storage let's assume closer to 100% capacity...
		dd if=/dev/zero of="${media}" bs=1024 count=0 seek=$((1024 * (gsize * 1024)))
		;;
	--dtb)
		checkparm $2
		dtb_board="$2"
		dir_check="${DIR}/"
		check_dtb_board
		;;
	--ro)
		echo "[--ro] is obsolete, and has been removed..."
		exit 2
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
	--distro-bootloader)
		USE_DISTRO_BOOTLOADER=1
		;;
	--spl)
		checkparm $2
		LOCAL_SPL="$2"
		SPL="${LOCAL_SPL##*/}"
		blank_SPL="${SPL}"
		USE_LOCAL_BOOT=1
		;;
	--bootloader)
		checkparm $2
		LOCAL_BOOTLOADER="$2"
		UBOOT="${LOCAL_BOOTLOADER##*/}"
		blank_UBOOT="${UBOOT}"
		USE_LOCAL_BOOT=1
		;;
	--use-beta-bootloader)
		USE_BETA_BOOTLOADER=1
		;;
	--a335-flasher)
		echo "[--a335-flasher] is obsolete, and has been removed..."
		exit 2
		;;
	--bp00-flasher)
		echo "[--bp00-flasher] is obsolete, and has been removed..."
		exit 2
		;;
	--bbg-flasher)
		oem_blank_eeprom="enable"
		bbg_flasher="enable"
		;;
	--bbgw-flasher)
		oem_blank_eeprom="enable"
		bbgw_flasher="enable"
		;;
	--bbgg-flasher)
		oem_blank_eeprom="enable"
		uboot_eeprom="bbgg_blank"
		#default:
		emmc_flasher="enable"
		;;
	--m10a-flasher)
		echo "[--m10a-flasher] is obsolete, and has been removed..."
		exit 2
		;;
	--me06-flasher)
		echo "[--me06-flasher] is obsolete, and has been removed..."
		exit 2
		;;
	--bbb-usb-flasher|--usb-flasher|--oem-flasher)
		echo "[--bbb-usb-flasher|--usb-flasher|--oem-flasher] is obsolete, and has been removed..."
		exit 2
		;;
	--bbb-flasher|--emmc-flasher)
		oem_blank_eeprom="enable"
		uboot_eeprom="bbb_blank"
		#default:
		emmc_flasher="enable"
		;;
	--bbbl-flasher)
		oem_blank_eeprom="enable"
		bbbl_flasher="enable"
		uboot_eeprom="bbbl_blank"
		;;
	--bbbw-flasher)
		oem_blank_eeprom="enable"
		bbbw_flasher="enable"
		uboot_eeprom="bbbw_blank"
		;;
	--bbb-old-bootloader-in-emmc)
		echo "[--bbb-old-bootloader-in-emmc] is obsolete, and has been removed..."
		exit 2
		;;
	--x15-force-revb-flash)
		x15_force_revb_flash="enable"
		;;
	--am57xx-x15-flasher)
		flasher_uboot="beagle_x15_flasher"
		;;
	--am57xx-x15-revc-flasher)
		flasher_uboot="beagle_x15_revc_flasher"
		;;
	--am571x-sndrblock-flasher)
		flasher_uboot="am571x_sndrblock_flasher"
		;;
	--oem-flasher-script)
		checkparm $2
		oem_flasher_script="$2"
		;;
	--oem-flasher-img)
		checkparm $2
		oem_flasher_img="$2"
		;;
	--oem-flasher-eeprom)
		checkparm $2
		oem_flasher_eeprom="$2"
		;;
	--oem-flasher-job)
		checkparm $2
		oem_flasher_job="$2"
		;;
	--enable-systemd)
		echo "--enable-systemd: option is depreciated (enabled by default Jessie+)"
		;;
	--enable-cape-universal)
		enable_cape_universal="enable"
		;;
	--enable-uboot-cape-overlays)
		uboot_cape_overlays="enable"
		;;
	--enable-uboot-disable-emmc)
		uboot_disable_emmc="enable"
		;;
	--enable-uboot-disable-video)
		uboot_disable_video="enable"
		;;
	--enable-uboot-disable-audio)
		uboot_disable_audio="enable"
		;;
	--enable-uboot-pru-rproc-44ti)
		echo "[--enable-uboot-pru-rproc-44ti] is obsolete, use [--enable-uboot-pru-rproc-414ti]"
		exit 2
		;;
	--enable-uboot-pru-rproc-49ti)
		echo "[--enable-uboot-pru-rproc-49ti] is obsolete, use [--enable-uboot-pru-rproc-414ti]"
		exit 2
		;;
	--enable-uboot-pru-rproc-414ti)
		uboot_pru_rproc_414ti="enable"
		;;
	--enable-uboot-pru-rproc-419ti)
		uboot_pru_rproc_419ti="enable"
		;;
	--enable-uboot-pru-rproc-54ti)
		uboot_pru_rproc_54ti="enable"
		;;
	--enable-mainline-pru-rproc)
		mainline_pru_rproc="enable"
		;;
	--enable-uboot-pru-uio-419)
		echo "[--enable-uboot-pru-uio-419] is obsolete, and has been removed..."
		exit 2
		;;
	--optional-uboot-uio-pru)
		optional_mainline_uio="enable"
		;;
	--enable-uboot-disable-pru)
		uboot_disable_pru="enable"
		;;
	--enable-bypass-bootup-scripts)
		bypass_bootup_scripts="enable"
		;;
	--enable-load-custom-overlay)
		load_custom_overlay="enable"
		;;
	# enable bela overlay
	--enable-load-bela-overlay)
		load_bela_overlay="enable"
		;;
	--efi)
		uboot_efi_mode="enable"
		;;
	--enable-extlinux-flasher)
		extlinux_flasher="enable"
		;;
	--offline)
		offline=1
		;;
	--kernel)
		checkparm $2
		kernel_override="$2"
		;;
	--enable-cape)
		#checkparm $2
		#oobe_cape="$2"
		echo "[--enable-cape XYZ] is obsolete, and has been removed..."
		exit 2
		;;
	--enable-fat-partition)
		enable_fat_partition="enable"
		;;
	--force-device-tree)
		checkparm $2
		forced_dtb="$2"
		;;
	esac
	shift
done

if [ ! "${media}" ] ; then
	echo "ERROR: --mmc undefined"
	usage
fi

if [ "${error_invalid_dtb}" ] ; then
	echo "-----------------------------"
	echo "ERROR: --dtb undefined"
	echo "-----------------------------"
	usage
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

	if [ ! "x${conf_boot_fstype}" = "xfat" ] ; then
		conf_boot_fstype="btrfs"
	fi
fi

find_issue
detect_software

if [ "${spl_name}" ] || [ "${boot_name}" ] ; then
	if [ "${USE_LOCAL_BOOT}" ] ; then
		local_bootloader
	elif [ "${USE_DISTRO_BOOTLOADER}" ] ; then
		distro_bootloader
	else
		dl_bootloader
	fi
fi

if [ ! "x${build_img_file}" = "xenable" ] ; then
	unmount_all_drive_partitions
fi
create_partitions
populate_boot
populate_rootfs
exit 0
#
