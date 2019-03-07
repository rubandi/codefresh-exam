# -*- mode: ruby -*-
# vi: set ft=ruby :

hosts = [
  {
    :name => "k8s-master",
    :type => "master",
    :box => "bento/ubuntu-16.04",
    :box_version => "201812.27.0",
    :eth => "192.168.7.101",
    :mem => "2048",
    :cpu => "2"
  },
  {
    :name => "k8s-node",
    :type => "node",
    :box => "bento/ubuntu-16.04",
    :box_version => "201812.27.0",
    :eth => "192.168.7.102",
    :mem => "2048",
    :cpu => "2"
  }
]

$generalConfiguration = <<-SCRIPT

#System upgrade
sudo apt-get update
sudo apt-get -y upgrade

#######CRI Installation
# Install Docker CE
## Set up the repository:  
### Install packages to allow apt to use a repository over HTTPS
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

### Add docker apt repository.
sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"

## Install docker ce.
sudo apt-get update && sudo apt-get install -y docker-ce=18.06.2~ce~3-0~ubuntu

# Setup daemon.
sudo cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
sudo systemctl daemon-reload
sudo systemctl restart docker
#######

# kubelet requires swap off
swapoff -a
# keep swap off after reboot
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#######Installing kubeadm, kubelet and kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
#######



SCRIPT

Vagrant.configure("2") do |config|

  hosts.each do |host|

    config.vm.define host[:name] do |config|

      config.vm.box = host[:box]
      config.vm.box_version = host[:box_version]
      config.vm.hostname = host[:name]
      config.vm.network :private_network, ip: host[:eth]

      config.vm.provider "virtualbox" do |vmachine|

        vmachine.name = host[:name]
        vmachine.customize ["modifyvm", :id, "--memory", host[:mem]]
        vmachine.customize ["modifyvm", :id, "--cpus", host[:cpu]]

      end

      config.vm.provision "shell", inline: $generalConfiguration

    end

  end

end