#!/bin/bash

# Update system and install required package
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y nfs-kernel-server

# Create NFS share directory and assign permissions
sudo mkdir /data
sudo chown nobody:nogroup /data
sudo chmod 777 /data

# Configure NFS share by appending the config string to the config file
echo "/data         10.0.0.0/8(rw,sync,insecure,no_subtree_check,crossmnt,fsid=0)" | sudo tee -a /etc/exports

# Apply changes
sudo exportfs -ar