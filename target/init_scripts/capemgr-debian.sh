#!/bin/sh -e
### BEGIN INIT INFO
# Provides:          capemgr.sh
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO

if test -f /etc/default/capemgr; then
    . /etc/default/capemgr
fi

#CAPE="cape-bone-proto"

cape_list=$(echo ${CAPE} | sed "s/ //g" | sed "s/,/ /g")
capemgr=$(ls /sys/devices/bone_capemgr.*/slots 2> /dev/null || true)

load_overlay () {
	echo ${overlay} > ${capemgr}
}

case "$1" in
start)
	if [ ! "x${cape_list}" = "x" ] ; then
		if [ ! "x${capemgr}" = "x" ] ; then
			for overlay in ${cape_list} ; do load_overlay ; done
		fi
	fi
	;;
reload|force-reload|restart|stop)
	;;
*)
	echo "Usage: /etc/init.d/capemgr.sh {start|stop|reload|restart|force-reload}"
	exit 1
	;;
esac

exit 0
