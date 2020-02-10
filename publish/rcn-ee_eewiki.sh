#!/bin/bash -e

OIB_USER=${OIB_USER:-1000}

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.us/rootfs/eewiki"
DIR="$PWD"

export apt_proxy=proxy.gfnd.rcn-ee.org:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

if [ ! -f jenkins.build ] ; then
./RootStock-NG.sh -c eewiki_minfs_debian_stretch_armel
./RootStock-NG.sh -c eewiki_minfs_debian_stretch_armhf
./RootStock-NG.sh -c eewiki_minfs_debian_buster_armel
./RootStock-NG.sh -c eewiki_minfs_debian_buster_armhf
./RootStock-NG.sh -c eewiki_minfs_ubuntu_bionic_armhf
else
	mkdir -p ${DIR}/deploy/ || true
fi

debian_stretch="debian-9.12"
debian_buster="debian-10.3"
ubuntu_stable="ubuntu-18.04.3"

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
base_rootfs="${debian_stretch}-minimal-armel-${time}" ; copy_base_rootfs_to_mirror
base_rootfs="${debian_stretch}-minimal-armhf-${time}" ; copy_base_rootfs_to_mirror

base_rootfs="${debian_buster}-minimal-armel-${time}" ; copy_base_rootfs_to_mirror
base_rootfs="${debian_buster}-minimal-armhf-${time}" ; copy_base_rootfs_to_mirror

base_rootfs="${ubuntu_stable}-minimal-armhf-${time}" ; copy_base_rootfs_to_mirror

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

image_prefix="eewiki"
#node:
if [ ! -d /var/www/html/farm/images/ ] ; then
	if [ ! -d /mnt/farm/images/ ] ; then
		#nfs mount...
		sudo mount -a
	fi

	if [ -d /mnt/farm/images/ ] ; then
		if [ ! -d /mnt/farm/images/${image_prefix}-${time}/ ] ; then
			echo "mkdir: /mnt/farm/images/${image_prefix}-${time}/"
			mkdir -p /mnt/farm/images/${image_prefix}-${time}/ || true
		fi

		echo "Copying: *.tar to server: images/${image_prefix}-${time}/"
		cp -v ${DIR}/deploy/*.tar /mnt/farm/images/${image_prefix}-${time}/ || true
		cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
		sudo chmod +x /mnt/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
		sudo chown -R ${OIB_USER}:${OIB_USER} /var/www/html/farm/images/${image_prefix}-${time}/ || true
	fi
fi

#x86:
if [ -d /var/www/html/farm/images/ ] ; then
	mkdir -p /var/www/html/farm/images/${image_prefix}-${time}/ || true

	echo "Copying: *.tar to server: images/${image_prefix}-${time}/"
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /var/www/html/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true

	sudo chown -R ${OIB_USER}:${OIB_USER} /var/www/html/farm/images/${image_prefix}-${time}/ || true
	sudo chmod +x /var/www/html/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
	sudo chmod g+wr /var/www/html/farm/images/${image_prefix}-${time}/ || true
	ls -lha /var/www/html/farm/images/${image_prefix}-${time}/
fi
