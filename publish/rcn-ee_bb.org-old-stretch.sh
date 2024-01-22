#!/bin/bash -e

OIB_USER=${OIB_USER:-1000}
IMAGE_DIR_PREFIX=${IMAGE_DIR_PREFIX:-bb.org}

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.us/rootfs/bb.org/testing"
DIR="$PWD"

git pull --no-edit https://github.com/beagleboard/image-builder master

export apt_proxy=192.168.1.10:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

if [ ! -f jenkins.build ] ; then
./RootStock-NG.sh -c machinekit-debian-stretch
./RootStock-NG.sh -c bb.org-debian-stretch-console-v4.14
./RootStock-NG.sh -c bb.org-debian-stretch-imgtec-v4.14.conf
./RootStock-NG.sh -c bb.org-debian-stretch-iot-v4.14
./RootStock-NG.sh -c bb.org-debian-stretch-iot-tidl-v4.14
./RootStock-NG.sh -c bb.org-debian-stretch-iot-grove-kit-v4.14.conf
./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-v4.14
./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-tidl-v4.14
./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-xm
else
	mkdir -p ${DIR}/deploy/ || true
fi

  debian_stretch_machinekit="debian-9.13-machinekit-armhf-${time}"
     debian_stretch_console="debian-9.13-console-armhf-${time}"
      debian_stretch_imgtec="debian-9.13-imgtec-armhf-${time}"
         debian_stretch_iot="debian-9.13-iot-armhf-${time}"
    debian_stretch_iot_tidl="debian-9.13-iot-tidl-armhf-${time}"
debian_stretch_iot_grove_kit="debian-9.13-iot-grove-kit-armhf-${time}"
        debian_stretch_lxqt="debian-9.13-lxqt-armhf-${time}"
   debian_stretch_lxqt_tidl="debian-9.13-lxqt-tidl-armhf-${time}"
     debian_stretch_lxqt_xm="debian-9.13-lxqt-xm-armhf-${time}"
     debian_stretch_wayland="debian-9.13-wayland-armhf-${time}"

xz_img="xz -T4 -z -8"
xz_tar="xz -T4 -z -8"

beagle_xm="--dtb omap3-beagle-xm --rootfs_label rootfs --hostname beagleboard"

  am335x_v414ti="--dtb beaglebone --distro-bootloader --rootfs_label rootfs --hostname beaglebone --enable-cape-universal --enable-uboot-pru-rproc-414ti"
  am335x_v419ti="--dtb beaglebone --distro-bootloader --rootfs_label rootfs --hostname beaglebone --enable-cape-universal --enable-uboot-pru-rproc-419ti"
   am335x_v54ti="--dtb beaglebone --distro-bootloader --rootfs_label rootfs --hostname beaglebone --enable-cape-universal --enable-uboot-pru-rproc-54ti"
  am335x_v510ti="--dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-disable-pru --enable-bypass-bootup-scripts"
am335x_mainline="--dtb beaglebone --distro-bootloader --rootfs_label rootfs --hostname beaglebone --enable-cape-universal"

am57xx_v414ti="--dtb am57xx-beagle-x15 --distro-bootloader --rootfs_label rootfs --hostname beaglebone"
am57xx_v419ti="--dtb am57xx-beagle-x15 --distro-bootloader --rootfs_label rootfs --hostname beaglebone --enable-uboot-cape-overlays"
 am57xx_v54ti="--dtb am57xx-beagle-x15 --distro-bootloader --rootfs_label rootfs --hostname beaglebone"
am57xx_v510ti="--dtb am57xx-beagle-x15 --distro-bootloader --enable-uboot-cape-overlays --enable-bypass-bootup-scripts"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

wait_till_Xgb_free () {
        memory=8192
        free_memory=\$(free --mega | grep Mem | awk '{print \$7}')
        until [ "\$free_memory" -gt "\$memory" ] ; do
                free_memory=\$(free --mega | grep Mem | awk '{print \$7}')
                echo "have [\$free_memory] need [\$memory]"
                sleep 10
        done
}

