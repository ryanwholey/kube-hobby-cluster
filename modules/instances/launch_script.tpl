#!/bin/bash -xe

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

sudo apt-get update
sudo apt-get install -y \
  awscli
aws s3 cp s3://${BUCKET}/${NODE_TYPE} /tmp --recursive
chmod +x /tmp/init.sh
sudo /tmp/init.sh
