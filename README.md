# Step 1 - vagrantfile

This files contains instructions to spin up master node and worker nodes. The number of master nodes and worker nodes is defined by NUM_MASTER_NODE and NUM_WORKER_NODE variables. Note that it also runs `setup-hosts.sh` and `update-dns.sh` scripts on all the VMs after setting up the VMs.

# Step 2 - network-docker-k8s-installation.sh

This takes care of several network settings and installs docker and kubernetes on the VM.

# Step 3 - setupmaster.sh

This creates the k8s cluster on the master01.

# Step 4 - setupworker.sh on worker01

This connects the worker01 node to the k8s cluster

# Step 5 - setupworker.sh on worker02

This connects the worker02 node to the k8s cluster

# Step 6 - Validate

Run `kubectl get all` to see the details of cluster showing the nodes connected to the cluster

# Step 7 - Deploy Polling App

Refer to https://github.com/syednoman84/reference-guide/blob/master/PROJECTS_README.md#polling-app-setup-on-local-k8s-cluster-using-vms-on-vagrant:~:text=Polling%20App%20Setup%20on%20Local%20K8s%20Cluster%20Using%20VMs%20on%20Vagrant which will walk you through the steps to deploy polling app and play around.

# Pending Things:

1. Metrics API Server installation
2. Dashboard installation
3. ConfigMap
4. Communication between microservices to avoid all base api urls and ports changes from one deployment to another
