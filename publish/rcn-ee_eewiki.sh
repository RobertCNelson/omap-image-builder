#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

./RootStock-NG.sh -c eewiki_bare_debian_jessie_armel
./RootStock-NG.sh -c eewiki_bare_debian_jessie_armhf

./RootStock-NG.sh -c eewiki_minfs_debian_jessie_armel
./RootStock-NG.sh -c eewiki_minfs_debian_jessie_armhf
./RootStock-NG.sh -c eewiki_minfs_ubuntu_trusty_armhf

debian_jessie="debian-8.0"
ubuntu_stable="ubuntu-14.04.2"
archive="xz -z -8 -v"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

${archive} ${debian_jessie}-bare-armel-${time}.tar
${archive} ${debian_jessie}-bare-armhf-${time}.tar

${archive} ${debian_jessie}-minimal-armel-${time}.tar
${archive} ${debian_jessie}-minimal-armhf-${time}.tar

${archive} ${ubuntu_stable}-minimal-armhf-${time}.tar

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ -d /mnt/farm/images/ ] ; then
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/gift_wrap_final_images.sh
	chmod +x /mnt/farm/images/gift_wrap_final_images.sh
	cp -v ${DIR}/deploy/*.tar /mnt/farm/images/
fi

