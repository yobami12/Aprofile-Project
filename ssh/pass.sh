#!/bin/bash
touch /tmp/pass.txt
echo 'input-passwd' > /tmp/pass.txt

for host in root@192.168.10.22 root@192.168.10.17
do
cat ~/.ssh/id_rsa.pub | sshpass -f pass.txt ssh -o StrictHostKeyChecking=no $host 'cat >> ~/.ssh/authorized_keys'
rm -f /tmp/pass.txt
done
