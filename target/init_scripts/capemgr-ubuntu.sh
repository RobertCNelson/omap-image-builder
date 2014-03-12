start on runlevel 2

script

if test -f /etc/default/capemgr; then
	. /etc/default/capemgr
fi

capemgr=$(ls /sys/devices/bone_capemgr.*/slots 2> /dev/null || true)

if [ ! "x${CAPE}" = "x" ] ; then
	if [ ! "x${capemgr}" = "x" ] ; then
		echo ${CAPE} > ${capemgr}
	fi
fi

end script
