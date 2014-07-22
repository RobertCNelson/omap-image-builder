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

BOOT_LABEL="BOOT"

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

VALID_ROOTFS_TYPES="ext2 ext3 ext4"

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

	if [ "x${build_img_file}" = "xenable" ] ; then
		check_for_command kpartx kpartx
	fi

	if [ "${NEEDS_COMMAND}" ] ; then
		echo ""
		echo "Your system is missing some dependencies"
		echo "Debian/Ubuntu: sudo apt-get install dosfstools git-core kpartx wget parted"
		echo "Fedora: yum install dosfstools dosfstools git-core wget"
		echo "Gentoo: emerge dosfstools git wget"
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
		SPL=${LOCAL_SPL##*/}
		echo "SPL Bootloader: ${SPL}"
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
		SPL=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:SPL" | awk '{print $2}')
		wget --no-verbose --directory-prefix="${TEMPDIR}/dl/" ${SPL}
		SPL=${SPL##*/}
		echo "SPL Bootloader: ${SPL}"
	else
		unset SPL
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
	dd if=/dev/zero of=${media} bs=1M count=100 || drive_error_ro
	sync
	dd if=${media} of=/dev/null bs=1M count=100
	sync
}

sfdisk_partition_layout () {
	echo ""
	echo "Using sfdisk to create partition layout"
	echo "-----------------------------"

	LC_ALL=C sfdisk --force --in-order --Linux --unit M "${media}" <<-__EOF__
		${conf_boot_startmb},${conf_boot_endmb},${sfdisk_fstype},*
		,,,-
	__EOF__

	sync
}

sfdisk_single_partition_layout () {
	echo ""
	echo "Using sfdisk to create partition layout"
	echo "-----------------------------"

	LC_ALL=C sfdisk --force --in-order --Linux --unit M "${media}" <<-__EOF__
		${conf_boot_startmb},,${sfdisk_fstype},-
	__EOF__

	sync
}

dd_uboot_boot () {
	#For: Freescale: i.mx5/6 Devices
	echo ""
	echo "Using dd to place bootloader on drive"
	echo "-----------------------------"
	dd if=${TEMPDIR}/dl/${UBOOT} of=${media} seek=${dd_uboot_seek} bs=${dd_uboot_bs}
	bootloader_installed=1
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
	echo "LC_ALL=C ${mkfs} ${mkfs_partition} ${mkfs_label}"
	echo "Failure: formating partition"
	exit
}

format_partition () {
	echo "Formating with: [${mkfs} ${mkfs_partition} ${mkfs_label}]"
	echo "-----------------------------"
	LC_ALL=C ${mkfs} ${mkfs_partition} ${mkfs_label} || format_partition_error
	sync
}

format_boot_partition () {
	mkfs_partition="${media_prefix}${media_boot_partition}"

	if [ "x${conf_boot_fstype}" = "xfat" ] ; then
		mount_partition_format="vfat"
		mkfs="mkfs.vfat -F 16"
		mkfs_label="-n ${BOOT_LABEL}"
	else
		mount_partition_format="${conf_boot_fstype}"
		mkfs="mkfs.${conf_boot_fstype}"
		mkfs_label="-L ${BOOT_LABEL}"
	fi

	format_partition
}

format_rootfs_partition () {
	mkfs="mkfs.${ROOTFS_TYPE}"
	mkfs_partition="${media_prefix}${media_rootfs_partition}"
	mkfs_label="-L ${ROOTFS_LABEL}"

	format_partition

	if [ "x${build_img_file}" = "xenable" ] ; then
		rootfs_drive="${conf_root_device}p${media_rootfs_partition}"
	else
		unset rootfs_uuid
		rootfs_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${mkfs_partition} || true)
		if [ ! "x${rootfs_uuid}" = "x" ] ; then
			rootfs_drive="UUID=${rootfs_uuid}"
		else
			rootfs_drive="${conf_root_device}p${media_rootfs_partition}"
		fi
	fi
}

create_partitions () {
	unset bootloader_installed

	media_boot_partition=1
	media_rootfs_partition=2

	case "${bootloader_location}" in
	fatfs_boot)
		sfdisk_partition_layout
		;;
	dd_uboot_boot)
		dd_uboot_boot
		sfdisk_single_partition_layout
		media_rootfs_partition=1
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
		format_rootfs_partition
	fi
}

