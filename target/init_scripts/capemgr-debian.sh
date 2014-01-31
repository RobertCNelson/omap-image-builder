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

case "$1" in
start)
	#FIXME: just a proof of concept..
	if [ ! "x${CAPE}" = "x" ] ; then
		capemgr=$(ls /sys/devices/bone_capemgr.*/slots 2> /dev/null)
		if [ ! "x${capemgr}" = "x" ] ; then
			echo ${CAPE} > ${capemgr}
		fi
	fi
	;;
reload|force-reload|restart|stop)
	exit 0
	;;
*)
	echo "Usage: /etc/init.d/capemgr.sh {start|stop|reload|restart|force-reload}"
	exit 1
	;;
esac

exit 0
