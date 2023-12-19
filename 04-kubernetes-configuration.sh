#!/bin/bash


# Generating kubeadm-proj Configuration Files for Authentication
# In this lab you will generate kubeadm-proj configuration files, also known as kubeconfigs, which enable kubeadm-proj clients to locate and authenticate to the kubeadm-proj API Servers.

# Client Authentication Configs
# In this section you will generate kubeconfig files for the controller manager, kubelet, kube-proxy, and scheduler clients and the admin user.

# kubeadm-proj Public DNS Address
# Each kubeconfig requires a kubeadm-proj API Server to connect to. To support high availability the IP address assigned to the external load balancer fronting the kubeadm-proj API Servers will be used.

# Retrieve the kubeadm-proj DNS address:

kubeadm-proj_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns ${LOAD_BALANCER_ARN} \
  --output text --query 'LoadBalancers[0].DNSName')

# The kubelet kubeadm-proj Configuration File
# When generating kubeconfig files for Kubelets the client certificate matching the Kubelet's node name must be used. This will ensure Kubelets are properly authorized by the kubeadm-proj Node Authorizer.

# The following commands must be run in the same directory used to generate the SSL certificates during the Generating TLS Certificates lab.

# Generate a kubeconfig file for each worker node:

for instance in worker-0 worker-1 worker-2; do
  kubectl config set-cluster kubeadm-proj \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${kubeadm-proj_PUBLIC_ADDRESS}:443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubeadm-proj \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done

# Results:

# worker-0.kubeconfig
# worker-1.kubeconfig
# worker-2.kubeconfig

# The kube-proxy kubeadm-proj Configuration File


# Generate a kubeconfig file for the kube-proxy service:

kubectl config set-cluster kubeadm-proj \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${kubeadm-proj_PUBLIC_ADDRESS}:443 \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubeadm-proj \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

# Results:

# kube-proxy.kubeconfig

# The kube-controller-manager kubeadm-proj Configuration File


# Generate a kubeconfig file for the kube-controller-manager service:

kubectl config set-cluster kubeadm-proj \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=kubeadm-proj \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

# Results:

# kube-controller-manager.kubeconfig

# The kube-scheduler kubeadm-proj Configuration File

# Generate a kubeconfig file for the kube-scheduler service:

kubectl config set-cluster kubeadm-proj \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=kubeadm-proj \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

# Results:

# kube-scheduler.kubeconfig

# The admin kubeadm-proj Configuration File


# Generate a kubeconfig file for the admin user:

kubectl config set-cluster kubeadm-proj \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=kubeadm-proj \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig
# Results:

# admin.kubeconfig

# Distribute the kubeadm-proj Configuration Files


# Copy the appropriate kubelet and kube-proxy kubeconfig files to each worker instance:

for instance in worker-0 worker-1 worker-2; do
  external_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=${instance}" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  scp -i kubeadm-proj.id_rsa \
    ${instance}.kubeconfig kube-proxy.kubeconfig ubuntu@${external_ip}:~/
done

# Copy the appropriate kube-controller-manager and kube-scheduler kubeconfig files to each controller instance:

for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=${instance}" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
  
  scp -i kubeadm-proj.id_rsa \
    admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ubuntu@${external_ip}:~/
done