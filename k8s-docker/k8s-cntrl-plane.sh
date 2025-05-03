#!/bin/bash
echo " "
echo "*********************************************"
echo "*********INSTALL DOCKER ENGINE***************"
echo "*********************************************"
echo " "
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

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

apt-get install golang-go -y
set -eu -o pipefail

CNI_COMMIT=${1:-$(go list -f "{{.Version}}" -m github.com/containernetworking/plugins)}
CNI_DIR=${DESTDIR:=''}/opt/cni
CNI_CONFIG_DIR=${DESTDIR}/etc/cni/net.d
: "${CNI_REPO:=https://github.com/containernetworking/plugins.git}"

SUDO=''
if (( $EUID != 0 )); then
    SUDO='sudo'
fi

TMPROOT=$(mktemp -d)
git clone "${CNI_REPO}" "${TMPROOT}"/plugins
pushd "${TMPROOT}"/plugins
git checkout "$CNI_COMMIT"
./build_linux.sh
$SUDO mkdir -p $CNI_DIR
$SUDO cp -r ./bin $CNI_DIR
$SUDO mkdir -p $CNI_CONFIG_DIR
$SUDO cat << EOF | $SUDO tee $CNI_CONFIG_DIR/10-containerd-net.conflist
{
  "cniVersion": "1.0.0",
  "name": "containerd-net",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni0",
      "isGateway": true,
      "ipMasq": true,
      "promiscMode": true,
      "ipam": {
        "type": "host-local",
        "ranges": [
          [{
            "subnet": "10.88.0.0/16"
          }],
          [{
            "subnet": "2001:4860:4860::/64"
          }]
        ],
        "routes": [
          { "dst": "0.0.0.0/0" },
          { "dst": "::/0" }
        ]
      }
    },
    {
      "type": "portmap",
      "capabilities": {"portMappings": true}
    }
  ]
}
EOF

popd
rm -fR "${TMPROOT}"

#wget https://github.com/containernetworking/plugins/releases/download/v1.7.1/cni-plugins-linux-amd64-v1.7.1.tgz
#mkdir -p /opt/cni/bin
#tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.7.1.tgz

ls -l /run/containerd/containerd.sock

containerd config default > /etc/containerd/config.toml
sed -i s/"ShimCgroup = ''"/"ShimCgroup = ''\n            SystemdCgroup = true"/g /etc/containerd/config.toml
sed -i 's/[plugins."io.containerd.grpc.v1.cri"]/[plugins."io.containerd.grpc.v1.cri"]\n    sandbox_image = "registry.k8s.io/pause:3.10"/g /etc/containerd/config.toml
sudo systemctl restart containerd

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
echo "*******************************************************"
echo "*********INITIALIZE KUBEADM WITH HOST IP***************"
echo "*******************************************************"
echo " "
###Execute below if currently configured node will be the master node(control panel)

#sudo kubeadm init --pod-network-cidr=192.168.0.0/16
sudo kubeadm init --apiserver-advertise-address=192.168.56.82 --pod-network-cidr=10.244.0.0/16 --apiserver-cert-extra-sans=192.168.56.82



###The --pod-network-cidr flag specifies the CIDR range for the pod network (adjust based on your network setup).

###Configure kubectl for the Current User:
###Set up Kubernetes admin configuration for the user:

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sed -i 's/cgroupDriver.*/cgroupDriver: systemd/g' /var/lib/kubelet/config.yaml

#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml (flannel)
#kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml (calico)

echo " "
echo "*****************************************************"
echo "*********INSTALLING INGRESS CONTROLLER***************"
echo "*****************************************************"
echo " "
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

###The below command is used to create metalLB for ingress but that is after adding the worker node to the cluster also.
#helm repo add metallb https://metallb.github.io/metallb
#helm install metallb metallb/metallb
#kubectl get ns default -o yaml > metallb.yaml     (ns will be the ns metallb is installed. in this case, it is default ns)
###Add the below "pod-security*" to the labels of the ns(default) in the file generated with abv cmd and apply.
    #pod-security.kubernetes.io/enforce: privileged
    #pod-security.kubernetes.io/audit: privileged
    #pod-security.kubernetes.io/warn: privileged

#kubectl apply -f metallb.yaml -n default

###The below command is used to create ingress but that is after adding the worker node and metalLB to the cluster
#helm upgrade --install ingress-nginx ingress-nginx   --repo https://kubernetes.github.io/ingress-nginx   --namespace ingress-nginx --create-namespace
#                                      OR
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/cloud/deploy.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml  (new)

#kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission (if creating ingress is showing webhook error)

###Note: if metalLB is not installed, ingress will not get 'external-IP'

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
