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

# 使用公钥登录
adduser anvps
usermod -aG sudo anvps
su - anvps

@生成密钥文件
@ssh-keygen -t rsa -b 2048 -C "anvps@example.com"
@输入此命令后，会收到提示让你设置密码，这个密码是额外用来加密密钥的,可直接回车键留空。
@参数说明：
@-t rsa: 指定密钥类型为 RSA。
@-b 2048: 指定密钥位数为 2048 位。你也可以选择其他位数，更高的位数提供更高的安全性。
@-C "your_email@example.com": 添加注释，任意信息都可。
@完成上述步骤后，你将在指定的路径中得到两个文件：
@私钥文件（默认为 id_rsa）: 存储在 ~/.ssh/ 目录下。
@公钥文件（默认为 id_rsa.pub）: 同样存储在 ~/.ssh/ 目录下。
@安装公钥
@使用下面的命令将公钥内容添加到 ~/.ssh/authorized_keys 文件中
@cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
@公钥安装完毕后一定要把私钥下载到本地妥善保管，同时建议删除远程服务器上的私钥。
@权限设置
@密钥文件必须设置正确的权限确保只有当前用户有访问权：
@chmod 700 ~/.ssh
@chmod 600 ~/.ssh/authorized_keys
@使用密钥登陆
@使用本地电脑打开一个终端使用下面命令登陆
@ssh -i ~/.ssh/id_rsa coco@ip
@~/.ssh/id_rsa 是私钥路径
@coco@ip: 用户和服务器ip
@确认能成功登陆后，继续下面的步骤

# 禁用密码登陆
不建议直接修改/etc/ssh/sshd_config文件，规范的做法是在/etc/ssh/sshd_config.d目录下新建配置文件。
比如使用vim新建并打开一个配置文件：ssh.conf，文件后缀必须是：.conf
sudo vim /etc/ssh/sshd_config.d/ssh.conf
写入下面配置：
Port 7077        #修改默认的22端口，为ssh指定一个新的端口，需提前防火墙放行！！
PasswordAuthentication no         #禁用密码登录,no为禁止
PermitRootLogin no                #禁止root账户登录
AllowUsers user1 user2            #只允许特定用户进行SSH登录
AllowUsers coco@110.256.15.26     #只允许指定用户使用指定ip的登陆
然后重启 SSH 服务：
sudo systemctl restart sshd
并且修改完毕后一定要重新打开一个终端尝试登陆，不要把自己关外面了！

@最后有两个命令可以显示当前系统有没有被尝试撞库，可以检查一下：
@显示系统上所有用户的登录历史记录。
@sudo last
@显示系统上所有用户登录失败的历史记录。
@sudo lastb



