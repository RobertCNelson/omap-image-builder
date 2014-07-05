#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

./RootStock-NG.sh -c bb.org-console-debian-testing

debian_testing="debian-jessie-console-armhf-${time}"
archive="xz -z -8 -v"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

if [ -d ./${debian_testing} ] ; then
	rm -rf ${debian_testing} || true
fi

#user may run ./ship.sh twice...
if [ -f ${debian_testing}.tar.xz ] ; then
	tar xf ${debian_testing}.tar.xz
else
	tar xf ${debian_testing}.tar
fi

if [ -f bone-${debian_testing}-4gb.img ] ; then
	rm bone-${debian_testing}-4gb.img || true
fi

cd ${debian_testing}/

sudo ./setup_sdcard.sh --img-4gb bone-${debian_testing} --dtb beaglebone --beagleboard.org-production --boot_label BEAGLE_BONE

mv *.img ../
cd ..
rm -rf ${debian_testing}/ || true

if [ ! -f ${debian_testing}.tar.xz ] ; then
	${archive} ${debian_testing}.tar
fi

if [ -f bone-${debian_testing}-4gb.img.xz ] ; then
	rm bone-${debian_testing}-4gb.img.xz || true
fi
${archive} bone-${debian_testing}-4gb.img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ -d /mnt/farm/testing/pending/ ] ; then
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/testing/pending/gift_wrap_final_images.sh
	chmod +x /mnt/farm/testing/pending/gift_wrap_final_images.sh
	cp -v ${DIR}/deploy/*.tar /mnt/farm/testing/pending/
fi

