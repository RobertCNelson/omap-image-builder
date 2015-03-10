#!/bin/bash -e

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.net/rootfs/bb.org/testing"
DIR="$PWD"

git pull --no-edit https://github.com/beagleboard/image-builder master

export apt_proxy=apt-proxy:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

./RootStock-NG.sh -c bb.org-debian-stable
./RootStock-NG.sh -c bb.org-debian-stable-4gb
./RootStock-NG.sh -c bb.org-console-debian-stable
./RootStock-NG.sh -c machinekit-debian-wheezy
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-2gb-v3.14
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-4gb-v3.14

debian_lxde_stable="debian-7.8-lxde-armhf-${time}"
debian_lxde_4gb_stable="debian-7.8-lxde-4gb-armhf-${time}"
debian_console_stable="debian-7.8-console-armhf-${time}"
debian_machinekit_wheezy="debian-7.8-machinekit-armhf-${time}"
debian_lxqt_2gb_next="debian-jessie-lxqt-2gb-armhf-${time}"
debian_lxqt_4gb_next="debian-jessie-lxqt-4gb-armhf-${time}"

archive="xz -z -8 -v"

beaglebone="--dtb beaglebone --beagleboard.org-production --boot_label BEAGLEBONE \
--rootfs_label rootfs --bbb-old-bootloader-in-emmc --hostname beaglebone"

bb_blank_flasher="--dtb bbb-blank-eeprom --boot_label BEAGLEBONE \
--rootfs_label rootfs --bbb-old-bootloader-in-emmc --hostname beaglebone"

beaglebone_console="--dtb beaglebone --boot_label BEAGLEBONE \
--bbb-old-bootloader-in-emmc --hostname beaglebone"

bb_blank_flasher_console="--dtb bbb-blank-eeprom --boot_label BEAGLEBONE \
--bbb-old-bootloader-in-emmc --hostname beaglebone"

omap5_uevm="--dtb omap5-uevm --hostname omap5-uevm"
am57xx_beagle_x15="--dtb am57xx-beagle-x15 --hostname BeagleBoard-X15"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash -x

copy_base_rootfs_to_mirror () {
        if [ -d ${mirror_dir} ] ; then
                if [ ! -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        mkdir -p ${mirror_dir}/${time}/\${blend}/ || true
                fi
                if [ -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        if [ -f \${base_rootfs}.tar.xz ] ; then
                                cp -v \${base_rootfs}.tar.xz ${mirror_dir}/${time}/\${blend}/
                        fi
                fi
        fi
}

archive_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi

        if [ ! -f \${base_rootfs}.tar.xz ] ; then
                ${archive} \${base_rootfs}.tar
        fi
        copy_base_rootfs_to_mirror
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
                        if [ -f \${wfile}.xz ] ; then
                                cp -v \${wfile}.xz ${mirror_dir}/${time}/\${blend}/
                        fi
                fi
        fi
}

archive_img () {
        if [ -f \${wfile} ] ; then
                ${archive} \${wfile}
                copy_img_to_mirror
        fi
}

generate_img () {
        cd \${base_rootfs}/
        sudo ./setup_sdcard.sh \${options}
        mv *.img ../
        cd ..
}

###Production lxde images: (BBB: 4GB eMMC)
base_rootfs="${debian_lxde_4gb_stable}" ; blend="lxde-4gb" ; extract_base_rootfs

options="--img-4gb BBB-blank-eMMC-flasher-\${base_rootfs} ${bb_blank_flasher} --enable-systemd --bbb-flasher" ; generate_img
options="--img-4gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone} --enable-systemd --bbb-flasher" ; generate_img
options="--img-4gb bone-\${base_rootfs} ${beaglebone} --enable-systemd" ; generate_img

###lxde images: (BBB: 2GB eMMC)
base_rootfs="${debian_lxde_stable}" ; blend="lxde" ; extract_base_rootfs

options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone} --enable-systemd --bbb-flasher" ; generate_img

###console images: (also single partition)
base_rootfs="${debian_console_stable}" ; blend="console" ; extract_base_rootfs

options="--img-2gb BBG-blank-eMMC-flasher-\${base_rootfs} ${bb_blank_flasher_console} --enable-systemd --bbg-flasher" ; generate_img
options="--img-2gb BBB-blank-eMMC-flasher-\${base_rootfs} ${bb_blank_flasher_console} --enable-systemd --bbb-flasher" ; generate_img
options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone_console} --enable-systemd --bbb-flasher" ; generate_img
options="--img-2gb bone-\${base_rootfs} ${beaglebone_console} --enable-systemd" ; generate_img

###machinekit:
base_rootfs="${debian_machinekit_wheezy}" ; blend="machinekit" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs} ${beaglebone} --enable-systemd" ; generate_img

###lxqt-4gb image
base_rootfs="${debian_lxqt_4gb_next}" ; blend="lxqt-4gb" ; extract_base_rootfs

options="--img-4gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone} --bbb-flasher" ; generate_img
options="--img-4gb bone-\${base_rootfs} ${beaglebone}" ; generate_img
options="--img-4gb bbx15-\${base_rootfs} ${am57xx_beagle_x15}" ; generate_img
options="--img-4gb omap5-uevm-\${base_rootfs} ${omap5_uevm}" ; generate_img

###lxqt-2gb image
base_rootfs="${debian_lxqt_2gb_next}" ; blend="lxqt-2gb" ; extract_base_rootfs

options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} ${beaglebone} --bbb-flasher" ; generate_img

###archive *.tar
base_rootfs="${debian_lxde_4gb_stable}" ; blend="lxde-4gb" ; archive_base_rootfs
base_rootfs="${debian_lxde_stable}" ; blend="lxde" ; archive_base_rootfs
base_rootfs="${debian_console_stable}" ; blend="console" ; archive_base_rootfs
base_rootfs="${debian_machinekit_wheezy}" ; blend="machinekit" ; archive_base_rootfs
base_rootfs="${debian_lxqt_4gb_next}" ; blend="lxqt-4gb" ; archive_base_rootfs
base_rootfs="${debian_lxqt_2gb_next}" ; blend="lxqt-2gb" ; archive_base_rootfs

###archive *.img
blend="lxde-4gb"
wfile="BBB-blank-eMMC-flasher-${debian_lxde_4gb_stable}-4gb.img" ; archive_img
wfile="BBB-eMMC-flasher-${debian_lxde_4gb_stable}-4gb.img" ; archive_img
wfile="bone-${debian_lxde_4gb_stable}-4gb.img" ; archive_img

blend="lxde"
wfile="BBB-eMMC-flasher-${debian_lxde_stable}-2gb.img" ; archive_img

blend="console"
wfile="BBB-blank-eMMC-flasher-${debian_console_stable}-2gb.img" ;archive_img
wfile="BBG-blank-eMMC-flasher-${debian_console_stable}-2gb.img" ;archive_img
wfile="BBB-eMMC-flasher-${debian_console_stable}-2gb.img" ; archive_img
wfile="bone-${debian_console_stable}-2gb.img" ; archive_img

blend="machinekit"
wfile="bone-${debian_machinekit_wheezy}-4gb.img" ; archive_img

blend="lxqt-4gb"
wfile="BBB-eMMC-flasher-${debian_lxqt_4gb_next}-4gb.img" ; archive_img
wfile="bone-${debian_lxqt_4gb_next}-4gb.img" ; archive_img
wfile="bbx15-${debian_lxqt_4gb_next}-4gb.img" ; archive_img
wfile="omap5-uevm-${debian_lxqt_4gb_next}-4gb.img" ; archive_img

blend="lxqt-2gb"
wfile="BBB-eMMC-flasher-${debian_lxqt_2gb_next}-2gb.img" ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ ! -d /mnt/farm/images/ ] ; then
	#nfs mount...
	sudo mount -a
fi

if [ -d /mnt/farm/images/ ] ; then
	cp -v ${DIR}/deploy/*.tar /mnt/farm/images/
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/gift_wrap_final_images.sh
	chmod +x /mnt/farm/images/gift_wrap_final_images.sh
fi

