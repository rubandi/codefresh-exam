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
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common htop mc stress

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

### Add docker apt repository.
add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"

## Install docker ce.
apt-get update && apt-get install -y docker-ce=18.06.2~ce~3-0~ubuntu

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker
#######

# kubelet requires swap off
swapoff -a
# keep swap off after reboot
sed -i "s/^.* swap .*$/#&/" /etc/fstab

#######Installing kubeadm, kubelet and kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
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
sed -i "/^[^#]*KUBELET_EXTRA_ARGS=/c\KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDR" /etc/default/kubelet
systemctl restart kubelet

SCRIPT

$masterConfiguration = <<-SCRIPT

echo "Initializing of master node"

# ip of this box
IP_ADDR=`ifconfig eth1 | grep Mask | awk '{print $2}'| cut -f2 -d:`
# Initializing k8s master
HOST_NAME=$(hostname -s)
kubeadm init --apiserver-advertise-address=$IP_ADDR --apiserver-cert-extra-sans=$IP_ADDR  --node-name $HOST_NAME --pod-network-cidr=10.244.0.0/16

#copying credentials for kubectl
mkdir -vp /home/vagrant/.kube
cp -v /etc/kubernetes/admin.conf /home/vagrant/.kube/config
cp -v /etc/kubernetes/admin.conf /vagrant/.kube/config
chown -v $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config

#installing a pod network add-on
sysctl net.bridge.bridge-nf-call-iptables=1
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f /vagrant/kube-flannel.yml

#allow schedule pods on master
kubectl taint nodes --all node-role.kubernetes.io/master-

kubeadm token create --print-join-command > /home/vagrant/kubeadm_join_cmd.sh

#deployment of prometheus, alertmanager and exporters
kubectl apply -f /vagrant/prometheus/namespace.yaml

kubectl apply -f /vagrant/prometheus/node-exporter/node-exporter-daemonset.yaml

kubectl apply -f /vagrant/prometheus/kube-state-metrics/kube-state-metrics-service-account.yaml
kubectl apply -f /vagrant/prometheus/kube-state-metrics/kube-state-metrics-cluster-role.yaml
kubectl apply -f /vagrant/prometheus/kube-state-metrics/kube-state-metrics-cluster-role-binding.yaml
kubectl apply -f /vagrant/prometheus/kube-state-metrics/kube-state-metrics-role.yaml
kubectl apply -f /vagrant/prometheus/kube-state-metrics/kube-state-metrics-role-binding.yaml
kubectl apply -f /vagrant/prometheus/kube-state-metrics/kube-state-metrics-deployment.yaml

kubectl apply -f /vagrant/prometheus/alert-manager/config-map.yaml
kubectl apply -f /vagrant/prometheus/alert-manager/alertmanager-deployment.yaml
kubectl apply -f /vagrant/prometheus/alert-manager/alertmanager-service.yaml

kubectl apply -f /vagrant/prometheus/clusterRole.yaml
kubectl apply -f /vagrant/prometheus/config-map.yaml
kubectl apply -f /vagrant/prometheus/prometheus-deployment.yaml
kubectl apply -f /vagrant/prometheus/prometheus-service.yaml

SCRIPT

$nodeConfiguration = <<-SCRIPT

echo "Adding node to cluster"
apt-get install -y sshpass
sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@192.168.7.101:/home/vagrant/kubeadm_join_cmd.sh .
sh ./kubeadm_join_cmd.sh

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