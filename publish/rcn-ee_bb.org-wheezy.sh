#!/bin/bash -e

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.us/rootfs/bb.org/release"
DIR="$PWD"

git pull --no-edit https://github.com/beagleboard/image-builder master

export apt_proxy=apt-proxy:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

./RootStock-NG.sh -c bb.org-debian-wheezy-lxde-2gb
./RootStock-NG.sh -c bb.org-debian-wheezy-lxde-4gb
./RootStock-NG.sh -c bb.org-debian-wheezy-console

debian_wheezy_lxde_2gb="debian-7.11-lxde-armhf-${time}"
debian_wheezy_lxde_4gb="debian-7.11-lxde-4gb-armhf-${time}"
 debian_wheezy_console="debian-7.11-console-armhf-${time}"

archive="xz -z -8"

beaglebone="--dtb beaglebone --bbb-old-bootloader-in-emmc \
--rootfs_label rootfs --hostname beaglebone --enable-systemd"

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
        fi

        if [ -f \${base_rootfs}.tar ] ; then
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
                                mv -v \${wfile}.bmap ${mirror_dir}/${time}/\${blend}/
                                sync
                        fi
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${wfile}.img.zx ] ; then
                                mv -v \${wfile}.img ${mirror_dir}/${time}/\${blend}/
                                sync
                                if [ -f \${wfile}.img.xz.job.txt ] ; then
                                        mv -v \${wfile}.img.xz.job.txt ${mirror_dir}/${time}/\${blend}/
                                        sync
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

###Production lxde images: (BBB: 4GB eMMC)
base_rootfs="${debian_wheezy_lxde_4gb}" ; blend="lxde-4gb" ; extract_base_rootfs

options="--img-4gb BBB-blank-\${base_rootfs} ${beaglebone} --emmc-flasher" ; generate_img
options="--img-4gb bone-\${base_rootfs}      ${beaglebone}"                ; generate_img

###lxde images: (BBB: 2GB eMMC)
base_rootfs="${debian_wheezy_lxde_2gb}" ; blend="lxde" ; extract_base_rootfs

options="--img-2gb BBB-blank-\${base_rootfs} ${beaglebone} --emmc-flasher" ; generate_img
options="--img-2gb bone-\${base_rootfs}      ${beaglebone}"                ; generate_img

###console images
base_rootfs="${debian_wheezy_console}" ; blend="console" ; extract_base_rootfs

options="--img-2gb BBB-blank-\${base_rootfs} ${beaglebone} --emmc-flasher" ; generate_img
options="--img-2gb bone-\${base_rootfs}      ${beaglebone}"                ; generate_img

###archive *.tar
base_rootfs="${debian_wheezy_lxde_4gb}" ; blend="lxde-4gb" ; archive_base_rootfs
base_rootfs="${debian_wheezy_lxde_2gb}" ; blend="lxde"     ; archive_base_rootfs
base_rootfs="${debian_wheezy_console}"  ; blend="console"  ; archive_base_rootfs

###archive *.img
base_rootfs="${debian_wheezy_lxde_4gb}" ; blend="lxde-4gb"

wfile="BBB-blank-\${base_rootfs}-4gb" ; archive_img
wfile="bone-\${base_rootfs}-4gb"      ; archive_img

#
base_rootfs="${debian_wheezy_lxde_2gb}" ; blend="lxde"

wfile="BBB-blank-\${base_rootfs}-2gb" ; archive_img
wfile="bone-\${base_rootfs}-2gb"      ; archive_img

#
base_rootfs="${debian_wheezy_console}" ; blend="console"

wfile="BBB-blank-\${base_rootfs}-2gb" ; archive_img
wfile="bone-\${base_rootfs}-2gb"      ; archive_img

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

