#!/bin/bash -e

IMAGE_DIR_PREFIX=${IMAGE_DIR_PREFIX:-elinux}

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.us/rootfs/"
DIR="$PWD"

export apt_proxy=192.168.1.10:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

if [ ! -f jenkins.build ] ; then
./RootStock-NG.sh -c rcn-ee.net-console-debian-buster-armhf
./RootStock-NG.sh -c rcn-ee.net-console-ubuntu-focal-armhf
else
	mkdir -p ${DIR}/deploy/ || true
fi

debian_stable="debian-10.13-console-armhf-${time}"
ubuntu_stable="ubuntu-20.04.4-console-armhf-${time}"

xz_img="xz -T2 -z -8"
xz_tar="xz -T2 -z -8"

beaglebone="--dtb beaglebone --distro-bootloader --rootfs_label rootfs --hostname beaglebone --enable-cape-universal"
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

#Debian Stable
base_rootfs="${debian_stable}" ; blend="elinux" ; extract_base_rootfs

options="--img am57xx-\${base_rootfs}              ${beagle_x15}"                 ; generate_img
options="--img am57xx-eMMC-flasher-\${base_rootfs} ${beagle_x15} --emmc-flasher"  ; generate_img
options="--img bone-\${base_rootfs}                ${beaglebone}"                 ; generate_img
options="--img bone-eMMC-flasher-\${base_rootfs}   ${beaglebone} --emmc-flasher"  ; generate_img
options="--img bbxm-\${base_rootfs}                ${beagle_xm}"                  ; generate_img

#Ubuntu Stable
base_rootfs="${ubuntu_stable}" ; blend="elinux" ; extract_base_rootfs

options="--img am57xx-\${base_rootfs}              ${beagle_x15}"                 ; generate_img
options="--img am57xx-eMMC-flasher-\${base_rootfs} ${beagle_x15} --emmc-flasher"  ; generate_img
options="--img bone-\${base_rootfs}                ${beaglebone}"                 ; generate_img
options="--img bone-eMMC-flasher-\${base_rootfs}   ${beaglebone} --emmc-flasher"  ; generate_img
options="--img bbxm-\${base_rootfs}                ${beagle_xm}"                  ; generate_img

#Archive tar:
base_rootfs="${debian_stable}" ; blend="elinux" ; archive_base_rootfs
base_rootfs="${ubuntu_stable}" ; blend="elinux" ; archive_base_rootfs

#Archive img:
base_rootfs="${debian_stable}" ; blend="microsd"
wfile="am57xx-\${base_rootfs}-2gb" ; archive_img
wfile="bone-\${base_rootfs}-2gb"   ; archive_img
wfile="bbxm-\${base_rootfs}-2gb"   ; archive_img

base_rootfs="${ubuntu_stable}" ; blend="microsd"
wfile="am57xx-\${base_rootfs}-2gb" ; archive_img
wfile="bone-\${base_rootfs}-2gb"   ; archive_img
wfile="bbxm-\${base_rootfs}-2gb"   ; archive_img

base_rootfs="${debian_stable}" ; blend="flasher"
wfile="am57xx-eMMC-flasher-\${base_rootfs}-2gb" ; archive_img
wfile="bone-eMMC-flasher-\${base_rootfs}-2gb"   ; archive_img

base_rootfs="${ubuntu_stable}" ; blend="flasher"
wfile="am57xx-eMMC-flasher-\${base_rootfs}-2gb" ; archive_img
wfile="bone-eMMC-flasher-\${base_rootfs}-2gb"   ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

#x86: My Server...
if [ -f /opt/images/nas.FREENAS ] ; then
	sudo mkdir -p /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/ || true

	echo "Copying: *.tar to server: images/${IMAGE_DIR_PREFIX}-${time}/"
	sudo cp -v ${DIR}/deploy/gift_wrap_final_images.sh /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/gift_wrap_final_images.sh || true

	ls -lha /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/
fi
