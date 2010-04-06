#!/bin/bash -e

RFS=ext3

function dl_xload_uboot {

wget -c http://rcn-ee.homeip.net:81/dl/omap/uboot/MLO-beagleboard-1.44+r9+gitr1c9276af4d6a5b7014a7630a1abeddf3b3177563-r9

wget -c http://rcn-ee.homeip.net:81/dl/omap/uboot/x-load-beagleboard-1.44+r9+gitr1c9276af4d6a5b7014a7630a1abeddf3b3177563-r9.bin.ift

wget -c http://rcn-ee.homeip.net:81/dl/omap/uboot/u-boot-beagleboard-2010.03-rc1+r44+gitr946351081bd14e8bf5816fc38b82e004a0e6b4fe-r44.bin

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

mkdir ./disk
sudo mount ${MMC}1 ./disk
sudo cp -v MLO-beagleboard-1.44+r9+gitr1c9276af4d6a5b7014a7630a1abeddf3b3177563-r9 ./disk/MLO

sudo cp -v x-load-beagleboard-1.44+r9+gitr1c9276af4d6a5b7014a7630a1abeddf3b3177563-r9.bin.ift ./disk/x-load.bin.ift

sudo cp -v u-boot-beagleboard-2010.03-rc1+r44+gitr946351081bd14e8bf5816fc38b82e004a0e6b4fe-r44.bin ./disk/u-boot.bin
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
	sudo mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000 -n "Linux" -d ./vmlinuz-* ./disk/uImage
	sudo mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d ./initrd.img-* ./disk/uInitrd

	sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Ubuntu 10.04" -d ./boot.cmd ./disk/boot.scr
	sudo cp -v ./disk/boot.scr ./disk/boot.ini
	sudo umount ./disk
}

function populate_rootfs {
	echo ""
	echo "Populating rootfs Partition"
	echo ""
	sudo mount ${MMC}2 ./disk

	sudo tar xfp armel-rootfs-* -C ./disk/
	sudo umount ./disk
}

if [ -e ${DIR}/system.sh ]; then
	. system.sh

	if test "-$MMC-" = "--"
	then
 		echo "MMC is not defined in system.sh"
	else
		dl_xload_uboot
		cleanup_sd
		create_partitions
		populate_boot
		populate_rootfs
	fi
else
	echo "Missing system.sh, please copy system.sh.sample to system.sh and edit as needed"
	echo "cp system.sh.sample system.sh"
	echo "gedit system.sh"		
fi



