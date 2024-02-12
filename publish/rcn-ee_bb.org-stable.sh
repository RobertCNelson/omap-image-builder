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
./RootStock-NG.sh -c bb.org-debian-buster-console-v4.19
#./RootStock-NG.sh -c bb.org-debian-buster-console-v5.4
./RootStock-NG.sh -c bb.org-debian-buster-iot-v4.19
#./RootStock-NG.sh -c bb.org-debian-buster-iot-v5.4
./RootStock-NG.sh -c bb.org-debian-buster-iot-tidl-v4.14
#./RootStock-NG.sh -c bb.org-debian-buster-iot-tidl-v4.19
#./RootStock-NG.sh -c bb.org-debian-buster-iot-tidl-v5.4
./RootStock-NG.sh -c bb.org-debian-buster-iot-mikrobus
./RootStock-NG.sh -c bb.org-debian-buster-lxqt-v4.19
#./RootStock-NG.sh -c bb.org-debian-buster-lxqt-v5.4
./RootStock-NG.sh -c bb.org-debian-buster-lxqt-tidl-v4.14
#./RootStock-NG.sh -c bb.org-debian-buster-lxqt-tidl-v4.19
#./RootStock-NG.sh -c bb.org-debian-buster-lxqt-tidl-v5.4
./RootStock-NG.sh -c bb.org-debian-buster-lxqt-xm

#./RootStock-NG.sh -c bb.org-ubuntu-bionic-ros-iot-v4.19
./RootStock-NG.sh -c bb.org-ubuntu-bionic-ros-iot-v5.4

./RootStock-NG.sh -c bb.org-debian-bullseye-minimal-v5.10-ti-armhf
./RootStock-NG.sh -c bb.org-debian-bullseye-iot-v5.10-ti-armhf
./RootStock-NG.sh -c bb.org-debian-bullseye-xfce-v5.10-ti-armhf
else
	mkdir -p ${DIR}/deploy/ || true
fi

         debian_buster_tiny="debian-10.13-tiny-armhf-${time}"
      debian_buster_console="debian-10.13-console-armhf-${time}"
   debian_buster_console_xm="debian-10.13-console-xm-armhf-${time}"
          debian_buster_iot="debian-10.13-iot-armhf-${time}"
     debian_buster_iot_tidl="debian-10.13-iot-tidl-armhf-${time}"
debian_buster_iot_grove_kit="debian-10.13-iot-grove-kit-armhf-${time}"
 debian_buster_iot_mikrobus="debian-10.13-iot-mikrobus-armhf-${time}"
      debian_buster_efi_iot="debian-10.13-efi-iot-armhf-${time}"
         debian_buster_lxqt="debian-10.13-lxqt-armhf-${time}"
    debian_buster_lxqt_tidl="debian-10.13-lxqt-tidl-armhf-${time}"
      debian_buster_lxqt_xm="debian-10.13-lxqt-xm-armhf-${time}"

      ubuntu_bionic_ros_iot="ubuntu-18.04.6-ros-iot-armhf-${time}"


debian_bullseye_minimal="debian-11.9-minimal-armhf-${time}"
    debian_bullseye_iot="debian-11.9-iot-armhf-${time}"
   debian_bullseye_xfce="debian-11.9-xfce-armhf-${time}"

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

###DEBIAN BUSTER: console
rootfs="${debian_buster_console}" ; blend="buster-console" ; extract_base_rootfs

options="--img-1gb am57xx-\${rootfs}               ${am57xx_v419ti}"                 ; generate_img
options="--img-1gb am57xx-eMMC-flasher-\${rootfs}  ${am57xx_v419ti} --emmc-flasher"  ; generate_img
options="--img-1gb bone-\${rootfs}                 ${am335x_v419ti}"                 ; generate_img
options="--img-1gb bone-eMMC-flasher-\${rootfs}    ${am335x_v419ti} --emmc-flasher"  ; generate_img

