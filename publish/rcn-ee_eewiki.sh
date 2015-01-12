#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

./RootStock-NG.sh -c eewiki_bare_debian_stable_armel
./RootStock-NG.sh -c eewiki_bare_debian_stable_armhf

./RootStock-NG.sh -c eewiki_minfs_debian_stable_armel
./RootStock-NG.sh -c eewiki_minfs_debian_stable_armhf
./RootStock-NG.sh -c eewiki_minfs_debian_testing_armhf
./RootStock-NG.sh -c eewiki_minfs_ubuntu_stable_armhf

debian_stable="debian-7.8"
debian_testing="debian-jessie"
ubuntu_stable="ubuntu-14.04.1"
archive="xz -z -8 -v"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

${archive} ${debian_stable}-bare-armel-${time}.tar
${archive} ${debian_stable}-bare-armhf-${time}.tar

${archive} ${debian_stable}-minimal-armel-${time}.tar
${archive} ${debian_stable}-minimal-armhf-${time}.tar
${archive} ${debian_testing}-minimal-armhf-${time}.tar

${archive} ${ubuntu_stable}-minimal-armhf-${time}.tar

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ -d /mnt/farm/images/ ] ; then
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/gift_wrap_final_images.sh
	chmod +x /mnt/farm/images/gift_wrap_final_images.sh
	cp -v ${DIR}/deploy/*.tar /mnt/farm/images/
fi

