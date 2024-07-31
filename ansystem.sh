#!/bin/bash

# 安装 cryptsetup 工具
sudo apt-get install cryptsetup

# 创建虚拟磁盘文件
mkdir /ancrypt-img
cd /ancrypt-img
fallocate -l 30G ancrypt.img

# 创建 dm-crypt LUKS 容器
cryptsetup -y luksFormat ancrypt.img
cryptsetup luksOpen /ancrypt-img/ancrypt.img ancrypt-img

# 在虚拟磁盘上创建文件系统
mkfs.ext4 /dev/mapper/ancrypt-img

# 挂载分区
cd 
mkdir /andata
mount /dev/mapper/ancrypt-img /andata

# 安装docker
curl -sSL https://get.docker.com/ | sh

# 安装1panel
curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh

# 添加swap
fallocate -l 4G /swapfile
# 如果这个命令无法使用，请安装 util-linux 包：
# apt install util-linux

# 设置这个文件的权限：
chmod 600 /swapfile

# 然后激活 SWAP 分区
mkswap /swapfile
swapon /swapfile
# 可以使用 swapon -s 或 free -m 命令查看 Swap 分区是否已经激活。

#设置开机自启
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

# docker改目录
# 查询真正的安装路径：
sudo docker info | grep "Docker Root Dir"
sudo systemctl stop docker

# 复制文件
mkdir /andata/docker
sudo apt-get install rsync
rsync -av --progress /var/lib/docker/* /andata/docker/

#修改配置文件
vim /etc/docker/daemon.json
加入
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

# 重启服务
systemctl daemon-reload
systemctl start docker.service

# 查看root目录
docker info |grep "Docker Root Dir"

# 删除原数据
rm -rf /var/lib/docker