boot_git_tools () {
	if [ ! "${offline}" ] && [ "${bborg_production}" ] ; then
		case "${SYSTEM}" in
		bone)
			echo "Debug: Adding BeagleBone drivers from: https://github.com/beagleboard/beaglebone-getting-started"
			#Not planning to change these too often, once pulled, remove .git stuff...
			mkdir -p ${TEMPDIR}/drivers/
			git clone https://github.com/beagleboard/beaglebone-getting-started.git ${TEMPDIR}/drivers/ --depth 1
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
	if ! mount -t ${mount_partition_format} ${media_prefix}${media_boot_partition} ${TEMPDIR}/disk; then
		echo "-----------------------------"
		echo "Unable to mount ${media_prefix}${media_boot_partition} at ${TEMPDIR}/disk to complete populating Boot Partition"
		echo "Please retry running the script, sometimes rebooting your system helps."
		echo "-----------------------------"
		exit
	fi

	if [ ! "${bootloader_installed}" ] ; then
		if [ "${spl_name}" ] ; then
			if [ -f ${TEMPDIR}/dl/${SPL} ] ; then
				cp -v ${TEMPDIR}/dl/${SPL} ${TEMPDIR}/disk/${spl_name}
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

	if [ "x${conf_board}" = "xam335x_boneblack" ] || [ "x${conf_board}" = "xam335x_evm" ] ; then

		if [ ! "x${bbb_old_bootloader_in_emmc}" = "xenable" ] ; then
			wfile="${TEMPDIR}/disk/bbb-uEnv.txt"
			echo "##Rename as: uEnv.txt to override old bootloader in eMMC" > ${wfile}
			echo "##These are needed to be compliant with Angstrom's 2013.06.20 u-boot." >> ${wfile}
		else
			wfile="${TEMPDIR}/disk/uEnv.txt"
			echo "##These are needed to be compliant with Angstrom's 2013.06.20 u-boot." > ${wfile}
		fi

		echo "" >> ${wfile}
		echo "loadaddr=0x82000000" >> ${wfile}
		echo "fdtaddr=0x88000000" >> ${wfile}
		echo "rdaddr=0x88080000" >> ${wfile}
		echo "" >> ${wfile}
		echo "initrd_high=0xffffffff" >> ${wfile}
		echo "fdt_high=0xffffffff" >> ${wfile}
		echo "" >> ${wfile}
		echo "##These are needed to be compliant with Debian 2014-05-14 u-boot." > ${wfile}
		echo "" >> ${wfile}
		echo "loadximage=load mmc 0:${media_rootfs_partition} \${loadaddr} /boot/vmlinuz-\${uname_r}" >> ${wfile}
		echo "loadxfdt=load mmc 0:${media_rootfs_partition} \${fdtaddr} /boot/dtbs/\${uname_r}/\${fdtfile}" >> ${wfile}
		echo "loadxrd=load mmc 0:${media_rootfs_partition} \${rdaddr} /boot/initrd.img-\${uname_r}; setenv rdsize \${filesize}" >> ${wfile}
		echo "loaduEnvtxt=load mmc 0:${media_rootfs_partition} \${loadaddr} /boot/uEnv.txt ; env import -t \${loadaddr} \${filesize};" >> ${wfile}
		echo "loadall=run loaduEnvtxt; run loadximage; run loadxrd; run loadxfdt;" >> ${wfile}
		echo "" >> ${wfile}
		echo "mmcargs=setenv bootargs console=tty0 console=\${console} \${optargs} \${cape_disable} \${cape_enable} \root=\${mmcroot} rootfstype=\${mmcrootfstype} \${cmdline}" >> ${wfile}
		echo "" >> ${wfile}
		echo "uenvcmd=run loadall; run mmcargs; bootz \${loadaddr} \${rdaddr}:\${rdsize} \${fdtaddr};" >> ${wfile}
		echo "" >> ${wfile}


		wfile="${TEMPDIR}/disk/nfs-uEnv.txt"
		echo "##Rename as: uEnv.txt to boot via nfs" > ${wfile}
		echo "" >> ${wfile}
		echo "##https://www.kernel.org/doc/Documentation/filesystems/nfs/nfsroot.txt" >> ${wfile}
		echo "" >> ${wfile}
		echo "##SERVER: sudo apt-get install tftpd-hpa" >> ${wfile}
		echo "##SERVER: TFTP_DIRECTORY defined in /etc/default/tftpd-hpa" >> ${wfile}
		echo "##SERVER: zImage/*.dtb need to be located here:" >> ${wfile}
		echo "##SERVER: TFTP_DIRECTORY/zImage" >> ${wfile}
		echo "##SERVER: TFTP_DIRECTORY/dtbs/*.dtb" >> ${wfile}
		echo "" >> ${wfile}
		echo "##client_ip needs to be set for u-boot to try booting via nfs" >> ${wfile}
		echo "" >> ${wfile}
		echo "client_ip=192.168.1.101" >> ${wfile}
		echo "" >> ${wfile}
		echo "#u-boot defaults: uncomment and override where needed" >> ${wfile}
		echo "" >> ${wfile}
		echo "#server_ip=192.168.1.100" >> ${wfile}
		echo "#gw_ip=192.168.1.1" >> ${wfile}
		echo "#netmask=255.255.255.0" >> ${wfile}
		echo "#hostname=" >> ${wfile}
		echo "#device=eth0" >> ${wfile}
		echo "#autoconf=off" >> ${wfile}
		echo "#root_dir=/home/userid/targetNFS" >> ${wfile}
		echo "#nfs_options=,vers=3" >> ${wfile}
		echo "#nfsrootfstype=ext4 rootwait fixrtc" >> ${wfile}
		echo "" >> ${wfile}

	fi

	if [ -f "${DIR}/ID.txt" ] ; then
		cp -v "${DIR}/ID.txt" ${TEMPDIR}/disk/ID.txt
	fi

	if [ ${has_uenvtxt} ] ; then
		if [ ! "x${bbb_old_bootloader_in_emmc}" = "xenable" ] ; then
			cp -v "${DIR}/uEnv.txt" ${TEMPDIR}/disk/uEnv.txt
			echo "-----------------------------"
		fi
	fi

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

