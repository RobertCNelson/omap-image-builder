#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

./RootStock-NG.sh -c bb.org-debian-stable
./RootStock-NG.sh -c bb.org-console-debian-stable

debian_lxde_stable="debian-7.5-lxde-armhf-${time}"
debian_console_stable="debian-7.5-console-armhf-${time}"
archive="xz -z -8 -v"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

generic_image () {
	if [ -d ./${debian_image} ] ; then
		rm -rf ${debian_image} || true
	fi

	#user may run ./ship.sh twice...
	if [ -f ${debian_image}.tar.xz ] ; then
		tar xf ${debian_image}.tar.xz
	else
		tar xf ${debian_image}.tar
	fi

	cd ${debian_image}/

	#using [boneblack_flasher] over [bone] for flasher, as this u-boot ignores the factory eeprom for production purposes...
	sudo ./setup_sdcard.sh --img BBB-blank-eMMC-flasher-${debian_image} --dtb bbb-blank-eeprom --beagleboard.org-production --bbb-flasher --boot_label BEAGLE_BONE --rootfs_label eMMC-Flasher --enable-systemd

	sudo ./setup_sdcard.sh --img BBB-eMMC-flasher-${debian_image} --dtb beaglebone --beagleboard.org-production --bbb-flasher --boot_label BEAGLE_BONE --rootfs_label eMMC-Flasher --enable-systemd --bbb-old-bootloader-in-emmc

	sudo ./setup_sdcard.sh ${bone_image} bone-${debian_image} --dtb beaglebone --beagleboard.org-production --boot_label BEAGLE_BONE --enable-systemd --bbb-old-bootloader-in-emmc

	mv *.img ../
	cd ..
	rm -rf ${debian_image}/ || true

	if [ ! -f ${debian_image}.tar.xz ] ; then
		${archive} ${debian_image}.tar
	fi

	if [ -f BBB-blank-eMMC-flasher-${debian_image}-2gb.img ] ; then
		${archive} BBB-blank-eMMC-flasher-${debian_image}-2gb.img
	fi

	if [ -f BBB-eMMC-flasher-${debian_image}-2gb.img ] ; then
		${archive} BBB-eMMC-flasher-${debian_image}-2gb.img
	fi

	if [ -f bone-${debian_image}-2gb.img ] ; then
		${archive} bone-${debian_image}-2gb.img
	fi

	if [ -f bone-${debian_image}-4gb.img ] ; then
		${archive} bone-${debian_image}-4gb.img
	fi

}

image="${debian_lxde_stable}"
bone_image="--img-4gb"
generic_image

image="${debian_console_stable}"
bone_image="--img"
generic_image

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ -d /mnt/farm/testing/pending/ ] ; then
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/testing/pending/gift_wrap_final_images.sh
	chmod +x /mnt/farm/testing/pending/gift_wrap_final_images.sh
	cp -v ${DIR}/deploy/*.tar /mnt/farm/testing/pending/
fi

