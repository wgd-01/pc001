#!/bin/bash

set -e

Manifest=$1
RELEASE_TYPE=$2
DEVICE_MODEL=$3
cd "$Manifest"
catalogue=$(pwd)
if [ -d .repo ]; then
    echo "Existing repo workspace found, skip init and sync directly..."
    repo sync -c -j$(nproc)
    ln -sfn $catalogue/tools/linux/toolchain \
          /opt/toolchain || true
    ll /opt/toolchain
else
    echo "Initializing repo workspace..."
    printf "auto\n" | repo init  -u https://github.com/DesignLibro/Firmware-manifests.git \
              -b master \
              -m $DEVICE_MODEL/$Manifest

    repo sync -c -j$(nproc)
    ln -sfn $catalogue/tools/linux/toolchain \
          /opt/toolchain || true
    ll /opt/toolchain
fi


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
    tar -cf $catalogue/output/$TAR_FILE -C $catalogue/output/image .
    echo "RELEASE 版本打包完成"

else
    echo "ERROR: RELEASE_TYPE must be SNAPSHOT or RELEASE"
    exit 1
fi