options="--img-1gb BBB-blank-\${rootfs}            ${am335x_v419ti} --bbb-flasher"   ; generate_img
options="--img-1gb BBBL-blank-\${rootfs}           ${am335x_v419ti} --bbbl-flasher"  ; generate_img
options="--img-1gb BBBW-blank-\${rootfs}           ${am335x_v419ti} --bbbw-flasher"  ; generate_img
#options="--img-1gb BBGG-blank-\${rootfs}           ${am335x_v419ti} --bbgg-flasher"  ; generate_img

###DEBIAN BUSTER: console-xm
rootfs="${debian_buster_console_xm}" ; blend="buster-console-xm" ; extract_base_rootfs

options="--img-1gb bbxm-\${rootfs}  ${beagle_xm}"  ; generate_img

###DEBIAN BUSTER: iot
rootfs="${debian_buster_iot}" ; blend="buster-iot" ; extract_base_rootfs

options="--img-4gb am57xx-\${rootfs}               ${am57xx_v419ti}"                 ; generate_img
options="--img-4gb am57xx-eMMC-flasher-\${rootfs}  ${am57xx_v419ti} --emmc-flasher"  ; generate_img
options="--img-4gb bone-\${rootfs}                 ${am335x_v419ti}"                 ; generate_img
options="--img-4gb bone-eMMC-flasher-\${rootfs}    ${am335x_v419ti} --emmc-flasher"  ; generate_img

###DEBIAN BUSTER: iot-tidl
rootfs="${debian_buster_iot_tidl}" ; blend="buster-iot-tidl" ; extract_base_rootfs

options="--img-6gb am57xx-\${rootfs}               ${am57xx_v414ti}"                 ; generate_img
options="--img-6gb am57xx-eMMC-flasher-\${rootfs}  ${am57xx_v414ti} --emmc-flasher"  ; generate_img

###DEBIAN BUSTER: iot-grove-kit
rootfs="${debian_buster_iot_grove_kit}" ; blend="buster-iot-grove-kit" ; extract_base_rootfs

options="--img-4gb bone-\${rootfs}  ${am335x_v54ti}"  ; generate_img

###DEBIAN BUSTER: iot-mikrobus
rootfs="${debian_buster_iot_mikrobus}" ; blend="buster-iot-mikrobus" ; extract_base_rootfs

options="--img-4gb bone-\${rootfs}  ${am335x_mainline}"  ; generate_img

###DEBIAN BUSTER: efi-iot
rootfs="${debian_buster_efi_iot}" ; blend="buster-efi-iot" ; extract_base_rootfs

options="--img-4gb am57xx-\${rootfs}  ${am57xx_v54ti} --efi"  ; generate_img
options="--img-4gb bone-\${rootfs}    ${am335x_v54ti} --efi"  ; generate_img

###DEBIAN BUSTER: lxqt
rootfs="${debian_buster_lxqt}" ; blend="buster-lxqt" ; extract_base_rootfs

options="--img-4gb am57xx-\${rootfs}             ${am57xx_v419ti}"                 ; generate_img
options="--img-4gb bone-\${rootfs}               ${am335x_v419ti}"                 ; generate_img
options="--img-4gb bone-eMMC-flasher-\${rootfs}  ${am335x_v419ti} --emmc-flasher"  ; generate_img

###DEBIAN BUSTER: lxqt-tidl
rootfs="${debian_buster_lxqt_tidl}" ; blend="buster-lxqt-tidl" ; extract_base_rootfs

options="--img-6gb am57xx-\${rootfs}               ${am57xx_v414ti}"                                   ; generate_img
options="--img-6gb am57xx-eMMC-flasher-\${rootfs}  ${am57xx_v414ti} --emmc-flasher"                    ; generate_img

###DEBIAN BUSTER: lxqt-xm
rootfs="${debian_buster_lxqt_xm}" ; blend="buster-lxqt-xm" ; extract_base_rootfs

