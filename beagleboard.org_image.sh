#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

./RootStock-NG.sh -c bb.org-debian-stable
./RootStock-NG.sh -c bb.org-debian-stable-4gb
./RootStock-NG.sh -c bb.org-console-debian-stable

debian_lxde_stable="debian-7.6-lxde-armhf-${time}"
debian_lxde_4gb_stable="debian-7.6-lxde-4gb-armhf-${time}"
debian_console_stable="debian-7.6-console-armhf-${time}"
archive="xz -z -8 -v"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

generic_image () {
	if [ -d ./\${debian_image} ] ; then
		rm -rf \${debian_image} || true
	fi

	#user may run ./ship.sh twice...
	if [ -f \${debian_image}.tar.xz ] ; then
		tar xf \${debian_image}.tar.xz
	else
		tar xf \${debian_image}.tar
	fi

	cd \${debian_image}/

	if [ "x\${flasher}" = "xenable" ] ; then
		#using [boneblack_flasher] over [bone] for flasher, as this u-boot ignores the factory eeprom for production purposes...
		sudo ./setup_sdcard.sh \${flasher_size} BBB-blank-eMMC-flasher-\${debian_image} --dtb bbb-blank-eeprom \${image_opts} --bbb-flasher --boot_label BEAGLEBONE --rootfs_label eMMC-Flasher --enable-systemd

		sudo ./setup_sdcard.sh \${flasher_size} BBB-eMMC-flasher-\${debian_image} --dtb beaglebone \${image_opts} --bbb-flasher --boot_label BEAGLEBONE --rootfs_label eMMC-Flasher --enable-systemd --bbb-old-bootloader-in-emmc
	fi

	sudo ./setup_sdcard.sh \${bone_size} bone-\${debian_image} --dtb beaglebone \${image_opts} --boot_label BEAGLEBONE --enable-systemd

	mv *.img ../
	cd ..
	rm -rf \${debian_image}/ || true

	if [ ! -f \${debian_image}.tar.xz ] ; then
		${archive} \${debian_image}.tar
	fi

	if [ "x\${flasher}" = "xenable" ] ; then
		if [ -f BBB-blank-eMMC-flasher-\${debian_image}-2gb.img ] ; then
			${archive} BBB-blank-eMMC-flasher-\${debian_image}-2gb.img
		fi

		if [ -f BBB-blank-eMMC-flasher-\${debian_image}-4gb.img ] ; then
			${archive} BBB-blank-eMMC-flasher-\${debian_image}-4gb.img
		fi

		if [ -f BBB-eMMC-flasher-\${debian_image}-2gb.img ] ; then
			${archive} BBB-eMMC-flasher-\${debian_image}-2gb.img
		fi

		if [ -f BBB-eMMC-flasher-\${debian_image}-4gb.img ] ; then
			${archive} BBB-eMMC-flasher-\${debian_image}-4gb.img
		fi
	fi

	if [ -f bone-\${debian_image}-2gb.img ] ; then
		${archive} bone-\${debian_image}-2gb.img
	fi

	if [ -f bone-\${debian_image}-4gb.img ] ; then
		${archive} bone-\${debian_image}-4gb.img
	fi

}

debian_image="${debian_lxde_stable}"
flasher_size="--img-2gb"
bone_size="--img-4gb"
image_opts="--beagleboard.org-production"
flasher="enable"
generic_image

debian_image="${debian_lxde_4gb_stable}"
flasher_size="--img-2gb"
bone_size="--img-4gb"
image_opts="--beagleboard.org-production"
flasher="enable"
generic_image

debian_image="${debian_console_stable}"
flasher_size="--img"
bone_size="--img"
image_opts=""
flasher="enable"
generic_image

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh
