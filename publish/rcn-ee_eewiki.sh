#!/bin/bash -e

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.us/rootfs/eewiki"
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

./RootStock-NG.sh -c eewiki_bare_debian_jessie_armel
./RootStock-NG.sh -c eewiki_bare_debian_jessie_armhf

./RootStock-NG.sh -c eewiki_minfs_debian_jessie_armel
./RootStock-NG.sh -c eewiki_minfs_debian_jessie_armhf
./RootStock-NG.sh -c eewiki_minfs_ubuntu_xenial_armhf

debian_stable="debian-8.4"
ubuntu_stable="ubuntu-16.04"
archive="xz -z -8"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

copy_base_rootfs_to_mirror () {
        if [ -d ${mirror_dir}/ ] ; then
                if [ ! -d ${mirror_dir}/\${blend}/ ] ; then
                        mkdir -p ${mirror_dir}/\${blend}/ || true
                fi
                if [ -d ${mirror_dir}/\${blend}/ ] ; then
                        if [ ! -f ${mirror_dir}/\${blend}/\${base_rootfs}.tar.xz ] ; then
                                cp -v \${base_rootfs}.tar ${mirror_dir}/\${blend}/
                                cd ${mirror_dir}/\${blend}/
                                ${archive} \${base_rootfs}.tar && sha256sum \${base_rootfs}.tar.xz > \${base_rootfs}.tar.xz.sha256sum &
                                cd -
                        fi
                fi
        fi
}

blend=barefs
base_rootfs="${debian_stable}-bare-armel-${time}" ; copy_base_rootfs_to_mirror
base_rootfs="${debian_stable}-bare-armhf-${time}" ; copy_base_rootfs_to_mirror

blend=minfs
base_rootfs="${debian_stable}-minimal-armel-${time}" ; copy_base_rootfs_to_mirror
base_rootfs="${debian_stable}-minimal-armhf-${time}" ; copy_base_rootfs_to_mirror

base_rootfs="${ubuntu_stable}-minimal-armhf-${time}" ; copy_base_rootfs_to_mirror

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

