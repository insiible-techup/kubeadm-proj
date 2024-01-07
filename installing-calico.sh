# install the Tigera Calico operator and custom resource definitions.

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml

# Install Calico by creating the necessary custom resource. For more information on configuration options available in this manifest

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

# Confirm that all of the pods are running with the following command.

watch kubectl get pods -n calico-system

# Remove the taints on the control plane so that you can schedule pods on it.

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-