#!/bin/bash -e

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.us/rootfs/bb.org/testing"
DIR="$PWD"

git pull --no-edit https://github.com/beagleboard/image-builder master

export apt_proxy=apt-proxy:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

if [ ! -f jenkins.build ] ; then
./RootStock-NG.sh -c machinekit-debian-jessie
./RootStock-NG.sh -c bb.org-debian-jessie-console-v4.4
./RootStock-NG.sh -c bb.org-debian-jessie-iot-v4.4
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-2gb-v4.4
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-4gb-v4.4
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-4gb-xm

./RootStock-NG.sh -c seeed-debian-jessie-lxqt-4gb-v4.4
./RootStock-NG.sh -c seeed-debian-jessie-iot-v4.4
./RootStock-NG.sh -c bb.org-debian-jessie-oemflasher

./RootStock-NG.sh -c machinekit-debian-stretch
./RootStock-NG.sh -c bb.org-debian-stretch-console-v4.9
./RootStock-NG.sh -c bb.org-debian-stretch-iot-v4.9
./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-2gb-v4.9
./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-v4.9
./RootStock-NG.sh -c bb.org-debian-stretch-lxqt-xm
./RootStock-NG.sh -c bb.org-debian-stretch-oemflasher-v4.9

./RootStock-NG.sh -c bb.org-debian-buster-iot-v4.9
else
	mkdir -p ${DIR}/deploy/ || true
fi

    debian_jessie_machinekit="debian-8.10-machinekit-armhf-${time}"

       debian_jessie_console="debian-8.10-console-armhf-${time}"
           debian_jessie_iot="debian-8.10-iot-armhf-${time}"
      debian_jessie_lxqt_2gb="debian-8.10-lxqt-2gb-armhf-${time}"
      debian_jessie_lxqt_4gb="debian-8.10-lxqt-4gb-armhf-${time}"
   debian_jessie_lxqt_xm_4gb="debian-8.10-lxqt-xm-4gb-armhf-${time}"
    debian_jessie_oemflasher="debian-8.10-oemflasher-armhf-${time}"

     debian_jessie_seeed_iot="debian-8.10-seeed-iot-armhf-${time}"
debian_jessie_seeed_lxqt_4gb="debian-8.10-seeed-lxqt-4gb-armhf-${time}"

   debian_stretch_machinekit="debian-9.3-machinekit-armhf-${time}"
      debian_stretch_console="debian-9.3-console-armhf-${time}"
          debian_stretch_iot="debian-9.3-iot-armhf-${time}"
     debian_stretch_lxqt_2gb="debian-9.3-lxqt-2gb-armhf-${time}"
         debian_stretch_lxqt="debian-9.3-lxqt-armhf-${time}"
      debian_stretch_lxqt_xm="debian-9.3-lxqt-xm-armhf-${time}"
      debian_stretch_wayland="debian-9.3-wayland-armhf-${time}"
   debian_stretch_oemflasher="debian-9.3-oemflasher-armhf-${time}"

           debian_buster_iot="debian-buster-iot-armhf-${time}"

xz_img="xz -z -8"
#xz_tar="xz -z -8"
xz_tar="xz -T2 -z -8"

beaglebone="--dtb beaglebone --rootfs_label rootfs --hostname beaglebone --enable-uboot-cape-overlays"
pru_rproc_v44ti="--enable-uboot-pru-rproc-44ti"
pru_rproc_v49ti="--enable-uboot-pru-rproc-49ti"

beagle_xm="--dtb omap3-beagle-xm --rootfs_label rootfs --hostname beagleboard"

beagle_x15="--dtb am57xx-beagle-x15 --rootfs_label rootfs \
--hostname BeagleBoard-X15"

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

###machinekit (jessie):
base_rootfs="${debian_jessie_machinekit}" ; blend="machinekit" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs} ${beaglebone}" ; generate_img

###console images (jessie):
base_rootfs="${debian_jessie_console}" ; blend="console" ; extract_base_rootfs

options="--img-1gb bbx15-\${base_rootfs}       ${beagle_x15}"                ; generate_img
options="--img-1gb bone-\${base_rootfs}        ${beaglebone} ${pru_rproc_v49ti}"   ; generate_img
options="--img-1gb a335-eeprom-\${base_rootfs} ${beaglebone} --a335-flasher" ; generate_img
options="--img-1gb bp00-eeprom-\${base_rootfs} ${beaglebone} --bp00-flasher" ; generate_img
options="--img-1gb am57xx-x15-eeprom-\${base_rootfs}       ${beagle_x15} --emmc-flasher --am57xx-x15-revc-flasher" ; generate_img
options="--img-1gb am571x-sndrblock-eeprom-\${base_rootfs} ${beagle_x15} --emmc-flasher --am571x-sndrblock-flasher" ; generate_img

