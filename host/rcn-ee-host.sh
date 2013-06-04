#!/bin/sh -e

system=$(uname -n)

case "${system}" in
hades|work-e6400)
	apt_proxy="192.168.0.10:3142/"
	mirror="http://rcn-ee.net/deb"
	;;
a53t|zeus|hestia|poseidon|panda-es-1gb-a3|imx6q-sabrelite-1gb-0|imx6q-sabrelite-1gb-1)
	apt_proxy="rcn-ee.homeip.net:3142/"
	mirror="http://rcn-ee.homeip.net:81/dl/mirrors/deb"
	;;
esac

RELEASE_HOST="imx6q-sabrelite-1gb-0"

