#!/bin/bash -e

time=$(date +%Y-%m-%d)
stage_dir="/var/www/html/rcn-ee.net/rootfs/bb.org/testing"
DIR="$PWD"

git pull --no-edit https://github.com/beagleboard/image-builder master

export apt_proxy=apt-proxy:3142/

if [ -d ./deploy ] ; then
	rm -rf ./deploy || true
fi

./RootStock-NG.sh -c bb.org-debian-stable
./RootStock-NG.sh -c bb.org-debian-stable-4gb
./RootStock-NG.sh -c bb.org-console-debian-stable
./RootStock-NG.sh -c bb.org-debian-next-4gb-v3.14
./RootStock-NG.sh -c machinekit-debian-wheezy

debian_lxde_stable="debian-7.8-lxde-armhf-${time}"
debian_lxde_4gb_stable="debian-7.8-lxde-4gb-armhf-${time}"
debian_console_stable="debian-7.8-console-armhf-${time}"
debian_lxqt_4gb_next="debian-jessie-lxqt-4gb-armhf-${time}"
debian_machinekit_wheezy="debian-7.8-machinekit-armhf-${time}"

archive="xz -z -8 -v"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

pre_generic_img () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi

        if [ -f \${base_rootfs}.tar.xz ] ; then
                tar xf \${base_rootfs}.tar.xz
        else
                tar xf \${base_rootfs}.tar
        fi
}

generic_img () {
        cd \${base_rootfs}/
        sudo ./setup_sdcard.sh \${options}
        mv *.img ../
        cd ..
}

stage_generic_img () {
        if [ -d ${stage_dir} ] ; then
                if [ ! -d ${stage_dir}/${time}/\${stage_blend}/ ] ; then
                        mkdir -p ${stage_dir}/${time}/\${stage_blend}/ || true
                fi
                if [ -d ${stage_dir}/${time}/\${stage_blend}/ ] ; then
                        if [ -f \${base_rootfs}.tar.xz ] ; then
                                cp -v \${base_rootfs}.tar.xz ${stage_dir}/${time}/\${stage_blend}/
                        fi
                fi
        fi
}

post_generic_img () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi

        if [ ! -f \${base_rootfs}.tar.xz ] ; then
                ${archive} \${base_rootfs}.tar
        fi
        stage_generic_img
}

stage_img () {
        if [ -d ${stage_dir} ] ; then
                if [ ! -d ${stage_dir}/${time}/\${stage_blend}/ ] ; then
                        mkdir -p ${stage_dir}/${time}/\${stage_blend}/ || true
                fi
                if [ -d ${stage_dir}/${time}/\${stage_blend}/ ] ; then
                        if [ -f \${wfile}.xz ] ; then
                                cp -v \${wfile}.xz ${stage_dir}/${time}/\${stage_blend}/
                        fi
                fi
        fi
}

compress_img () {
        if [ -f \${wfile} ] ; then
                ${archive} \${wfile}
                stage_img
        fi
}

###Production lxde images: (BBB: 4GB eMMC)
base_rootfs="${debian_lxde_4gb_stable}"
stage_blend="lxde-4gb"
pre_generic_img

options="--img-4gb BBB-blank-eMMC-flasher-\${base_rootfs} --dtb bbb-blank-eeprom --beagleboard.org-production --boot_label BEAGLEBONE --enable-systemd --rootfs_label rootfs --bbb-flasher --hostname beaglebone"
generic_img
options="--img-4gb BBB-eMMC-flasher-\${base_rootfs}       --dtb beaglebone       --beagleboard.org-production --boot_label BEAGLEBONE --enable-systemd --rootfs_label rootfs --bbb-flasher  --bbb-old-bootloader-in-emmc --hostname beaglebone"
generic_img
options="--img-4gb bone-\${base_rootfs}                   --dtb beaglebone       --beagleboard.org-production --boot_label BEAGLEBONE --enable-systemd --bbb-old-bootloader-in-emmc --hostname beaglebone"
generic_img

###lxde images: (BBB: 2GB eMMC)
base_rootfs="${debian_lxde_stable}"
stage_blend="lxde"
pre_generic_img

options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} --dtb beaglebone --beagleboard.org-production --boot_label BEAGLEBONE --enable-systemd --rootfs_label rootfs --bbb-flasher  --bbb-old-bootloader-in-emmc --hostname beaglebone"
generic_img

###console images: (also single partition)
base_rootfs="${debian_console_stable}"
stage_blend="console"
pre_generic_img

options="--img-2gb BBB-eMMC-flasher-\${base_rootfs} --dtb beaglebone --boot_label BEAGLEBONE --enable-systemd --bbb-flasher --bbb-old-bootloader-in-emmc --hostname beaglebone"
generic_img
options="--img-2gb bone-\${base_rootfs}             --dtb beaglebone --boot_label BEAGLEBONE --enable-systemd --bbb-old-bootloader-in-emmc --hostname beaglebone"
generic_img

###lxqt image
base_rootfs="${debian_lxqt_4gb_next}"
stage_blend="lxqt-4gb"
pre_generic_img

options="--img-4gb BBB-eMMC-flasher-\${base_rootfs} --dtb beaglebone        --beagleboard.org-production --boot_label BEAGLEBONE --rootfs_label rootfs --bbb-flasher  --bbb-old-bootloader-in-emmc --hostname beaglebone"
generic_img
options="--img-4gb bone-\${base_rootfs}             --dtb beaglebone        --beagleboard.org-production --boot_label BEAGLEBONE --rootfs_label rootfs --bbb-old-bootloader-in-emmc --hostname beaglebone"
generic_img
options="--img-4gb bbx15-\${base_rootfs}            --dtb am57xx-beagle-x15 --hostname BeagleBoard-X15"
generic_img

options="--img-4gb omap5-uevm-\${base_rootfs}       --dtb omap5-uevm        --hostname omap5-uevm"
generic_img

###machinekit:
base_rootfs="${debian_machinekit_wheezy}"
stage_blend="machinekit"
pre_generic_img

options="--img-4gb bone-\${base_rootfs}                   --dtb beaglebone       --beagleboard.org-production --boot_label BEAGLEBONE --enable-systemd --bbb-old-bootloader-in-emmc --hostname beaglebone"
generic_img

###archive *.tar
base_rootfs="${debian_lxde_4gb_stable}"
stage_blend="lxde-4gb"
post_generic_img

base_rootfs="${debian_lxde_stable}"
stage_blend="lxde"
post_generic_img

base_rootfs="${debian_console_stable}"
stage_blend="console"
post_generic_img

base_rootfs="${debian_lxqt_4gb_next}"
stage_blend="lxqt-4gb"
post_generic_img

base_rootfs="${debian_machinekit_wheezy}"
stage_blend="machinekit"
post_generic_img

###archive *.img
wfile="BBB-blank-eMMC-flasher-${debian_lxde_4gb_stable}-4gb.img"
compress_img
wfile="BBB-eMMC-flasher-${debian_lxde_4gb_stable}-4gb.img"
compress_img
wfile="bone-${debian_lxde_4gb_stable}-4gb.img"
compress_img

wfile="BBB-eMMC-flasher-${debian_lxde_stable}-2gb.img"
compress_img

wfile="BBB-eMMC-flasher-${debian_console_stable}-2gb.img"
compress_img
wfile="bone-${debian_console_stable}-2gb.img"
compress_img

wfile="BBB-eMMC-flasher-${debian_lxqt_4gb_next}-4gb.img"
compress_img

wfile="bone-${debian_lxqt_4gb_next}-4gb.img"
compress_img

wfile="bbx15-${debian_lxqt_4gb_next}-4gb.img"
compress_img

wfile="omap5-uevm-${debian_lxqt_4gb_next}-4gb.img"
compress_img

wfile="bone-${debian_machinekit_wheezy}-4gb.img"
compress_img

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

