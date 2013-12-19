#!/bin/sh -e

system=$(uname -n)

mirror="http://rcn-ee.net/deb"
case "${system}" in
poseidon|imx6q-sabrelite-1gb-0|imx6q-sabrelite-1gb-1|imx6q-wandboard-2gb-0|imx6q-wandboard-2gb-1)
	mirror="http://rcn-ee.homeip.net:81/dl/mirrors/deb"
	;;
esac

apt_proxy="apt-proxy:3142/"
RELEASE_HOST="imx6q-sabrelite-1gb-0"

