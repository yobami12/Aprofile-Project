#!/bin/bash

sudo yum update -y
#sudo yum install epel-release -y
#sudo dnf config-manager --disable epel
sudo dnf config-manager --disable extras
sudo dnf clean all
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
sudo dnf install https://rpms.remirepo.net/enterprise/remi-release-9.rpm -y
sudo crb install
sudo /usr/bin/crb enable
sudo dnf config-manager --set-enable remi
sudo dnf update -y
TOMURL="https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz"
dnf -y install java-11-openjdk java-11-openjdk-devel
dnf install git maven wget -y
cd /tmp/
wget $TOMURL
tar xzfv apache-tomcat-9.0.85.tar.gz
rm -f /tmp/apache-tomcat-9.0.85.tar.gz

mkdir /usr/local/tomcat
useradd --home /usr/local/tomcat --shell /sbin/nologin tomcat
cp -r /tmp/apache-tomcat-9.0.85/* /usr/local/tomcat
chown -R tomcat.tomcat /usr/local/tomcat

rm -rf /etc/systemd/system/tomcat.service

cat<<EOF >> /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat
After=network.target

[Service]

Type=forking
User=tomcat
Group=tomcat
UMask=0007

WorkingDirectory=/usr/local/tomcat

Environment=JRE_HOME=/usr/lib/jvm/jre
Environment=JAVA_HOME=/usr/lib/jvm/jre

Environment=CATALINA_PID=/var/tomcat/%i/run/tomcat.pid
Environment=CATALINA_HOME=/usr/local/tomcat
Environment=CATALINE_BASE=/usr/local/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/usr/local/tomcat/bin/startup.sh
ExecStop=/usr/local/tomcat/bin/shutdown.sh


RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat

rm -rf /tmp/Aprofile-Project
git clone -b main https://github.com/yobami12/Aprofile-Project.git
cd Aprofile-Project
mvn install || mvn install || mvn install
systemctl stop tomcat
sleep 20
rm -rf /usr/local/tomcat/webapps/ROOT*
cp target/vprofile-v2.war /usr/local/tomcat/webapps/
mv -i /usr/local/tomcat/webapps/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
systemctl start tomcat
sleep 20
systemctl stop firewalld
systemctl disable firewalld
systemctl restart tomcat
