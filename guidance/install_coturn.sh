#!/bin/bash

# sudo bash install_coturn.sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的信息函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
    print_error "请使用 sudo 运行此脚本"
    exit 1
fi

# 检查系统是否为 Ubuntu
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
        print_error "此脚本仅支持 Ubuntu 系统"
        exit 1
    fi
else
    print_error "无法确定操作系统类型"
    exit 1
fi

# 获取用户输入
print_info "请输入 TURN 服务器用户名："
read -r turn_username

while [ -z "$turn_username" ]; do
    print_error "用户名不能为空"
    print_info "请输入 TURN 服务器用户名："
    read -r turn_username
done

print_info "请输入 TURN 服务器密码："
read -rs turn_password
echo

while [ -z "$turn_password" ]; do
    print_error "密码不能为空"
    print_info "请输入 TURN 服务器密码："
    read -rs turn_password
    echo
done

# 获取公网 IP
print_info "正在获取公网 IP 地址..."
public_ip=$(curl -s ifconfig.me)
if [ -z "$public_ip" ]; then
    print_warning "无法自动获取公网 IP 地址"
    print_info "请输入公网 IP 地址："
    read -r public_ip
    while [ -z "$public_ip" ]; do
        print_error "IP 地址不能为空"
        print_info "请输入公网 IP 地址："
        read -r public_ip
    done
else
    print_info "检测到公网 IP 地址：${public_ip}"
fi

# 安装 Coturn
print_info "开始安装 Coturn..."
apt-get update -y
if ! apt-get install -y coturn; then
    print_error "Coturn 安装失败"
    exit 1
fi
print_info "Coturn 安装完成"

# 配置 Coturn
print_info "开始配置 Coturn..."

# 启用 Coturn 服务
sed -i 's/TURNSERVER_ENABLED=0/TURNSERVER_ENABLED=1/' /etc/default/coturn

# 备份原始配置文件
if [ -f /etc/turnserver.conf ]; then
    mv /etc/turnserver.conf /etc/turnserver.conf.backup
    print_info "已备份原始配置文件到 /etc/turnserver.conf.backup"
fi

# 创建新的配置文件
cat > /etc/turnserver.conf << EOF
# 监听的 IP 地址
listening-ip=0.0.0.0

# 外部 IP 地址
external-ip=${public_ip}

# 监听端口
listening-port=3478

# 中继端口范围
min-port=10000
max-port=20000

# 域名
realm=cloudplayplusturn

# 用户认证信息
user=${turn_username}:${turn_password}

# 日志文件路径
log-file=/var/log/turnserver.log

# 启用详细日志
verbose

# 启用长期凭证机制
lt-cred-mech
EOF

print_info "配置文件已创建"

# 创建日志文件并设置权限
touch /var/log/turnserver.log
chown turnserver:turnserver /var/log/turnserver.log

# 配置防火墙
print_info "配置防火墙规则..."
if command -v ufw &> /dev/null; then
    ufw allow 3478/tcp
    ufw allow 3478/udp
    ufw allow 10000:20000/udp
    print_info "防火墙规则已配置"
else
    print_warning "未检测到 ufw，请手动配置防火墙规则"
fi

# 启动服务
print_info "启动 Coturn 服务..."
systemctl enable coturn
systemctl restart coturn

# 检查服务状态
if systemctl is-active --quiet coturn; then
    print_info "Coturn 服务已成功启动"
    print_info "服务状态："
    systemctl status coturn | cat
else
    print_error "Coturn 服务启动失败"
    exit 1
fi

# 显示配置信息
print_info "安装和配置完成！"
echo "----------------------------------------"
echo "TURN 服务器配置信息："
echo "服务器地址：${public_ip}"
echo "TURN 端口：3478"
echo "中继端口范围：10000-20000"
echo "用户名：${turn_username}"
echo "----------------------------------------"

print_info "您可以使用以下命令查看服务状态："
echo "sudo systemctl status coturn"
print_info "查看日志："
echo "sudo tail -f /var/log/turnserver.log"

# 测试连接信息
print_info "测试连接信息："
echo "TURN URL: turn:${public_ip}:3478"
echo "用户名: ${turn_username}"
echo "密码: ${turn_password}" 