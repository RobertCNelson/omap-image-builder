#!/bin/bash -e

# SPDX-FileCopyrightText: 2012 Robert Nelson <robertcnelson@gmail.com>
#
# SPDX-License-Identifier: MIT

DIR=$PWD

. "${DIR}/.project"

check_defines () {
	#http://linux.die.net/man/8/debootstrap

	unset options
	if [ ! "${deb_arch}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: deb_arch undefined"
		exit 1
	else
		options="--arch=${deb_arch}"
		if [ "x${deb_arch}" = "xriscv64" ] ; then
			options="${options} --no-check-gpg --no-check-certificate"
		fi
	fi

	if [ "${deb_include}" ] ; then
		include=$(echo ${deb_include} | sed 's/ /,/g' | sed 's/\t/,/g')

		if [ "${tasksel_lang}" ] ; then
			if [ "${tasksel_task}" ] ; then
				#Debian trixie: wtmpdb
				task_include="tasksel,apt-listchanges,${tasksel_task},${tasksel_lang},${include}"
			else
				task_include="tasksel,apt-listchanges,${tasksel_lang},${include}"
			fi
			include="${task_include}"
		fi

		options="${options} --include=ca-certificates,${include}"
	fi

	if [ "${deb_exclude}" ] ; then
		exclude=$(echo ${deb_exclude} | sed 's/ /,/g' | sed 's/\t/,/g')
		options="${options} --exclude=${exclude}"
	fi

	if [ "${deb_components}" ] ; then
		components=$(echo ${deb_components} | sed 's/ /,/g' | sed 's/\t/,/g')
		options="${options} --components=${components}"
	fi

	#https://manpages.debian.org/buster/debootstrap/debootstrap.8.en.html
	if [ "${deb_variant}" ] ; then
		#--variant=minbase|buildd|fakechroot|scratchbox
		options="${options} --variant=${deb_variant}"
	fi

	if [ ! "${deb_distribution}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: deb_distribution undefined"
		exit 1
	fi

	unset suite
	if [ ! "${deb_codename}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: deb_codename undefined"
		exit 1
	else
		suite="${deb_codename}"
	fi

	case "${deb_distribution}" in
	debian)
		if [ ! -f /usr/share/debootstrap/scripts/${suite} ] ; then
			sudo ln -s /usr/share/debootstrap/scripts/sid /usr/share/debootstrap/scripts/${suite}
		fi
		if [ ! -f /usr/share/keyrings/debian-archive-keyring.gpg ] ; then
			options="${options} --no-check-gpg"
		fi
		;;
	ubuntu)
		if [ ! -f /usr/share/debootstrap/scripts/${suite} ] ; then
			sudo ln -s /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/${suite}
		fi
		if [ ! -f /usr/share/keyrings/ubuntu-archive-keyring.gpg ] ; then
			options="${options} --no-check-gpg"
		fi
		;;
	esac
	options="${options} --foreign"

	unset target
	if [ ! "${tempdir}" ] ; then
		echo "scripts/deboostrap_first_stage.sh: Error: tempdir undefined"
		exit 1
	else
		target="${tempdir}"
	fi

	unset mirror
	if [ ! "${apt_proxy}" ] ; then
		apt_proxy=""
	fi
	if [ ! "${deb_mirror}" ] ; then
		case "${deb_distribution}" in
		debian)
			deb_mirror="deb.debian.org/debian"
			#if [ "x${deb_arch}" = "xriscv64" ] ; then
			#	deb_mirror="deb.debian.org/debian-ports"
			#fi
			;;
		ubuntu)
			deb_mirror="ports.ubuntu.com/"
			;;
		esac
	fi
	mirror="http://${apt_proxy}${deb_mirror}"
}

report_size () {
	echo "Log: Size of: [${tempdir}]: $(du -sh ${tempdir} 2>/dev/null | awk '{print $1}')"
}

check_defines

echo "Log: Creating: [${deb_distribution}] [${deb_codename}] image for: [${deb_arch}]"

if [ "${apt_proxy}" ] ; then
	echo "Log: using apt proxy: [${apt_proxy}]"
fi

echo "Log: Running: debootstrap in [${tempdir}]"

case "${deb_codename}" in
bookworm|trixie|forky|sid|jammy|lunar|mantic|noble)
	echo "Log: [sudo debootstrap ${options} ${suite} ${target} ${mirror}]"
	sudo debootstrap ${options} ${suite} "${target}" ${mirror}
	;;
*)
	###FIXME: --no-merged-usr eventually we will support, but as of 1.0.101+ it's back, so default to pre...
	echo "Log: [sudo debootstrap --no-merged-usr ${options} ${suite} ${target} ${mirror}]"
	sudo debootstrap --no-merged-usr ${options} ${suite} "${target}" ${mirror}
	;;
esac

report_size
#
