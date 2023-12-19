#!/bin/bash


# Installing the Client Tools

# The cfssl and cfssljson command line utilities will be used to provision a PKI Infrastructure and generate TLS certificates.

# Download and install cfssl and cfssljson:

go install github.com/cloudflare/cfssl/cmd/cfssl@lates

# Verfication

cfssl version

# Installing kubectl

wget https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl