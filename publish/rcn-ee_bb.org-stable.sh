#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

./RootStock-NG.sh -c bb.org-debian-stable

debian_stable="debian-7.5-lxde-armhf-${time}"
archive="xz -z -8 -v"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

if [ -d ./${debian_stable} ] ; then
	rm -rf ${debian_stable} || true
fi

#user may run ./ship.sh twice...
if [ -f ${debian_stable}.tar.xz ] ; then
	tar xf ${debian_stable}.tar.xz
else
	tar xf ${debian_stable}.tar
fi

if [ -f BBB-eMMC-flasher-${debian_stable}-2gb.img ] ; then
	rm BBB-eMMC-flasher-${debian_stable}-2gb.img || true
fi

if [ -f bone-${debian_stable}-4gb.img ] ; then
	rm bone-${debian_stable}-4gb.img || true
fi

cd ${debian_stable}/

#using [boneblack_flasher] over [bone] for flasher, as this u-boot ignores the factory eeprom for production purposes...
sudo ./setup_sdcard.sh --img BBB-blank-eMMC-flasher-${debian_stable} --uboot boneblack_flasher --beagleboard.org-production --bbb-flasher --boot_label BEAGLE_BONE --rootfs_label eMMC-Flasher --enable-systemd

sudo ./setup_sdcard.sh --img BBB-eMMC-flasher-${debian_stable} --dtb beaglebone --beagleboard.org-production --bbb-flasher --boot_label BEAGLE_BONE --rootfs_label eMMC-Flasher --enable-systemd

sudo ./setup_sdcard.sh --img-4gb bone-${debian_stable} --dtb beaglebone --beagleboard.org-production --boot_label BEAGLE_BONE --enable-systemd

mv *.img ../
cd ..
rm -rf ${debian_stable}/ || true

if [ ! -f ${debian_stable}.tar.xz ] ; then
	${archive} ${debian_stable}.tar
fi

if [ -f BBB-blank-eMMC-flasher-${debian_stable}-2gb.img.xz ] ; then
	rm BBB-blank-eMMC-flasher-${debian_stable}-2gb.img.xz || true
fi
${archive} BBB-blank-eMMC-flasher-${debian_stable}-2gb.img

if [ -f BBB-eMMC-flasher-${debian_stable}-2gb.img.xz ] ; then
	rm BBB-eMMC-flasher-${debian_stable}-2gb.img.xz || true
fi
${archive} BBB-eMMC-flasher-${debian_stable}-2gb.img

if [ -f bone-${debian_stable}-4gb.img.xz ] ; then
	rm bone-${debian_stable}-4gb.img.xz || true
fi
${archive} bone-${debian_stable}-4gb.img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ -d /mnt/farm/testing/pending/ ] ; then
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/testing/pending/gift_wrap_final_images.sh
	chmod +x /mnt/farm/testing/pending/gift_wrap_final_images.sh
	cp -v ${DIR}/deploy/*.tar /mnt/farm/testing/pending/
fi

