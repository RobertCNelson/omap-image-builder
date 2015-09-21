#!/bin/bash -e

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.net/rootfs/"
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

./RootStock-NG.sh -c rcn-ee_console_debian_jessie_armhf
./RootStock-NG.sh -c rcn-ee_console_debian_stretch_armhf
./RootStock-NG.sh -c rcn-ee_console_ubuntu_trusty_armhf

debian_stable="debian-8.2-console-armhf-${time}"
debian_testing="debian-stretch-console-armhf-${time}"
ubuntu_stable="ubuntu-14.04.3-console-armhf-${time}"

archive="xz -z -8"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

copy_base_rootfs_to_mirror () {
        if [ -d ${mirror_dir}/ ] ; then
                if [ ! -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        mkdir -p ${mirror_dir}/${time}/\${blend}/ || true
                fi
                if [ -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${base_rootfs}.tar.xz ] ; then
                                cp -v \${base_rootfs}.tar ${mirror_dir}/${time}/\${blend}/
                                cd ${mirror_dir}/${time}/\${blend}/
                                ${archive} \${base_rootfs}.tar && sha256sum \${base_rootfs}.tar.xz > \${base_rootfs}.tar.xz.sha256sum &
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
        else
                tar xf \${base_rootfs}.tar
        fi
}

copy_img_to_mirror () {
        if [ -d ${mirror_dir} ] ; then
                if [ ! -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        mkdir -p ${mirror_dir}/${time}/\${blend}/ || true
                fi
                if [ -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        if [ -f \${wfile}.bmap ] ; then
                                cp -v \${wfile}.bmap ${mirror_dir}/${time}/\${blend}/
                        fi
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${wfile}.img.zx ] ; then
                                cp -v \${wfile}.img ${mirror_dir}/${time}/\${blend}/
                                if [ -f \${wfile}.img.xz.job.txt ] ; then
                                        cp -v \${wfile}.img.xz.job.txt ${mirror_dir}/${time}/\${blend}/
                                fi
                                cd ${mirror_dir}/${time}/\${blend}/
                                ${archive} \${wfile}.img && sha256sum \${wfile}.img.xz > \${wfile}.img.xz.sha256sum &
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
        cd \${base_rootfs}/
        sudo ./setup_sdcard.sh \${options}
        mv *.img ../
        mv *.job.txt ../
        cd ..
}

#Debian Stable
base_rootfs="${debian_stable}" ; blend="elinux" ; extract_base_rootfs

options="--img BBB-eMMC-flasher-${debian_stable} --dtb beaglebone --emmc-flasher --bbb-old-bootloader-in-emmc" ; generate_img
options="--img bone-${debian_stable} --dtb beaglebone --bbb-old-bootloader-in-emmc" ; generate_img
options="--img bbxm-${debian_stable} --dtb omap3-beagle-xm" ; generate_img
options="--img bbx15-${debian_stable} --dtb am57xx-beagle-x15" ; generate_img
options="--img bbx15-eMMC-flasher-${debian_stable} --dtb am57xx-beagle-x15 --emmc-flasher" ; generate_img
options="--img omap5-uevm-${debian_stable} --dtb omap5-uevm" ; generate_img

#Ubuntu Stable
base_rootfs="${ubuntu_stable}" ; blend="elinux" ; extract_base_rootfs

options="--img BBB-eMMC-flasher-${ubuntu_stable} --dtb beaglebone --emmc-flasher  --bbb-old-bootloader-in-emmc" ; generate_img
options="--img bone-${ubuntu_stable} --dtb beaglebone --bbb-old-bootloader-in-emmc" ; generate_img
options="--img bbxm-${ubuntu_stable} --dtb omap3-beagle-xm" ; generate_img
options="--img bbx15-${ubuntu_stable} --dtb am57xx-beagle-x15" ; generate_img
options="--img bbx15-eMMC-flasher-${ubuntu_stable} --dtb am57xx-beagle-x15 --emmc-flasher" ; generate_img
options="--img omap5-uevm-${ubuntu_stable} --dtb omap5-uevm" ; generate_img

#Archive tar:
base_rootfs="${debian_stable}" ; blend="elinux" ; archive_base_rootfs
base_rootfs="${ubuntu_stable}" ; blend="elinux" ; archive_base_rootfs
base_rootfs="${debian_testing}" ; blend="elinux" ; archive_base_rootfs

#Archive img:
blend="microsd"
wfile="bone-${debian_stable}-2gb" ; archive_img
wfile="bbxm-${debian_stable}-2gb" ; archive_img
wfile="bbx15-${debian_stable}-2gb" ; archive_img
wfile="omap5-uevm-${debian_stable}-2gb" ; archive_img

wfile="bone-${ubuntu_stable}-2gb" ; archive_img
wfile="bbxm-${ubuntu_stable}-2gb" ; archive_img
wfile="bbx15-${ubuntu_stable}-2gb" ; archive_img
wfile="omap5-uevm-${ubuntu_stable}-2gb" ; archive_img

blend="flasher"
wfile="BBB-eMMC-flasher-${debian_stable}-2gb" ; archive_img
wfile="bbx15-eMMC-flasher-${debian_stable}-2gb" ; archive_img

wfile="BBB-eMMC-flasher-${ubuntu_stable}-2gb" ; archive_img
wfile="bbx15-eMMC-flasher-${ubuntu_stable}-2gb" ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ ! -d /mnt/farm/images/ ] ; then
	#nfs mount...
	sudo mount -a
fi

if [ -d /mnt/farm/images/ ] ; then
	mkdir /mnt/farm/images/${time}/
	cp -v ${DIR}/deploy/*.tar /mnt/farm/images/${time}/
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/${time}/gift_wrap_final_images.sh
	chmod +x /mnt/farm/images/${time}/gift_wrap_final_images.sh
fi