kernel_detection () {
	unset has_multi_armv7_kernel
	unset check
	check=$(ls "${dir_check}" | grep vmlinuz- | grep armv7 | grep -v lpae | head -n 1)
	if [ "x${check}" != "x" ] ; then
		armv7_kernel=$(ls "${dir_check}" | grep vmlinuz- | grep armv7 | grep -v lpae | head -n 1 | awk -F'vmlinuz-' '{print $2}')
		echo "Debug: image has: v${armv7_kernel}"
		has_multi_armv7_kernel="enable"
	fi

	unset has_multi_armv7_lpae_kernel
	unset check
	check=$(ls "${dir_check}" | grep vmlinuz- | grep armv7 | grep lpae | head -n 1)
	if [ "x${check}" != "x" ] ; then
		armv7_lpae_kernel=$(ls "${dir_check}" | grep vmlinuz- | grep armv7 | grep lpae | head -n 1 | awk -F'vmlinuz-' '{print $2}')
		echo "Debug: image has: v${armv7_lpae_kernel}"
		has_multi_armv7_lpae_kernel="enable"
	fi

	unset has_bone_kernel
	unset check
	check=$(ls "${dir_check}" | grep vmlinuz- | grep bone | head -n 1)
	if [ "x${check}" != "x" ] ; then
		bone_dt_kernel=$(ls "${dir_check}" | grep vmlinuz- | grep bone | head -n 1 | awk -F'vmlinuz-' '{print $2}')
		echo "Debug: image has: v${bone_dt_kernel}"
		has_bone_kernel="enable"
	fi
}

