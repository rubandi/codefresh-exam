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

#######CRI Installation
# Install Docker CE
## Set up the repository:  
### Install packages to allow apt to use a repository over HTTPS
sudo apt-get update
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

# ip of this box
IP_ADDR=`ifconfig eth1 | grep Mask | awk '{print $2}'| cut -f2 -d:`
# set node-ip
sudo sed -i "/^[^#]*KUBELET_EXTRA_ARGS=/c\KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDR" /etc/default/kubelet
sudo systemctl restart kubelet

SCRIPT

$masterConfiguration = <<-SCRIPT

echo "Initializing of master node"

# ip of this box
IP_ADDR=`ifconfig eth1 | grep Mask | awk '{print $2}'| cut -f2 -d:`
# Initializing k8s master
HOST_NAME=$(hostname -s)
sudo kubeadm init --apiserver-advertise-address=$IP_ADDR --apiserver-cert-extra-sans=$IP_ADDR  --node-name $HOST_NAME --pod-network-cidr=10.244.0.0/16

#copying credentials for kubectl
mkdir -vp /home/vagrant/.kube
sudo cp -v /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -v $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config

#installing a pod network add-on
sudo sysctl net.bridge.bridge-nf-call-iptables=1
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml

#allow schedule pods on master
kubectl taint nodes --all node-role.kubernetes.io/master-

kubeadm token create --print-join-command > /home/vagrant/kubeadm_join_cmd.sh

SCRIPT

$nodeConfiguration = <<-SCRIPT

echo "Adding node to cluster"
sudo apt-get install -y sshpass
sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@192.168.7.101:/home/vagrant/kubeadm_join_cmd.sh .
sudo sh ./kubeadm_join_cmd.sh

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

      if host[:type] == "master"
        config.vm.provision "shell", inline: $masterConfiguration
      else
        config.vm.provision "shell", inline: $nodeConfiguration
      end

    end

  end

end