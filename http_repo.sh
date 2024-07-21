#!/bin/bash

mkdir -p /var/www/html/centos7
cd /opt
file=` find -name "*.iso" | awk -F/ '{print $2}' `
echo "查找到当前路径镜像： $file"
mkdir -p /iso
echo "开始挂载镜像"
mount -o loop -t iso9660 $file /iso
echo "挂载镜像成功，正常拷贝文件..."
cp -r /iso/* /var/www/html/centos7/
echo "拷贝完成，正在卸载镜像"
umount /iso
echo "正在备份repo文件..."
mkdir -p /etc/yum.repos.d/repo_bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/repo_bak
echo "repo文件备份完成，正在配置本地repo文件..."
cat >> /etc/yum.repos.d/local.repo <<-EOF
[local_repo]
name=local_repo
baseurl=file:///var/www/html/centos7
enabled=1
gpgcheck=0
EOF
echo "配置完成,正在清理缓存..."
yum clean all
yum makecache
yum repolist
echo "本地yum仓库配置完成..."
echo "正在安装常用工具：vim,get,lsof,net-tools..."
yum install -y vim get lsof net-tools

# 安装http，发布本地yum源
echo "正在安装http，发布本地yum源..."
yum install -y httpd
sed -i s/'Listen 80'/'Listen 2180\nServerName localhost:2180'/g /etc/httpd/conf/httpd.conf
echo "关闭selinux"
sed -ri '/^SELINUX=/cSELINUX=disabled' /etc/selinux/config
setenforce 0
echo "关闭防火墙"
systemctl stop firewalld
systemctl disabled firewalld
#重启服务
echo "重启httpd..."
systemctl restart httpd
systemctl enable httpd
echo "配置完成，可以通过ip:2180/centos7访问yum源"
