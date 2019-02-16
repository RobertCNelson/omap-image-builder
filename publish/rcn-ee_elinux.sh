#!/bin/bash -e

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.us/rootfs/"
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

if [ ! -f jenkins.build ] ; then
./RootStock-NG.sh -c rcn-ee_console_debian_stretch_armhf
./RootStock-NG.sh -c rcn-ee_console_debian_buster_armhf
./RootStock-NG.sh -c rcn-ee_console_ubuntu_bionic_armhf
else
	mkdir -p ${DIR}/deploy/ || true
fi

 debian_stable="debian-9.8-console-armhf-${time}"
debian_testing="debian-buster-console-armhf-${time}"
 ubuntu_stable="ubuntu-18.04.2-console-armhf-${time}"
#ubuntu_testing="ubuntu-bionic-console-armhf-${time}"

xz_img="xz -z -8"
xz_tar="xz -T2 -z -8"

beaglebone="--dtb beaglebone --rootfs_label rootfs --enable-cape-universal"

omap3_beagle_xm="--dtb omap3-beagle-xm --rootfs_label rootfs"
omap5_uevm="--dtb omap5-uevm --rootfs_label rootfs"
am57xx_beagle_x15="--dtb am57xx-beagle-x15 --rootfs_label rootfs"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

wait_till_Xgb_free () {
        memory=4096
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
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${wfile}.img.zx ] ; then
                                mv -v \${wfile}.img ${mirror_dir}/${time}/\${blend}/
                                sync
                                if [ -f \${wfile}.img.xz.job.txt ] ; then
                                        mv -v \${wfile}.img.xz.job.txt ${mirror_dir}/${time}/\${blend}/
                                        sync
                                fi
                                cd ${mirror_dir}/${time}/\${blend}/
                                ${xz_img} \${wfile}.img && sha256sum \${wfile}.img.xz > \${wfile}.img.xz.sha256sum &
                                cd -
                        fi
                fi
        fi
}

archive_img () {
        if [ -f \${wfile}.img ] ; then
                copy_img_to_mirror
        fi
}

generate_img () {
        if [ -d \${base_rootfs}/ ] ; then
                cd \${base_rootfs}/
                sudo ./setup_sdcard.sh \${options}
                sudo chown 1000:1000 *.img || true
                sudo chown 1000:1000 *.job.txt || true
                mv *.img ../ || true
                mv *.job.txt ../ || true
                cd ..
        fi
}

#Debian Stable
base_rootfs="${debian_stable}" ; blend="elinux" ; extract_base_rootfs

options="--img BBB-eMMC-flasher-\${base_rootfs}   ${beaglebone}        --emmc-flasher" ; generate_img
options="--img bone-\${base_rootfs}               ${beaglebone}"                       ; generate_img
options="--img bbxm-\${base_rootfs}               ${omap3_beagle_xm}"                  ; generate_img
options="--img bbx15-eMMC-flasher-\${base_rootfs} ${am57xx_beagle_x15} --emmc-flasher" ; generate_img
options="--img bbx15-\${base_rootfs}              ${am57xx_beagle_x15}"                ; generate_img
options="--img omap5-uevm-\${base_rootfs}         ${omap5_uevm}"                       ; generate_img

#Ubuntu Stable
base_rootfs="${ubuntu_stable}" ; blend="elinux" ; extract_base_rootfs

options="--img BBB-eMMC-flasher-\${base_rootfs}   ${beaglebone} --emmc-flasher"        ; generate_img
options="--img bone-\${base_rootfs}               ${beaglebone}"                       ; generate_img
options="--img bbxm-\${base_rootfs}               ${omap3_beagle_xm}"                  ; generate_img
options="--img bbx15-eMMC-flasher-\${base_rootfs} ${am57xx_beagle_x15} --emmc-flasher" ; generate_img
options="--img bbx15-\${base_rootfs}              ${am57xx_beagle_x15}"                ; generate_img
options="--img omap5-uevm-\${base_rootfs}         ${omap5_uevm}"                       ; generate_img

#Archive tar:
base_rootfs="${debian_stable}"  ; blend="elinux" ; archive_base_rootfs
base_rootfs="${ubuntu_stable}"  ; blend="elinux" ; archive_base_rootfs
base_rootfs="${debian_testing}" ; blend="elinux" ; archive_base_rootfs
base_rootfs="${ubuntu_testing}" ; blend="elinux" ; archive_base_rootfs

#Archive img:
base_rootfs="${debian_stable}" ; blend="microsd"
wfile="bone-\${base_rootfs}-2gb"       ; archive_img
wfile="bbxm-\${base_rootfs}-2gb"       ; archive_img
wfile="bbx15-\${base_rootfs}-2gb"      ; archive_img
wfile="omap5-uevm-\${base_rootfs}-2gb" ; archive_img

base_rootfs="${ubuntu_stable}" ; blend="microsd"
wfile="bone-\${base_rootfs}-2gb"       ; archive_img
wfile="bbxm-\${base_rootfs}-2gb"       ; archive_img
wfile="bbx15-\${base_rootfs}-2gb"      ; archive_img
wfile="omap5-uevm-\${base_rootfs}-2gb" ; archive_img

base_rootfs="${debian_stable}" ; blend="flasher"
wfile="BBB-eMMC-flasher-\${base_rootfs}-2gb"   ; archive_img
wfile="bbx15-eMMC-flasher-\${base_rootfs}-2gb" ; archive_img

base_rootfs="${ubuntu_stable}" ; blend="flasher"
wfile="BBB-eMMC-flasher-\${base_rootfs}-2gb"   ; archive_img
wfile="bbx15-eMMC-flasher-\${base_rootfs}-2gb" ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

image_prefix="elinux"
#node:
if [ ! -d /var/www/html/farm/images/ ] ; then
	if [ ! -d /mnt/farm/images/ ] ; then
		#nfs mount...
		sudo mount -a
	fi

	if [ -d /mnt/farm/images/ ] ; then
		mkdir -p /mnt/farm/images/${image_prefix}-${time}/ || true
		echo "Copying: *.tar to server: images/${image_prefix}-${time}/"
		cp -v ${DIR}/deploy/*.tar /mnt/farm/images/${image_prefix}-${time}/ || true
		cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
		chmod +x /mnt/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
	fi
fi

#x86:
if [ -d /var/www/html/farm/images/ ] ; then
	mkdir -p /var/www/html/farm/images/${image_prefix}-${time}/ || true
	echo "Copying: *.tar to server: images/${image_prefix}-${time}/"
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /var/www/html/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
	chmod +x /var/www/html/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
	sudo chown -R apt-cacher-ng:apt-cacher-ng /var/www/html/farm/images/${image_prefix}-${time}/ || true
fi