options="--img-4gb bbxm-\${rootfs}  ${beagle_xm}"  ; generate_img

###UBUNTU BIONIC: ros-iot
rootfs="${ubuntu_bionic_ros_iot}" ; blend="bionic-ros-iot" ; extract_base_rootfs

options="--img-6gb am57xx-\${rootfs}  ${am57xx_v54ti}"  ; generate_img
options="--img-6gb bone-\${rootfs}    ${am335x_v54ti}"  ; generate_img

###debian bullseye minimal
rootfs="${debian_bullseye_minimal}" ; blend="bullseye-minimal" ; extract_base_rootfs

options="--img-2gb am335x-\${rootfs}  ${am335x_v510ti}"  ; generate_img
options="--img-2gb am57xx-\${rootfs}  ${am57xx_v510ti}"  ; generate_img

###debian bullseye iot
rootfs="${debian_bullseye_iot}" ; blend="bullseye-iot" ; extract_base_rootfs

options="--img-4gb am335x-\${rootfs}  ${am335x_v510ti}"  ; generate_img
options="--img-4gb am57xx-\${rootfs}  ${am57xx_v510ti}"  ; generate_img

###debian bullseye xfce
rootfs="${debian_bullseye_xfce}" ; blend="bullseye-xfce" ; extract_base_rootfs

options="--img-4gb am335x-\${rootfs}  ${am335x_v510ti}"  ; generate_img
options="--img-4gb am57xx-\${rootfs}  ${am57xx_v510ti}"  ; generate_img

###archive *.tar
rootfs="${debian_buster_tiny}"           ; blend="buster-tiny"       ; archive_base_rootfs
rootfs="${debian_buster_console}"        ; blend="buster-console"    ; archive_base_rootfs
rootfs="${debian_buster_console_xm}"     ; blend="buster-console-xm" ; archive_base_rootfs
rootfs="${debian_buster_iot}"            ; blend="buster-iot"        ; archive_base_rootfs
rootfs="${debian_buster_iot_tidl}"       ; blend="buster-iot-tidl"   ; archive_base_rootfs
rootfs="${debian_buster_iot_grove_kit}"  ; blend="buster-iot-grove-kit"   ; archive_base_rootfs
rootfs="${debian_buster_iot_mikrobus}"   ; blend="buster-iot-mikrobus"    ; archive_base_rootfs
rootfs="${debian_buster_efi_iot}"        ; blend="buster-efi-iot"    ; archive_base_rootfs
rootfs="${debian_buster_lxqt}"           ; blend="buster-lxqt"       ; archive_base_rootfs
rootfs="${debian_buster_lxqt_tidl}"      ; blend="buster-lxqt-tidl"  ; archive_base_rootfs
rootfs="${debian_buster_lxqt_xm}"        ; blend="buster-lxqt-xm"    ; archive_base_rootfs

rootfs="${ubuntu_bionic_ros_iot}"        ; blend="bionic-ros-iot"  ; archive_base_rootfs

rootfs="${debian_bullseye_minimal}"  ; blend="bullseye-minimal"  ; archive_base_rootfs
rootfs="${debian_bullseye_iot}"      ; blend="bullseye-iot"      ; archive_base_rootfs
rootfs="${debian_bullseye_xfce}"     ; blend="bullseye-xfce"     ; archive_base_rootfs

###archive *.img
###DEBIAN BUSTER: console
rootfs="${debian_buster_console}" ; blend="buster-console"

wfile="am57xx-\${rootfs}-1gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${rootfs}-1gb"  ; archive_img
wfile="bone-\${rootfs}-1gb"                 ; archive_img
wfile="bone-eMMC-flasher-\${rootfs}-1gb"    ; archive_img

wfile="BBB-blank-\${rootfs}-1gb"            ; archive_img
wfile="BBBL-blank-\${rootfs}-1gb"           ; archive_img
wfile="BBBW-blank-\${rootfs}-1gb"           ; archive_img
#wfile="BBGG-blank-\${rootfs}-1gb"           ; archive_img

