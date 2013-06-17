echo "LOG: machinekit chroot hook script"

echo "chroot: ${tempdir}"

echo "userid: ${user_name}:${password}"

#xenomai_gid="$(sed -n '/xenomai/{s/^[^:]*:[^:]*:\([^:]*\):.*/\1/;p;}' /etc/group)"
#echo "xenomai gid: ${xenomai_gid}"

sudo rsync -va ${DIR}/machinekit/scripts/* ${tempdir}/tmp/

for SCRIPT in ${tempdir}/tmp/[0-9][0-9][0-9]* ; do
	case "$SCRIPT" in
	*.shr)	sudo chroot ${tempdir} /bin/sh  ${SCRIPT#$tempdir} ${user_name}
		;;
	*.shu)	sudo chroot ${tempdir} /bin/su  ${user_name} -c ${SCRIPT#$tempdir}
		;;
	*.sh)	. ${SCRIPT}
		;;
	*)	echo "Log: Unknown script format: ${SCRIPT}"
		;;
	esac
done

