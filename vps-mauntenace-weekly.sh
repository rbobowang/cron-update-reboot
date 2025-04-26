#!/bin/bash
# 服务器维护脚本 - 时区检查 + 系统更新 + 智能重启
# 执行权限：sudo chmod +x /usr/local/bin/server-maintenance.sh

set -euo pipefail  # 严格错误处理

# 日志配置
LOG_DIR="/var/log/server-maintenance"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +'%Y-%m-%d').log"
exec > >(tee -a "$LOG_FILE") 2>&1

# 带时区的日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $1"
}

log "=== 启动系统维护任务 ==="

# ---------------------------
# 时区检查与设置
# ---------------------------
CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || {
    # 兼容没有timedatectl的系统
    ls -l /etc/localtime | awk -F'/' '{print $(NF-1)"/"$NF}' | cut -d'/' -f2-
})

DESIRED_TZ="Asia/Shanghai"

if [[ "$CURRENT_TZ" != "$DESIRED_TZ" ]]; then
    log "检测到时区未设置正确（当前：$CURRENT_TZ），正在修改..."
    
    # 优先使用timedatectl
    if command -v timedatectl &> /dev/null; then
        timedatectl set-timezone "$DESIRED_TZ"
    else
        ln -sf "/usr/share/zoneinfo/$DESIRED_TZ" /etc/localtime
    fi
    
    # 二次验证
    NEW_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || {
        ls -l /etc/localtime | awk -F'/' '{print $(NF-1)"/"$NF}' | cut -d'/' -f2-
    })
    
    if [[ "$NEW_TZ" == "$DESIRED_TZ" ]]; then
        log "时区已成功设置为 $DESIRED_TZ"
        apt-get install hwclock
        hwclock --systohc  # 同步硬件时钟
    else
        log "错误：时区设置失败！" >&2
        exit 1
    fi
else
    log "时区已正确配置为 $DESIRED_TZ"
fi

# ---------------------------
# 系统更新
# ---------------------------
log "开始系统更新..."
{
    apt-get update -y
    apt-get upgrade -y --only-upgrade-security
    apt-get autoremove -y --purge
} || {
    log "系统更新过程中出现错误！" >&2
    exit 2
}

# ---------------------------
# 重启判断
# ---------------------------
if [ -f /run/reboot-required ]; then
    log "检测到需要系统重启"
    REBOOT_TIME="+10"
    log "将在 $REBOOT_TIME 分钟后重启（UTC: $(date -d "+10 minutes" +'%H:%M')）"
    
    # 发送警告信息（所有登录用户可见）
    wall "警告：系统将于 $REBOOT_TIME 分钟后重启进行维护！"
    
    # 提交重启计划
    shutdown -r $REBOOT_TIME "计划维护重启"
else
    log "当前无需系统重启"
fi

log "=== 维护任务完成 ==="
