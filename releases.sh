# Custom releases go in this file.  Each release should be a shell function
# following the pattern of the existing release functions in build_image.sh

# Override RCN 3.8 BeagleBone with Xenomai version
select_custom_kernel () {
	SUBARCH="omap"
	KERNEL_ABI="STABLE"
	kernel_chooser
	chroot_KERNEL_HTTP_DIR="${mirror}/${release}-${dpkg_arch}/${FTP_DIR}/"

	#SUBARCH="omap-psp"
	#KERNEL_ABI="TESTING"
	#kernel_chooser
	chroot_KERNEL_HTTP_DIR="${chroot_KERNEL_HTTP_DIR} http://www.machinekit.net/deb/wheezy-armhf/v3.8.13xenomai-bone23/"

	SUBARCH="omap-psp"
	KERNEL_ABI="STABLE"
	kernel_chooser
	chroot_KERNEL_HTTP_DIR="${chroot_KERNEL_HTTP_DIR} ${mirror}/${release}-${dpkg_arch}/${FTP_DIR}/"
}


machinekit_release () {
	image_type="machinekit"
	extra_pkgs="atmel-firmware firmware-ralink libertas-firmware zd1211-firmware nfs-common git-core build-essential autoconf libgd2-xpm libpth-dev dvipng tcl8.5-dev tk8.5-dev bwidget blt libxaw7-dev libncurses5-dev libreadline-dev asciidoc source-highlight dblatex xsltproc groff python-dev python-support python-tk python-lxml libglu1-mesa-dev libgl1-mesa-dev libgtk2.0-dev libgnomeprintui2.2-dev gettext libboost-python-dev texlive-lang-cyrillic libmodbus-dev libboost-thread-dev libboost-serialization-dev python-gtk2 python-gtk2-dev python-gtk2-doc python-gi python-gtksourceview2 python-imaging-tk python-notify2 python-vte python-xlib flex bison python-gtkglext1 python-serial ssh-askpass"
	#extra_pkgs="gitk git-gui"

	#is_debian - inlined below with some changes

	image_hostname="arm"
	distro="debian"
	user_name="linuxcnc"
	password="linuxcnc"
	full_name="Tux Chipcutter"
	chroot_hook="machinekit/chroot_hook.sh"

	deb_mirror="ftp.us.debian.org/debian/"
	deb_components="main contrib non-free"

	. ${DIR}/var/pkg_list.sh
	base_pkg_list="${base_pkgs} ${extra_pkgs}"

	#is_debian - end

	release="wheezy"
	select_custom_kernel
	minimal_armel
	compression
}
