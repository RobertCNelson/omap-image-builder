#!/bin/bash -e

IMAGE_DIR_PREFIX=${IMAGE_DIR_PREFIX:-eewiki}

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.us/rootfs/eewiki"
DIR="$PWD"

export apt_proxy=proxy.gfnd.rcn-ee.org:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

if [ ! -f jenkins.build ] ; then
./RootStock-NG.sh -c eewiki_minfs_debian_buster_armel
./RootStock-NG.sh -c eewiki_minfs_debian_buster_armhf
./RootStock-NG.sh -c eewiki_minfs_ubuntu_focal_armhf
else
	mkdir -p ${DIR}/deploy/ || true
fi

debian_buster="debian-10.7"
ubuntu_stable="ubuntu-20.04.1"

xz_img="xz -z -8"
xz_tar="xz -T2 -z -8"

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
                                ${xz_tar} \${base_rootfs}.tar && sha256sum \${base_rootfs}.tar.xz > \${base_rootfs}.tar.xz.sha256sum &
                                cd -
                        fi
                fi
        fi
}

blend=minfs
base_rootfs="${debian_buster}-minimal-armel-${time}" ; copy_base_rootfs_to_mirror
base_rootfs="${debian_buster}-minimal-armhf-${time}" ; copy_base_rootfs_to_mirror

base_rootfs="${ubuntu_stable}-minimal-armhf-${time}" ; copy_base_rootfs_to_mirror

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

#x86: My Server...
if [ -f /opt/images/nas.FREENAS ] ; then
	sudo mkdir -p /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/ || true

	echo "Copying: *.tar to server: images/${IMAGE_DIR_PREFIX}-${time}/"
	sudo cp -v ${DIR}/deploy/gift_wrap_final_images.sh /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/gift_wrap_final_images.sh || true

	ls -lha /opt/images/wip/${IMAGE_DIR_PREFIX}-${time}/
fi
