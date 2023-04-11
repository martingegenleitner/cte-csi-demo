# Demo App for CTE for Kubernetes

Small Golang Demo App that stores and displays a simple picture. It will be used to demonstrate transparent encryption of application data in container environments with THALES CipherTrust Transparent Encryption for Kubernetes ([CTE for Kubernetes](https://thalesdocs.com/ctp/cte-con/cte-k8s/latest/index.html)).

## Run the app locally

```shell
# Checkout the repo and change into its root directory
cd cte-csi-demo
# Build the image
docker build -t demo-app .
# Run the app and listen on the local port 8888
docker run -d --name demo-app -p 8888:80 demo-app
# Stop and remove the container and image to clean up
docker stop demo-app
docker rm demo-app
docker rmi demo-app
```

## Push app to DockerHub

```shell
# Build the app with the desired tag
docker build -t demo-app .
# Push the image to the registry
docker push demo-app
```

## Create EKS Cluster

Terraform files have been stolen from <https://github.com/hashicorp/learn-terraform-provision-eks-cluster> and instructions are taken from the offical terraform training site (<https://learn.hashicorp.com/tutorials/terraform/eks>).

```shell
# Move to the terraform files
cd cte-csi-demo/terraform/eks

# (optional) Login and ensure you are logged in via AWS CLI
aws configure
# (or via Authv2 and SSO)
# Configure SSO
aws configure sso
# Login via configured SSO if already done before
aws login sso --profile YOUR_SSO_PROFILE_NAME

# Check your identity with classic credentials (AccessKey)
aws sts get-caller-identity

# Check your identity with v2 sso credentials
aws sts get-caller-identity --profile YOUR_SSO_PROFILE_NAME

# Initialize terraform workspace
terraform init
# Deploy resources
terraform apply

# Merge k8s context to use EKS with kubectl
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)

# When you are finished using the EKS, destroy it to reduce costs
terraform destroy
```

## Create GKE Cluster

Terraform files have been stolen from <https://github.com/hashicorp/learn-terraform-provision-gke-cluster> and instructions are taken from the official terraform training site (<https://learn.hashicorp.com/tutorials/terraform/gke>). The file `terraform/gke/gke.tf` has been adjusted to include all OAuth-Scopes to allow GKE to fetch images from GCR.

```shell
# Move to the terraform files
cd cte-csi-demo/terraform/gke

# Ensure your gcloud is initialized and connected to your account
gcloud init
gcloud auth application-default login

# Initialize terraform workspace
terraform init
# Deploy resources
terraform apply

# Merge k8s context to use GKE with kubectl
gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --region $(terraform output -raw region)

# When you are finished using the GKE, destroy it to reduce costs
terraform destroy
```

## Setup NFS Servers in AWS and GCP

Both NFS servers must be configured to accept incoming NFS traffic and store files at `/data`.
Connect to both servers via SSH and copy+execute the script `${repository_root}/terraform/install_nfs-server.sh` as root (via sudo).

For NFS-Server on AWS EC2 use the username "ubuntu" and the private key file of the pubkey file used at `terraform/eks/nfs.tf`.

For NFS-Server on GCP's Compute Engine use the username defined in the file `terraform/gke/terraform.tfvars` with the according private key. In the sample it's also `ubuntu`.

## Create KMS in Azure

```shell
# List available images/versions of k170v
az vm image list --offer cm_k170v --all

# Accept the license terms
az vm image terms accept --urn thalesdiscplusainc1596561677238:cm_k170v:ciphertrust_manager:2.10.7973

# Create vm from image
az vm create --resource-group MartinGegenleitner --name cm-1 --image thalesdiscplusainc1596561677238:cm_k170v:ciphertrust_manager:2.10.7973 --size Standard_DS3_v2 --admin-username ksadmin --ssh-key-name cm-1_key --public-ip-sku Basic --vnet-name demo_vnet --location northeurope --subnet default
```

... or just follow the wizard when deploying a CipherTrust Manager Community Edition (CE) from the Azure Marketplace.

## Configure the Key Management Service

Perform the following steps on the vanilla CipherTrust-Manager created on Azure to prepare the endpoints for the CTE CSI integration.

1. Perform initial config of the appliance.
   1. Set SSH-key
   2. Set initial admin password
   3. Configure interface `web` as desired (e. g. upload a valid certificate or enable cert based auth)
2. Create a simple registration token in the Menu of Access Management -> Registration Tokens.
   1. Important: Set the usage limit to a high value as registrations and deregistrations on every creation of a Pod using CTE for Kubernetes. Recommondation for PoC: 1000
3. Configure CTE 4 K8s - change to the `Transparent Encryption` product tile
   1. On the `K8s Storage Groups`, create a new Storage Group with the following parameters. It is important to choose values that later match the parameter values from `k8s/cte-storageclass.yaml`
      1. Name = myapp-storage-group
      2. StorageClass = cte-4-k8s-sc
      3. Namespace = default
   2. Within the new storage group, create a new GuardPolicy of type `CTE for Kubernetes` and choose the name `op-encrypt-only` as it is important that the name matches the parameter `csi.cte.cpl.thalesgroup.com/policy` in the PVC configured at `k8s/cte-claim.yaml`. Create a policy with a single Security Rule which permits all access, applies the key and audits every access. Also use a single key rule with a simple AES key (don't use the XTS key!).

## Deploy the app on Kubernetes

### Deploy ingress with letsencrypt

Taken from <https://www.fosstechnix.com/kubernetes-nginx-ingress-controller-letsencrypt-cert-managertls/>

```shell
# Install nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx
# Check ingress and public service endpoint
kubectl get services

#############
# !!! Now apply DNS configuration to map your choosen DNS names to the kubernetes service endpoint!
#############

# Install certmanager for cluster
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml

# Create clusterissuer
kubectl apply -f cluster-issuer.yaml

# Create certificate
kubectl apply -f (eks|gke)-letsencrypt-cert.yaml

# Create ingress
kubectl apply -f (eks|gke)-ingress.yaml
```

### Deploy CTE for Kubernetes Storage driver

Checkout the repository from <https://github.com/thalescpl-io/cte-csi-deploy> and run...

```shell
./deploy.sh
```

... in `bash`.

### Deploy the actual applications

Before you begin to apply configuration to the cluster, make sure the files `k8s/cte-storageclass.yaml` and `k8s/cte-claim.yaml` contain the correct values from your key management setup!

```shell
# Ensure to be in the correct directory
cd cte-csi-demo/k8s

# Deploy the PV and PVC for the actual storage over NFS
kubectl apply -f (eks|gke)-nfs-claim.yaml

# Create the storage class and PVC for CTE CSI
kubectl apply -f cte-storageclass.yaml

# Create the PVC for the later application
kubectl apply -f cte-claim.yaml

# Finally deploy the application
kubectl apply -f app-deployment.yaml
```
