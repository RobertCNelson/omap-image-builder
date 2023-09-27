#!/usr/bin/env bash
#
# build single target in CI using matrix var arguments
#
# only positional args are allowed
#
#  $dist $suite $deb_arch
#

set -euo pipefail

failures=0
trap 'failures=$((failures+1))' ERR

DIST=${1:-ubuntu}
SUITE=${2:-""}
DEB_ARCH=${3:-arm64}
VERBOSE="false"  # set to "true" for extra output

time=$(date +%Y-%m-%d)
DIR="$PWD"
archive="xz -z -8 -v"

! [[ -n "SUITE" ]] && echo "Missing arg SUITE ..." && exit 1

if [[ "${DIST}" = "ubuntu" ]]; then
    if [[ "${SUITE}" = "bionic" ]]; then
        target="${DIST}-18.04.6"
    elif [[ "${SUITE}" = "focal" ]]; then
        target="${DIST}-20.04.6"
    elif [[ "${SUITE}" = "jammy" ]]; then
        target="${DIST}-22.04.3"
    fi
fi

echo "TARGET is: ${target}"
target_config="eewiki_minfs_${DIST}_${SUITE}_${DEB_ARCH}"
echo "CFG is: ${target_config}"
rootfs_tarball="${target}-minimal-${DEB_ARCH}-${time}.tar"
echo "ROOTFS is: ${rootfs_tarball}"

CMD="./RootStock-NG.sh -c ${target_config}"
echo "CMD is: ${CMD}"
echo ""

./RootStock-NG.sh -c ${target_config}

source .project
if [ ! -f ./deploy/${export_filename}.tar ] ; then
    echo "Error: deploy/${export_filename}.tar"
    exit 1
else
    echo "Compressing: deploy/${export_filename}.tar"
    sudo chown $(id -u):$(id -g) ./deploy/${export_filename}.tar || true
    ${archive} ./deploy/${export_filename}.tar
fi

if ((failures != 0)); then
    echo "Something went wrong !!!"
    exit 1
fi
