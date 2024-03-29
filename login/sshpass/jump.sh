#!/bin/bash

# 查看跳板机隧道
function jump_proxy_list() {
    line=$(netstat -an | grep -c -E "$JUMP_BIND_HOST.($JUMP_PROXY_PORT).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo '未设置跳板机隧道'
    else
        echo "已设置跳板机隧道"
        netstat -an | grep -E "$JUMP_BIND_HOST.($JUMP_PROXY_PORT).*LISTEN"
    fi
    return "$line"
}

# 关闭跳板机隧道
function jump_proxy_kill() {
    netstat -an | grep -E "($JUMP_PROXY_PORT).*LISTEN"
    ps axu | grep -E "ssh.*$JUMP_BIND_HOST:$JUMP_PROXY_PORT" | grep -v grep | awk '{print $2}' | xargs -I {} kill {}
    line=$(netstat -an | grep -c -E "($JUMP_PROXY_PORT).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo '清理跳板机隧道成功'
    else
        echo "清理跳板机隧道失败"
    fi
}

# 手动创建跳板机隧道
function jump_proxy_login() {
    ssh "$JUMP_SERVER_USER@$JUMP_SERVER" -p "$JUMP_SERVER_PORT" \
        -o "ServerAliveInterval=60" \
        -o 'StrictHostKeyChecking=no' \
        -o 'UserKnownHostsFile=/dev/null' \
        -f -q -N -D "$JUMP_BIND_HOST:$JUMP_PROXY_PORT"
}

# 设置跳板机的代理
function set_jump_proxy() {
    jump_proxy_list
    line=$?
    if [[ $line -eq 0 ]]; then
        jump_proxy_kill

        # 删除原始记录
        sed -in "s/.*$JUMP_SERVER.*//g" ~/.ssh/known_hosts
        sed -in '/^$/d' ~/.ssh/known_hosts
        if [[ $(grep -c "$JUMP_SERVER" < ~/.ssh/known_hosts) -ge 1 ]]; then
            # 通过 ssh-keygen 会有各种转义的问题，改为使用 sed
            # ssh-keygen -R "[$JUMP_SERVER]:$JUMP_SERVER_PORT"
            echo "sed -in \"s/.*$JUMP_SERVER.*//g\" ~/.ssh/known_hosts | sed -in \"/^$/d\""
            grep "$JUMP_SERVER" < ~/.ssh/known_hosts
        fi

        echo "正在设置跳板机隧道"
        sshpass -p "$JUMP_SERVER_PASSWORD" \
            ssh "$JUMP_SERVER_USER@$JUMP_SERVER" -p "$JUMP_SERVER_PORT" \
            -o "ServerAliveInterval=60" \
            -o 'StrictHostKeyChecking=no' \
            -o 'UserKnownHostsFile=/dev/null' \
            -f -q -N -D "$JUMP_BIND_HOST:$JUMP_PROXY_PORT" \
        > /dev/null 2>&1

        clear

        if [[ $(netstat -an | grep -c "$JUMP_BIND_HOST.$JUMP_PROXY_PORT") -lt 1 ]]; then
            echo "设置跳板机隧道失败"
            exit
        else
            echo "执行 : jump list 查看隧道"
            echo "执行 : jump kill 删除隧道"
        fi
    fi
    echo '已设置跳板机隧道'
}

# 读取服务器信息
source "$(dirname "$0")"/config/config.sh

# 判断执行的命令
if [[ $# == 1 ]]; then
    case $1 in
        list)
            jump_proxy_list
            ;;
        kill)
            jump_proxy_kill
            ;;
        login)
            jump_proxy_login
            ;;
        *)
            echo '参数非法'
            ;;
    esac
else
    set_jump_proxy "$JUMP_PROXY_PORT"
fi
