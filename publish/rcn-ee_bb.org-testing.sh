#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

./RootStock-NG.sh -c bb.org-console-debian-testing

debian_stable="jessie"
image="console"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

if [ -d ./debian-${debian_stable}-${image}-armhf-${time} ] ; then
	rm -rf debian-${debian_stable}-${image}-armhf-${time} || true
fi

#user may run ./ship.sh twice...
if [ -f debian-${debian_stable}-${image}-armhf-${time}.tar.xz ] ; then
	tar xf debian-${debian_stable}-${image}-armhf-${time}.tar.xz
else
	tar xf debian-${debian_stable}-${image}-armhf-${time}.tar
fi

if [ -f bone-debian-${debian_stable}-${image}-${time}-4gb.img ] ; then
	rm bone-debian-${debian_stable}-${image}-${time}-4gb.img || true
fi

cd debian-${debian_stable}-${image}-armhf-${time}/

sudo ./setup_sdcard.sh --img-4gb bone-debian-${debian_stable}-${image}-${time} --dtb beaglebone-microsdx --beagleboard.org-production --boot_label BEAGLE_BONE 

mv *.img ../
cd ..
rm -rf debian-${debian_stable}-${image}-armhf-${time}/ || true

if [ ! -f debian-${debian_stable}-${image}-armhf-${time}.tar.xz ] ; then
	xz -z -8 -v debian-${debian_stable}-${image}-armhf-${time}.tar
fi

if [ -f bone-debian-${debian_stable}-${image}-${time}-4gb.img.xz ] ; then
	rm bone-debian-${debian_stable}-${image}-${time}-4gb.img.xz || true
fi
xz -z -8 -v bone-debian-${debian_stable}-${image}-${time}-4gb.img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ -d /mnt/farm/testing/pending/ ] ; then
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/testing/pending/gift_wrap_final_images.sh
	chmod +x /mnt/farm/testing/pending/gift_wrap_final_images.sh
	cp -v ${DIR}/deploy/*.tar /mnt/farm/testing/pending/
fi

