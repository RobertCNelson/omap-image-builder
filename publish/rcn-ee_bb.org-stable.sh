#!/bin/bash -e

OIB_USER=${OIB_USER:-1000}

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.us/rootfs/bb.org/testing"
DIR="$PWD"

git pull --no-edit https://github.com/beagleboard/image-builder master

export apt_proxy=proxy.gfnd.rcn-ee.org:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

if [ ! -f jenkins.build ] ; then
./RootStock-NG.sh -c machinekit-debian-stretch
./RootStock-NG.sh -c bb.org-debian-stretch-console-v4.14
./RootStock-NG.sh -c bb.org-debian-stretch-iot-v4.14
./RootStock-NG.sh -c bb.org-debian-stretch-iot-tidl-v4.14
./RootStock-NG.sh -c bb.org-debian-stretch-iot-grove-kit-v4.14.conf
./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-v4.14
./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-tidl-v4.14
./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-xm

./RootStock-NG.sh -c bb.org-debian-buster-console-v4.19
./RootStock-NG.sh -c bb.org-debian-buster-iot-v4.19
./RootStock-NG.sh -c bb.org-debian-buster-lxqt-v4.19
./RootStock-NG.sh -c bb.org-debian-buster-iot-webthings-gateway-v4.19

./RootStock-NG.sh -c bb.org-ubuntu-bionic-ros-iot-v4.19

else
	mkdir -p ${DIR}/deploy/ || true
fi

          debian_stretch_machinekit="debian-9.12-machinekit-armhf-${time}"
             debian_stretch_console="debian-9.12-console-armhf-${time}"
                 debian_stretch_iot="debian-9.12-iot-armhf-${time}"
            debian_stretch_iot_tidl="debian-9.12-iot-tidl-armhf-${time}"
       debian_stretch_iot_grove_kit="debian-9.12-iot-grove-kit-armhf-${time}"
                debian_stretch_lxqt="debian-9.12-lxqt-armhf-${time}"
           debian_stretch_lxqt_tidl="debian-9.12-lxqt-tidl-armhf-${time}"
             debian_stretch_lxqt_xm="debian-9.12-lxqt-xm-armhf-${time}"
             debian_stretch_wayland="debian-9.12-wayland-armhf-${time}"

                 debian_buster_tiny="debian-10.3-tiny-armhf-${time}"
              debian_buster_console="debian-10.3-console-armhf-${time}"
           debian_buster_console_xm="debian-10.3-console-xm-armhf-${time}"
                  debian_buster_iot="debian-10.3-iot-armhf-${time}"
        debian_buster_iot_grove_kit="debian-10.3-iot-grove-kit-armhf-${time}"
              debian_buster_efi_iot="debian-10.3-efi-iot-armhf-${time}"
                 debian_buster_lxqt="debian-10.3-lxqt-armhf-${time}"
debian_buster_iot_webthings_gateway="debian-10.3-iot-webthings-gateway-armhf-${time}"

              ubuntu_bionic_ros_iot="ubuntu-18.04.3-ros-iot-armhf-${time}"

xz_img="xz -T3 -z -8"
xz_tar="xz -T4 -z -8"

beaglebone="--dtb beaglebone --rootfs_label rootfs --hostname beaglebone --enable-cape-universal"
pru_rproc_v414ti="--enable-uboot-pru-rproc-414ti"
pru_rproc_v419ti="--enable-uboot-pru-rproc-419ti"

beagle_xm="--dtb omap3-beagle-xm --rootfs_label rootfs --hostname beagleboard"

beagle_x15="--dtb am57xx-beagle-x15 --rootfs_label rootfs --hostname beaglebone"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

wait_till_Xgb_free () {
        memory=16384
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
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${base_rootfs}.tar.xz ] ; then
                                cp -v \${base_rootfs}.tar ${mirror_dir}/${time}/\${blend}/
                                cd ${mirror_dir}/${time}/\${blend}/
                                ${xz_tar} \${base_rootfs}.tar && sha256sum \${base_rootfs}.tar.xz > \${base_rootfs}.tar.xz.sha256sum &
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
        wait_till_Xgb_free
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
                                cd ${mirror_dir}/${time}/\${blend}/
                                ${xz_img} \${wfile}.img && sha256sum \${wfile}.img.xz > \${wfile}.img.xz.sha256sum &
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
                echo "./setup_sdcard.sh \${options}"
                sudo ./setup_sdcard.sh \${options}
                sudo chown 1000:1000 *.img || true
                mv *.img ../ || true
                cd ..
        fi
}

###DEBIAN STRETCH: machinekit
base_rootfs="${debian_stretch_machinekit}" ; blend="stretch-machinekit" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs} ${beaglebone}" ; generate_img

###DEBIAN STRETCH: console
base_rootfs="${debian_stretch_console}" ; blend="stretch-console" ; extract_base_rootfs

options="--img-1gb am57xx-\${base_rootfs}               ${beagle_x15}"                                    ; generate_img
options="--img-1gb am57xx-eMMC-flasher-\${base_rootfs}  ${beagle_x15} --emmc-flasher"                     ; generate_img
options="--img-1gb bone-\${base_rootfs}                 ${beaglebone} ${pru_rproc_v414ti}"                ; generate_img
options="--img-1gb bone-eMMC-flasher-\${base_rootfs}    ${beaglebone} ${pru_rproc_v414ti} --emmc-flasher" ; generate_img

options="--img-1gb BBB-blank-\${base_rootfs}            ${beaglebone} ${pru_rproc_v414ti} --bbb-flasher"  ; generate_img
options="--img-1gb BBBL-blank-\${base_rootfs}           ${beaglebone} ${pru_rproc_v414ti} --bbbl-flasher" ; generate_img
options="--img-1gb BBBW-blank-\${base_rootfs}           ${beaglebone} ${pru_rproc_v414ti} --bbbw-flasher" ; generate_img
options="--img-1gb BBGG-blank-\${base_rootfs}           ${beaglebone} ${pru_rproc_v414ti} --bbgg-flasher" ; generate_img

###DEBIAN STRETCH: iot
base_rootfs="${debian_stretch_iot}" ; blend="stretch-iot" ; extract_base_rootfs

options="--img-4gb am57xx-\${base_rootfs}               ${beagle_x15}"                                    ; generate_img
options="--img-4gb bone-\${base_rootfs}                 ${beaglebone} ${pru_rproc_v414ti}"                ; generate_img
options="--img-4gb bone-eMMC-flasher-\${base_rootfs}    ${beaglebone} ${pru_rproc_v414ti} --emmc-flasher" ; generate_img

###DEBIAN STRETCH: iot-tidl
base_rootfs="${debian_stretch_iot_tidl}" ; blend="stretch-iot-tidl" ; extract_base_rootfs

options="--img-4gb am57xx-\${base_rootfs}               ${beagle_x15}"                                    ; generate_img
options="--img-4gb am57xx-eMMC-flasher-\${base_rootfs}  ${beagle_x15} --emmc-flasher"                     ; generate_img

###DEBIAN STRETCH: iot-grove-kit
base_rootfs="${debian_stretch_iot_grove_kit}" ; blend="stretch-iot-grove-kit" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}                 ${beaglebone} ${pru_rproc_v414ti}"                ; generate_img

###DEBIAN STRETCH: lxqt
base_rootfs="${debian_stretch_lxqt}" ; blend="stretch-lxqt" ; extract_base_rootfs

options="--img-4gb am57xx-\${base_rootfs}               ${beagle_x15}"                                    ; generate_img
options="--img-4gb bone-\${base_rootfs}                 ${beaglebone} ${pru_rproc_v414ti}"                ; generate_img
options="--img-4gb bone-eMMC-flasher-\${base_rootfs}    ${beaglebone} ${pru_rproc_v414ti} --emmc-flasher" ; generate_img

###DEBIAN STRETCH: lxqt-tidl
base_rootfs="${debian_stretch_lxqt_tidl}" ; blend="stretch-lxqt-tidl" ; extract_base_rootfs

options="--img-6gb am57xx-\${base_rootfs}               ${beagle_x15}"                                    ; generate_img
options="--img-6gb am57xx-eMMC-flasher-\${base_rootfs}  ${beagle_x15} --emmc-flasher"                     ; generate_img
options="--img-6gb am57xx-blank-\${base_rootfs} ${beagle_x15} --emmc-flasher --am57xx-x15-revc-flasher" ; generate_img

###DEBIAN STRETCH: lxqt-xm
base_rootfs="${debian_stretch_lxqt_xm}" ; blend="stretch-lxqt-xm" ; extract_base_rootfs

options="--img-4gb bbxm-\${base_rootfs}  ${beagle_xm}" ; generate_img

###DEBIAN STRETCH: wayland
base_rootfs="${debian_stretch_wayland}" ; blend="stretch-wayland" ; extract_base_rootfs

options="--img-4gb am57xx-\${base_rootfs}  ${beagle_x15}" ; generate_img
options="--img-4gb bone-\${base_rootfs}    ${beaglebone}" ; generate_img

###DEBIAN BUSTER: console
base_rootfs="${debian_buster_console}" ; blend="buster-console" ; extract_base_rootfs

options="--img-1gb am57xx-\${base_rootfs}               ${beagle_x15}"                                    ; generate_img
options="--img-1gb am57xx-eMMC-flasher-\${base_rootfs}  ${beagle_x15} --emmc-flasher"                     ; generate_img
options="--img-1gb bone-\${base_rootfs}                 ${beaglebone} ${pru_rproc_v419ti}"                ; generate_img
options="--img-1gb bone-eMMC-flasher-\${base_rootfs}    ${beaglebone} ${pru_rproc_v419ti} --emmc-flasher" ; generate_img

options="--img-1gb BBB-blank-\${base_rootfs}            ${beaglebone} ${pru_rproc_v419ti} --bbb-flasher"  ; generate_img
options="--img-1gb BBBL-blank-\${base_rootfs}           ${beaglebone} ${pru_rproc_v419ti} --bbbl-flasher" ; generate_img
options="--img-1gb BBBW-blank-\${base_rootfs}           ${beaglebone} ${pru_rproc_v419ti} --bbbw-flasher" ; generate_img
#options="--img-1gb BBGG-blank-\${base_rootfs}           ${beaglebone} ${pru_rproc_v419ti} --bbgg-flasher" ; generate_img

###DEBIAN BUSTER: console-xm
base_rootfs="${debian_buster_console_xm}" ; blend="buster-console-xm" ; extract_base_rootfs

options="--img-1gb bbxm-\${base_rootfs}  ${beagle_xm}" ; generate_img

###DEBIAN BUSTER: iot
base_rootfs="${debian_buster_iot}" ; blend="buster-iot" ; extract_base_rootfs

options="--img-4gb am57xx-\${base_rootfs}               ${beagle_x15}"                                    ; generate_img
options="--img-4gb am57xx-eMMC-flasher-\${base_rootfs}  ${beagle_x15} --emmc-flasher"                     ; generate_img
options="--img-4gb bone-\${base_rootfs}                 ${beaglebone} ${pru_rproc_v419ti}"                ; generate_img
options="--img-4gb bone-eMMC-flasher-\${base_rootfs}    ${beaglebone} ${pru_rproc_v419ti} --emmc-flasher" ; generate_img

###DEBIAN BUSTER: iot-grove-kit
base_rootfs="${debian_buster_iot_grove_kit}" ; blend="buster-iot-grove-kit" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}                 ${beaglebone} ${pru_rproc_v419ti}"                ; generate_img

###DEBIAN BUSTER: iot-webthings-gateway
base_rootfs="${debian_buster_iot_webthings_gateway}" ; blend="buster-iot-webthings-gateway" ; extract_base_rootfs

#options="--img-4gb am57xx-\${base_rootfs}               ${beagle_x15}"                                    ; generate_img
options="--img-4gb bone-\${base_rootfs}                 ${beaglebone} ${pru_rproc_v419ti}"                ; generate_img

###DEBIAN BUSTER: efi-iot
base_rootfs="${debian_buster_efi_iot}" ; blend="buster-efi-iot" ; extract_base_rootfs

options="--img-4gb am57xx-\${base_rootfs}  ${beagle_x15} --efi"                     ; generate_img
options="--img-4gb bone-\${base_rootfs}    ${beaglebone} ${pru_rproc_v419ti} --efi" ; generate_img

###DEBIAN BUSTER: lxqt
base_rootfs="${debian_buster_lxqt}" ; blend="buster-lxqt" ; extract_base_rootfs

options="--img-4gb am57xx-\${base_rootfs}  ${beagle_x15}"                     ; generate_img
options="--img-4gb bone-\${base_rootfs}    ${beaglebone} ${pru_rproc_v419ti}" ; generate_img

###UBUNTU BIONIC: ros-iot
base_rootfs="${ubuntu_bionic_ros_iot}" ; blend="bionic-ros-iot" ; extract_base_rootfs

options="--img-6gb am57xx-\${base_rootfs}  ${beagle_x15}"                      ; generate_img
options="--img-6gb bone-\${base_rootfs}    ${beaglebone} ${pru_rproc_v419ti}"  ; generate_img

###archive *.tar
base_rootfs="${debian_stretch_machinekit}"    ; blend="stretch-machinekit" ; archive_base_rootfs
base_rootfs="${debian_stretch_console}"       ; blend="stretch-console"    ; archive_base_rootfs
base_rootfs="${debian_stretch_iot}"           ; blend="stretch-iot"        ; archive_base_rootfs
base_rootfs="${debian_stretch_iot_tidl}"      ; blend="stretch-iot-tidl"   ; archive_base_rootfs
base_rootfs="${debian_stretch_iot_grove_kit}" ; blend="stretch-iot-grove-kit"   ; archive_base_rootfs
base_rootfs="${debian_stretch_lxqt}"          ; blend="stretch-lxqt"       ; archive_base_rootfs
base_rootfs="${debian_stretch_lxqt_tidl}"     ; blend="stretch-lxqt-tidl"  ; archive_base_rootfs
base_rootfs="${debian_stretch_lxqt_xm}"       ; blend="stretch-lxqt-xm"    ; archive_base_rootfs
base_rootfs="${debian_stretch_wayland}"       ; blend="stretch-wayland"    ; archive_base_rootfs

base_rootfs="${debian_buster_tiny}"           ; blend="buster-tiny"       ; archive_base_rootfs
base_rootfs="${debian_buster_console}"        ; blend="buster-console"    ; archive_base_rootfs
base_rootfs="${debian_buster_console_xm}"     ; blend="buster-console-xm" ; archive_base_rootfs
base_rootfs="${debian_buster_iot}"            ; blend="buster-iot"        ; archive_base_rootfs
base_rootfs="${debian_buster_iot_grove_kit}"  ; blend="buster-iot-grove-kit"   ; archive_base_rootfs
base_rootfs="${debian_buster_efi_iot}"        ; blend="buster-efi-iot"    ; archive_base_rootfs
base_rootfs="${debian_buster_lxqt}"           ; blend="buster-lxqt"       ; archive_base_rootfs
base_rootfs="${debian_buster_iot_webthings_gateway}"            ; blend="buster-iot-webthings-gateway"        ; archive_base_rootfs

base_rootfs="${ubuntu_bionic_ros_iot}"        ; blend="bionic-ros-iot"  ; archive_base_rootfs

###archive *.img
###DEBIAN STRETCH: machinekit
base_rootfs="${debian_stretch_machinekit}" ; blend="stretch-machinekit"

wfile="bone-\${base_rootfs}-4gb"  ; archive_img

###DEBIAN STRETCH: console
base_rootfs="${debian_stretch_console}" ; blend="stretch-console"

wfile="am57xx-\${base_rootfs}-1gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${base_rootfs}-1gb"  ; archive_img
wfile="bone-\${base_rootfs}-1gb"                 ; archive_img
wfile="bone-eMMC-flasher-\${base_rootfs}-1gb"    ; archive_img

wfile="BBB-blank-\${base_rootfs}-1gb"            ; archive_img
wfile="BBBL-blank-\${base_rootfs}-1gb"           ; archive_img
wfile="BBBW-blank-\${base_rootfs}-1gb"           ; archive_img
wfile="BBGG-blank-\${base_rootfs}-1gb"           ; archive_img

###DEBIAN STRETCH: iot
base_rootfs="${debian_stretch_iot}" ; blend="stretch-iot"

wfile="am57xx-\${base_rootfs}-4gb"               ; archive_img
wfile="bone-\${base_rootfs}-4gb"                 ; archive_img
wfile="bone-eMMC-flasher-\${base_rootfs}-4gb"    ; archive_img

###DEBIAN STRETCH: iot-tidl
base_rootfs="${debian_stretch_iot_tidl}" ; blend="stretch-iot-tidl"

wfile="am57xx-\${base_rootfs}-4gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${base_rootfs}-4gb"  ; archive_img

###DEBIAN STRETCH: iot-grove-kit
base_rootfs="${debian_stretch_iot_grove_kit}" ; blend="stretch-iot-grove-kit"

wfile="bone-\${base_rootfs}-4gb"                 ; archive_img

###DEBIAN STRETCH: lxqt
base_rootfs="${debian_stretch_lxqt}" ; blend="stretch-lxqt"

wfile="am57xx-\${base_rootfs}-4gb"               ; archive_img
wfile="bone-\${base_rootfs}-4gb"                 ; archive_img
wfile="bone-eMMC-flasher-\${base_rootfs}-4gb"    ; archive_img

###DEBIAN STRETCH: lxqt-tidl
base_rootfs="${debian_stretch_lxqt_tidl}" ; blend="stretch-lxqt-tidl"

wfile="am57xx-\${base_rootfs}-6gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${base_rootfs}-6gb"  ; archive_img

wfile="am57xx-blank-\${base_rootfs}-6gb"       ; archive_img

###DEBIAN STRETCH: lxqt-xm
base_rootfs="${debian_stretch_lxqt_xm}" ; blend="stretch-lxqt-xm"

wfile="bbxm-\${base_rootfs}-4gb"  ; archive_img

###DEBIAN STRETCH: wayland
base_rootfs="${debian_stretch_wayland}" ; blend="stretch-wayland"

wfile="am57xx-\${base_rootfs}-4gb"  ; archive_img
wfile="bone-\${base_rootfs}-4gb"    ; archive_img

###DEBIAN BUSTER: console
base_rootfs="${debian_buster_console}" ; blend="buster-console"

wfile="am57xx-\${base_rootfs}-1gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${base_rootfs}-1gb"  ; archive_img
wfile="bone-\${base_rootfs}-1gb"                 ; archive_img
wfile="bone-eMMC-flasher-\${base_rootfs}-1gb"    ; archive_img

wfile="BBB-blank-\${base_rootfs}-1gb"            ; archive_img
wfile="BBBL-blank-\${base_rootfs}-1gb"           ; archive_img
wfile="BBBW-blank-\${base_rootfs}-1gb"           ; archive_img
#wfile="BBGG-blank-\${base_rootfs}-1gb"           ; archive_img

###DEBIAN BUSTER: console-xm
base_rootfs="${debian_buster_console_xm}" ; blend="buster-console-xm"

wfile="bbxm-\${base_rootfs}-1gb"               ; archive_img

###DEBIAN BUSTER: iot
base_rootfs="${debian_buster_iot}" ; blend="buster-iot"

wfile="am57xx-\${base_rootfs}-4gb"               ; archive_img
wfile="am57xx-eMMC-flasher-\${base_rootfs}-4gb"  ; archive_img
wfile="bone-\${base_rootfs}-4gb"                 ; archive_img
wfile="bone-eMMC-flasher-\${base_rootfs}-4gb"    ; archive_img

###DEBIAN BUSTER: iot-grove-kit
base_rootfs="${debian_buster_iot_grove_kit}" ; blend="buster-iot-grove-kit"

wfile="bone-\${base_rootfs}-4gb"                 ; archive_img

###DEBIAN BUSTER: iot-webthings-gateway
base_rootfs="${debian_buster_iot_webthings_gateway}" ; blend="buster-iot-webthings-gateway"

wfile="am57xx-\${base_rootfs}-4gb"               ; archive_img
wfile="bone-\${base_rootfs}-4gb"                 ; archive_img

###DEBIAN BUSTER: efi-iot
base_rootfs="${debian_buster_efi_iot}" ; blend="buster-efi-iot"

wfile="am57xx-\${base_rootfs}-4gb"  ; archive_img
wfile="bone-\${base_rootfs}-4gb"    ; archive_img

###DEBIAN BUSTER: lxqt
base_rootfs="${debian_buster_lxqt}" ; blend="buster-lxqt"

wfile="am57xx-\${base_rootfs}-4gb"  ; archive_img
wfile="bone-\${base_rootfs}-4gb"    ; archive_img

###UBUNTU BIONIC: ros-iot
base_rootfs="${ubuntu_bionic_ros_iot}" ; blend="bionic-ros-iot"

wfile="am57xx-\${base_rootfs}-6gb"  ; archive_img
wfile="bone-\${base_rootfs}-6gb"    ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

image_prefix="bb.org"
#node:
if [ ! -d /var/www/html/farm/images/ ] ; then
	if [ ! -d /mnt/farm/images/ ] ; then
		#nfs mount...
		sudo mount -a
	fi

	if [ -d /mnt/farm/images/ ] ; then
		if [ ! -d /mnt/farm/images/${image_prefix}-${time}/ ] ; then
			echo "mkdir: /mnt/farm/images/${image_prefix}-${time}/"
			mkdir -p /mnt/farm/images/${image_prefix}-${time}/ || true
		fi

		echo "Copying: *.tar to server: images/${image_prefix}-${time}/"
		cp -v ${DIR}/deploy/*.tar /mnt/farm/images/${image_prefix}-${time}/ || true
		cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
		sudo chmod +x /mnt/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
		sudo chown -R ${OIB_USER}:${OIB_USER} /var/www/html/farm/images/${image_prefix}-${time}/ || true
	fi
fi

#x86:
if [ -d /var/www/html/farm/images/ ] ; then
	mkdir -p /var/www/html/farm/images/${image_prefix}-${time}/ || true

	echo "Copying: *.tar to server: images/${image_prefix}-${time}/"
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /var/www/html/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true

	sudo chown -R ${OIB_USER}:${OIB_USER} /var/www/html/farm/images/${image_prefix}-${time}/ || true
	sudo chmod +x /var/www/html/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
	sudo chmod g+wr /var/www/html/farm/images/${image_prefix}-${time}/ || true
	ls -lha /var/www/html/farm/images/${image_prefix}-${time}/
fi