kernel_select () {
	unset select_kernel
	if [ "x${conf_kernel}" = "xarmv7" ] || [ "x${conf_kernel}" = "x" ] ; then
		if [ "x${has_multi_armv7_kernel}" = "xenable" ] ; then
			select_kernel="${armv7_kernel}"
		fi
	fi

	if [ "x${conf_kernel}" = "xarmv7_lpae" ] ; then
		if [ "x${has_multi_armv7_lpae_kernel}" = "xenable" ] ; then
			select_kernel="${armv7_lpae_kernel}"
		else
			if [ "x${has_multi_armv7_kernel}" = "xenable" ] ; then
				select_kernel="${armv7_kernel}"
			fi
		fi
	fi

	if [ "x${conf_kernel}" = "xbone" ] ; then
		if [ "x${has_bone_kernel}" = "xenable" ] ; then
			select_kernel="${bone_dt_kernel}"
		else
			if [ "x${has_multi_armv7_kernel}" = "xenable" ] ; then
				select_kernel="${armv7_kernel}"
			fi
		fi
	fi

	if [ "${select_kernel}" ] ; then
		echo "Debug: using: v${select_kernel}"
	else
		echo "Error: [conf_kernel] not defined [armv7_lpae,armv7,bone]..."
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
		echo "Unable to mount ${media_prefix}${media_rootfs_partition} at ${TEMPDIR}/disk to complete populating rootfs Partition"
		echo "Please retry running the script, sometimes rebooting your system helps."
		echo "-----------------------------"
		exit
	fi

	if [ -f "${DIR}/${ROOTFS}" ] ; then
		if which pv > /dev/null ; then
			pv "${DIR}/${ROOTFS}" | tar --numeric-owner --preserve-permissions -xf - -C ${TEMPDIR}/disk/
		else
			echo "pv: not installed, using tar verbose to show progress"
			tar --numeric-owner --preserve-permissions --verbose -xf "${DIR}/${ROOTFS}" -C ${TEMPDIR}/disk/
		fi

		echo "Transfer of data is Complete, now syncing data to disk..."
		sync
		sync
		echo "-----------------------------"
	fi

	dir_check="${TEMPDIR}/disk/boot/"
	kernel_detection
	kernel_select

	wfile="${TEMPDIR}/disk/boot/uEnv.txt"
	echo "#Docs: http://elinux.org/Beagleboard:U-boot_partitioning_layout_2.0" > ${wfile}
	echo "" >> ${wfile}

	if [ "x${kernel_override}" = "x" ] ; then
		echo "uname_r=${select_kernel}" >> ${wfile}
	else
		echo "uname_r=${kernel_override}" >> ${wfile}
	fi
	echo "" >> ${wfile}

	if [ ! "x${conf_fdtfile}" = "x" ] ; then
		echo "dtb=${conf_fdtfile}" >> ${wfile}
	else
		echo "#dtb=" >> ${wfile}
	fi
	echo "" >> ${wfile}

	if [ ! "x${rootfs_uuid}" = "x" ] ; then
		echo "uuid=${rootfs_uuid}" >> ${wfile}
		echo "" >> ${wfile}
	fi

	if [ "x${enable_systemd}" = "xenabled" ] ; then
		echo "cmdline=quiet init=/lib/systemd/systemd" >> ${wfile}
	else
		echo "cmdline=quiet" >> ${wfile}
	fi
	echo "" >> ${wfile}

	if [ "x${conf_board}" = "xam335x_boneblack" ] || [ "x${conf_board}" = "xam335x_evm" ] ; then
		echo "##Example" >> ${wfile}
		echo "#cape_disable=capemgr.disable_partno=" >> ${wfile}
		echo "#cape_enable=capemgr.enable_partno=" >> ${wfile}
		echo "" >> ${wfile}
	fi

	if [ ! "x${has_post_uenvtxt}" = "x" ] ; then
		cat "${DIR}/post-uEnv.txt" >> ${wfile}
		echo "" >> ${wfile}
	fi

	if [ "x${conf_board}" = "xam335x_boneblack" ] || [ "x${conf_board}" = "xam335x_evm" ] ; then
		if [ "${bbb_flasher}" ] ; then
			echo "##enable BBB: eMMC Flasher:" >> ${wfile}
			echo "cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v2.sh" >> ${wfile}
		else
			echo "##enable BBB: eMMC Flasher:" >> ${wfile}
			echo "##make sure, these tools are installed: dosfstools rsync" >> ${wfile}
			echo "#cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v2.sh" >> ${wfile}
		fi
		echo "" >> ${wfile}
	fi

	#am335x_boneblack is a custom u-boot to ignore empty factory eeproms...
	if [ "x${conf_board}" = "xam335x_boneblack" ] ; then
		board="am335x_evm"
	else
		board=${conf_board}
	fi

	#This should be compatible with hwpacks variable names..
	#https://code.launchpad.net/~linaro-maintainers/linaro-images/
	cat > ${TEMPDIR}/disk/boot/SOC.sh <<-__EOF__
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
		conf_boot_startmb=${conf_boot_startmb}
		conf_boot_endmb=${conf_boot_endmb}
		sfdisk_fstype=${sfdisk_fstype}

		serial_tty=${SERIAL}
		fdtfile=${conf_fdtfile}

		usbnet_mem=${usbnet_mem}

	__EOF__

	#RootStock-NG
	if [ -f ${TEMPDIR}/disk/etc/rcn-ee.conf ] ; then
		. ${TEMPDIR}/disk/etc/rcn-ee.conf

		mkdir -p ${TEMPDIR}/disk/boot/uboot || true

		wfile="${TEMPDIR}/disk/etc/fstab"
		echo "# /etc/fstab: static file system information." > ${wfile}
		echo "#" >> ${wfile}
		echo "# Auto generated by RootStock-NG: setup_sdcard.sh" >> ${wfile}
		echo "#" >> ${wfile}
		echo "${rootfs_drive}  /  ${ROOTFS_TYPE}  noatime,errors=remount-ro  0  1" >> ${wfile}

		echo "debugfs  /sys/kernel/debug  debugfs  defaults  0  0" >> ${wfile}

		if [ "x${distro}" = "xDebian" ] ; then
			wfile="${TEMPDIR}/disk/etc/inittab"
			serial_num=$(echo -n "${SERIAL}"| tail -c -1)
			echo "" >> ${wfile}
			echo "T${serial_num}:23:respawn:/sbin/getty -L ${SERIAL} 115200 vt102" >> ${wfile}
			echo "" >> ${wfile}
		fi

		if [ "x${distro}" = "xUbuntu" ] ; then
			wfile="${TEMPDIR}/disk/etc/init/serial.conf"
			echo "start on stopped rc RUNLEVEL=[2345]" > ${wfile}
			echo "stop on runlevel [!2345]" >> ${wfile}
			echo "" >> ${wfile}
			echo "respawn" >> ${wfile}
			echo "exec /sbin/getty 115200 ${SERIAL}" >> ${wfile}
		fi

		wfile="${TEMPDIR}/disk/etc/network/interfaces"
		echo "# This file describes the network interfaces available on your system" > ${wfile}
		echo "# and how to activate them. For more information, see interfaces(5)." >> ${wfile}
		echo "" >> ${wfile}
		echo "# The loopback network interface" >> ${wfile}
		echo "auto lo" >> ${wfile}
		echo "iface lo inet loopback" >> ${wfile}
		echo "" >> ${wfile}
		echo "# The primary network interface" >> ${wfile}

		if [ "${DISABLE_ETH}" ] ; then
			echo "#auto eth0" >> ${wfile}
			echo "#iface eth0 inet dhcp" >> ${wfile}
		else
			echo "auto eth0"  >> ${wfile}
			echo "iface eth0 inet dhcp" >> ${wfile}
		fi

		#if we have systemd & wicd-gtk, diable eth0 in /etc/network/interfaces
		if [ -f ${TEMPDIR}/disk/lib/systemd/systemd ] ; then
			if [ -f ${TEMPDIR}/disk/usr/bin/wicd-gtk ] ; then
				sed -i 's/auto eth0/#auto eth0/g' ${wfile}
				sed -i 's/allow-hotplug eth0/#allow-hotplug eth0/g' ${wfile}
				sed -i 's/iface eth0 inet dhcp/#iface eth0 inet dhcp/g' ${wfile}
			fi
		fi

		echo "# Example to keep MAC address between reboots" >> ${wfile}
		echo "#hwaddress ether DE:AD:BE:EF:CA:FE" >> ${wfile}

		echo "" >> ${wfile}
		echo "# The secondary network interface" >> ${wfile}
		echo "#auto eth1" >> ${wfile}
		echo "#iface eth1 inet dhcp" >> ${wfile}

		echo "" >> ${wfile}

		echo "# WiFi Example" >> ${wfile}
		echo "#auto wlan0" >> ${wfile}
		echo "#iface wlan0 inet dhcp" >> ${wfile}
		echo "#    wpa-ssid \"essid\"" >> ${wfile}
		echo "#    wpa-psk  \"password\"" >> ${wfile}

		echo "" >> ${wfile}

		echo "# Ethernet/RNDIS gadget (g_ether)" >> ${wfile}
		echo "# ... or on host side, usbnet and random hwaddr" >> ${wfile}
		echo "# Note on some boards, usb0 is automaticly setup with an init script" >> ${wfile}
		echo "iface usb0 inet static" >> ${wfile}
		echo "    address 192.168.7.2" >> ${wfile}
		echo "    netmask 255.255.255.0" >> ${wfile}
		echo "    network 192.168.7.0" >> ${wfile}
		echo "    gateway 192.168.7.1" >> ${wfile}

		if [ ! "${bborg_production}" ] ; then
			rm -f ${TEMPDIR}/disk/var/www/index.html || true
		fi
		sync

	else

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
	bone)
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
		http_brcm="https://raw.githubusercontent.com/Freescale/meta-fsl-arm-extra/master/recipes-bsp/broadcom-nvram-config/files/wandboard"
		wget --no-verbose --directory-prefix="${TEMPDIR}/disk/lib/firmware/brcm/" ${http_brcm}/brcmfmac4329-sdio.txt
		wget --no-verbose --directory-prefix="${TEMPDIR}/disk/lib/firmware/brcm/" ${http_brcm}/brcmfmac4330-sdio.txt
	fi

	if [ "x${build_img_file}" = "xenable" ] ; then
		git_rcn_boot="https://raw.githubusercontent.com/RobertCNelson/boot-scripts/master"

		if [ ! -f ${TEMPDIR}/disk/opt/scripts/tools/grow_partition.sh ] ; then
			mkdir -p ${TEMPDIR}/disk/opt/scripts/tools/
			wget --no-verbose --directory-prefix="${TEMPDIR}/disk/opt/scripts/tools/" ${git_rcn_boot}/tools/grow_partition.sh
			sudo chmod +x ${TEMPDIR}/disk/opt/scripts/tools/grow_partition.sh
		fi

	fi

	cd ${TEMPDIR}/disk/
	sync
	sync
	cd "${DIR}/"

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
		echo "Image file: ${media}"
		echo "-----------------------------"
	fi
}

