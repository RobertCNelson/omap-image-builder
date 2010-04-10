#!/bin/bash -e

#Notes: need to check for: parted, fdisk, wget, mkfs.*, mkimage, md5sum

unset MMC

RFS=ext3

DIR=$PWD

function dl_xload_uboot {
 sudo rm -rfd ${DIR}/deploy/ || true
 mkdir -p ${DIR}/deploy/

 wget -c --no-verbose --directory-prefix=${DIR}/deploy/ http://rcn-ee.net/deb/tools/MLO-beagleboard-1.44+r9+gitr1c9276af4d6a5b7014a7630a1abeddf3b3177563-r9

 wget -c --no-verbose --directory-prefix=${DIR}/deploy/ http://rcn-ee.net/deb/tools/x-load-beagleboard-1.44+r9+gitr1c9276af4d6a5b7014a7630a1abeddf3b3177563-r9.bin.ift
 wget -c --no-verbose --directory-prefix=${DIR}/deploy/ http://rcn-ee.net/deb/tools/u-boot-beagleboard-2010.03-rc1+r44+gitr946351081bd14e8bf5816fc38b82e004a0e6b4fe-r44.bin
}

function cleanup_sd {

sudo umount ${MMC}1 &> /dev/null || true
sudo umount ${MMC}2 &> /dev/null || true

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

sudo mkfs.vfat -F 16 ${MMC}1

sudo rm -rfd ./disk || true

mkdir ./disk
sudo mount ${MMC}1 ./disk
sudo cp -v ${DIR}/deploy/MLO-beagleboard-1.44+r9+gitr1c9276af4d6a5b7014a7630a1abeddf3b3177563-r9 ./disk/MLO

sudo cp -v ${DIR}/deploy/x-load-beagleboard-1.44+r9+gitr1c9276af4d6a5b7014a7630a1abeddf3b3177563-r9.bin.ift ./disk/x-load.bin.ift

sudo cp -v ${DIR}/deploy/u-boot-beagleboard-2010.03-rc1+r44+gitr946351081bd14e8bf5816fc38b82e004a0e6b4fe-r44.bin ./disk/u-boot.bin
cd ./disk
sync
cd ..
sudo umount ./disk || true
echo "done"

sudo fdisk ${MMC} << ROOTFS
n
p
2


p
w
ROOTFS

sudo mkfs.${RFS} ${MMC}2

}

function populate_boot {
	echo ""
	echo "Populating Boot Partition"
	echo ""
	sudo mount ${MMC}1 ./disk
	sudo mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000 -n "Linux" -d ${DIR}/vmlinuz-* ./disk/uImage
	sudo mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d ${DIR}/initrd.img-* ./disk/uInitrd

	sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Ubuntu 10.04" -d ${DIR}/boot.cmd ./disk/boot.scr
	sudo cp -v ./disk/boot.scr ./disk/boot.ini
	sudo umount ./disk || true
}

function populate_rootfs {
	echo ""
	echo "Populating rootfs Partition"
	echo "Be patient, this may take a few minutes"
	echo ""
	sudo mount ${MMC}2 ./disk

	sudo tar xfp ${DIR}/armel-rootfs-* -C ./disk/
	sudo umount ./disk || true
}

function check_mmc {
 FDISK=$(sudo fdisk -l | grep "Disk ${MMC}" | awk '{print $2}')

 if test "-$FDISK-" = "-$MMC:-"
 then
  echo ""
  echo "I see...fdisk"
  sudo fdisk -l | grep "Disk /dev/" --color=never
  echo ""
  echo "System Mounts"
  mount | grep -v none | grep "/dev/" --color=never
  echo ""
  read -p "Are you 100% sure, on selecting [${MMC}] (y/n)?"
  [ "$REPLY" == "y" ] || exit
  echo ""
 else
  echo ""
  echo "Are you sure? I Don't see [${MMC}], here is what I do see..."
  echo ""
  sudo fdisk -l | grep "Disk /dev/" --color=never
  echo ""
  echo "System Mounts"
  mount | grep -v none | grep "/dev/" --color=never
  echo ""
  exit
 fi
}

function usage {
    echo "usage: $(basename $0) --mmc /dev/sdd"
cat <<EOF

required options:
--mmc </dev/sdX>
    Unformated MMC Card

additional options:
-h --help
    this help

--ignore_md5sum
    skip md5sum check    

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
            check_mmc 
            ;;
        --ignore_md5sum)
            IGNORE_MD5SUM=1
            ;;
    esac
    shift
done

if [ ! "${MMC}" ];then
    usage
fi

 if [ "$IGNORE_MD5SUM" ] ; then
   MD5SUM=0
 else
  #FIXME: Ugly
  rm -f /tmp/ubuntu-lucid-beta2-minimal-armel.md5sums || true
  wget -c --no-verbose --directory-prefix=/tmp http://www.rcn-ee.net/deb/rootfs/ubuntu-lucid-beta2-minimal-armel.md5sums
  md5sum -c /tmp/ubuntu-lucid-beta2-minimal-armel.md5sums | grep -vi 'OK$' > /tmp/test.md5sum
  MD5SUM=$(stat -c%s /tmp/test.md5sum)
 fi

 if [ $MD5SUM -ge 1 ] ; then
 	echo "MD5SUM check as failed, try re-downloading or tweak this script to ignore it."
 else
		dl_xload_uboot
		cleanup_sd
		create_partitions
		populate_boot
		populate_rootfs

 fi



