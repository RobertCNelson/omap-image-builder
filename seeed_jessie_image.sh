#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

./RootStock-NG.sh -c bb.org-debian-jessie-oemflasher
./RootStock-NG.sh -c seeed-debian-jessie-lxqt-4gb-v4.4
./RootStock-NG.sh -c seeed-debian-jessie-iot-v4.4

    debian_jessie_oemflasher="debian-8.8-oemflasher-armhf-${time}"
debian_jessie_seeed_lxqt_4gb="debian-8.8-seeed-lxqt-4gb-armhf-${time}"
     debian_jessie_seeed_iot="debian-8.8-seeed-iot-armhf-${time}"

archive="xz -z -8 -v"

beaglebone="--dtb beaglebone --bbb-old-bootloader-in-emmc --hostname beaglebone"

bb_blank_flasher="--dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc \
--hostname beaglebone"

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

###oemflasher images: (also single partition)
base_rootfs="${debian_jessie_oemflasher}" ; blend="oemflasher" ; extract_base_rootfs

options="--img-4gb BBB-blank-\${base_rootfs} --dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc --hostname beaglebone --usb-flasher" ; generate_img

###Seeed lxqt-4gb image
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs} ${beaglebone}" ; generate_img

###Seeed iot image
base_rootfs="${debian_jessie_seeed_iot}" ; blend="seeed-iot" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs} ${beaglebone}" ; generate_img

###archive *.tar
base_rootfs="${debian_jessie_oemflasher}" ; blend="oemflasher" ; archive_base_rootfs
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb" ; archive_base_rootfs
base_rootfs="${debian_jessie_seeed_iot}" ; blend="seeed-iot" ; archive_base_rootfs

#
base_rootfs="${debian_jessie_oemflasher}" ; blend="oemflasher"
wfile="bbx15-\${base_rootfs}-4gb" ; archive_img

#
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb"
wfile="bone-\${base_rootfs}-4gb" ; archive_img

#
base_rootfs="${debian_jessie_seeed_iot}" ; blend="seeed-iot"
wfile="bone-\${base_rootfs}-4gb" ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh
