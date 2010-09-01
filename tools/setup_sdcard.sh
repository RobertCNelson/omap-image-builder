#!/bin/bash -e

#Latest can be found at:
#http://bazaar.launchpad.net/~beagleboard-kernel/%2Bjunk/image-builder/annotate/head:/tools/setup_sdcard.sh

#Notes: need to check for: parted, fdisk, wget, mkfs.*, mkimage, md5sum

unset MMC
unset SWAP_BOOT_USER

#Defaults
RFS=ext4
BOOT_LABEL=boot
RFS_LABEL=rootfs
PARTITION_PREFIX=""

DIR=$PWD

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
 PACKAGE="wget "
 APT=1
fi

if [ ! $(which pv) ];then
 echo "Missing pv"
 PACKAGE="pv "
 APT=1
fi

if [ "${APT}" ];then
 echo "Installing Dependicies"
 sudo aptitude install $PACKAGE
fi
}

function beagle_boot_scripts {

cat > /tmp/boot.cmd <<beagle_boot_cmd
if test "\${beaglerev}" = "xMA"; then
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
if test "\${beaglerev}" = "xMA"; then
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

beagle_user_cmd

}


function dl_xload_uboot {
 sudo rm -rfd ${DIR}/deploy/ || true
 mkdir -p ${DIR}/deploy/

case "$SYSTEM" in
    beagle)

