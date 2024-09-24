################################
# Setup master node
################################

rm /etc/containerd/config.toml
systemctl restart containerd

# Variables initialization
IPADDR="192.168.56.2"
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"

# Initializing kuberenetes cluster on master using kubeadm init command
sudo kubeadm init --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR  --pod-network-cidr=$POD_CIDR --node-name $NODENAME


# Use the following commands from the output to create the kubeconfig in master so that you can use kubectl to interact with cluster API.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Now, verify the kubeconfig by executing the following kubectl command to list all the pods in the kube-system namespace.
kubectl get po -n kube-system

# You should see the following output. 
# You will see the two Coredns pods in a pending state. 
# It is the expected behavior. Once we install the network plugin, it will be in a running state.
NAME                               READY   STATUS    RESTARTS        AGE
coredns-6f6b679f8f-427zc           0/1     Pending   0               5h25m
coredns-6f6b679f8f-gx75l           0/1     Pending   0               5h25m
etcd-master01                      1/1     Running   0               5h26m
kube-apiserver-master01            1/1     Running   0               5h26m
kube-controller-manager-master01   1/1     Running   0               5h26m
kube-proxy-g7qbg                   1/1     Running   0               5h25m
kube-scheduler-master01            1/1     Running   4 (2m21s ago)   5h26m

# The below command should show the status as NotReady for control-plane
kubectl get nodes

NAME       STATUS     ROLES           AGE     VERSION
master01   NotReady   control-plane   5h26m   v1.31.0

# You verify all the cluster component health statuses using the following command.
kubectl get --raw='/readyz?verbose'

root@master01:~# kubectl get --raw='/readyz?verbose'
[+]ping ok
[+]log ok
[+]etcd ok
[+]etcd-readiness ok
[+]informer-sync ok
[+]poststarthook/start-apiserver-admission-initializer ok
[+]poststarthook/generic-apiserver-start-informers ok
[+]poststarthook/priority-and-fairness-config-consumer ok
[+]poststarthook/priority-and-fairness-filter ok
[+]poststarthook/storage-object-count-tracker-hook ok
[+]poststarthook/start-apiextensions-informers ok
[+]poststarthook/start-apiextensions-controllers ok
[+]poststarthook/crd-informer-synced ok
[+]poststarthook/start-system-namespaces-controller ok
[+]poststarthook/start-cluster-authentication-info-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-garbage-collector ok
[+]poststarthook/start-legacy-token-tracking-controller ok
[+]poststarthook/start-service-ip-repair-controllers ok
[+]poststarthook/rbac/bootstrap-roles ok
[+]poststarthook/scheduling/bootstrap-system-priority-classes ok
[+]poststarthook/priority-and-fairness-config-producer ok
[+]poststarthook/bootstrap-controller ok
[+]poststarthook/aggregator-reload-proxy-client-cert ok
[+]poststarthook/start-kube-aggregator-informers ok
[+]poststarthook/apiservice-status-local-available-controller ok
[+]poststarthook/apiservice-status-remote-available-controller ok
[+]poststarthook/apiservice-registration-controller ok
[+]poststarthook/apiservice-discovery-controller ok
[+]poststarthook/kube-apiserver-autoregistration ok
[+]autoregister-completion ok
[+]poststarthook/apiservice-openapi-controller ok
[+]poststarthook/apiservice-openapiv3-controller ok
[+]shutdown ok
readyz check passed

# You can get the cluster info using the following command.
kubectl cluster-info 

Kubernetes control plane is running at https://192.168.56.2:6443
CoreDNS is running at https://192.168.56.2:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.


####################################
Joining a worker node to the cluster
####################################
1. Login to the worker node and do following commands:
root@master01:~# rm /etc/containerd/config.toml
root@master01:~# systemctl restart containerd

2. Then run the setupworker.sh which should output the following:

root@worker02:~/k8s-project1-templates# sh setupworker.sh [TASK 1] Join node to Kubernetes Cluster
[TASK 2] Change private key permission
[TASK 3] Pull cluster connection token
joincluster.sh          100%  167    45.3KB/s   00:00    
[Task 4] Join the cluster
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 1.003329127s
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.


# Now if you do kubectl get nodes, you should see all the nodes joined the cluster like below:
NAME       STATUS   ROLES           AGE     VERSION
master01   Ready    control-plane   6h32m   v1.31.0
worker01   Ready    <none>          7m35s   v1.31.0
worker02   Ready    <none>          3m17s   v1.31.0

In the above output, note that ROLES is <none>.
Use below command to name them as worker from master node:

kubectl label node worker01  node-role.kubernetes.io/worker=worker
kubectl label node worker02  node-role.kubernetes.io/worker=worker

now the ROLES should be updated to worker:

NAME       STATUS   ROLES           AGE     VERSION
master01   Ready    control-plane   6h47m   v1.31.0
worker01   Ready    worker          22m     v1.31.0
worker02   Ready    worker          18m     v1.31.0

