*ON-PREM K8s CLUSTER USING VMs*

This project demonstrates the use of ‘kubeadm’ to deploy a Kubernetes cluster of 1 master and 2 worker nodes; also, multi-tier containerized web application deployed and monitoring with Prometheus and Grafana.

Prerequisites (host pc):

Install

  -Gitbash
  
  -Virtualbox
  
  -Vagrant

  
NOTE: host pc should also have 100GB free disk space and 16GB ram or more

Step 1:

[create vms and initialize cluster with kubeadm]

###Open gitbash on host pc and run:

clone repo:

	git clone -b main https://github.com/yobami12/Aprofile-Project.git

cd to dir:

	cd Aprofile-Project/k8s-docker

install vagrant-disksize:

	vagrant plugin install vagrant-disksize

install vagrant-hostmanager:

	vagrant plugin install vagrant-hostmanager

spin up VMs:

	vagrant up

![Screenshot (181)](https://github.com/user-attachments/assets/74eb39a6-c88a-48b8-9939-f7438d1b68b7)


###reboot all vms

Step 2:

[add worker nodes to the cluster]

###login to master node vm(master01) and run:

 	kubeadm token create --print-join-command

###copy the output of the ‘kubeadm token …’ command above; login and paste it to each worker node to add them to the cluster.

 ###verify on the master node that the worker nodes have been added.
	
 	Kubectl get nodes

![Screenshot (182)](https://github.com/user-attachments/assets/17c6b3a3-1f54-4f33-862b-21404fbf192c)


Step 3:

[deploy multi-tier web application in ‘default’ namespace]

###on master node vm run:

clone repo:

 	git clone -b main https://github.com/yobami12/Aprofile-Project.git

cd to dir:

 	cd Aprofile-Project/def-files

deploy application with manifest:

 	kubectl create -f .

get pods:

 	Kubectl get all -n default

![Screenshot (185)](https://github.com/user-attachments/assets/07755bc2-dec1-4256-82fe-eb57ef761920)


###test application on the browser with url:

 http://192.168.56.82:31933

Note: “:31933” is the auto assigned port to the “app01-lb” in this cluster. Replace with yours.

![Screenshot (187)](https://github.com/user-attachments/assets/2bb93ebf-4e31-43d3-a278-9afeccd7015e)

Username and password:

	admin_vp

Step 4:

[deploy prometheus and grafana for monitoring]

PROMETHEUS

###create PVs - on master node vm run:

check created PVs:

	kubectl get pv

![Screenshot (189)](https://github.com/user-attachments/assets/3452e201-c45a-4318-94d7-e637fa642c03)


###add prometheus and grafana repo using helm cmd:

add prometheus repo:

	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

add grafana repo:

	helm repo add grafana https://grafana.github.io/helm-charts

update repos:

	helm repo update

###install and deploy prometheus to cluster

	helm install prometheus prometheus-community/prometheus

Note: both ‘prometheus-alertmanager’ and ‘prometheus-server’ pods will be in pending state because the created pv and pvc are yet to be bound.

###Update pvc with created pv’s "storageClassName" so they can be bound.

	kubectl edit pvc prometheus-server

###add “storageClassName: standard” as in below img

![Screenshot (194)](https://github.com/user-attachments/assets/526c5194-ad74-4bd9-a2bb-679fadbcb51e)


add the highlighted line in your pvc yaml file just as in img. Save and quit.

###do same here

	kubectl edit pvc storage-prometheus-alertmanager-0

###verify that both pv and pvc are in ‘bound’ state

	Kubectl get pv && Kubectl get pvc

![Screenshot (195)](https://github.com/user-attachments/assets/c0807132-c708-45c1-bbc5-bf6997cae8cb)


Both ‘prometheus-alertmanager’ and ‘prometheus-server’ pods should be running now because the created pv and pvc are in bound state.

###but if the ‘prometheus-server’ pod is in ‘CrashLoopBackOff’ state.

	Kubectl get pods

![Screenshot (196)](https://github.com/user-attachments/assets/a0012040-6b54-4cea-97dc-cd1d717f2319)


prometheus-server in CrashLoopBackOff

###edit ‘prometheus-server’ deployment file

	kubectl edit deploy prometheus-server

“

fsGroup: 0

runAsGroup: 0

#runAsNonRoot: true

runAsUser: 0

“

###scroll to lines with the above and update value as ‘0’ (digit) as in above.

![Screenshot (198)](https://github.com/user-attachments/assets/067bc516-6900-41fc-922b-fc9fddf5272a)

save and quit

	Kubectl get pods

![Screenshot (201)](https://github.com/user-attachments/assets/4e2cdc47-6386-451e-921c-499bcd84cfa8)
Prometheus-server pod now running

![Screenshot (214)](https://github.com/user-attachments/assets/82557986-7287-4a96-8eba-5fbb389ed72a)


GRAFANA

###install and deploy grafana to the cluster

	helm install grafana grafana/grafana

###verify grafana pod is running

	kubectl get pods

![Screenshot (204)](https://github.com/user-attachments/assets/07488f1d-97ff-4053-acea-2d764b35c9ef)



###create NodePort service for  both ‘prometheus-server’ and ‘grafana’.

create NodePort for prometheus:

	kubectl expose service prometheus-server --type=NodePort --target-port=9090 --name=prometheus-servernodeport

create NodePort for grafana:

	kubectl expose service grafana --type=NodePort --target-port=3000 --name=grafana-nodeport


###verify NodePort service creation

	kubectl get svc | grep NodePort

![Screenshot (206)](https://github.com/user-attachments/assets/5441a242-0c65-4851-b948-8bda767839a4)


###access grafana on 

http://192.168.56.82:32121

Note: replace “32121” with yours

![Screenshot (207)](https://github.com/user-attachments/assets/78439d7e-257c-4cf1-94a9-3e83d7425726)


###run below command to get login password for grafana

###password:

	kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

###username:

	admin



###add ‘prometheus-server as data source in grafana

-on grafana home page in the browser, goto datasource, select prometheus and add 'prometheus-server' as datasource with url 'http://prometheus-server' (prometheus-server = cluster service name for prometheus server)

-then 'save and test' (must successfully query).

![Screenshot (210)](https://github.com/user-attachments/assets/1596cd2f-b5cf-4a23-b80e-87736d75c61b)

Prometheus server url: http://prometheus-server

![Screenshot (211)](https://github.com/user-attachments/assets/fc2cf4c1-ad17-47fb-accc-db984eb7188f)

Prometheus server successfully queried after clicking ‘save & test’.



###Create dashboard

-goto google and search 'grafana dashboards for kubernetes'. select links from grafana.com

-copy dashboard ID, goto your grafana ui, on the home page, click on 'create your first dashboard',

-click on 'import dashboard', paste the copied id, select created data source and click on 'load'

![Screenshot (213)](https://github.com/user-attachments/assets/5bd493de-7cd0-4b72-a76b-a9b9cebd2f18)

Grafana dashborad for kubernetes created.
