#!/bin/bash

RAMTMP_TEST=$(cat /etc/default/tmpfs | grep -v "#" | grep RAMTMP | awk -F"=" '{print $2}')
if [ -f /etc/default/tmpfs ] ; then
	if [ "x${RAMTMP_TEST}" == "xyes" ] ; then
		echo ""
		echo "ERROR"
		echo "With RAMTMP=yes this script will fail..."
		echo "Please modify /etc/default/tmpfs and set RAMTMP=no and reboot."
		echo ""
		exit
	fi
fi

