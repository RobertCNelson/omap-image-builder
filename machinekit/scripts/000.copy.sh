#!/bin/sh

# If we have a 'kickstart' image, copy the pre-compiled source tree as a tarball
for SOURCE in machinekit xenomai-2.6 dtc ; do

	if [ -d ~/beaglebone.kickstart/home/machinekit/${SOURCE} ] ; then
		sudo tar cf ${tempdir}/home/machinekit/kickstart.${SOURCE}.tar -C ~/beaglebone.kickstart/home/machinekit ${SOURCE}
	fi
done

