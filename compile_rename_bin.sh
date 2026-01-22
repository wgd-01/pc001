#!/bin/bash

set -e

Manifest=$1
RELEASE_TYPE=$2
DEVICE_MODEL=$3
TAG="${TAG:-}"
cd "$Manifest"
catalogue=$(pwd)
echo "TAG = '${TAG}'"

init_repo() {
    printf "auto\n" | repo init \
        -u https://github.com/DesignLibro/Firmware-manifests.git \
        -b master \
        -m "$DEVICE_MODEL/$Manifest"

    repo sync -c -j$(nproc)
}

sync_repo() {
    cd .repo/manifests
    git pull
    cd -

    repo sync -c -j$(nproc)
}

checkout_tag_if_needed() {
    if [ -n "$TAG" ]; then
        echo "Checking out TAG: $TAG"
        repo forall -c "git checkout $TAG"
    else
        echo "TAG is empty, skip checkout"
    fi
}

setup_toolchain() {
#    ln -sfn "$catalogue/tools/linux/toolchain" /opt/toolchain || true
    cp -rd $catalogue/tools/linux/toolchain /opt/ 
#    echo "export PATH=/opt/toolchain/arm-rockchip830-linux-gnueabihf/bin:$PATH" >> ~/.bashrc
#    source ~/.bashrc
    TOOLCHAIN_ROOT="/opt/toolchain"

    for tc in "$TOOLCHAIN_ROOT"/*; do
        if [ -d "$tc/bin" ]; then
            export PATH="$tc/bin:$PATH"
        fi
    done
    if ! which arm-rockchip1240-linux-gnueabihf-gcc >/dev/null 2>&1; then
       echo "❌ 没有找到 arm-rockchip1240-linux-gnueabihf-gcc"
       exit 1
    else
        echo "✅ 找到 arm-rockchip1240-linux-gnueabihf-gcc: $(which arm-rockchip1240-linux-gnueabihf-gcc)"
    fi
    which aarch64-rockchip1240-linux-gnu-gcc
}

if [ -d .repo ]; then
    echo "Existing repo workspace found"
    sync_repo
    setup_toolchain
    checkout_tag_if_needed
else
    echo "Repo workspace not found, initializing..."
    init_repo
    setup_toolchain
    checkout_tag_if_needed

fi




#if [ -d .repo ]; then
#    echo "Existing repo workspace found, skip init and sync directly..."
#    cd .repo/manifests
#    git pull
#    cd -
#    repo sync -c -j$(nproc)
#    ln -sfn $catalogue/tools/linux/toolchain \
#          /opt/toolchain || true
#    ls -l /opt/toolchain
#else
#    echo "Initializing repo workspace..."
#    printf "auto\n" | repo init  -u https://github.com/DesignLibro/Firmware-manifests.git \
#              -b master \
#              -m $DEVICE_MODEL/$Manifest
#
#    repo sync -c -j$(nproc)
#    ln -sfn $catalogue/tools/linux/toolchain \
#          /opt/toolchain || true
#    ls -l /opt/toolchain
#fi


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
    update_otamd5=$(md5sum $catalogue/output/image/update_ota.tar | awk '{print $1}')
    touch $catalogue/output/image/update_ota_$update_otamd5
    update_md5=$(md5sum $catalogue/output/image/update.img | awk '{print $1}')
    touch $catalogue/output/image/update_$update_md5
    tar -cf $catalogue/output/$TAR_FILE -C $catalogue/output/image .
    echo "RELEASE 版本打包完成"

else
    echo "ERROR: RELEASE_TYPE must be SNAPSHOT or RELEASE"
    exit 1
fi

