#!/bin/bash

echo " "
echo "*********************************************"
echo "*********DEPLOY K8S CLUSTER***************"
echo "*********************************************"
echo " "
sudo apt-get update && sudo apt-get upgrade -y
sudo systemctl disable ufw
sudo systemctl stop ufw
sudo apt-get install -y wget curl

echo " "
echo "##########INSTALLING KUBEAMD, KUBLET AND KUBECTL###########"
echo " "

#curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
#curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
curl -LO https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl
curl -LO https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl.sha256
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
sudo mkdir /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl kubeadm kubelet
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

echo " "
echo "##########INSTALLING CONTAINER RUNTIME (CONTAINERD)################"
echo " "

wget https://github.com/containerd/containerd/releases/download/v2.0.5/containerd-2.0.5-linux-amd64.tar.gz
tar Cxzvf /usr/local/ containerd-2.0.5-linux-amd64.tar.gz
mkdir -p /usr/local/lib/systemd/system/
touch /usr/local/lib/systemd/system/containerd.service
cat <<. >> /usr/local/lib/systemd/system/containerd.service
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target dbus.service

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
.

systemctl daemon-reload
systemctl enable --now containerd

echo " "
echo "############INSTALLING RUNC####################"
echo " "

wget https://github.com/opencontainers/runc/releases/download/v1.2.6/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

echo " "
echo "############INSTALLING CNI PLUGINS##################"
echo " "

wget https://github.com/containernetworking/plugins/releases/download/v1.7.1/cni-plugins-linux-amd64-v1.7.1.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.7.1.tgz

ls -l /run/containerd/containerd.sock

sudo mkdir -p /etc/containerd/
sudo touch /etc/containerd/config.toml
containerd config default > /etc/containerd/config.toml
sed -i s/"ShimCgroup = ''"/"ShimCgroup = ''\n            SystemdCgroup = true"/g /etc/containerd/config.toml
sed -i "s/disable_tcp_service = true/disable_tcp_service = true\n    sandbox_image = \'registry.k8s.io\/pause:3.10\'/g" /etc/containerd/config.toml
sudo systemctl restart containerd
sudo ctr images ls | grep pause || sudo ctr image pull registry.k8s.io/pause:3.10

echo " "
echo "#############DISABLE SWAP##################"
echo " "

sudo swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo " "
echo "#############SET br_netfilter##################"
echo " "
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

echo " "
echo "*******************************************"
echo "*********SWITCH TO CGROUP V2***************"
echo "*******************************************"
echo " "
mount | grep cgroup
sed -i 's/GRUB_CMDLINE_LINUX=*/GRUB_CMDLINE_LINUX="... other options ... systemd.unified_cgroup_hierarchy=1"/g' /etc/default/grub
sudo update-grub

sudo mkdir /sys/fs/cgroup/hugetlb
sudo mount -t cgroup -o hugetlb none /sys/fs/cgroup/hugetlb
echo "cgroup /sys/fs/cgroup/hugetlb cgroup hugetlb 0 0" >> /etc/fstab
echo " "
echo "*********************************************"
echo "*********DONE (REBOOT REQUIRED)***************"
echo "*********************************************"
echo " "
#reboot

###Verify the Cluster Status:

#kubectl get nodes
