#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

./RootStock-NG.sh -c rcn-ee_console_debian_stable_armhf
./RootStock-NG.sh -c rcn-ee_console_debian_testing_armhf

./RootStock-NG.sh -c rcn-ee_console_ubuntu_stable_armhf
./RootStock-NG.sh -c rcn-ee_console_ubuntu_testing_armhf

debian_stable="debian-7.7-console-armhf-${time}"
debian_testing="debian-jessie-console-armhf-${time}"

ubuntu_stable="ubuntu-14.04-console-armhf-${time}"
ubuntu_testing="ubuntu-utopic-console-armhf-${time}"
archive="xz -z -8 -v"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

${archive} ${ubuntu_stable}.tar
${archive} ${debian_stable}.tar

tar xf ${debian_stable}.tar.xz
tar xf ${ubuntu_stable}.tar.xz

cd ${debian_stable}/
sudo ./setup_sdcard.sh --img BBB-eMMC-flasher-${debian_stable} --dtb beaglebone --beagleboard.org-production --bbb-flasher --enable-systemd  --bbb-old-bootloader-in-emmc
sudo ./setup_sdcard.sh --img bone-${debian_stable} --dtb beaglebone --beagleboard.org-production --enable-systemd --bbb-old-bootloader-in-emmc
sudo ./setup_sdcard.sh --img bb-${debian_stable} --dtb omap3-beagle --enable-systemd
sudo ./setup_sdcard.sh --img bbxm-${debian_stable} --dtb omap3-beagle-xm --enable-systemd
sudo ./setup_sdcard.sh --img omap5-uevm-${debian_stable} --dtb omap5-uevm --enable-systemd
mv *.img ../
cd ..
rm -rf ${debian_stable}/ || true

cd ${ubuntu_stable}/
sudo ./setup_sdcard.sh --img BBB-eMMC-flasher-${ubuntu_stable}.img --dtb beaglebone --beagleboard.org-production --bbb-flasher  --bbb-old-bootloader-in-emmc
sudo ./setup_sdcard.sh --img bone-${ubuntu_stable}.img --dtb beaglebone --beagleboard.org-production --bbb-old-bootloader-in-emmc
sudo ./setup_sdcard.sh --img bb-${ubuntu_stable}.img --dtb omap3-beagle
sudo ./setup_sdcard.sh --img bbxm-${ubuntu_stable}.img --dtb omap3-beagle-xm
sudo ./setup_sdcard.sh --img omap5-uevm-${ubuntu_stable}.img --dtb omap5-uevm
mv *.img ../
cd ..
rm -rf ${ubuntu_stable}/ || true

${archive} ${ubuntu_testing}.tar
${archive} ${debian_testing}.tar

${archive} BBB-eMMC-flasher-${debian_stable}-2gb.img
${archive} bone-${debian_stable}-2gb.img
${archive} bb-${debian_stable}-2gb.img
${archive} bbxm-${debian_stable}-2gb.img
${archive} omap5-uevm-${debian_stable}-2gb.img
${archive} BBB-eMMC-flasher-${ubuntu_stable}-2gb.img
${archive} bone-${ubuntu_stable}-2gb.img
${archive} bb-${ubuntu_stable}-2gb.img
${archive} bbxm-${ubuntu_stable}-2gb.img
${archive} omap5-uevm-${ubuntu_stable}-2gb.img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ -d /mnt/farm/images/ ] ; then
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/gift_wrap_final_images.sh
	chmod +x /mnt/farm/images/gift_wrap_final_images.sh
	cp -v ${DIR}/deploy/*.tar /mnt/farm/images/
fi

