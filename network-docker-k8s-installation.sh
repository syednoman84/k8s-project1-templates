# This script makes some network related changes to the VM and installs docker and kubernetes.
# If you want to not install kubernetes or docker, you can comment out the tasks from 6 to 9.
export DEBIAN_FRONTEND=noninteractive

echo "----------------------------------"
echo "[TASK 1] show whoami"
echo "----------------------------------"
whoami

echo "----------------------------------"
echo "[TASK 2] Stop and Disable firewall"
echo "----------------------------------"
systemctl disable --now ufw >/dev/null 2>&1

echo "----------------------------------"
echo "[TASK 3] Disable swap"
echo "----------------------------------"
sudo swapoff -a

echo "----------------------------------"
echo "[TASK 4] Keeps the swaf off during reboot"
echo "----------------------------------"
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y


echo "----------------------------------"
echo "[TASK 5] Letting iptables see bridged traffic"
echo "----------------------------------"
modprobe br_netfilter

echo "----------------------------------"
echo "[TASK 6] Enable and Load Kernel modules"
echo "----------------------------------"
cat >>/etc/modules-load.d/k8s.conf<<EOF
br_netfilter
EOF

echo "----------------------------------"
echo "[TASK 7] Add Kernel settings"
echo "----------------------------------"
cat >>/etc/sysctl.d/k8s.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

echo "----------------------------------"
echo "[TASK 8] Installing docker"
echo "----------------------------------"
apt-get update
apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg \
lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
     "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io -y

echo "----------------------------------"
echo "[TASK 9] Configure the Docker daemon, in particular to use systemd for the management of the container’s cgroups."
echo "----------------------------------"
rm -rf /etc/Docker
mkdir /etc/Docker
cat >>/etc/docker/daemon.json<<EOF
{
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {
    "max-size": "100m"
},
"storage-driver": "overlay2"
}
EOF
systemctl enable docker
systemctl daemon-reload
systemctl restart docker

# Optionally you can choose to install crio instead of docker if you want as container runtime for k8s
# sudo apt-get update -y
# sudo apt-get install -y cri-o

# sudo systemctl daemon-reload
#sudo systemctl enable crio --now
#sudo systemctl start crio.service

# echo "CRI runtime installed successfully"

echo "----------------------------------"
echo "[TASK 10] Installing dependencies for k8s"
echo "----------------------------------"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg -y

echo "----------------------------------"
echo "[TASK 11] Installing k8s"
echo "----------------------------------"
# In releases older than Debian 12 and Ubuntu 22.04, directory /etc/apt/keyrings does not exist by default, 
# and it should be created before the curl command.
sudo mkdir -p -m 755 /etc/apt/keyrings

# Add the appropriate Kubernetes apt repository. 
# Please note that this repository have packages only for Kubernetes 1.31; 
# for other Kubernetes minor versions, you need to change the Kubernetes minor version in the URL to match your desired minor version
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update
# Note that you can provide the versions to following command as well if you want to install any particular versions
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


echo "----------------------------------"
echo "[TASK 12] Add the node IP to KUBELET_EXTRA_ARGS"
echo "----------------------------------"
sudo apt-get install -y jq
local_ip="$(ip --json addr show eth0 | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF

