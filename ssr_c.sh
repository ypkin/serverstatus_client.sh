#!/bin/bash
set -e

# 固定的服务地址
server_address="https://status.67890.de/report"

# 提示用户输入用户名和密码
read -p "请输入用户名（例如：h2）: " user_name
read -p "请输入密码（例如：p2）: " user_password

# 更新系统并安装必要插件
apt update -y && apt install -y curl socat wget nano unzip

# 创建工作目录
WORKSPACE="/opt/ServerStatus"
mkdir -p ${WORKSPACE}
cd ${WORKSPACE}

# 设置架构，默认为 x86_64。如果是 ARM，请修改为 "armv7" 或 "aarch64"
OS_ARCH="x86_64"

# 获取最新版本号
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/zdz/ServerStatus-Rust/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')

# 下载客户端文件
wget --no-check-certificate -qO "client-${OS_ARCH}-unknown-linux-musl.zip" "https://github.com/zdz/ServerStatus-Rust/releases/download/${latest_version}/client-${OS_ARCH}-unknown-linux-musl.zip"

# 解压缩
unzip -o "client-${OS_ARCH}-unknown-linux-musl.zip"

# 配置 systemd 服务
cat <<EOF > /etc/systemd/system/stat_client.service
[Unit]
Description=ServerStatus-Rust Client
After=network.target

[Service]
User=root
Group=root
Environment="RUST_BACKTRACE=1"
WorkingDirectory=/opt/ServerStatus
ExecStart=/opt/ServerStatus/stat_client -a "${server_address}" -u ${user_name} -p ${user_password}
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 服务文件
systemctl daemon-reload

# 启动服务
systemctl start stat_client

# 设置开机自启
systemctl enable stat_client

# 显示服务状态
echo "服务状态如下："
systemctl status stat_client -n 20
