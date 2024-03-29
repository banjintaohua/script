#!/usr/bin/env bash
###
### Filename: disk_monitor.sh
### Author: banjintaohua
### Version: 1.0.0
###
### Description:
###   monitoring disk usage.
###
### Usage: disk_monitor.sh [options...]
###
### Options:
###   -h, --help         show help message.
###   -m, --mount-point  mount point
###   -t, --threshold    threshold

# 读取配置信息
MOUNT_POINT="/"
THRESHOLD=80
source "$(dirname "$0")"/config/config.sh

# 失败立即退出
set -e
set -o pipefail

# 使用说明
function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

# 磁盘使用率过高则发送告警
function main() {
    disk_usage=$(df -h | grep -e " $MOUNT_POINT$" | awk '{print $5}' | sed 's/%//g')
    if [[ $disk_usage -ge $THRESHOLD ]]; then
        local_ip=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}')
        curl --location --request POST "$BARK_URL" \
            --form "title=$local_ip $MOUNT_POINT disk usage reaches $disk_usage%" \
            --form "body=please release the disk space" \
            --form "group=monitor" > /dev/null 2>&1
    fi
}

# 解析脚本参数
args=$(
    getopt \
        --options hm:t: \
        --longoptions help,mount-point:,THRESHOLD: \
        -- "$@"
)
eval set -- "${args}"
test $# -le 1 && help && exit 1

# 处理脚本参数
while true; do
    case "$1" in
        -h | --help)
            help
            break
            ;;
        -m | --mount-point)
            MOUNT_POINT=$2
            shift 2
            ;;
        -t | --threshold)
            THRESHOLD=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "invalid argument";
            exit 1
            ;;
    esac
done

main
