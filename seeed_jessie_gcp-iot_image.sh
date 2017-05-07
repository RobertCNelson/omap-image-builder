#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

./RootStock-NG.sh -c seeed-debian-jessie-gcp-iot-v4.4

debian_jessie_seeed_gcp_iot="debian-8.8-seeed-gcp-iot-armhf-${time}"

archive="xz -z -8 -v"

beaglebone="--dtb beaglebone --bbb-old-bootloader-in-emmc \
--rootfs_label rootfs --hostname beaglebone --enable-cape-universal"

omap5_uevm="--dtb omap5-uevm --rootfs_label rootfs --hostname omap5-uevm"
beagle_x15="--dtb am57xx-beagle-x15 --rootfs_label rootfs \
--hostname BeagleBoard-X15"

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
        fi

        if [ -f \${base_rootfs}.tar ] ; then
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
        if [ -d \${base_rootfs}/ ] ; then
                cd \${base_rootfs}/
                sudo ./setup_sdcard.sh \${options}
                mv *.img ../ || true
                mv *.job.txt ../ || true
                cd ..
        fi
}

###seeed gcp iot image
base_rootfs="${debian_jessie_seeed_gcp_iot}" ; blend="seeed-gcp-iot" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}       ${beaglebone}"                ; generate_img
options="--img-4gb BBGW-blank-\${base_rootfs} ${beaglebone} --bbgw-flasher" ; generate_img

###archive *.tar
base_rootfs="${debian_jessie_seeed_gcp_iot}"      ; blend="seeed-gcp-iot"      ; archive_base_rootfs

###archive *.img
base_rootfs="${debian_jessie_seeed_gcp_iot}" ; blend="seeed-gcp-iot"

wfile="bone-\${base_rootfs}-4gb"       ; archive_img
wfile="BBGW-blank-\${base_rootfs}-4gb" ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh
