#!/bin/bash

<< comment
Here you need to consider two options.

Master Node with Private IP: If you have nodes with only private IP addresses the API server would be accessed over the private IP of the master node.
Master Node With Public IP: If you are setting up a Kubeadm cluster on Cloud platforms and you need master Api server access over the Public IP of the master node server.
Only the Kubeadm initialization command differs for Public and Private IPs.

Execute the commands in this section only on the master node.

If you are using a Private IP for the master Node,

Set the following environment variables. Replace 10.0.0.10 with the IP of your master node.

IPADDR="10.0.0.10"
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
If you want to use the Public IP of the master node,

Set the following environment variables. The IPADDR variable will be automatically set to the server’s public IP using ifconfig.me curl call. You can also replace it with a public IP address

IPADDR=$(curl ifconfig.me && echo "")
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
Now, initialize the master node control plane configurations using the kubeadm command.

For a Private IP address-based setup use the following init command.

sudo kubeadm init --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR  --pod-network-cidr=$POD_CIDR --node-name $NODENAME --ignore-preflight-errors Swap
--ignore-preflight-errors Swap is actually not required as we disabled the swap initially.

For Public IP address-based setup use the following init command.

Here instead of --apiserver-advertise-address we use --control-plane-endpoint parameter for the API server endpoint.

sudo kubeadm init --control-plane-endpoint=$IPADDR  --apiserver-cert-extra-sans=$IPADDR  --pod-network-cidr=$POD_CIDR --node-name $NODENAME
sudo kubeadm init --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR  --pod-network-cidr=$POD_CIDR --node-name $NODENAME

comment

# Variables initialization
IPADDR="192.168.56.2"
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"

# Initializing kuberenetes cluster on master using kubeadm init command
sudo kubeadm init --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR  --pod-network-cidr=$POD_CIDR --node-name $NODENAME

