#!/bin/sh -e
### BEGIN INIT INFO
# Provides:          generic-boot-script.sh
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO

case "$1" in
start|reload|force-reload|restart)

	#Let systemd-timesyncd control the clock updates...
	if [ ! -f /lib/systemd/systemd-timesyncd ] ; then

		#This script is to just get the (non-battery backed up) rtc 'in the ballbark'..
		#Usually it will be around a month at most off, vs 40-ish years...
		#/etc/timestamp is set via:
		#date --utc "+%4Y%2m%2d%2H%2M" > /etc/timestamp

		if [ -f /etc/timestamp ] ; then
			systemdate=$(/bin/date --utc "+%4Y%2m%2d%2H%2M")
			timestamp=$(cat /etc/timestamp)

			if [ ${timestamp} -gt ${systemdate} ] ; then
				year=$(cat /etc/timestamp | cut -b 1-4)
				month=$(cat /etc/timestamp | cut -b 5-6)
				day=$(cat /etc/timestamp | cut -b 7-8)
				hour=$(cat /etc/timestamp | cut -b 9-10)
				min=$(cat /etc/timestamp | cut -b 11-12)

				#/bin/date --utc -s "10/08/2008 11:37:23"
				/bin/date --utc -s "${month}/${day}/${year} ${hour}:${min}:00"
				/sbin/hwclock --systohc || true
			fi
		fi
	fi

	#Regenerate ssh host keys
	if [ -f /etc/ssh/ssh.regenerate ] ; then
		rm -rf /etc/ssh/ssh_host_* || true
		dpkg-reconfigure openssh-server
		sync
		if [ -s /etc/ssh/ssh_host_ecdsa_key.pub ] ; then
			rm -f /etc/ssh/ssh.regenerate || true
			sync
		fi
		if [ -f /etc/init.d/ssh ] ; then
			/etc/init.d/ssh restart
		fi
	fi

	if [ -f /opt/scripts/boot/generic-startup.sh ] ; then
		/bin/sh /opt/scripts/boot/generic-startup.sh >/dev/null 2>&1 &
	fi

	;;
stop)
	exit 0
	;;
*)
	echo "Usage: /etc/init.d/generic-boot-script.sh {start|stop|reload|restart|force-reload}"
	exit 1
	;;
esac

exit 0
