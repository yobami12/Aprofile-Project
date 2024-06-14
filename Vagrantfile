Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
   config.vm.network "private_network", ip: "192.168.56.82"
   config.vm.network "public_network"
   config.vm.provider "virtualbox" do |vb|
     vb.memory = "2048"
   end
   config.vm.provision "shell", inline: <<-SHELL
   sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
   SHELL
end
