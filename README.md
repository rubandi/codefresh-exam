# codefresh-exam

## Deployment

To deploy the solution you need to install Virtualbox and Vagrant clone this repository and in the repository directory run:

`$ vagrant up`

[Prometheus UI](http://192.168.7.102:30000/alerts)  
[AlertManager UI](http://192.168.7.102:30001/#/alerts)

## Alert testing

To test alerts you may use scripts from *alert-test* directory. To run scripts you need to login to one of nodes by using command **vagrant ssh <VM_name>**. For example, to login to *k8s-master* VM run:

`$ vagrant ssh k8s-master`

Repository directory is mount to */vagrant*. For example, to run *KubeControllerIsDown-no-pod_break.sh* script you need to use:

`$ sudo /vagrant/alert-tests/KubeControllerIsDown-no-pod_break.sh`

All scripts, except *NonPodCpuHigh.sh*, should be run on master node (*k8s-master* VM). Also *KubeControllerIsDown* scripts should be run with *sudo*.

## Notifications

To get notifications you need to update AlertManager config in *codefresh-exam/prometheus/alert-manager/config-map.yaml* by updating the following fields:

```
receivers:  
  ...
  slack_configs:
    api_url: <your_webhook_URL>  
    channel: <your_chanel_name>
```

How to create Incoming Webhooks for Slack you may read [here](https://api.slack.com/incoming-webhooks).