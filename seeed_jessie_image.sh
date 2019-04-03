#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

./RootStock-NG.sh -c seeed-debian-jessie-lxqt-4gb-v4.4
./RootStock-NG.sh -c seeed-debian-jessie-iot-v4.4

     debian_jessie_seeed_iot="debian-8.11-seeed-iot-armhf-${time}"
debian_jessie_seeed_lxqt_4gb="debian-8.11-seeed-lxqt-4gb-armhf-${time}"

archive="xz -z -8 -v"

beaglebone="--dtb beaglebone --rootfs_label rootfs --hostname beaglebone --enable-cape-universal"
pru_rproc_v44ti="--enable-uboot-pru-rproc-44ti"
pru_rproc_v414ti="--enable-uboot-pru-rproc-414ti"
pru_rproc_v419ti="--enable-uboot-pru-rproc-419ti"
pru_rproc_mainline="--enable-mainline-pru-rproc"
pru_uio_v419="--enable-uboot-pru-uio-419"

beagle_xm="--dtb omap3-beagle-xm --rootfs_label rootfs --hostname beagleboard"

beagle_x15="--dtb am57xx-beagle-x15 --rootfs_label rootfs --hostname BeagleBoard-X15"

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
                if [ -f \${base_rootfs}.tar ] ; then
                        tar xf \${base_rootfs}.tar
                fi
        fi
}

archive_img () {
        if [ -f \${wfile}.img ] ; then
                #prevent xz warning for 'Cannot set the file group: Operation not permitted'
                sudo chown 1000:1000 \${wfile}.img
                if [ ! -f \${wfile}.bmap ] ; then
                        if [ -f /usr/bin/bmaptool ] ; then
                                bmaptool create -o \${wfile}.bmap \${wfile}.img
                        fi
                fi
                ${archive} \${wfile}.img && sha256sum \${wfile}.img.xz > \${wfile}.img.xz.sha256sum &
        fi
}

generate_img () {
        if [ ! "x\${base_rootfs}" = "x" ] ; then
                if [ -d \${base_rootfs}/ ] ; then
                        cd \${base_rootfs}/
                        sudo ./setup_sdcard.sh \${options}
                        mv *.img ../ || true
                        mv *.job.txt ../ || true
                        cd ..
                fi
        fi
}

###Seeed iot image (jessie):
base_rootfs="${debian_jessie_seeed_iot}" ; blend="seeed-iot" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}       ${beaglebone}"                ; generate_img

###Seeed lxqt-4gb image (jessie):
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}      ${beaglebone}"                ; generate_img

###archive *.tar
base_rootfs="${debian_jessie_seeed_iot}"      ; blend="seeed-iot"       ; archive_base_rootfs
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb"  ; archive_base_rootfs

###Seeed iot image (jessie):
base_rootfs="${debian_jessie_seeed_iot}" ; blend="seeed-iot"

wfile="bone-\${base_rootfs}-4gb"       ; archive_img

###Seeed lxqt-4gb image (jessie):
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb"

wfile="bone-\${base_rootfs}-4gb"      ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh
