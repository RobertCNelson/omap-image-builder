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

	#Resize drive when requested
	if [ -f /resizerootfs ] ; then
		drive=$(cat /resizerootfs)
		if [ ! "x${drive}" = "x" ] ; then
			if [ "x${drive}" = "x/dev/mmcblk0" ] || [ "x${drive}" = "x/dev/mmcblk1" ] ; then
				resize2fs ${drive}p2 >/var/log/resize.log 2>&1 || true
			else
				resize2fs ${drive} >/var/log/resize.log 2>&1 || true
			fi
		fi
		rm -rf /resizerootfs || true
	fi

	if [ -f /boot/SOC.sh ] ; then
		board=$(grep board /boot/SOC.sh | awk -F"=" '{print $2}')
		if [ -f "/opt/scripts/boot/${board}.sh" ] ; then
			/bin/sh /opt/scripts/boot/${board}.sh >/dev/null 2>&1 &
		fi
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
