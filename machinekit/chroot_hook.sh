echo "LOG: machinekit chroot hook script"

echo "chroot: ${tempdir}"

echo "userid: ${rfs_username}:${rfs_password}"

#xenomai_gid="$(sed -n '/xenomai/{s/^[^:]*:[^:]*:\([^:]*\):.*/\1/;p;}' /etc/group)"
#echo "xenomai gid: ${xenomai_gid}"

sudo rsync -va ${DIR}/machinekit/scripts/* ${tempdir}/tmp/

for SCRIPT in ${tempdir}/tmp/[0-9][0-9][0-9]* ; do
	case "$SCRIPT" in
	*.shr)	sudo chroot ${tempdir} /bin/sh  ${SCRIPT#$tempdir} ${rfs_username}
		;;
	*.shu)	sudo chroot ${tempdir} /bin/su  ${rfs_username} -c ${SCRIPT#$tempdir}
		;;
	*.sh)	. ${SCRIPT}
		;;
	*)	echo "Log: Unknown script format: ${SCRIPT}"
		;;
	esac
done

# Copy custom uEnv.txt file to destination, which will prevent the 
# setup_sdcard.sh script from using it's default version
cp ${DIR}/machinekit/uEnv.txt ${DIR}/deploy/${export_filename}/

