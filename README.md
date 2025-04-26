# cron-update-reboot
weekly change timezone to asia/shang and update system and reboot every weekly


部署与使用说明
安装脚本

bash

sudo curl -o /usr/local/bin/server-maintenance.sh https://raw.githubusercontent.com/rbobowang/cron-update-reboot/refs/heads/main/vps-mauntenace-weekly.sh

sudo chmod +x /usr/local/bin/server-maintenance.sh

设置定时任务（每周日凌晨3点）

bash

sudo tee /etc/cron.d/server-maintenance <<'EOF'

# 时区设置为亚洲/上海
TZ=Asia/Shanghai

# 每周日凌晨3点执行
0 3 * * 0 root /usr/local/bin/server-maintenance.sh
EOF

# 重载cron配置
sudo systemctl reload cron
