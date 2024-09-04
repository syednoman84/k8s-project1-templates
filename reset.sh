#!/bin/bash

kubectl config delete-cluster
kubectl delete all --all-namespaces --all
kubeadm reset

sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube*
sudo apt-get autoremove
sudo rm -rf ~/.kube /etc/cni /etc/kubernetes /var/lib/etcd /var/lib/kubelet

sudo systemctl reload-daemon
