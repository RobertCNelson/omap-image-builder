#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

./RootStock-NG.sh -c bb.org-debian-jessie-console-v4.4
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-2gb-v4.4
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-4gb-v4.4

       debian_jessie_console="debian-8.11-console-armhf-${time}"
      debian_jessie_lxqt_2gb="debian-8.11-lxqt-2gb-armhf-${time}"
      debian_jessie_lxqt_4gb="debian-8.11-lxqt-4gb-armhf-${time}"

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


###console images (jessie):
base_rootfs="${debian_jessie_console}" ; blend="console" ; extract_base_rootfs

options="--img-1gb am57xx-\${base_rootfs}       ${beagle_x15}"                ; generate_img
options="--img-1gb bone-\${base_rootfs}        ${beaglebone} ${pru_rproc_v44ti}"   ; generate_img

###lxqt-2gb image (jessie):
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb" ; extract_base_rootfs

options="--img-2gb BBB-blank-\${base_rootfs} ${beaglebone}  ${pru_rproc_v44ti} --emmc-flasher" ; generate_img

###lxqt-4gb image (jessie):
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb" ; extract_base_rootfs

options="--img-4gb am57xx-\${base_rootfs}       ${beagle_x15}"                             ; generate_img
options="--img-4gb am57xx-blank-\${base_rootfs} ${beagle_x15} --emmc-flasher --am57xx-x15-revc-flasher" ; generate_img
options="--img-4gb bone-\${base_rootfs}        ${beaglebone} ${pru_rproc_v44ti}"                ; generate_img
options="--img-4gb BBB-blank-\${base_rootfs}   ${beaglebone} ${pru_rproc_v44ti} --emmc-flasher" ; generate_img

###archive *.tar
base_rootfs="${debian_jessie_console}"        ; blend="console"         ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_2gb}"       ; blend="lxqt-2gb"        ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_4gb}"       ; blend="lxqt-4gb"        ; archive_base_rootfs

###console images (jessie):
base_rootfs="${debian_jessie_console}" ; blend="console"

wfile="am57xx-\${base_rootfs}-1gb"       ; archive_img
wfile="bone-\${base_rootfs}-1gb"        ; archive_img

###lxqt-2gb image (jessie):
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb"

wfile="BBB-blank-\${base_rootfs}-2gb"      ; archive_img

###lxqt-4gb image (jessie):
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb"

wfile="am57xx-\${base_rootfs}-4gb"       ; archive_img
wfile="am57xx-blank-\${base_rootfs}-4gb" ; archive_img
wfile="bone-\${base_rootfs}-4gb"        ; archive_img
wfile="BBB-blank-\${base_rootfs}-4gb"   ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh
