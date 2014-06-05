#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

./RootStock-NG.sh -c rcn-ee_console_debian_stable_armhf
./RootStock-NG.sh -c rcn-ee_console_debian_testing_armhf

./RootStock-NG.sh -c rcn-ee_console_ubuntu_stable_armhf
./RootStock-NG.sh -c rcn-ee_console_ubuntu_testing_armhf

debian_stable="7.5"
debian_testing="jessie"

ubuntu_stable="14.04"
ubuntu_testing="utopic"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

xz -z -8 -v ubuntu-${ubuntu_stable}-console-armhf-${time}.tar
xz -z -8 -v debian-${debian_stable}-console-armhf-${time}.tar

tar xf debian-${debian_stable}-console-armhf-${time}.tar.xz
tar xf ubuntu-${ubuntu_stable}-console-armhf-${time}.tar.xz

cd debian-${debian_stable}-console-armhf-${time}/
sudo ./setup_sdcard.sh --img BBB-eMMC-flasher-debian-${debian_stable}-console-${time} --dtb beaglebone --beagleboard.org-production --bbb-flasher --enable-systemd
sudo ./setup_sdcard.sh --img bone-debian-${debian_stable}-console-${time} --dtb beaglebone --beagleboard.org-production --enable-systemd
sudo ./setup_sdcard.sh --img bbxm-debian-${debian_stable}-console-${time} --dtb omap3-beagle-xm --enable-systemd
mv *.img ../
cd ..
rm -rf debian-${debian_stable}-console-armhf-${time}/ || true

cd ubuntu-${ubuntu_stable}-console-armhf-${time}/
sudo ./setup_sdcard.sh --img BBB-eMMC-flasher-ubuntu-${ubuntu_stable}-console-${time}.img --dtb beaglebone --beagleboard.org-production --bbb-flasher
sudo ./setup_sdcard.sh --img bone-ubuntu-${ubuntu_stable}-console-${time}.img --dtb beaglebone --beagleboard.org-production
sudo ./setup_sdcard.sh --img bbxm-ubuntu-${ubuntu_stable}-console-${time}.img --dtb omap3-beagle-xm
mv *.img ../
cd ..
rm -rf ubuntu-${ubuntu_stable}-console-armhf-${time}/ || true

xz -z -8 -v ubuntu-${ubuntu_testing}-console-armhf-${time}.tar
xz -z -8 -v debian-${debian_testing}-console-armhf-${time}.tar

xz -z -8 -v BBB-eMMC-flasher-debian-${debian_stable}-console-${time}-2gb.img
xz -z -8 -v bone-debian-${debian_stable}-console-${time}-2gb.img
xz -z -8 -v bbxm-debian-${debian_stable}-console-${time}-2gb.img
xz -z -8 -v BBB-eMMC-flasher-ubuntu-${ubuntu_stable}-console-${time}-2gb.img
xz -z -8 -v bone-ubuntu-${ubuntu_stable}-console-${time}-2gb.img
xz -z -8 -v bbxm-ubuntu-${ubuntu_stable}-console-${time}-2gb.img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ -d /mnt/farm/testing/pending/ ] ; then
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/testing/pending/gift_wrap_final_images.sh
	chmod +x /mnt/farm/testing/pending/gift_wrap_final_images.sh
	cp -v ${DIR}/deploy/*.tar /mnt/farm/testing/pending/
fi

