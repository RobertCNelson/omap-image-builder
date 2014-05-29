#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

./RootStock-NG.sh -c eewiki_bare_debian_stable_armel
./RootStock-NG.sh -c eewiki_bare_debian_stable_armhf

./RootStock-NG.sh -c eewiki_minfs_debian_stable_armel
./RootStock-NG.sh -c eewiki_minfs_debian_stable_armhf
./RootStock-NG.sh -c eewiki_minfs_ubuntu_stable_armhf

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

xz -z -7 -v debian-7.5-bare-armel-${time}.tar
xz -z -7 -v debian-7.5-bare-armhf-${time}.tar

xz -z -7 -v debian-7.5-minimal-armel-${time}.tar
xz -z -7 -v debian-7.5-minimal-armhf-${time}.tar

xz -z -7 -v ubuntu-14.04-minimal-armhf-${time}.tar

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ -d /mnt/farm/testing/pending/ ] ; then
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/testing/pending/gift_wrap_final_images.sh
	chmod +x /mnt/farm/testing/pending/gift_wrap_final_images.sh
	cp -v ${DIR}/deploy/*.tar /mnt/farm/testing/pending/
fi

