#!/bin/sh

cp -v /etc/kubernetes/manifests/kube-controller-manager.yaml /vagrant/alert-tests/manifests/kube-controller-manager.yaml_err_backup
cp -v /vagrant/alert-tests/manifests/kube-controller-manager.yaml_broken /etc/kubernetes/manifests/kube-controller-manager.yaml
