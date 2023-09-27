#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

./RootStock-NG.sh -c eewiki_minfs_ubuntu_focal_arm64.conf
./RootStock-NG.sh -c eewiki_minfs_ubuntu_bionic_arm64.conf

ubuntu_bionic="ubuntu-18.04.6"
ubuntu_focal="ubuntu-20.04.6"

archive="xz -z -8 -v"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

${archive} ${ubuntu_bionic}-minimal-arm64-${time}.tar
${archive} ${ubuntu_focal}-minimal-arm64-${time}.tar

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ ! -d /mnt/farm/images/ ] ; then
	#nfs mount...
	#sudo mount -a
	echo "NFS not available"
	cd ${DIR}/deploy
	./gift_wrap_final_images.sh
	cd -
fi

if [ -d /mnt/farm/images/ ] ; then
	mkdir /mnt/farm/images/eewiki-${time}/
	cp -v ${DIR}/deploy/*.tar /mnt/farm/images/eewiki-${time}/
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/eewiki-${time}/gift_wrap_final_images.sh
	chmod +x /mnt/farm/images/eewiki-${time}/gift_wrap_final_images.sh
fi
