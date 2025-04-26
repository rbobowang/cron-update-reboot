#!/bin/bash

# sudo nano /usr/local/bin/weekly-update-reboot.sh
# change timezone
# 查看当前时区
timedatectl

# 列出所有可用时区（查找 Asia/Shanghai）
timedatectl list-timezones | grep -i shanghai

sudo timedatectl set-timezone Asia/Shanghai
sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# 再次验证
timedatectl

# 记录日志（按日期归档）
LOG_DIR="/var/log/weekly-updates"
LOG_FILE="$LOG_DIR/update-$(date +'%Y-%m-%d').log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 函数：记录带时间戳的消息
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting weekly system update..."

# 更新包列表
apt-get update -y 2>&1 | tee -a "$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log "Error: apt-get update failed"
    exit 1
fi

# 执行安全升级（仅安装安全更新，更保守的选择）
#apt-get upgrade -y --only-upgrade-security 2>&1 | tee -a "$LOG_FILE"
#UPGRADE_STATUS=${PIPESTATUS[0]}

# 可选：完整升级（注释掉上面行，取消注释下面行）
apt-get dist-upgrade -y 2>&1 | tee -a "$LOG_FILE"
UPGRADE_STATUS=${PIPESTATUS[0]}

if [ $UPGRADE_STATUS -ne 0 ]; then
    log "Error: Package upgrade failed"
    exit 2
fi

# 清理旧包
apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE"

log "Update completed. Preparing to reboot..."

