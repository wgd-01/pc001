# !/usr/bin/env python
# -*- encoding:utf-8 -*-

import requests
import os

JOB_NAME = os.getenv("JOB_NAME", "未知任务")
BUILD_USER = os.getenv("BUILD_USER", "未知")
GIT_BRANCH = os.getenv("GIT_BRANCH", "未知")
#BUILD_URL = os.getenv("BUILD_URL", "")
JOB_URL = os.getenv("JOB_URL")
BUILD_NUMBER = os.getenv("BUILD_NUMBER")
BUILD_STATUS = os.getenv("BUILD_STATUS", "FAILURE")

DOWNLOAD_URL = os.getenv("DOWNLOAD_URL")
FIRMWARE_NAME = os.getenv("FIRMWARE_NAME", "未知")

# 飞书 Webhook（注意：不要有空格）
WEBHOOK_URL = "https://open.feishu.cn/open-apis/bot/v2/hook/6521b95e-3d37-4e91-823f-379c774b0d8a"

# 状态样式
if BUILD_STATUS == "SUCCESS":
    title = f"【{JOB_NAME}】构建成功"
    header_color = "green"
else:
    title = f"【{JOB_NAME}】构建失败"
    header_color = "red"

# 文本内容
content = (
    f"**构建分支**：{GIT_BRANCH}\n"
    f"**构建用户**：{BUILD_USER}\n"
)

if BUILD_STATUS == "SUCCESS":
    content += f"**固件名称**：`{FIRMWARE_NAME}`"
else:
    content += "**失败原因**：构建或上传阶段失败"

# 按钮区
actions = []

if BUILD_STATUS == "SUCCESS" and DOWNLOAD_URL:
    actions.append({
        "tag": "button",
        "text": {
            "tag": "lark_md",
            "content": "下载固件"
        },
        "url": DOWNLOAD_URL,
        "type": "default"
    })

if BUILD_STATUS != "SUCCESS":
    actions.append({
        "tag": "button",
        "text": {
            "tag": "lark_md",
            "content": "查看构建日志"
        },
        "url": JOB_URL + BUILD_NUMBER + "/console",
        "type": "danger"
    })

payload = {
    "msg_type": "interactive",
    "card": {
        "config": {
            "wide_screen_mode": True
        },
        "header": {
            "title": {
                "tag": "plain_text",
                "content": title
            },
            "template": header_color
        },
        "elements": [
            {
                "tag": "div",
                "text": {
                    "tag": "lark_md",
                    "content": content
                }
            },
            {
                "tag": "action",
                "actions": actions
            }
        ]
    }
}

requests.post(WEBHOOK_URL, json=payload)

