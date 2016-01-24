#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-2gb-v4.1
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-4gb-v4.1
./RootStock-NG.sh -c bb.org-debian-jessie-console-v4.1

debian_jessie_lxqt_2gb="debian-8.3-lxqt-2gb-armhf-${time}"
debian_jessie_lxqt_4gb="debian-8.3-lxqt-4gb-armhf-${time}"
debian_jessie_console="debian-8.3-console-armhf-${time}"

archive="xz -z -8 -v"

beaglebone="--dtb beaglebone --bbb-old-bootloader-in-emmc --hostname beaglebone"

bb_blank_flasher="--dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc \
--hostname beaglebone"

beaglebone_console="--dtb beaglebone --bbb-old-bootloader-in-emmc \
--hostname beaglebone"

bb_blank_flasher_console="--dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc \
--hostname beaglebone"

arduino_tre="--dtb am335x-arduino-tre --boot_label ARDUINO-TRE \
--rootfs_label rootfs --hostname arduino-tre"

omap3_beagle_xm="--dtb omap3-beagle-xm --hostname BeagleBoard"
omap5_uevm="--dtb omap5-uevm --hostname omap5-uevm"
am57xx_beagle_x15="--dtb am57xx-beagle-x15 --hostname BeagleBoard-X15"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

archive_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi
        if [ -f \${base_rootfs}.tar ] ; then
                ${archive} \${base_rootfs}.tar && sha256sum \${base_rootfs}.tar.xz > \${base_rootfs}.tar.xz.sha256sum &
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

archive_img () {
	#prevent xz warning for 'Cannot set the file group: Operation not permitted'
	sudo chown \${UID}:\${GROUPS} \${wfile}.img
        if [ -f \${wfile}.img ] ; then
                if [ ! -f \${wfile}.bmap ] ; then
                        if [ -f /usr/bin/bmaptool ] ; then
                                bmaptool create -o \${wfile}.bmap \${wfile}.img
                        fi
                fi
                ${archive} \${wfile}.img && sha256sum \${wfile}.img.xz > \${wfile}.img.xz.sha256sum &
        fi
}

generate_img () {
        cd \${base_rootfs}/
        sudo ./setup_sdcard.sh \${options}
        mv *.img ../
        mv *.job.txt ../
        cd ..
}

###lxqt-4gb image
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb" ; extract_base_rootfs

options="--img-4gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone} --emmc-flasher" ; generate_img
options="--img-4gb bone-\${base_rootfs} ${beaglebone}" ; generate_img
options="--img-4gb bbx15-eMMC-flasher-\${base_rootfs} ${am57xx_beagle_x15} --emmc-flasher" ; generate_img
options="--img-4gb bbx15-\${base_rootfs} ${am57xx_beagle_x15}" ; generate_img

###lxqt-2gb image
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb" ; extract_base_rootfs

options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone} --bbb-flasher" ; generate_img

###console images: (also single partition)
base_rootfs="${debian_jessie_console}" ; blend="console" ; extract_base_rootfs

options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone_console} --emmc-flasher" ; generate_img
options="--img-2gb bone-\${base_rootfs} ${beaglebone_console}" ; generate_img
options="--img-2gb bbx15-eMMC-flasher-\${base_rootfs} ${am57xx_beagle_x15} --emmc-flasher" ; generate_img
options="--img-2gb bbx15-\${base_rootfs} ${am57xx_beagle_x15}" ; generate_img

###archive *.tar
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb" ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb" ; archive_base_rootfs
base_rootfs="${debian_jessie_console}" ; blend="console" ; archive_base_rootfs

blend="lxqt-4gb"
wfile="BBB-eMMC-flasher-${debian_jessie_lxqt_4gb}-4gb" ; archive_img
wfile="bone-${debian_jessie_lxqt_4gb}-4gb" ; archive_img
wfile="bbx15-eMMC-flasher-${debian_jessie_lxqt_4gb}-4gb" ; archive_img
wfile="bbx15-${debian_jessie_lxqt_4gb}-4gb" ; archive_img

blend="lxqt-2gb"
wfile="BBB-eMMC-flasher-${debian_jessie_lxqt_2gb}-2gb" ; archive_img

blend="console"
wfile="BBB-eMMC-flasher-${debian_jessie_console}-2gb" ; archive_img
wfile="bone-${debian_jessie_console}-2gb" ; archive_img
wfile="bbx15-eMMC-flasher-${debian_jessie_console}-2gb" ; archive_img
wfile="bbx15-${debian_jessie_console}-2gb" ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh
