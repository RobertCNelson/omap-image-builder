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

./RootStock-NG.sh -c bb.org-debian-bullseye-minimal-v5.10-ti-armhf
./RootStock-NG.sh -c bb.org-debian-bullseye-iot-v5.10-ti-armhf
./RootStock-NG.sh -c bb.org-debian-bullseye-xfce-v5.10-ti-armhf
else
	mkdir -p ${DIR}/deploy/ || true
fi

debian_bullseye_minimal="debian-11.9-minimal-armhf-${time}"
    debian_bullseye_iot="debian-11.9-iot-armhf-${time}"
   debian_bullseye_xfce="debian-11.9-xfce-armhf-${time}"

xz_img="xz -T4 -z -8"
xz_tar="xz -T4 -z -8"

beagle_xm="--dtb omap3-beagle-xm"

  am335x_v414ti="--dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-pru-rproc-414ti"
  am335x_v419ti="--dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-pru-rproc-419ti"
   am335x_v54ti="--dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-pru-rproc-54ti"
  am335x_v510ti="--dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-disable-pru --enable-bypass-bootup-scripts"
am335x_mainline="--dtb beaglebone --distro-bootloader --enable-cape-universal"

am57xx_v414ti="--dtb am57xx-beagle-x15 --distro-bootloader"
am57xx_v419ti="--dtb am57xx-beagle-x15 --distro-bootloader --enable-uboot-cape-overlays"
 am57xx_v54ti="--dtb am57xx-beagle-x15 --distro-bootloader"
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
rootfs="${debian_bullseye_minimal}"  ; blend="bullseye-minimal"  ; archive_base_rootfs
rootfs="${debian_bullseye_iot}"      ; blend="bullseye-iot"      ; archive_base_rootfs
rootfs="${debian_bullseye_xfce}"     ; blend="bullseye-xfce"     ; archive_base_rootfs

###archive *.img
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
