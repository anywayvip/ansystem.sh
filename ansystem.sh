#!/bin/bash

# 一键安装和配置脚本

# 更新和升级系统
echo "正在更新和升级系统..."
sudo apt-get update -y
sudo apt-get upgrade -y

# 安装 cryptsetup 工具
echo "正在安装 cryptsetup 工具..."
sudo apt-get install -y cryptsetup

# 创建虚拟磁盘文件
echo "请输入虚拟磁盘大小（例如：30G、50G、100M等）："
read disk_size

echo "正在创建虚拟磁盘文件..."
mkdir -p /ancrypt-img
cd /ancrypt-img
fallocate -l "$disk_size" ancrypt.img

# 创建 dm-crypt LUKS 容器
echo "正在创建 dm-crypt LUKS 容器..."
cryptsetup -y luksFormat ancrypt.img
cryptsetup luksOpen /ancrypt-img/ancrypt.img ancrypt-img

# 在虚拟磁盘上创建文件系统
echo "正在创建文件系统..."
mkfs.ext4 /dev/mapper/ancrypt-img

# 挂载分区
echo "正在挂载分区..."
cd 
mkdir -p /andata
mount /dev/mapper/ancrypt-img /andata

# 安装 Docker
echo "正在安装 Docker..."
curl -sSL https://get.docker.com/ | sh

# 安装 1panel
echo "正在安装 1panel..."
curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh

# 添加 swap
echo "请输入 swap 文件大小（例如：4G、8G、2G等）："
read swap_size

echo "正在创建 swap 文件..."
fallocate -l "$swap_size" /swapfile
# 如果这个命令无法使用，请安装 util-linux 包：
# apt install util-linux

# 设置这个文件的权限：
chmod 600 /swapfile

# 激活 SWAP 分区
echo "正在激活 SWAP 分区..."
mkswap /swapfile
swapon /swapfile
echo "可以使用 swapon -s 或 free -m 命令查看 Swap 分区是否已经激活。"

# 设置开机自启
echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab

# 停止 Docker 服务
echo "正在停止 Docker 服务..."
sudo systemctl stop docker

# 复制 Docker 数据
echo "正在复制 Docker 数据..."
mkdir -p /andata/docker
sudo apt-get install -y rsync
rsync -av --progress /var/lib/docker/* /andata/docker/

# 修改 Docker 配置文件
echo "正在修改 Docker 配置文件..."
sudo bash -c 'cat > /etc/docker/daemon.json <<EOF
{
	"data-root": "/andata/docker",
	"experimental": true,
	"fixed-cidr-v6": "fd12:3456:789a:1::/64",
	"ip6tables": true,
	"ipv6": true,
	"live-restore": true,
	"log-driver": "json-file",
	"log-opts": {
		"max-file": "3",
		"max-size": "10m"
	}
}
EOF'

# 重启 Docker 服务
echo "正在重启 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl start docker.service

# 删除原 Docker 数据
echo "正在删除原 Docker 数据..."
sudo rm -rf /var/lib/docker

# 创建新用户并设置公钥登录
echo "正在创建新用户并设置公钥登录..."
read -p "请输入新用户名: " username
sudo adduser $username
sudo usermod -aG sudo $username

# 提示用户上传公钥
echo "请上传公钥到 /home/$username/.ssh/authorized_keys"
echo "完成后，请确认您可以通过 SSH 登录。"
read -p "确认完成后输入 'YES' 继续: " confirmation

if [[ "$confirmation" != "YES" ]]; then
    echo "您输入的不是 'YES'，脚本将退出。"
    exit 1
fi

# 设置权限
echo "正在设置权限..."
sudo mkdir -p /home/$username/.ssh
sudo touch /home/$username/.ssh/authorized_keys
sudo chmod 700 /home/$username/.ssh
sudo chmod 600 /home/$username/.ssh/authorized_keys
sudo chown -R $username:$username /home/$username/.ssh

# 禁用密码登录并允许密钥登录
echo "正在禁用密码登录..."
sudo bash -c 'cat > /etc/ssh/sshd_config.d/ssh.conf <<EOF
Port 30000
PasswordAuthentication no
PermitRootLogin no
AllowUsers $username
PubkeyAuthentication yes
EOF'

# 重启 SSH 服务
echo "重启 SSH 服务..."
sudo systemctl restart sshd

echo "脚本执行完毕！"
