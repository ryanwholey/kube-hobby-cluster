#!/usr/bin/env bash

set -ex -o pipefail

PRIVATE_IP=$(curl -fsS http://169.254.169.254/latest/meta-data/local-ipv4)
HOST_NAME=$(hostname -s)

sudo hostnamectl set-hostname $(curl http://169.254.169.254/latest/meta-data/local-hostname)

# ETCD
sudo mkdir -p \
  /etc/etcd \
  /var/lib/etcd

cat > /etc/etcd/etcd.env <<EOF
PRIVATE_IP=$PRIVATE_IP
ETCD_NAME=$HOST_NAME
EOF

curl -o /tmp/etcd.tar.gz -fsSL https://github.com/etcd-io/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz
tar xvf /tmp/etcd.tar.gz -C /tmp
sudo mv /tmp/etcd-v${ETCD_VERSION}-linux-amd64/etcd* /usr/local/bin

sudo cp \
  /tmp/ca-cert.pem \
  /tmp/kubernetes-key.pem \
  /tmp/kubernetes-cert.pem \
  /etc/etcd/

sudo cp /tmp/etcd.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd


# KUBERNETES

sudo mkdir -p \
  /etc/kubernetes/config/ \
  /var/lib/kubernetes/

curl -o /tmp/kube-apiserver -fsS https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kube-apiserver
chmod +x /tmp/kube-apiserver
sudo mv /tmp/kube-apiserver /usr/local/bin/

curl -o /tmp/kube-controller-manager -fsS https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kube-controller-manager
chmod +x /tmp/kube-controller-manager
sudo mv /tmp/kube-controller-manager /usr/local/bin/

curl -o /tmp/kube-scheduler -fsS https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kube-scheduler
chmod +x /tmp/kube-scheduler
sudo mv /tmp/kube-scheduler /usr/local/bin/

curl -o /tmp/kubectl -fsS https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl
chmod +x /tmp/kubectl
sudo mv /tmp/kubectl /usr/local/bin/

sudo cp \
  /tmp/ca-cert.pem \
  /tmp/ca-key.pem \
  /tmp/kubernetes-key.pem \
  /tmp/kubernetes-cert.pem \
  /tmp/service-account-key.pem \
  /tmp/service-account-cert.pem \
  /tmp/encryption-config.yaml \
  /tmp/kube-controller-manager.kubeconfig \
  /tmp/kube-scheduler.kubeconfig \
  /var/lib/kubernetes/

sudo cp \
  /tmp/kube-scheduler.yaml \
  /etc/kubernetes/config/

cat > /var/lib/kubernetes/kube-apiserver.env <<EOF
PRIVATE_IP=$PRIVATE_IP
EOF

sudo cp \
  /tmp/kube-apiserver.service \
  /tmp/kube-scheduler.service \
  /tmp/kube-controller-manager.service \
  /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-scheduler kube-controller-manager
sudo systemctl start kube-apiserver kube-scheduler kube-controller-manager

# nginx api health
sudo apt-get update
sudo apt-get install -y nginx
sudo mv /tmp/kubernetes.default.svc.cluster.local /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/ || true
sudo systemctl restart nginx
sudo systemctl enable nginx