#################################################
Install Calico Network Plugin for Pod Networking
#################################################
Kubeadm does not configure any network plugin. You need to install a network plugin of your choice for kubernetes pod networking and enable network policy.

Execute the following commands to install the Calico network plugin operator on the cluster.

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
After a couple of minutes, if you check the pods in kube-system namespace, you will see calico pods and running CoreDNS pods.

kubectl get po -n kube-system

NAME                                       READY   STATUS     RESTARTS        AGE
calico-kube-controllers-6879d4fcdc-rsmqt   0/1     Running    0               57s
calico-node-2mmq6                          1/1     Running    0               58s
calico-node-2rqvf                          0/1     Init:0/4   0               8s
calico-node-xncfr                          1/1     Running    0               79m
coredns-6f6b679f8f-427zc                   1/1     Running    0               6h51m
coredns-6f6b679f8f-gx75l                   1/1     Running    0               6h51m
etcd-master01                              1/1     Running    0               6h51m
kube-apiserver-master01                    1/1     Running    0               6h51m
kube-controller-manager-master01           1/1     Running    2 (3m49s ago)   6h51m
kube-proxy-g7qbg                           1/1     Running    0               6h51m
kube-proxy-lq76n                           1/1     Running    0               21m
kube-proxy-mdn9c                           1/1     Running    0               26m
kube-scheduler-master01                    1/1     Running    5 (42m ago)     6h51m

################################
Setup Kubernetes Metrics Server
################################
Kubeadm doesn’t install metrics server component during its initialization. We have to install it separately.
To verify this, if you run the top command, you will see the Metrics API not available error.

root@controlplane:~# kubectl top nodes
error: Metrics API not available

To install the metrics server, execute the following metric server manifest file. It deploys metrics server version v0.6.2

NEED TO ADD STEPS TO INSTALL METRICS API

Once the metrics server objects are deployed, it takes a minute for you to see the node and pod metrics using the top command.

kubectl top nodes

You should be able to view the node metrics as shown below.

root@controlplane:~# kubectl top nodes

NAME           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
controlplane   142m         7%     1317Mi          34%
node01         36m          1%     915Mi           23%
You can also view the pod CPU and memory metrics using the following command.

kubectl top pod -n kube-system

###################################
Delete a worker node from cluster
###################################

To drain/remvoe a node from cluster, run below command on master node

kubectl drain <node-name> --force --ignore-daemonsets

Now if you get nodes, you will see SchedulingDisabled for the node you removed

NAME       STATUS                     ROLES           AGE     VERSION
master01   Ready                      control-plane   6h16m   v1.31.0    
worker01   Ready,SchedulingDisabled   <none>          14m     v1.31.0

Run below command on worker node:
kubeadm reset

Finally delete the node from master node as:
kubectl delete node <node-name>


######################################################
Joining a worker node to cluster manually using token
######################################################
If you missed copying the join command, execute the following command in the master node to recreate the token with the join command.

kubeadm token create --print-join-command

Here is what the command looks like. Use sudo if you running as a normal user. This command performs the TLS bootstrapping for the nodes.

sudo kubeadm join 10.128.0.37:6443 --token j4eice.33vgvgyf5cxw4u8i \
    --discovery-token-ca-cert-hash sha256:37f94469b58bcc8f26a4aa44441fb17196a585b37288f85e22475b00c36f1c61

On successful execution, you will see the output saying, “This node has joined the cluster”.


######################################
commands
######################################
kubectl cluster-info 
kubectl get po -n kube-system
kubectl get apiservices (to check status of all api services)
kubectl get po -n kube-system
kubectl get all
kubectl get nodes
kubectl exec <podname> -it -- /bin/sh (to connect to pod as ssh)
kubectl get nodes -o wide (IPs of all nodes including master)
kubectl get services -o wide (IPs and Ports of all services)
kubectl get deployment --watch

# to see the cluster name
# This command will Check all possible clusters, as you know .KUBECONFIG may have multiple contexts
kubectl config view -o jsonpath='{"Cluster name\tServer\n"}{range .clusters[*]}{.name}{"\t"}{.cluster.server}{"\n"}{end}'


To delete metrics-server:
kubectl delete service/metrics-server -n  kube-system
kubectl delete deployment.apps/metrics-server  -n  kube-system
kubectl delete apiservices.apiregistration.k8s.io v1beta1.metrics.k8s.io
kubectl delete clusterroles.rbac.authorization.k8s.io system:aggregated-metrics-reader
kubectl delete clusterroles.rbac.authorization.k8s.io system:metrics-server 
kubectl delete clusterrolebinding metrics-server:system:auth-delegator
kubectl delete clusterrolebinding system:metrics-server          
kubectl delete rolebinding metrics-server-auth-reader -n kube-system 
kubectl delete serviceaccount metrics-server -n kube-system


sudo systemctl reload-daemon

################################################
Notes about creating cluster using kubeadm init
################################################
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