beagle_boot_scripts

 #beagle
 MIRROR="http://rcn-ee.net/deb/"

 echo ""
 echo "Downloading X-loader and Uboot"
 echo ""

 rm -f ${DIR}/deploy/bootloader || true
 wget -c --no-verbose --directory-prefix=${DIR}/deploy/ ${MIRROR}tools/latest/bootloader

 MLO=$(cat ${DIR}/deploy/bootloader | grep "ABI:1 MLO" | awk '{print $3}')
 UBOOT=$(cat ${DIR}/deploy/bootloader | grep "ABI:1 UBOOT" | awk '{print $3}')

 wget -c --no-verbose --directory-prefix=${DIR}/deploy/ ${MLO}
 wget -c --no-verbose --directory-prefix=${DIR}/deploy/ ${UBOOT}

 MLO=${MLO##*/}
 UBOOT=${UBOOT##*/}

        ;;
    igepv2)

 #MLO=${MLO##*/}
 #UBOOT=${UBOOT##*/}
 MLO=NA
 UBOOT=NA

        ;;
    fairlane)

 MIRROR="http://rcn-ee.net/deb/"

 echo ""
 echo "Downloading X-loader and Uboot"
 echo ""

 rm -f ${DIR}/deploy/bootloader || true
 wget -c --no-verbose --directory-prefix=${DIR}/deploy/ ${MIRROR}tools/latest/bootloader

 MLO=$(cat ${DIR}/deploy/bootloader | grep "ABI:3 MLO" | awk '{print $3}')
 UBOOT=$(cat ${DIR}/deploy/bootloader | grep "ABI:3 UBOOT" | awk '{print $3}')

 wget -c --no-verbose --directory-prefix=${DIR}/deploy/ ${MLO}
 wget -c --no-verbose --directory-prefix=${DIR}/deploy/ ${UBOOT}

 MLO=${MLO##*/}
 UBOOT=${UBOOT##*/}

        ;;
esac

}

function cleanup_sd {

 echo ""
 echo "Umounting Partitions"
 echo ""

 sudo umount ${MMC}${PARTITION_PREFIX}1 &> /dev/null || true
 sudo umount ${MMC}${PARTITION_PREFIX}2 &> /dev/null || true

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

echo ""
echo "Formating Boot Partition"
echo ""

sudo mkfs.vfat -F 16 ${MMC}${PARTITION_PREFIX}1 -n ${BOOT_LABEL} &> ${DIR}/sd.log

sudo rm -rfd ${DIR}/disk || true

mkdir ${DIR}/disk
sudo mount ${MMC}${PARTITION_PREFIX}1 ${DIR}/disk

if [ "$DO_UBOOT" ];then
 if ls ${DIR}/deploy/${MLO} >/dev/null 2>&1;then
 sudo cp -v ${DIR}/deploy/${MLO} ${DIR}/disk/MLO
 rm -f ${DIR}/deploy/${MLO} || true
 fi

 if ls ${DIR}/deploy/${UBOOT} >/dev/null 2>&1;then
 sudo cp -v ${DIR}/deploy/${UBOOT} ${DIR}/disk/u-boot.bin
 rm -f ${DIR}/deploy/${UBOOT} || true
 fi
fi

cd ${DIR}/disk
sync
cd ${DIR}/
sudo umount ${DIR}/disk || true
echo "done"

sudo fdisk ${MMC} << ROOTFS
n
p
2


p
w
ROOTFS

echo ""
echo "Formating ${RFS} Partition"
echo ""
sudo mkfs.${RFS} ${MMC}${PARTITION_PREFIX}2 -L ${RFS_LABEL} &>> ${DIR}/sd.log

}

function populate_boot {
 echo ""
 echo "Populating Boot Partition"
 echo ""
 sudo mount ${MMC}${PARTITION_PREFIX}1 ${DIR}/disk
 sudo mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000 -n "Linux" -d ${DIR}/vmlinuz-* ${DIR}/disk/uImage
 sudo mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d ${DIR}/initrd.img-* ${DIR}/disk/uInitrd

#Some boards, like my xM Prototype have the user button polarity reversed
#in that case user.scr gets loaded over boot.scr
if [ "$SWAP_BOOT_USER" ] ; then
 if ls /tmp/boot.cmd >/dev/null 2>&1;then
  sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d /tmp/boot.cmd ${DIR}/disk/user.scr
  sudo cp /tmp/boot.cmd ${DIR}/disk/boot.cmd
  sudo cp /tmp/boot.cmd ${DIR}/disk/user.cmd
  rm -f /tmp/boot.cmd || true
  rm -f /tmp/user.cmd || true
 fi
fi

 if ls /tmp/boot.cmd >/dev/null 2>&1;then
 sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d /tmp/boot.cmd ${DIR}/disk/boot.scr
 sudo cp /tmp/boot.cmd ${DIR}/disk/boot.cmd
 rm -f /tmp/boot.cmd || true
 fi

 if ls /tmp/user.cmd >/dev/null 2>&1;then
 sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Reset Nand" -d /tmp/user.cmd ${DIR}/disk/user.scr
 sudo cp /tmp/user.cmd ${DIR}/disk/user.cmd
 rm -f /tmp/user.cmd || true
 fi

 #for igepv2 users
 sudo cp -v ${DIR}/disk/boot.scr ${DIR}/disk/boot.ini

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
sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d /boot/uboot/boot.cmd /boot/uboot/boot.scr
sudo cp /boot/uboot/boot.scr /boot/uboot/boot.ini
sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Reset Nand" -d /boot/uboot/user.cmd /boot/uboot/user.scr

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
  . /tmp/install-me.sh
 fi

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

 sudo mkdir -p ${DIR}/disk/tools
 sudo cp -v /tmp/rebuild_uinitrd.sh ${DIR}/disk/tools/rebuild_uinitrd.sh
 sudo chmod +x ${DIR}/disk/tools/rebuild_uinitrd.sh

 sudo cp -v /tmp/boot_scripts.sh ${DIR}/disk/tools/boot_scripts.sh
 sudo chmod +x ${DIR}/disk/tools/boot_scripts.sh

 sudo cp -v /tmp/fix_zippy2.sh ${DIR}/disk/tools/fix_zippy2.sh
 sudo chmod +x ${DIR}/disk/tools/fix_zippy2.sh

 sudo cp -v /tmp/latest_kernel.sh ${DIR}/disk/tools/latest_kernel.sh
 sudo chmod +x ${DIR}/disk/tools/latest_kernel.sh

 cd ${DIR}/disk/
 sync
 sync
 cd ${DIR}/

 sudo umount ${DIR}/disk || true
}

function populate_rootfs {
 echo ""
 echo "Populating rootfs Partition"
 echo "Be patient, this may take a few minutes"
 echo ""
 sudo mount ${MMC}${PARTITION_PREFIX}2 ${DIR}/disk

 if ls ${DIR}/armel-rootfs-*.tgz >/dev/null 2>&1;then
   pv ${DIR}/armel-rootfs-*.tgz | sudo tar xzfp - -C ${DIR}/disk/
 fi

 if ls ${DIR}/armel-rootfs-*.tar >/dev/null 2>&1;then
   pv ${DIR}/armel-rootfs-*.tar | sudo tar xfp - -C ${DIR}/disk/
 fi

 if [ "$CREATE_SWAP" ] ; then

  echo ""
  echo "Creating SWAP File"
  echo ""

  SPACE_LEFT=$(df ${DIR}/disk/ | grep ${MMC}${PARTITION_PREFIX}2 | awk '{print $4}')

  let SIZE=$SWAP_SIZE*1024

  if [ $SPACE_LEFT -ge $SIZE ] ; then
   sudo dd if=/dev/zero of=${DIR}/disk/mnt/SWAP.swap bs=1M count=$SWAP_SIZE
   sudo mkswap ${DIR}/disk/mnt/SWAP.swap
   echo "/mnt/SWAP.swap  none  swap  sw  0 0" | sudo tee -a ${DIR}/disk/etc/fstab
   else
   echo "FIXME Recovery after user selects SWAP file bigger then whats left not implemented"
  fi
 fi

 cd ${DIR}/disk/
 sync
 sync
 cd ${DIR}/

 sudo umount ${DIR}/disk || true
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
    fairlane)
#hidden: unreleased

 SYSTEM=fairlane
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
    echo "usage: $(basename $0) --mmc /dev/sdd"
cat <<EOF

required options:
--mmc </dev/sdX>
    Unformated MMC Card

Additional/Optional options:
-h --help
    this help

--uboot <dev board>
    beagle - <Bx, C2/C3/C4, xMA>
    igepv2 - (no u-boot or MLO yet>

--addon <device>
    pico

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


