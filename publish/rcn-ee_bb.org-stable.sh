#!/bin/bash -e

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.net/rootfs/bb.org/testing"
DIR="$PWD"

git pull --no-edit https://github.com/beagleboard/image-builder master

export apt_proxy=apt-proxy:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

./RootStock-NG.sh -c machinekit-debian-wheezy
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-2gb-v4.1
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-4gb-v4.1
./RootStock-NG.sh -c bb.org-debian-jessie-console-v4.1
./RootStock-NG.sh -c bb.org-debian-jessie-usbflasher

debian_wheezy_machinekit="debian-7.9-machinekit-armhf-${time}"
debian_jessie_lxqt_2gb="debian-8.2-lxqt-2gb-armhf-${time}"
debian_jessie_lxqt_4gb="debian-8.2-lxqt-4gb-armhf-${time}"
debian_jessie_console="debian-8.2-console-armhf-${time}"
debian_jessie_usbflasher="debian-8.2-usbflasher-armhf-${time}"

archive="xz -z -8"

beaglebone="--dtb beaglebone --beagleboard.org-production --boot_label BEAGLEBONE \
--rootfs_label rootfs --bbb-old-bootloader-in-emmc --hostname beaglebone"

bb_blank_flasher="--dtb bbb-blank-eeprom --boot_label BEAGLEBONE \
--rootfs_label rootfs --bbb-old-bootloader-in-emmc --hostname beaglebone"

beaglebone_console="--dtb beaglebone --boot_label BEAGLEBONE \
--bbb-old-bootloader-in-emmc --hostname beaglebone"

bb_blank_flasher_console="--dtb bbb-blank-eeprom --boot_label BEAGLEBONE \
--bbb-old-bootloader-in-emmc --hostname beaglebone"

arduino_tre="--dtb am335x-arduino-tre --beagleboard.org-production --boot_label ARDUINO-TRE \
--rootfs_label rootfs --hostname arduino-tre"

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
                                ${archive} \${base_rootfs}.tar && sha256sum \${base_rootfs}.tar.zx > \${base_rootfs}.tar.zx.sha256sum &
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
        else
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
                                cp -v \${wfile}.bmap ${mirror_dir}/${time}/\${blend}/
                        fi
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${wfile}.img.zx ] ; then
                                cp -v \${wfile}.img ${mirror_dir}/${time}/\${blend}/
                                if [ -f \${wfile}.img.xz.job.txt ] ; then
                                        cp -v \${wfile}.img.xz.job.txt ${mirror_dir}/${time}/\${blend}/
                                fi
                                cd ${mirror_dir}/${time}/\${blend}/
                                ${archive} \${wfile}.img && sha256sum \${wfile}.img.zx > \${wfile}.img.zx.sha256sum &
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
        cd \${base_rootfs}/
        sudo ./setup_sdcard.sh \${options}
        mv *.img ../
        mv *.job.txt ../
        cd ..
}

###machinekit:
base_rootfs="${debian_wheezy_machinekit}" ; blend="machinekit" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs} ${beaglebone} --enable-systemd" ; generate_img

###lxqt-4gb image
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb" ; extract_base_rootfs

options="--img-4gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone} --emmc-flasher" ; generate_img
options="--img-4gb bbx15-eMMC-flasher-\${base_rootfs} ${am57xx_beagle_x15} --emmc-flasher" ; generate_img
options="--img-4gb bbx15-\${base_rootfs} ${am57xx_beagle_x15}" ; generate_img
options="--img-4gb bbxm-\${base_rootfs} ${omap3_beagle_xm}" ; generate_img
options="--img-4gb bone-\${base_rootfs} ${beaglebone}" ; generate_img
options="--img-4gb omap5-uevm-\${base_rootfs} ${omap5_uevm}" ; generate_img
options="--img-4gb tre-\${base_rootfs} ${arduino_tre}" ; generate_img

###lxqt-2gb image
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb" ; extract_base_rootfs

options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone} --bbb-flasher" ; generate_img

###console images: (also single partition)
base_rootfs="${debian_jessie_console}" ; blend="console" ; extract_base_rootfs

#options="--img-2gb BBG-blank-eMMC-flasher-\${base_rootfs} ${bb_blank_flasher_console} --bbg-flasher" ; generate_img
#options="--img-2gb BBB-blank-eMMC-flasher-\${base_rootfs} ${bb_blank_flasher_console} --emmc-flasher" ; generate_img
options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone_console} --emmc-flasher" ; generate_img
options="--img-2gb bbx15-eMMC-flasher-\${base_rootfs} ${am57xx_beagle_x15} --emmc-flasher" ; generate_img
options="--img-2gb bbx15-\${base_rootfs} ${am57xx_beagle_x15}" ; generate_img
options="--img-2gb bbxm-\${base_rootfs} ${omap3_beagle_xm}" ; generate_img
options="--img-2gb bone-\${base_rootfs} ${beaglebone_console}" ; generate_img
options="--img-2gb omap5-uevm-\${base_rootfs} ${omap5_uevm}" ; generate_img

###usbflasher images: (also single partition)
base_rootfs="${debian_jessie_usbflasher}" ; blend="usbflasher" ; extract_base_rootfs
options="--img-2gb BBB-blank-\${base_rootfs} --dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc --hostname beaglebone --usb-flasher" ; generate_img
options="--img-2gb bbx15-\${base_rootfs} --dtb am57xx-beagle-x15 --hostname BeagleBoard-X15 --usb-flasher" ; generate_img

###archive *.tar
base_rootfs="${debian_wheezy_machinekit}" ; blend="machinekit" ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb" ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb" ; archive_base_rootfs
base_rootfs="${debian_jessie_console}" ; blend="console" ; archive_base_rootfs
base_rootfs="${debian_jessie_usbflasher}" ; blend="usbflasher" ; archive_base_rootfs

###archive *.img
blend="machinekit"
wfile="bone-${debian_wheezy_machinekit}-4gb" ; archive_img

blend="lxqt-4gb"
wfile="BBB-eMMC-flasher-${debian_jessie_lxqt_4gb}-4gb" ; archive_img
wfile="bbx15-eMMC-flasher-${debian_jessie_lxqt_4gb}-4gb" ; archive_img
wfile="bbx15-${debian_jessie_lxqt_4gb}-4gb" ; archive_img
wfile="bbxm-${debian_jessie_lxqt_4gb}-4gb" ; archive_img
wfile="bone-${debian_jessie_lxqt_4gb}-4gb" ; archive_img
wfile="omap5-uevm-${debian_jessie_lxqt_4gb}-4gb" ; archive_img
wfile="tre-${debian_jessie_lxqt_4gb}-4gb" ; archive_img

blend="lxqt-2gb"
wfile="BBB-eMMC-flasher-${debian_jessie_lxqt_2gb}-2gb" ; archive_img

blend="console"
#wfile="BBB-blank-eMMC-flasher-${debian_jessie_console}-2gb" ; archive_img
#wfile="BBG-blank-eMMC-flasher-${debian_jessie_console}-2gb" ; archive_img
wfile="BBB-eMMC-flasher-${debian_jessie_console}-2gb" ; archive_img
wfile="bbx15-eMMC-flasher-${debian_jessie_console}-2gb" ; archive_img
wfile="bbx15-${debian_jessie_console}-2gb" ; archive_img
wfile="bbxm-${debian_jessie_console}-2gb" ; archive_img
wfile="bone-${debian_jessie_console}-2gb" ; archive_img
wfile="omap5-uevm-${debian_jessie_console}-2gb" ; archive_img

blend="usbflasher"
wfile="BBB-blank-${debian_jessie_usbflasher}-2gb" ; archive_img
wfile="bbx15-${debian_jessie_usbflasher}-2gb" ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ ! -d /mnt/farm/images/ ] ; then
	#nfs mount...
	sudo mount -a
fi

if [ -d /mnt/farm/images/ ] ; then
	mkdir /mnt/farm/images/${time}/
	cp -v ${DIR}/deploy/*.tar /mnt/farm/images/${time}/
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/${time}/gift_wrap_final_images.sh
	chmod +x /mnt/farm/images/${time}/gift_wrap_final_images.sh
fi

