#!/bin/bash
# usage: ./upload_cos.sh <设备型号> <固件文件>
set -e

DEVICE_MODEL=$1
RELEASE_TYPE=$2
Manifest=$3
cd "$Manifest"
FIRMWARE_FILE=$(ls output/*.tar 2>/dev/null | head -n1)


if [[ -z "$FIRMWARE_FILE" ]]; then
  echo "错误：当前目录未找到 固件文件！"
  exit 2
fi

if [[ ! -f "$FIRMWARE_FILE" ]]; then
  echo "错误：文件 $FIRMWARE_FILE 不存在！"
  exit 3
fi



# 可改常量
COS_BUCKET=${COS_BUCKET:-embedded-test-yanny-1319977552}
COS_REGION=${COS_REGION:-ap-guangzhou}



# 上传

REMOTE_PATH="embedded/$RELEASE_TYPE/${DEVICE_MODEL}/$(basename "$FIRMWARE_FILE")"
echo "====== 开始上传 ======"
echo "本地文件 : $FIRMWARE_FILE"
echo "远程路径 : cos://${COS_BUCKET}/${REMOTE_PATH}"

coscmd upload "$FIRMWARE_FILE" "$REMOTE_PATH"

echo "====== 上传完成 ======"

# 生成浏览器可直接打开的 https 下载地址
DOWNLOAD_URL="https://${COS_BUCKET}.cos.${COS_REGION}.myqcloud.com/${REMOTE_PATH}"
# 写入临时文件，供 Jenkins 下游步骤读取
echo "DOWNLOAD_URL=${DOWNLOAD_URL}" > download_url.properties
echo "FIRMWARE_NAME=$(basename "$FIRMWARE_FILE")" >> download_url.properties
