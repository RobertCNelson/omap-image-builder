#!/bin/bash

export apt_proxy=proxy.gfnd.rcn-ee.org:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

./RootStock-NG.sh -c bb.org-debian-buster-console-v4.19
./RootStock-NG.sh -c octavo-debian-buster-console-v4.19
./RootStock-NG.sh -c bb.org-debian-bullseye-console-v5.10-ti-armhf
./RootStock-NG.sh -c bb.org-debian-bullseye-console-arm64
./RootStock-NG.sh -c bb.org-debian-sid-console-riscv64

if [ -d ./ignore ] ; then
	sudo rm -rf ./ignore || true
fi
