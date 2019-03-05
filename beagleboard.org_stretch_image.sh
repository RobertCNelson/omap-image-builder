#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

#./RootStock-NG.sh -c bb.org-debian-stretch-console-v4.14
./RootStock-NG.sh -c bb.org-debian-stretch-iot-v4.14
#./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-2gb-v4.14
#./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-v4.14
#./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-xm

      debian_stretch_console="debian-9.8-console-armhf-${time}"
          debian_stretch_iot="debian-9.8-iot-armhf-${time}"
     debian_stretch_lxqt_2gb="debian-9.8-lxqt-2gb-armhf-${time}"
         debian_stretch_lxqt="debian-9.8-lxqt-armhf-${time}"
      debian_stretch_lxqt_xm="debian-9.8-lxqt-xm-armhf-${time}"

archive="xz -z -8 -v"

beaglebone="--dtb beaglebone --rootfs_label rootfs --hostname beaglebone"
pru_rproc_v44ti="--enable-uboot-pru-rproc-44ti"
pru_rproc_v414ti="--enable-uboot-pru-rproc-414ti"
pru_rproc_v419ti="--enable-uboot-pru-rproc-419ti"
pru_rproc_mainline="--enable-mainline-pru-rproc"
pru_uio_v419="--enable-uboot-pru-uio-419"

beagle_xm="--dtb omap3-beagle-xm --rootfs_label rootfs --hostname beagleboard"

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

###machinekit (stretch):
base_rootfs="${debian_stretch_machinekit}" ; blend="stretch-machinekit" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs} ${beaglebone}" ; generate_img

###console image (stretch):
base_rootfs="${debian_stretch_console}" ; blend="stretch-console" ; extract_base_rootfs

options="--img-1gb am57xx-\${base_rootfs}     ${beagle_x15}"                ; generate_img
options="--img-1gb bone-\${base_rootfs}      ${beaglebone}  ${pru_rproc_v414ti}"                ; generate_img

###iot image (stretch):
base_rootfs="${debian_stretch_iot}" ; blend="stretch-iot" ; extract_base_rootfs

options="--img-4gb am57xx-\${base_rootfs}      ${beagle_x15}"                                   ; generate_img
options="--img-4gb bone-\${base_rootfs}       ${beaglebone} ${pru_rproc_v414ti}"                ; generate_img
options="--img-4gb BBB-blank-\${base_rootfs}  ${beaglebone} ${pru_rproc_v414ti} --emmc-flasher" ; generate_img
options="--img-4gb BBBL-blank-\${base_rootfs} ${beaglebone} ${pru_rproc_v414ti} --bbbl-flasher" ; generate_img

###lxqt-2gb image (stretch):
base_rootfs="${debian_stretch_lxqt_2gb}" ; blend="stretch-lxqt-2gb" ; extract_base_rootfs

options="--img-2gb bone-\${base_rootfs}      ${beaglebone} ${pru_rproc_v414ti}" ; generate_img
options="--img-2gb BBB-blank-\${base_rootfs} ${beaglebone} ${pru_rproc_v414ti} --emmc-flasher" ; generate_img

###lxqt image (stretch):
base_rootfs="${debian_stretch_lxqt}" ; blend="stretch-lxqt" ; extract_base_rootfs

options="--img-4gb am57xx-\${base_rootfs}       ${beagle_x15}"                             ; generate_img
options="--img-4gb am57xx-blank-\${base_rootfs} ${beagle_x15} --emmc-flasher --am57xx-x15-revc-flasher" ; generate_img
options="--img-4gb bone-\${base_rootfs}        ${beaglebone} ${pru_rproc_v414ti}"                ; generate_img
options="--img-4gb BBB-blank-\${base_rootfs}   ${beaglebone} ${pru_rproc_v414ti} --emmc-flasher" ; generate_img

###lxqt image (stretch):
base_rootfs="${debian_stretch_lxqt_xm}" ; blend="stretch-lxqt-xm" ; extract_base_rootfs

options="--img-4gb bbxm-\${base_rootfs}  ${beagle_xm}" ; generate_img

### wayland image (stretch):
base_rootfs="${debian_stretch_wayland}" ; blend="stretch-wayland" ; extract_base_rootfs

options="--img-4gb am57xx-\${base_rootfs} ${beagle_x15}"    ; generate_img
options="--img-4gb bone-\${base_rootfs}  ${beaglebone}"    ; generate_img

###archive *.tar
base_rootfs="${debian_stretch_console}"       ; blend="stretch-console"    ; archive_base_rootfs
base_rootfs="${debian_stretch_iot}"           ; blend="stretch-iot"        ; archive_base_rootfs
base_rootfs="${debian_stretch_lxqt_2gb}"      ; blend="stretch-lxqt-2gb"   ; archive_base_rootfs
base_rootfs="${debian_stretch_lxqt}"          ; blend="stretch-lxqt"       ; archive_base_rootfs
base_rootfs="${debian_stretch_lxqt_xm}"       ; blend="stretch-lxqt-xm"    ; archive_base_rootfs

###console image (stretch):
base_rootfs="${debian_stretch_console}" ; blend="stretch-console"

wfile="am57xx-\${base_rootfs}-1gb"          ; archive_img
wfile="bone-\${base_rootfs}-1gb"           ; archive_img

###iot image (stretch):
base_rootfs="${debian_stretch_iot}" ; blend="stretch-iot"

wfile="am57xx-\${base_rootfs}-4gb"          ; archive_img
wfile="bone-\${base_rootfs}-4gb"           ; archive_img
wfile="BBB-blank-\${base_rootfs}-4gb"      ; archive_img
wfile="BBBL-blank-\${base_rootfs}-4gb"     ; archive_img

###lxqt-2gb image (stretch):
base_rootfs="${debian_stretch_lxqt_2gb}" ; blend="stretch-lxqt-2gb"

wfile="bone-\${base_rootfs}-2gb"           ; archive_img
wfile="BBB-blank-\${base_rootfs}-2gb"      ; archive_img

###lxqt image (stretch):
base_rootfs="${debian_stretch_lxqt}" ; blend="stretch-lxqt"

wfile="am57xx-\${base_rootfs}-4gb"          ; archive_img
wfile="am57xx-blank-\${base_rootfs}-4gb"    ; archive_img
wfile="bone-\${base_rootfs}-4gb"           ; archive_img
wfile="BBB-blank-\${base_rootfs}-4gb"      ; archive_img

###lxqt-xm image (stretch):
base_rootfs="${debian_stretch_lxqt_xm}" ; blend="stretch-lxqt-xm"

wfile="bbxm-\${base_rootfs}-4gb"      ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh
