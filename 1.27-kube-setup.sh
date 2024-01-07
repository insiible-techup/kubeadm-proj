#!/bin/bash


ufw disable


swapoff -a; sed -i '/swap/d' /etc/fstab


# Install packages

# Create a configuration file for Containerd

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF


# Load the modules for Networking

modprobe overlay
modprobe br_netfilter


# Set System Configurations for Kubernetes Networking

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply the new settings:

sysctl --system


# Install Containerd

#Install dependencies
apt install -y curl gnupg software-properties-common apt-transport-https ca-certificates

#Enable docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

#install containerd
apt-get update && sudo apt-get install -y containerd.io


# Create the Default Configuration File for Containerd

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# Restart and Enable Containerd and check status

systemctl restart containerd
systemctl enable containerd
systemctl status containerd


# Update Dependency Packages

sudo apt-get update 
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https curl gpg


# Download the public signing key for the Kubernetes package repositories

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the appropriate Kubernetes apt repo

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version

sudo apt-get update

# FYI - In releases older than Debian 12 and Ubuntu 22.04, /etc/apt/keyrings does not exist by default; 
# you can create it by running sudo mkdir -m 755 /etc/apt/keyrings


# Install K8's packages and turnoff automatic updates

sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
