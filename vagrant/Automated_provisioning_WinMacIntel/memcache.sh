#!/bin/bash
sudo yum update -y
#sudo yum install epel-release -y
#sudo dnf config-manager --disable epel
sudo dnf config-manager --disable extra*
sudo dnf clean all
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
sudo dnf install https://rpms.remirepo.net/enterprise/remi-release-9.rpm -y
sudo crb install || sudo /usr/bin/crb enable
sudo dnf config-manager --set-enable remi
sudo dnf update -y
sudo dnf install memcached -y
sudo systemctl start memcached
sudo systemctl enable memcached
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
sudo systemctl restart memcached
sudo systemctl start firewalld
sudo systemctl enable firewalld
firewall-cmd --add-port=11211/tcp
firewall-cmd --runtime-to-permanent
firewall-cmd --add-port=11111/udp
firewall-cmd --runtime-to-permanent
sudo memcached -p 11211 -U 11111 -u memcached -d
