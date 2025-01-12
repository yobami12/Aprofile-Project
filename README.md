-spin up vm with vagrant using virtualbox as the provider with two net intrfces (int&ext)

			ON WEB01 SERVER
update server
cmd: apt-get update

-open port 9000/tcp on web01 and allow connection from 10.200.16.100/29 on vlan interface
cmd: ip link add link enp0s8 name stakingVlan type vlan id 150
![Screenshot (159)](https://github.com/user-attachments/assets/29842758-1205-4ba3-8469-6c0c19c6c2e8)

cmd: ufw default deny incoming
cmd: ufw default allow outgoing
cmd: ufw allow in on enp0s9 to any port 22
cmd: ufw allow in on enp0s9 to any port 80
cmd: ufw allow in on enp0s9 to any port 443
cmd: ufw allow in on stakingVlan to any port 9000 from 10.200.16.100/29
cmd: ufw enable
cmd: ufw status

-turn on the interface
cmd: ip link set stakingVlan up

-configure and restart sshd service

-create ssh keypair
cmd: ssh-keygen -t rsa -b 2048

-copy pubkey to .ssh/authorized_keys

-install ansible
cmd: apt-get install ansible -y

configure ansible host and cfg file

test connection with ansible
cmd: ansible all --key-file ~/.ssh/id_rsa -i /etc/ansible/hosts -m ping -u root

-write and run ansible playbook to install application and secure server