check_mmc () {
	FDISK=$(LC_ALL=C fdisk -l 2>/dev/null | grep "Disk ${media}:" | awk '{print $2}')

	if [ "x${FDISK}" = "x${media}:" ] ; then
		echo ""
		echo "I see..."
		echo "fdisk -l:"
		LC_ALL=C fdisk -l 2>/dev/null | grep "Disk /dev/" --color=never
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
		echo "fdisk -l:"
		LC_ALL=C fdisk -l 2>/dev/null | grep "Disk /dev/" --color=never
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
	conf_boot_startmb=${conf_boot_startmb:-"1"}
	#https://wiki.linaro.org/WorkingGroups/KernelArchived/Projects/FlashCardSurvey
	conf_boot_endmb=${conf_boot_endmb:-"12"}
	conf_root_device=${conf_root_device:-"/dev/mmcblk0"}

	#error checking...

	if [ ! "${conf_boot_fstype}" ] ; then
		conf_boot_fstype="${ROOTFS_TYPE}"
	fi

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
		build_img_file="enable"
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
		build_img_file="enable"
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
		build_img_file="enable"
		check_root
		if [ -f "${media}" ] ; then
			rm -rf "${media}" || true
		fi
		#FIXME: (should fit most 4Gb microSD cards)
		dd if=/dev/zero of="${media}" bs=1024 count=0 seek=$[1024*3700]
		;;
	--dtb)
		checkparm $2
		dtb_board="$2"
		dir_check="${DIR}/"
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
		conf_boot_endmb="96"
		;;
	--bbb-old-bootloader-in-emmc)
		bbb_old_bootloader_in_emmc="enable"
		;;
	--enable-systemd)
		enable_systemd="enabled"
		;;
	--offline)
		offline=1
		;;
	--kernel)
		checkparm $2
		kernel_override="$2"
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

find_issue
detect_software

if [ "${spl_name}" ] || [ "${boot_name}" ] ; then
	if [ "${USE_LOCAL_BOOT}" ] ; then
		local_bootloader
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
#