#options="--img-1gb me06-blank-\${base_rootfs}  ${beaglebone} --me06-flasher" ; generate_img
#options="--img-1gb BBB-blank-\${base_rootfs}   ${beaglebone} --emmc-flasher" ; generate_img
#options="--img-1gb bbx15-blank-\${base_rootfs} ${beagle_x15} --emmc-flasher" ; generate_img

###iot image (jessie):
base_rootfs="${debian_jessie_iot}" ; blend="iot" ; extract_base_rootfs

options="--img-4gb bbx15-\${base_rootfs}      ${beagle_x15}"                             ; generate_img
options="--img-4gb bone-\${base_rootfs}       ${beaglebone} ${pru_rproc_v49ti}"                ; generate_img
options="--img-4gb BBB-blank-\${base_rootfs}  ${beaglebone} ${pru_rproc_v49ti} --emmc-flasher" ; generate_img
options="--img-4gb BBBL-blank-\${base_rootfs} ${beaglebone} ${pru_rproc_v49ti} --bbbl-flasher" ; generate_img

#options="--img-4gb BBB-blank-uboot-overlay-\${base_rootfs}  ${beaglebone} --emmc-flasher ${overlay}" ; generate_img
#options="--img-4gb BBBW-blank-\${base_rootfs}  ${beaglebone}   --bbbw-flasher" ; generate_img

###lxqt-2gb image (jessie):
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb" ; extract_base_rootfs

options="--img-2gb bone-\${base_rootfs}  ${beaglebone} ${pru_rproc_v49ti}" ; generate_img
options="--img-2gb BBB-blank-\${base_rootfs} ${beaglebone}  ${pru_rproc_v49ti} --emmc-flasher" ; generate_img

###lxqt-4gb image (jessie):
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb" ; extract_base_rootfs

options="--img-4gb bbx15-\${base_rootfs}       ${beagle_x15}"                             ; generate_img
options="--img-4gb bbx15-blank-\${base_rootfs} ${beagle_x15} --emmc-flasher --am57xx-x15-revc-flasher" ; generate_img
options="--img-4gb bone-\${base_rootfs}        ${beaglebone} ${pru_rproc_v49ti}"                ; generate_img
options="--img-4gb BBB-blank-\${base_rootfs}   ${beaglebone} ${pru_rproc_v49ti} --emmc-flasher" ; generate_img
options="--img-4gb BBBW-blank-\${base_rootfs}  ${beaglebone} ${pru_rproc_v49ti} --bbbw-flasher" ; generate_img

#options="--img-4gb BBB-blank-uboot-overlay-\${base_rootfs}  ${beaglebone} --emmc-flasher ${overlay}" ; generate_img
#options="--img-4gb m10a-blank-\${base_rootfs}  ${beaglebone}  --m10a-flasher" ; generate_img

###lxqt-xm-4gb image (jessie):
base_rootfs="${debian_jessie_lxqt_xm_4gb}" ; blend="lxqt-xm-4gb" ; extract_base_rootfs

options="--img-4gb bbxm-\${base_rootfs}  ${beagle_xm}" ; generate_img

###Seeed iot image (jessie):
base_rootfs="${debian_jessie_seeed_iot}" ; blend="seeed-iot" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}       ${beaglebone}"                ; generate_img
#options="--img-4gb BBGW-blank-\${base_rootfs} ${beaglebone} --bbgw-flasher" ; generate_img

###Seeed lxqt-4gb image (jessie):
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}      ${beaglebone}"                ; generate_img
#options="--img-4gb BBG-blank-\${base_rootfs} ${beaglebone}  --bbg-flasher" ; generate_img

###machinekit (stretch):
base_rootfs="${debian_stretch_machinekit}" ; blend="stretch-machinekit" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs} ${beaglebone}" ; generate_img

###console image (stretch):
base_rootfs="${debian_stretch_console}" ; blend="stretch-console" ; extract_base_rootfs

options="--img-1gb bbx15-\${base_rootfs}     ${beagle_x15}"                ; generate_img
options="--img-1gb bone-\${base_rootfs}      ${beaglebone}"                ; generate_img

###iot image (stretch):
base_rootfs="${debian_stretch_iot}" ; blend="stretch-iot" ; extract_base_rootfs

options="--img-4gb bbx15-\${base_rootfs}      ${beagle_x15}"                                   ; generate_img
options="--img-4gb bone-\${base_rootfs}       ${beaglebone} ${pru_rproc_v49ti}"                ; generate_img
options="--img-4gb BBB-blank-\${base_rootfs}  ${beaglebone} ${pru_rproc_v49ti} --emmc-flasher" ; generate_img
options="--img-4gb BBBL-blank-\${base_rootfs} ${beaglebone} ${pru_rproc_v49ti} --bbbl-flasher" ; generate_img

###lxqt-2gb image (stretch):
base_rootfs="${debian_stretch_lxqt_2gb}" ; blend="stretch-lxqt-2gb" ; extract_base_rootfs

options="--img-2gb bone-\${base_rootfs}  ${beaglebone}" ; generate_img
options="--img-2gb BBB-blank-\${base_rootfs} ${beaglebone} --emmc-flasher" ; generate_img

###lxqt image (stretch):
base_rootfs="${debian_stretch_lxqt}" ; blend="stretch-lxqt" ; extract_base_rootfs

options="--img-4gb bbx15-\${base_rootfs}       ${beagle_x15}"                             ; generate_img
options="--img-4gb bbx15-blank-\${base_rootfs} ${beagle_x15} --emmc-flasher --am57xx-x15-revc-flasher" ; generate_img
options="--img-4gb bone-\${base_rootfs}        ${beaglebone}"                ; generate_img
options="--img-4gb BBB-blank-\${base_rootfs}   ${beaglebone} --emmc-flasher" ; generate_img

###lxqt image (stretch):
base_rootfs="${debian_stretch_lxqt_xm}" ; blend="stretch-lxqt-xm" ; extract_base_rootfs

options="--img-4gb bbxm-\${base_rootfs}  ${beagle_xm}" ; generate_img

### wayland image (stretch):
base_rootfs="${debian_stretch_wayland}" ; blend="stretch-wayland" ; extract_base_rootfs

options="--img-4gb bbx15-\${base_rootfs} ${beagle_x15}"    ; generate_img
options="--img-4gb bone-\${base_rootfs}  ${beaglebone}"    ; generate_img

###iot image (buster):
base_rootfs="${debian_buster_iot}" ; blend="buster-iot" ; extract_base_rootfs

options="--img-4gb bbx15-\${base_rootfs}     ${beagle_x15}"                ; generate_img
options="--img-4gb bone-\${base_rootfs}      ${beaglebone}"                ; generate_img
options="--img-4gb BBB-blank-\${base_rootfs} ${beaglebone} --emmc-flasher" ; generate_img

###archive *.tar
base_rootfs="${debian_jessie_machinekit}"     ; blend="machinekit"      ; archive_base_rootfs
base_rootfs="${debian_jessie_console}"        ; blend="console"         ; archive_base_rootfs
base_rootfs="${debian_jessie_iot}"            ; blend="iot"             ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_2gb}"       ; blend="lxqt-2gb"        ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_4gb}"       ; blend="lxqt-4gb"        ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_xm_4gb}"    ; blend="lxqt-xm-4gb"     ; archive_base_rootfs
base_rootfs="${debian_jessie_oemflasher}"     ; blend="oemflasher"      ; archive_base_rootfs
base_rootfs="${debian_jessie_seeed_iot}"      ; blend="seeed-iot"       ; archive_base_rootfs
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb"  ; archive_base_rootfs

base_rootfs="${debian_stretch_machinekit}"    ; blend="stretch-machinekit" ; archive_base_rootfs
base_rootfs="${debian_stretch_console}"       ; blend="stretch-console"    ; archive_base_rootfs
base_rootfs="${debian_stretch_iot}"           ; blend="stretch-iot"        ; archive_base_rootfs
base_rootfs="${debian_stretch_lxqt_2gb}"      ; blend="stretch-lxqt-2gb"   ; archive_base_rootfs
base_rootfs="${debian_stretch_lxqt}"          ; blend="stretch-lxqt"       ; archive_base_rootfs
base_rootfs="${debian_stretch_lxqt_xm}"       ; blend="stretch-lxqt-xm"    ; archive_base_rootfs
base_rootfs="${debian_stretch_wayland}"       ; blend="stretch-wayland"    ; archive_base_rootfs
base_rootfs="${debian_stretch_oemflasher}"    ; blend="stretch-oemflasher" ; archive_base_rootfs

base_rootfs="${debian_buster_iot}"            ; blend="buster-iot"      ; archive_base_rootfs

###archive *.img
###machinekit (jessie):
base_rootfs="${debian_jessie_machinekit}" ; blend="machinekit"

wfile="bone-\${base_rootfs}-4gb" ; archive_img

###console images (jessie):
base_rootfs="${debian_jessie_console}" ; blend="console"

wfile="bbx15-\${base_rootfs}-1gb"       ; archive_img
wfile="bone-\${base_rootfs}-1gb"        ; archive_img
wfile="a335-eeprom-\${base_rootfs}-1gb" ; archive_img
wfile="bp00-eeprom-\${base_rootfs}-1gb" ; archive_img

wfile="am57xx-x15-eeprom-\${base_rootfs}-1gb"       ; archive_img
wfile="am571x-sndrblock-eeprom-\${base_rootfs}-1gb" ; archive_img

###iot image (jessie):
base_rootfs="${debian_jessie_iot}" ; blend="iot"

wfile="bbx15-\${base_rootfs}-4gb"        ; archive_img
wfile="bone-\${base_rootfs}-4gb"        ; archive_img
wfile="BBB-blank-\${base_rootfs}-4gb"   ; archive_img
wfile="BBBL-blank-\${base_rootfs}-4gb"  ; archive_img

###lxqt-2gb image (jessie):
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb"

wfile="bone-\${base_rootfs}-2gb"      ; archive_img
wfile="BBB-blank-\${base_rootfs}-2gb"      ; archive_img

###lxqt-4gb image (jessie):
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb"

wfile="bbx15-\${base_rootfs}-4gb"       ; archive_img
wfile="bbx15-blank-\${base_rootfs}-4gb" ; archive_img
wfile="bone-\${base_rootfs}-4gb"        ; archive_img
wfile="BBB-blank-\${base_rootfs}-4gb"   ; archive_img
wfile="BBBW-blank-\${base_rootfs}-4gb"  ; archive_img

###lxqt-xm-4gb image (jessie):
base_rootfs="${debian_jessie_lxqt_xm_4gb}" ; blend="lxqt-xm-4gb"

wfile="bbxm-\${base_rootfs}-4gb"      ; archive_img

###Seeed iot image (jessie):
base_rootfs="${debian_jessie_seeed_iot}" ; blend="seeed-iot"

wfile="bone-\${base_rootfs}-4gb"       ; archive_img

###Seeed lxqt-4gb image (jessie):
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb"

wfile="bone-\${base_rootfs}-4gb"      ; archive_img

###machinekit (stretch):
base_rootfs="${debian_stretch_machinekit}" ; blend="stretch-machinekit"

wfile="bone-\${base_rootfs}-4gb" ; archive_img

###console image (stretch):
base_rootfs="${debian_stretch_console}" ; blend="stretch-console"

wfile="bbx15-\${base_rootfs}-1gb"          ; archive_img
wfile="bone-\${base_rootfs}-1gb"           ; archive_img

###iot image (stretch):
base_rootfs="${debian_stretch_iot}" ; blend="stretch-iot"

wfile="bbx15-\${base_rootfs}-4gb"          ; archive_img
wfile="bone-\${base_rootfs}-4gb"           ; archive_img
wfile="BBB-blank-\${base_rootfs}-4gb"      ; archive_img
wfile="BBBL-blank-\${base_rootfs}-4gb"     ; archive_img

###lxqt-2gb image (stretch):
base_rootfs="${debian_stretch_lxqt_2gb}" ; blend="stretch-lxqt-2gb"

wfile="bone-\${base_rootfs}-2gb"           ; archive_img
wfile="BBB-blank-\${base_rootfs}-2gb"      ; archive_img

###lxqt image (stretch):
base_rootfs="${debian_stretch_lxqt}" ; blend="stretch-lxqt"

wfile="bbx15-\${base_rootfs}-4gb"          ; archive_img
wfile="bbx15-blank-\${base_rootfs}-4gb"    ; archive_img
wfile="bone-\${base_rootfs}-4gb"           ; archive_img
wfile="BBB-blank-\${base_rootfs}-4gb"      ; archive_img

###lxqt-xm image (stretch):
base_rootfs="${debian_stretch_lxqt_xm}" ; blend="stretch-lxqt-xm"

wfile="bbxm-\${base_rootfs}-4gb"      ; archive_img

### wayland image (stretch):
base_rootfs="${debian_stretch_wayland}" ; blend="stretch-wayland"

wfile="bbx15-\${base_rootfs}-4gb"      ; archive_img
wfile="bone-\${base_rootfs}-4gb"       ; archive_img

###iot image (buster):
base_rootfs="${debian_buster_iot}" ; blend="buster-iot"

wfile="bbx15-\${base_rootfs}-4gb"          ; archive_img
wfile="bone-\${base_rootfs}-4gb"           ; archive_img
wfile="BBB-blank-\${base_rootfs}-4gb"      ; archive_img

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