copy_base_rootfs_to_mirror () {
        wait_till_Xgb_free
        if [ -d ${mirror_dir}/ ] ; then
                if [ ! -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        mkdir -p ${mirror_dir}/${time}/\${blend}/ || true
                fi
                if [ -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${rootfs}.tar.xz ] ; then
                                ${xz_tar} \${rootfs}.tar
                                sha256sum \${rootfs}.tar.xz > \${rootfs}.tar.xz.sha256sum
                                cp -v \${rootfs}.tar.xz ${mirror_dir}/${time}/\${blend}/
                                mv -v \${rootfs}.tar.xz.sha256sum ${mirror_dir}/${time}/\${blend}/
                        fi
                fi
        fi
}

archive_base_rootfs () {
        if [ -d ./\${rootfs} ] ; then
                rm -rf \${rootfs} || true
        fi
        if [ -f \${rootfs}.tar ] ; then
                copy_base_rootfs_to_mirror
        fi
}

extract_base_rootfs () {
        if [ -d ./\${rootfs} ] ; then
                rm -rf \${rootfs} || true
        fi

        if [ -f \${rootfs}.tar.xz ] ; then
                tar xf \${rootfs}.tar.xz
        fi

        if [ -f \${rootfs}.tar ] ; then
                tar xf \${rootfs}.tar
        fi
}

copy_img_to_mirror () {
        wait_till_Xgb_free
        if [ -d ${mirror_dir} ] ; then
                if [ ! -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        mkdir -p ${mirror_dir}/${time}/\${blend}/ || true
                fi
                if [ -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        if [ -f ./generate.log ] ; then
                                mv -v ./generate.log ${mirror_dir}/${time}/\${blend}/
                                sync
                        fi
                        if [ -f \${wfile}.bmap ] ; then
                                mv -v \${wfile}.bmap ${mirror_dir}/${time}/\${blend}/
                                sync
                        fi
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${wfile}.img.zx ] ; then
                                ${xz_img} \${wfile}.img
                                sha256sum \${wfile}.img.xz > \${wfile}.img.xz.sha256sum
                                mv -v \${wfile}.img.xz ${mirror_dir}/${time}/\${blend}/
                                mv -v \${wfile}.img.xz.sha256sum ${mirror_dir}/${time}/\${blend}/
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
        if [ -d \${rootfs}/ ] ; then
                cd \${rootfs}/
                echo "./setup_sdcard.sh \${options}" >> ../generate.log
                echo "./setup_sdcard.sh \${options}"
                sudo ./setup_sdcard.sh \${options}
                sudo chown 1000:1000 *.img || true
                mv *.img ../ || true
                cd ..
        fi
}

###DEBIAN STRETCH: machinekit
rootfs="${debian_stretch_machinekit}" ; blend="stretch-machinekit" ; extract_base_rootfs

options="--img-4gb bone-\${rootfs} ${am335x_mainline}"  ; generate_img

###DEBIAN STRETCH: console
rootfs="${debian_stretch_console}" ; blend="stretch-console" ; extract_base_rootfs

options="--img-1gb am57xx-\${rootfs}               ${am57xx_v414ti}"                 ; generate_img
options="--img-1gb am57xx-eMMC-flasher-\${rootfs}  ${am57xx_v414ti} --emmc-flasher"  ; generate_img
options="--img-1gb bone-\${rootfs}                 ${am335x_v414ti}"                 ; generate_img
options="--img-1gb bone-eMMC-flasher-\${rootfs}    ${am335x_v414ti} --emmc-flasher"  ; generate_img

options="--img-1gb BBB-blank-\${rootfs}            ${am335x_v414ti} --bbb-flasher"   ; generate_img
options="--img-1gb BBBL-blank-\${rootfs}           ${am335x_v414ti} --bbbl-flasher"  ; generate_img
options="--img-1gb BBBW-blank-\${rootfs}           ${am335x_v414ti} --bbbw-flasher"  ; generate_img
options="--img-1gb BBGG-blank-\${rootfs}           ${am335x_v414ti} --bbgg-flasher"  ; generate_img

###DEBIAN STRETCH: imgtec
rootfs="${debian_stretch_imgtec}" ; blend="stretch-imgtec" ; extract_base_rootfs

options="--img-4gb bone-\${rootfs}  ${am335x_v414ti}"  ; generate_img

###DEBIAN STRETCH: iot
rootfs="${debian_stretch_iot}" ; blend="stretch-iot" ; extract_base_rootfs

options="--img-4gb am57xx-\${rootfs}               ${am57xx_v414ti}"                 ; generate_img
options="--img-4gb am57xx-eMMC-flasher-\${rootfs}  ${am57xx_v414ti} --emmc-flasher"  ; generate_img
options="--img-4gb bone-\${rootfs}                 ${am335x_v414ti}"                 ; generate_img
options="--img-4gb bone-eMMC-flasher-\${rootfs}    ${am335x_v414ti} --emmc-flasher"  ; generate_img

###DEBIAN STRETCH: iot-tidl
rootfs="${debian_stretch_iot_tidl}" ; blend="stretch-iot-tidl" ; extract_base_rootfs

options="--img-6gb am57xx-\${rootfs}               ${am57xx_v414ti}"                 ; generate_img
options="--img-6gb am57xx-eMMC-flasher-\${rootfs}  ${am57xx_v414ti} --emmc-flasher"  ; generate_img

###DEBIAN STRETCH: iot-grove-kit
rootfs="${debian_stretch_iot_grove_kit}" ; blend="stretch-iot-grove-kit" ; extract_base_rootfs

options="--img-4gb bone-\${rootfs}  ${am335x_v414ti}"  ; generate_img

###DEBIAN STRETCH: lxqt
rootfs="${debian_stretch_lxqt}" ; blend="stretch-lxqt" ; extract_base_rootfs

options="--img-4gb am57xx-\${rootfs}             ${am57xx_v414ti}"                 ; generate_img
options="--img-4gb bone-\${rootfs}               ${am335x_v414ti}"                 ; generate_img
options="--img-4gb bone-eMMC-flasher-\${rootfs}  ${am335x_v414ti} --emmc-flasher"  ; generate_img

###DEBIAN STRETCH: lxqt-tidl
rootfs="${debian_stretch_lxqt_tidl}" ; blend="stretch-lxqt-tidl" ; extract_base_rootfs

options="--img-6gb am57xx-\${rootfs}               ${am57xx_v414ti}"                                   ; generate_img
options="--img-6gb am57xx-eMMC-flasher-\${rootfs}  ${am57xx_v414ti} --emmc-flasher"                    ; generate_img

###DEBIAN STRETCH: lxqt-xm
rootfs="${debian_stretch_lxqt_xm}" ; blend="stretch-lxqt-xm" ; extract_base_rootfs

options="--img-4gb bbxm-\${rootfs}  ${beagle_xm}"  ; generate_img

###DEBIAN STRETCH: wayland
rootfs="${debian_stretch_wayland}" ; blend="stretch-wayland" ; extract_base_rootfs

options="--img-4gb am57xx-\${rootfs}  ${am57xx_v414ti}"  ; generate_img
options="--img-4gb bone-\${rootfs}    ${am335x_v414ti}"  ; generate_img

###archive *.tar
rootfs="${debian_stretch_machinekit}"    ; blend="stretch-machinekit" ; archive_base_rootfs
rootfs="${debian_stretch_console}"       ; blend="stretch-console"    ; archive_base_rootfs
rootfs="${debian_stretch_imgtec}"        ; blend="stretch-imgtec"     ; archive_base_rootfs
rootfs="${debian_stretch_iot}"           ; blend="stretch-iot"        ; archive_base_rootfs
rootfs="${debian_stretch_iot_tidl}"      ; blend="stretch-iot-tidl"   ; archive_base_rootfs
rootfs="${debian_stretch_iot_grove_kit}" ; blend="stretch-iot-grove-kit"   ; archive_base_rootfs
rootfs="${debian_stretch_lxqt}"          ; blend="stretch-lxqt"       ; archive_base_rootfs
rootfs="${debian_stretch_lxqt_tidl}"     ; blend="stretch-lxqt-tidl"  ; archive_base_rootfs
rootfs="${debian_stretch_lxqt_xm}"       ; blend="stretch-lxqt-xm"    ; archive_base_rootfs
rootfs="${debian_stretch_wayland}"       ; blend="stretch-wayland"    ; archive_base_rootfs

###archive *.img
###DEBIAN STRETCH: machinekit
rootfs="${debian_stretch_machinekit}" ; blend="stretch-machinekit"

wfile="bone-\${rootfs}-4gb"  ; archive_img

###DEBIAN STRETCH: console
rootfs="${debian_stretch_console}" ; blend="stretch-console"

wfile="am57xx-\${rootfs}-1gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${rootfs}-1gb"  ; archive_img
wfile="bone-\${rootfs}-1gb"                 ; archive_img
wfile="bone-eMMC-flasher-\${rootfs}-1gb"    ; archive_img

wfile="BBB-blank-\${rootfs}-1gb"            ; archive_img
wfile="BBBL-blank-\${rootfs}-1gb"           ; archive_img
wfile="BBBW-blank-\${rootfs}-1gb"           ; archive_img
wfile="BBGG-blank-\${rootfs}-1gb"           ; archive_img

###DEBIAN STRETCH: imgtec
rootfs="${debian_stretch_imgtec}" ; blend="stretch-imgtec"

wfile="bone-\${rootfs}-4gb"                 ; archive_img

###DEBIAN STRETCH: iot
rootfs="${debian_stretch_iot}" ; blend="stretch-iot"

wfile="am57xx-\${rootfs}-4gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${rootfs}-4gb"  ; archive_img
wfile="bone-\${rootfs}-4gb"                 ; archive_img
wfile="bone-eMMC-flasher-\${rootfs}-4gb"    ; archive_img

###DEBIAN STRETCH: iot-tidl
rootfs="${debian_stretch_iot_tidl}" ; blend="stretch-iot-tidl"

wfile="am57xx-\${rootfs}-6gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${rootfs}-6gb"  ; archive_img

###DEBIAN STRETCH: iot-grove-kit
rootfs="${debian_stretch_iot_grove_kit}" ; blend="stretch-iot-grove-kit"

wfile="bone-\${rootfs}-4gb"                 ; archive_img

###DEBIAN STRETCH: lxqt
rootfs="${debian_stretch_lxqt}" ; blend="stretch-lxqt"

wfile="am57xx-\${rootfs}-4gb"               ; archive_img
wfile="bone-\${rootfs}-4gb"                 ; archive_img
wfile="bone-eMMC-flasher-\${rootfs}-4gb"    ; archive_img

###DEBIAN STRETCH: lxqt-tidl
rootfs="${debian_stretch_lxqt_tidl}" ; blend="stretch-lxqt-tidl"

wfile="am57xx-\${rootfs}-6gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${rootfs}-6gb"  ; archive_img

###DEBIAN STRETCH: lxqt-xm
rootfs="${debian_stretch_lxqt_xm}" ; blend="stretch-lxqt-xm"

wfile="bbxm-\${rootfs}-4gb"  ; archive_img

###DEBIAN STRETCH: wayland
rootfs="${debian_stretch_wayland}" ; blend="stretch-wayland"

wfile="am57xx-\${rootfs}-4gb"  ; archive_img
wfile="bone-\${rootfs}-4gb"    ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

#x86: My Server...
if [ -f /opt/images/nas.FREENAS ] ; then
	sudo mkdir -p /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/ || true

	echo "Copying: *.tar to server: images/${IMAGE_DIR_PREFIX}-${time}/"
	sudo cp -v ${DIR}/deploy/gift_wrap_final_images.sh /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/gift_wrap_final_images.sh || true

	ls -lha /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/
fi
