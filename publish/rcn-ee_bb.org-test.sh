#!/bin/bash -e

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.us/rootfs/bb.org/testing"
DIR="$PWD"

git pull --no-edit https://github.com/beagleboard/image-builder master

export apt_proxy=apt-proxy:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

#./RootStock-NG.sh -c bb.org-debian-jessie-oemflasher

  debian_jessie_lxqt_2gb="debian-8.11-lxqt-2gb-armhf-${time}"
  debian_jessie_lxqt_4gb="debian-8.11-lxqt-4gb-armhf-${time}"
   debian_jessie_console="debian-8.11-console-armhf-${time}"
debian_jessie_oemflasher="debian-8.11-oemflasher-armhf-${time}"

archive="xz -z -8"

beaglebone="--dtb beaglebone --bbb-old-bootloader-in-emmc --hostname beaglebone --enable-cape-universal"

bb_blank_flasher="--dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc \
--hostname beaglebone --enable-cape-universal"

beaglebone_console="--dtb beaglebone --bbb-old-bootloader-in-emmc \
--hostname beaglebone --enable-cape-universal"

bb_blank_flasher_console="--dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc \
--hostname beaglebone --enable-cape-universal"

omap3_beagle_xm="--dtb omap3-beagle-xm --hostname BeagleBoard"
omap5_uevm="--dtb omap5-uevm --hostname omap5-uevm"
am57xx_beagle_x15="--dtb am57xx-beagle-x15 --hostname BeagleBoard-X15"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

copy_base_rootfs_to_mirror () {
        if [ -d ${mirror_dir}/ ] ; then
                if [ ! -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        mkdir -p ${mirror_dir}/${time}/\${blend}/ || true
                fi
                if [ -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${base_rootfs}.tar.xz ] ; then
                                cp -v \${base_rootfs}.tar ${mirror_dir}/${time}/\${blend}/
                                cd ${mirror_dir}/${time}/\${blend}/
                                ${archive} \${base_rootfs}.tar && sha256sum \${base_rootfs}.tar.xz > \${base_rootfs}.tar.xz.sha256sum &
                                cd -
                        fi
                fi
        fi
}

archive_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi
        if [ -f \${base_rootfs}.tar ] ; then
                copy_base_rootfs_to_mirror
        fi
}

extract_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi

        if [ -f \${base_rootfs}.tar.xz ] ; then
                tar xf \${base_rootfs}.tar.xz
        fi

        if [ -f \${base_rootfs}.tar ] ; then
                tar xf \${base_rootfs}.tar
        fi
}

copy_img_to_mirror () {
        if [ -d ${mirror_dir} ] ; then
                if [ ! -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        mkdir -p ${mirror_dir}/${time}/\${blend}/ || true
                fi
                if [ -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        if [ -f \${wfile}.bmap ] ; then
                                mv -v \${wfile}.bmap ${mirror_dir}/${time}/\${blend}/
                                sync
                        fi
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${wfile}.img.zx ] ; then
                                mv -v \${wfile}.img ${mirror_dir}/${time}/\${blend}/
                                sync
                                if [ -f \${wfile}.img.xz.job.txt ] ; then
                                        mv -v \${wfile}.img.xz.job.txt ${mirror_dir}/${time}/\${blend}/
                                        sync
                                fi
                                cd ${mirror_dir}/${time}/\${blend}/
                                ${archive} \${wfile}.img && sha256sum \${wfile}.img.xz > \${wfile}.img.xz.sha256sum &
                                cd -
                        fi
                fi
        fi
}

archive_img () {
        if [ -f \${wfile}.img ] ; then
                if [ ! -f \${wfile}.bmap ] ; then
                        if [ -f /usr/bin/bmaptool ] ; then
                                bmaptool create -o \${wfile}.bmap \${wfile}.img
                        fi
                fi
                copy_img_to_mirror
        fi
}

generate_img () {
        if [ -d \${base_rootfs}/ ] ; then
                cd \${base_rootfs}/
                sudo ./setup_sdcard.sh \${options}
                sudo chown 1000:1000 *.img || true
                sudo chown 1000:1000 *.job.txt || true
                mv *.img ../ || true
                mv *.job.txt ../ || true
                cd ..
        fi
}

###lxqt-4gb image
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb" ; extract_base_rootfs

options="--img-4gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone} --emmc-flasher" ; generate_img
options="--img-4gb bone-\${base_rootfs} ${beaglebone}" ; generate_img
options="--img-4gb am57xx-eMMC-flasher-\${base_rootfs} ${am57xx_beagle_x15} --emmc-flasher" ; generate_img
options="--img-4gb am57xx-\${base_rootfs} ${am57xx_beagle_x15}" ; generate_img
options="--img-4gb omap5-uevm-\${base_rootfs} ${omap5_uevm}" ; generate_img

###lxqt-2gb image
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb" ; extract_base_rootfs

options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone} --bbb-flasher" ; generate_img

###console images: (also single partition)
base_rootfs="${debian_jessie_console}" ; blend="console" ; extract_base_rootfs

options="--img-2gb a335-eeprom-\${base_rootfs} ${bb_blank_flasher_console} --a335-flasher" ; generate_img
#options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone_console} --emmc-flasher" ; generate_img
#options="--img-2gb bone-\${base_rootfs} ${beaglebone_console}" ; generate_img
#options="--img-2gb am57xx-eMMC-flasher-\${base_rootfs} ${am57xx_beagle_x15} --emmc-flasher" ; generate_img
#options="--img-2gb am57xx-\${base_rootfs} ${am57xx_beagle_x15}" ; generate_img
#options="--img-2gb omap5-uevm-\${base_rootfs} ${omap5_uevm}" ; generate_img

###oemflasher images: (also single partition)
base_rootfs="${debian_jessie_oemflasher}" ; blend="oemflasher" ; extract_base_rootfs

options="--img-2gb BBB-blank-\${base_rootfs} --dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc --hostname beaglebone --usb-flasher" ; generate_img
options="--img-2gb am57xx-\${base_rootfs} --dtb am57xx-beagle-x15 --hostname BeagleBoard-X15 --usb-flasher" ; generate_img

###archive *.tar
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb" ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb" ; archive_base_rootfs
base_rootfs="${debian_jessie_console}" ; blend="console" ; archive_base_rootfs
base_rootfs="${debian_jessie_oemflasher}" ; blend="oemflasher" ; archive_base_rootfs

###archive *.img
#
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb"

wfile="BBB-eMMC-flasher-\${base_rootfs}-4gb" ; archive_img
wfile="bone-\${base_rootfs}-4gb" ; archive_img
wfile="am57xx-eMMC-flasher-\${base_rootfs}-4gb" ; archive_img
wfile="am57xx-\${base_rootfs}-4gb" ; archive_img
wfile="omap5-uevm-\${base_rootfs}-4gb" ; archive_img
wfile="tre-\${base_rootfs}-4gb" ; archive_img

#
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb"

wfile="BBB-eMMC-flasher-\${base_rootfs}-2gb" ; archive_img

#
base_rootfs="${debian_jessie_console}" ; blend="console"

wfile="a335-eeprom-\${base_rootfs}-2gb" ; archive_img
wfile="BBB-eMMC-flasher-\${base_rootfs}-2gb" ; archive_img
wfile="bone-\${base_rootfs}-2gb" ; archive_img
wfile="am57xx-eMMC-flasher-\${base_rootfs}-2gb" ; archive_img
wfile="am57xx-\${base_rootfs}-2gb" ; archive_img
wfile="omap5-uevm-\${base_rootfs}-2gb" ; archive_img

#
base_rootfs="${debian_jessie_oemflasher}" ; blend="oemflasher"

wfile="BBB-blank-\${base_rootfs}-2gb" ; archive_img
wfile="am57xx-\${base_rootfs}-2gb" ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ ! -d /mnt/farm/images/ ] ; then
	#nfs mount...
	sudo mount -a
fi

if [ -d /mnt/farm/images/ ] ; then
	mkdir /mnt/farm/images/bb.org-${time}/
	cp -v ${DIR}/deploy/*.tar /mnt/farm/images/bb.org-${time}/
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/bb.org-${time}/gift_wrap_final_images.sh
	chmod +x /mnt/farm/images/bb.org-${time}/gift_wrap_final_images.sh
fi

