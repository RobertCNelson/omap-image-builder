#!/bin/bash -e

unset MMC
unset STOP

RFS=ext3

DIR=$PWD

function dl_xload_uboot {

sudo rm -rfd ${DIR}/deploy/ || true
mkdir -p ${DIR}/deploy/

wget -c --directory-prefix=${DIR}/deploy/ http://rcn-ee.net/deb/tools/MLO-beagleboard-1.44+r9+gitr1c9276af4d6a5b7014a7630a1abeddf3b3177563-r9

wget -c --directory-prefix=${DIR}/deploy/ http://rcn-ee.net/deb/tools/x-load-beagleboard-1.44+r9+gitr1c9276af4d6a5b7014a7630a1abeddf3b3177563-r9.bin.ift

wget -c --directory-prefix=${DIR}/deploy/ http://rcn-ee.net/deb/tools/u-boot-beagleboard-2010.03-rc1+r44+gitr946351081bd14e8bf5816fc38b82e004a0e6b4fe-r44.bin

}

function cleanup_sd {

sudo umount ${MMC}1
sudo umount ${MMC}2

sudo fdisk ${MMC} << CLEAN
d
2
d
p
w
CLEAN

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
sudo umount ./disk
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
	sudo umount ./disk
}

function populate_rootfs {
	echo ""
	echo "Populating rootfs Partition"
	echo "Be patient, this may take a few minutes"
	echo ""
	sudo mount ${MMC}2 ./disk

	sudo tar xfp ${DIR}/armel-rootfs-* -C ./disk/
	sudo umount ./disk
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

EOF
STOP=1
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
            ;;
    esac
    shift
done

if [ ! "${MMC}" ];then
    usage
fi

if [ ! "${STOP}" ] ; then

#FIXME: Ugly
rm -f /tmp/ubuntu-lucid-beta2-minimal-armel.md5sums || true
wget -c --directory-prefix=/tmp http://www.rcn-ee.net/deb/rootfs/ubuntu-lucid-beta2-minimal-armel.md5sums
md5sum -c /tmp/ubuntu-lucid-beta2-minimal-armel.md5sums | grep -vi 'OK$' > /tmp/test.md5sum
MD5SUM=$(stat -c%s /tmp/test.md5sum)

sudo fdisk -l | grep ${MMC} | grep Disk > /tmp/fdisk.check
FDISK=$(stat -c%s /tmp/fdisk.check)

if [ $MD5SUM -ge 1 ] ; then
	echo "MD5SUM check as failed, try re-downloading or tweak this script to ignore it."
else
	if [ $FDISK -ge 1 ] ; then
		dl_xload_uboot
		cleanup_sd
		create_partitions
		populate_boot
		populate_rootfs
	else
		echo "Are you sure? Here's what I see"
		sudo fdisk -l
	fi
fi
fi


