echo "LOG: machinekit chroot hook script"

echo "chroot: ${tempdir}"

echo "userid: ${rfs_username}:${rfs_password}"

sudo rsync -va ${DIR}/machinekit/scripts/* ${tempdir}/tmp/ || true

for SCRIPT in ${tempdir}/tmp/[0-9][0-9][0-9]* ; do
	case "$SCRIPT" in
	# Run script as root on the new image
	*.shr)	time sudo chroot ${tempdir} /bin/sh  ${SCRIPT#$tempdir} ${rfs_username}
		;;

	# Run script as user on the new image
	*.shu)	time sudo chroot ${tempdir} /bin/su  ${rfs_username} -c ${SCRIPT#$tempdir}
		;;

	# Run script on the build host, which can see both filesystems
	*.sh)	. ${SCRIPT}
		;;

	*)	echo "Log: Unknown script format: ${SCRIPT}"
		;;
	esac
done

# Copy custom uEnv.txt file to destination, which will prevent the 
# setup_sdcard.sh script from using it's default version
#cp ${DIR}/machinekit/uEnv.txt ${DIR}/deploy/${export_filename}/

