#!/bin/sh -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

./RootStock-NG.sh -c bb.org-debian-stable

debian_stable="7.6"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

if [ -d ./debian-${debian_stable}-lxde-armhf-${time} ] ; then
	rm -rf debian-${debian_stable}-lxde-armhf-${time} || true
fi

#user may run ./ship.sh twice...
if [ -f debian-${debian_stable}-lxde-armhf-${time}.tar.xz ] ; then
	tar xf debian-${debian_stable}-lxde-armhf-${time}.tar.xz
else
	tar xf debian-${debian_stable}-lxde-armhf-${time}.tar
fi

if [ -f BBB-eMMC-flasher-debian-${debian_stable}-lxde-${time}-2gb.img ] ; then
	rm BBB-eMMC-flasher-debian-${debian_stable}-lxde-${time}-2gb.img || true
fi

if [ -f bone-debian-${debian_stable}-lxde-${time}-4gb.img ] ; then
	rm bone-debian-${debian_stable}-lxde-${time}-4gb.img || true
fi

cd debian-${debian_stable}-lxde-armhf-${time}/

#using [boneblack_flasher] over [bone] for flasher, as this u-boot ignores the factory eeprom for production purposes...
sudo ./setup_sdcard.sh --img BBB-blank-eMMC-flasher-debian-${debian_stable}-lxde-${time} --uboot boneblack_flasher --beagleboard.org-production --bbb-flasher --boot_label BEAGLE_BONE --rootfs_label eMMC-Flasher --enable-systemd

sudo ./setup_sdcard.sh --img BBB-eMMC-flasher-debian-${debian_stable}-lxde-${time} --dtb beaglebone --beagleboard.org-production --bbb-flasher --boot_label BEAGLE_BONE --rootfs_label eMMC-Flasher --enable-systemd

sudo ./setup_sdcard.sh --img-4gb bone-debian-${debian_stable}-lxde-${time} --dtb beaglebone --beagleboard.org-production --boot_label BEAGLE_BONE --enable-systemd

mv *.img ../
cd ..
rm -rf debian-${debian_stable}-lxde-armhf-${time}/ || true

if [ ! -f debian-${debian_stable}-lxde-armhf-${time}.tar.xz ] ; then
	xz -z -8 -v debian-${debian_stable}-lxde-armhf-${time}.tar
fi

if [ -f BBB-blank-eMMC-flasher-debian-${debian_stable}-lxde-${time}-2gb.img.xz ] ; then
	rm BBB-blank-eMMC-flasher-debian-${debian_stable}-lxde-${time}-2gb.img.xz || true
fi
xz -z -8 -v BBB-blank-eMMC-flasher-debian-${debian_stable}-lxde-${time}-2gb.img

if [ -f BBB-eMMC-flasher-debian-${debian_stable}-lxde-${time}-2gb.img.xz ] ; then
	rm BBB-eMMC-flasher-debian-${debian_stable}-lxde-${time}-2gb.img.xz || true
fi
xz -z -8 -v BBB-eMMC-flasher-debian-${debian_stable}-lxde-${time}-2gb.img

if [ -f bone-debian-${debian_stable}-lxde-${time}-4gb.img.xz ] ; then
	rm bone-debian-${debian_stable}-lxde-${time}-4gb.img.xz || true
fi
xz -z -8 -v bone-debian-${debian_stable}-lxde-${time}-4gb.img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh
