#!/bin/bash

echo "----------------------------------"
echo "[Task 1] Remove existing containerd config"
echo "----------------------------------"
rm /etc/containerd/config.toml
systemctl restart containerd

echo "----------------------------------"
echo "[TASK 2] Pull required containers"
echo "----------------------------------"
kubeadm config images pull >/dev/null 2>&1

echo "----------------------------------"
echo "[TASK 3] Initialize Kubernetes Cluster"
echo "----------------------------------"
# Variables initialization
IPADDR="192.168.56.2"
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
# Initializing kuberenetes cluster on master using kubeadm init command
sudo kubeadm init --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR  --pod-network-cidr=$POD_CIDR --node-name $NODENAME

echo "----------------------------------"
echo "[TASK 4] Copying configs from etc to home .kube"
echo "----------------------------------"
# Use the following commands from the output to create the kubeconfig in master so that you can use kubectl to interact with cluster API.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# echo "----------------------------------"
# echo "[TASK 5] Deploy Calico network"
# echo "----------------------------------"
# kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml >/dev/null 2>&1

echo "----------------------------------"
echo "[TASK 5] Deploy Weave network"
echo "----------------------------------"
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

echo "----------------------------------"
echo "[TASK 6] Generate and save cluster join command to /joincluster.sh"
echo "----------------------------------"
kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null

echo "----------------------------------"
echo "[TASK 7] Setup public key for workers to access master"
echo "----------------------------------"
cat >>~/.ssh/authorized_keys<<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVVswUXh11xbn8Wtuj0jZeEtCXGlbfU3eP9NKIAzjj5H3IgZxWGcbSvz+dBkUfP50CRjQx5v1k4vpe1DCx3K+nL2zidk6qotlKqGybnz9UHS61EGuKvxuDOwCwWMK1OEkmrjYdZVKgCn1qUMfI3UzIn0N9DVTFolLm/vjpSZ0NX9PLkzMbUv/MMO4GY6fk4O9Lo/cog9L5pvtGSl4ecFl3RJ+a/o3gWGLYWwJdV/2tpTps3/hh559nAVqdk0EPkFvJJklFhzjL4B5kpHsk2wvKGbgpca2PUmE6hVEljBivUfV7RCuFJB+0NVsJhO61TsErROt7h+2uJWhGwiP7YJTn vagrant@master01
EOF

echo "----------------------------------"
echo "[TASK 8] Setup kubectl"
echo "----------------------------------"
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

echo "----------------------------------"
echo "[TASK 9] Verify K8s Cluster"
echo "----------------------------------"
kubectl get pods -n kube-system -o wide
