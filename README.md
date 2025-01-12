-spin up vm with vagrant using virtualbox as the provider with two net intrfces (int&ext)

![Screenshot (161)](https://github.com/user-attachments/assets/5336e085-05a4-4209-af1f-942ec4ff9dae)


			ON WEB01 SERVER
update server

cmd: apt-get update

-open port 9000/tcp on web01 and allow connection from 10.200.16.100/29 on vlan interface

cmd: ip link add link enp0s8 name stakingVlan type vlan id 150

![Screenshot (162)](https://github.com/user-attachments/assets/57328f3e-0e1b-4d34-acb5-22c93f8a9682)


-Configure firewall

cmd: ufw default deny incoming

cmd: ufw default allow outgoing

cmd: ufw allow in on enp0s9 to any port 22

cmd: ufw allow in on enp0s9 to any port 80

cmd: ufw allow in on enp0s9 to any port 443

cmd: ufw allow in on stakingVlan to any port 9000 from 10.200.16.100/29

cmd: ufw enable

cmd: ufw status

![Screenshot (163)](https://github.com/user-attachments/assets/012179a3-3895-4d85-ae8d-955cd0e9fdb9)


-turn on the interface

cmd: ip link set stakingVlan up

![Screenshot (164)](https://github.com/user-attachments/assets/1b75b4bd-5a8c-44b7-bad2-b1690f3ed889)


-configure and restart sshd service

-create ssh keypair

cmd: ssh-keygen -t rsa -b 2048

-copy pubkey to .ssh/authorized_keys

-install ansible

cmd: apt-get install ansible -y

configure ansible 'host' and 'cfg' file

test connection with ansible

cmd: ansible all --key-file ~/.ssh/id_rsa -i /etc/ansible/hosts -m ping -u root

![Screenshot (165)](https://github.com/user-attachments/assets/98d613d3-eee1-433e-a137-0c346af3aaab)


-run ansible playbook to deploy artifact 

![Screenshot (166)](https://github.com/user-attachments/assets/5ba1a2d1-6688-4041-b6a7-3ed395a308c0)

-Test deployment on browser

http://192.168.1.16

![Screenshot (167)](https://github.com/user-attachments/assets/9d39d315-238c-4be4-b1ad-434feef8d2f3)

-run ansible playbook to secure server

![Screenshot (168)](https://github.com/user-attachments/assets/3f95c465-8ef7-4de3-a0b5-376c409bdf3f)


