#!/bin/sh -e

system=$(uname -n)

mirror="https://rcn-ee.net/deb"
case "${system}" in
poseidon)
	mirror="http://rcn-ee.homeip.net:81/dl/mirrors/deb"
	;;
imx6q-sabrelite-1gb-0|imx6q-sabrelite-1gb-1|imx6q-wandboard-2gb-0|imx6q-wandboard-2gb-1)
	mirror="http://rcn-ee.homeip.net:81/dl/mirrors/deb"
	RELEASE_HOST="${system}"
	;;
esac

apt_proxy="apt-proxy:3142/"
#
