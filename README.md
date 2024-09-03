# vagrantfile

This files contains instructions to spin up master node and worker nodes. The number of master nodes and worker nodes is defined by NUM_MASTER_NODE and NUM_WORKER_NODE variables. Note that it also runs `setup-hosts.sh` and `update-dns.sh` scripts on all the VMs after setting up the VMs.

# network-docker-k8s-installation.sh

This takes care of several network settings and installs docker and kubernetes on the VM.

# manually creating cluster

We have run kubeadm init on master so far. We need to proceed further and connect worker nodes.

# Pending Things:

1. Metrics API Server installation
2. Dashboard installation

Steps:

1. Vagrantfile
2. network-docker-k8s-installation.sh on all VMs
3. setupmaster.sh on master node
4. setupworker.sh on all worker nodes
