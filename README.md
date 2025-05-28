ON-PREM K8s CLUSTER USING VMs

This project demonstrates the use of ‘kubeadm’ to deploy a Kubernetes cluster of 1 master and 2 worker nodes with multi-tier web application deployed and monitoring with Prometheus and Grafana.

Prerequisites (host pc):
Install
-Gitbash
-Virtualbox
-Vagrant
NOTE: host pc should also have more than 120GB free disk space and 16GB ram

Step 1:
[create vms and initialize cluster with kubeadm]

###On gitbash clone repo: 
git clone -b main https://github.com/yobami12/Aprofile-Project.git
cd Aprofile-Project/k8s-docker
