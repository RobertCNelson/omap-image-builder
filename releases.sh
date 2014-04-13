# Custom releases go in this file.  Each release should be a shell function
# following the pattern of the existing release functions in build_image.sh

# Override RCN 3.8 BeagleBone with Xenomai version
select_machinekit_kernel () {
	SUBARCH="omap-psp"
	KERNEL_ABI="STABLE"
	#kernel_chooser
	#chroot_KERNEL_HTTP_DIR="${mirror}/${deb_codename}-${deb_arch}/${FTP_DIR}/"
	chroot_KERNEL_HTTP_DIR="${chroot_KERNEL_HTTP_DIR} http://www.machinekit.net/deb/wheezy-armhf/v3.8.13xenomai-bone47/"
}

machinekit_pkg_list () {
	base_pkg_list=""
	if [ ! "x${no_pkgs}" = "xenable" ] ; then
		. ${DIR}/machinekit/pkg_list.sh

		deb_include="git-core,initramfs-tools,locales,sudo,wget"

		if [ "x${include_firmware}" = "xenable" ] ; then
			base_pkg_list="${base_pkgs} ${extra_pkgs} ${bborg_pkg_list} ${firmware_pkgs}"
		else
			base_pkg_list="${base_pkgs} ${extra_pkgs} ${bborg_pkg_list}"
		fi
		base_pkg_list=$(echo ${base_pkg_list} | sed 's/  / /g')
	fi
}

machinekit_release () {
	image_type="machinekit"
	#extra_pkgs="systemd"
	extra_pkgs="systemd nfs-common git-core build-essential autoconf libgd2-xpm libpth-dev dvipng tcl8.5-dev tk8.5-dev bwidget blt libxaw7-dev libncurses5-dev libreadline-dev asciidoc source-highlight dblatex xsltproc groff python-dev python-support python-tk python-lxml libglu1-mesa-dev libgl1-mesa-dev libgtk2.0-dev libgnomeprintui2.2-dev gettext libboost-python-dev texlive-lang-cyrillic libmodbus-dev libboost-thread-dev libboost-serialization-dev python-gtk2 python-gtk2-dev python-gtk2-doc python-gi python-gtksourceview2 python-imaging-tk python-notify2 python-vte python-xlib flex bison python-gtkglext1 python-serial libusb-1.0-0-dev libtk-img"

	firmware_pkgs="atmel-firmware firmware-ralink firmware-realtek libertas-firmware zd1211-firmware"

	#is_debian - inlined below with some changes

	deb_distribution="debian"

	rfs_hostname="beaglebone"
	rfs_username="machinekit"
	rfs_password="machinekit"
	rfs_fullname="Tux Chipcutter"
	chroot_hook="machinekit/chroot_hook.sh"

	deb_mirror="ftp.us.debian.org/debian/"

	#pkg_list
	machinekit_pkg_list
	deb_exclude=""
	deb_components="main contrib non-free"
	#is_debian - end

	deb_codename="wheezy"
	#select_rcn_ee_net_kernel
	select_machinekit_kernel
	minimal_armel
	compression
}

