#!/bin/bash



# Certificate Authority
# In this section you will provision a Certificate Authority that can be used to generate additional TLS certificates.

# Generate the CA configuration file, certificate, and private key:

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubeadm-proj": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "kubeadm-proj",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "kubeadm-proj",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

# Results:

# ca-key.pem
# ca.pem
# Client and Server Certificates
# In this section you will generate client and server certificates for each kubeadm-proj component and a client certificate for the kubeadm-proj admin user.

# The Admin Client Certificate
# Generate the admin client certificate and private key:

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "kubeadm-proj",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubeadm-proj \
  admin-csr.json | cfssljson -bare admin

# Results:

# admin-key.pem
# admin.pem
# The Kubelet Client Certificates
# kubeadm-proj uses a special-purpose authorization mode called Node Authorizer, that specifically authorizes API requests made by Kubelets. In order to be authorized by the Node Authorizer, Kubelets must use a credential that identifies them as being in the system:nodes group, with a username of system:node:<nodeName>. In this section you will create a certificate for each kubeadm-proj worker node that meets the Node Authorizer requirements.

# Generate a certificate and private key for each kubeadm-proj worker node:

for i in 0 1 2; do
  instance="worker${i}"
  instance_hostname="ip-10-0-1-2.${i}" 
  cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance_hostname}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "kubeadm-proj",
      "ST": "Oregon"
    }
  ]
}
EOF

  # Get external IP address
  external_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=${instance}" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  # Check if external IP is empty
  if [ -z "${external_ip}" ]; then
    echo "Error: Unable to retrieve external IP for ${instance}"
  else
    echo "External IP for ${instance}: ${external_ip}"
  fi

  # Get internal IP address
  internal_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=${instance}" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PrivateIpAddress')

  # Check if internal IP is empty
  if [ -z "${internal_ip}" ]; then
    echo "Error: Unable to retrieve internal IP for ${instance}"
  else
    echo "Internal IP for ${instance}: ${internal_ip}"
  fi
  
  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=${instance_hostname},${external_ip},${internal_ip} \
    -profile=kubeadm-proj \
    worker-${i}-csr.json | cfssljson -bare worker-${i}
done


# Results:

# worker-0-key.pem
# worker-0.pem
# worker-1-key.pem
# worker-1.pem
# worker-2-key.pem
# worker-2.pem
# The Controller Manager Client Certificate
# Generate the kube-controller-manager client certificate and private key:

cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "kubeadm-proj",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubeadm-proj \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager


# Results:

# kube-controller-manager-key.pem
# kube-controller-manager.pem
# The Kube Proxy Client Certificate
# Generate the kube-proxy client certificate and private key:

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "kubeadm-proj",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubeadm-proj \
  kube-proxy-csr.json | cfssljson -bare kube-proxy


# Results:

# kube-proxy-key.pem
# kube-proxy.pem
# The Scheduler Client Certificate
# Generate the kube-scheduler client certificate and private key:

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "kubeadm-proj",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubeadm-proj \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

# Results:

# kube-scheduler-key.pem
# kube-scheduler.pem
# The kubeadm-proj API Server Certificate
# The kubeadm-proj static IP address will be included in the list of subject alternative names for the kubeadm-proj API Server certificate. This will ensure the certificate can be validated by remote clients.

# Generate the kubeadm-proj API Server certificate and private key:

kubeadm-proj_HOSTNAMES=kubeadm-proj,kubeadm-proj.default,kubeadm-proj.default.svc,kubeadm-proj.default.svc.cluster,kubeadm-proj.svc.cluster.local

cat > kubeadm-proj-csr.json <<EOF
{
  "CN": "kubeadm-proj",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "kubeadm-proj",
      "OU": "kubeadm-proj",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.0.1.10,10.0.1.11,10.0.1.12,${kubeadm-proj_PUBLIC_ADDRESS},127.0.0.1,${kubeadm-proj_HOSTNAMES} \
  -profile=kubeadm-proj \
  kubeadm-proj-csr.json | cfssljson -bare kubeadm-proj


# The kubeadm-proj API server is automatically assigned the kubeadm-proj internal dns name, which will be linked to the first IP address (10.32.0.1) from the address range (10.32.0.0/24) reserved for internal cluster services during the control plane bootstrapping lab.

# Results:

# kubeadm-proj-key.pem
# kubeadm-proj.pem
# The Service Account Key Pair
# The kubeadm-proj Controller Manager leverages a key pair to generate and sign service account tokens as described in the managing service accounts documentation.

# Generate the service-account certificate and private key:

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "kubeadm-proj",
      "OU": "kubeadm-proj",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubeadm-proj \
  service-account-csr.json | cfssljson -bare service-account

# Results:

# service-account-key.pem
# service-account.pem
# Distribute the Client and Server Certificates
# Copy the appropriate certificates and private keys to each worker instance:


for instance in "${instances[@]}"; do
  # Get external IP address of the EC2 instance
  external_ip=$(aws ec2 describe-instances --profile "${aws_profile}" --region "${AWS_REGION}" \
    --filters "Name=tag:Name,Values=${instance}" "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  # Check if external IP is empty
  if [ -z "${external_ip}" ]; then
    echo "Error: Unable to retrieve external IP for ${instance}"
    continue
  fi

  # Copy files to the EC2 instance using SCP
  scp -i kubeadm-proj.id_rsa ca.pem "${instance}-key.pem" "${instance}.pem" "ubuntu@${external_ip}:~/"

  # Check SCP exit status
  if [ $? -eq 0 ]; then
    echo "Files copied successfully to ${instance}"
  else
    echo "Error: Failed to copy files to ${instance}"
  fi
done
# Copy the appropriate certificates and private keys to each controller instance:

for instance in controller-0 controller-1 controller-2; do
  external_ip=$(multipass info worker1 | head -3 | tail -1 | awk '{print $2}')

  scp -i kubeadm-proj.id_rsa \
    ca.pem ca-key.pem kubeadm-proj-key.pem kubeadm-proj.pem \
    service-account-key.pem service-account.pem ubuntu@${external_ip}:~/
done

# The kube-proxy, kube-controller-manager, kube-scheduler, and kubelet client certificates will be used to generate client authentication configuration files in the next lab.