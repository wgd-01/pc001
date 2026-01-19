#!/bin/bash

set -e

Manifest=$1
RELEASE_TYPE=$2
DEVICE_MODEL=$3
mkdir -p "$Manifest" && cd "$Manifest"
if [ -d .repo ]; then
    echo "Existing repo workspace found, skip init and sync directly..."
    repo sync -c -j$(nproc)
else
    echo "Initializing repo workspace..."
    printf "auto\n" | repo init  -u https://github.com/DesignLibro/Firmware-manifests.git \
              -b master \
              -m $DEVICE_MODEL/$Manifest

    repo sync -c -j$(nproc)
    catalogue=$(pwd)
    ln -s $catalogue/tools/linux/toolchain \
          $catalogue/toolchain
fi

[ -d output ] && rm -rf output

bash build.sh all

TS=$(date +%Y%m%d%H%M%S)

if [[ "${RELEASE_TYPE}" == "SNAPSHOT" ]]; then
    SRC=$catalogue/output/image/update_ota.tar
    [[ -f $SRC ]] || { echo "ERROR: $SRC not found"; exit 1; }
    mv -v "$SRC" "$catalogue/output/image/update_ota-SNAPSHOT-${TS}.tar"
    mv $catalogue/output/image/update_ota-SNAPSHOT-${TS}.tar $catalogue/output/
    echo "SNAPSHOT 版本打包完成"
elif [[ "${RELEASE_TYPE}" == "RELEASE" ]]; then
    TAR_FILE="image-RELEASE-${TS}.tar"
    tar -C output -cf "$TAR_FILE" image
    echo "RELEASE 版本打包完成"

else
    echo "ERROR: RELEASE_TYPE must be SNAPSHOT or RELEASE"
    exit 1
fi

