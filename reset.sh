#!/bin/bash

# before reset verify that kubeadm and kubectl are there on your vm
kubeadm version
which kubeadm
kubectl version
which kubectl


# Run these commands one by one manually
kubectl config delete-cluster kubernetes
kubectl delete all --all-namespaces --all
kubeadm reset

sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube*
sudo apt-get autoremove
sudo rm -rf ~/.kube /etc/cni /etc/kubernetes /var/lib/etcd /var/lib/kubelet

# after that if you run these commands, you should see that kubeadm doesn't exist
kubeadm version
which kubeadm
kubectl version
which kubectl