###DEBIAN BUSTER: console-xm
rootfs="${debian_buster_console_xm}" ; blend="buster-console-xm"

wfile="bbxm-\${rootfs}-1gb"               ; archive_img

###DEBIAN BUSTER: iot
rootfs="${debian_buster_iot}" ; blend="buster-iot"

wfile="am57xx-\${rootfs}-4gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${rootfs}-4gb"  ; archive_img
wfile="bone-\${rootfs}-4gb"                 ; archive_img
wfile="bone-eMMC-flasher-\${rootfs}-4gb"    ; archive_img

###DEBIAN BUSTER: iot-tidl
rootfs="${debian_buster_iot_tidl}" ; blend="buster-iot-tidl"

wfile="am57xx-\${rootfs}-6gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${rootfs}-6gb"  ; archive_img

###DEBIAN BUSTER: iot-grove-kit
rootfs="${debian_buster_iot_grove_kit}" ; blend="buster-iot-grove-kit"

wfile="bone-\${rootfs}-4gb"                 ; archive_img

###DEBIAN BUSTER: iot-mikrobus
rootfs="${debian_buster_iot_mikrobus}" ; blend="buster-iot-mikrobus"

wfile="bone-\${rootfs}-4gb"                 ; archive_img

###DEBIAN BUSTER: efi-iot
rootfs="${debian_buster_efi_iot}" ; blend="buster-efi-iot"

wfile="am57xx-\${rootfs}-4gb"  ; archive_img
wfile="bone-\${rootfs}-4gb"    ; archive_img

###DEBIAN BUSTER: lxqt
rootfs="${debian_buster_lxqt}" ; blend="buster-lxqt"

wfile="am57xx-\${rootfs}-4gb"  ; archive_img
wfile="bone-\${rootfs}-4gb"    ; archive_img
wfile="bone-eMMC-flasher-\${rootfs}-4gb"    ; archive_img

###DEBIAN BUSTER: lxqt-tidl
rootfs="${debian_buster_lxqt_tidl}" ; blend="buster-lxqt-tidl"

wfile="am57xx-\${rootfs}-6gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${rootfs}-6gb"  ; archive_img

###DEBIAN BUSTER: lxqt-xm
rootfs="${debian_buster_lxqt_xm}" ; blend="buster-lxqt-xm"

wfile="bbxm-\${rootfs}-4gb"  ; archive_img

###UBUNTU BIONIC: ros-iot
rootfs="${ubuntu_bionic_ros_iot}" ; blend="bionic-ros-iot"

wfile="am57xx-\${rootfs}-6gb"  ; archive_img
wfile="bone-\${rootfs}-6gb"    ; archive_img

###debian bullseye minimal
rootfs="${debian_bullseye_minimal}" ; blend="bullseye-minimal"

wfile="am335x-\${rootfs}-2gb"  ; archive_img
wfile="am57xx-\${rootfs}-2gb"  ; archive_img

###debian bullseye iot
rootfs="${debian_bullseye_iot}" ; blend="bullseye-iot"

wfile="am335x-\${rootfs}-4gb"  ; archive_img
wfile="am57xx-\${rootfs}-4gb"  ; archive_img

###debian bullseye xfce
rootfs="${debian_bullseye_xfce}" ; blend="bullseye-xfce"

wfile="am335x-\${rootfs}-4gb"  ; archive_img
wfile="am57xx-\${rootfs}-4gb"  ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

#x86: My Server...
if [ -f /opt/images/nas.FREENAS ] ; then
	sudo mkdir -p /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/ || true

	echo "Copying: *.tar to server: images/${IMAGE_DIR_PREFIX}-${time}/"
	sudo cp -v ${DIR}/deploy/gift_wrap_final_images.sh /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/gift_wrap_final_images.sh || true

	ls -lha /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/
fi
