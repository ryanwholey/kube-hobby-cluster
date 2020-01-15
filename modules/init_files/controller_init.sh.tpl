#!/usr/bin/env bash

KUBERNETES_VERSION="1.15.3"
ETCD_VERSION="3.4.0"
PRIVATE_IP=$(curl -fsS http://169.254.169.254/latest/meta-data/local-ipv4)
HOST_NAME=$(hostname -s)

fetch-to-bin() {
  name="$1"

  curl -fsSL -o /tmp/$name "https://storage.googleapis.com/kubernetes-release/release/v$KUBERNETES_VERSION/bin/linux/amd64/$name"
  chmod +x "/tmp/$name"
  sudo mv "/tmp/$name" /usr/local/bin
}

sudo mkdir -p \
  /etc/etcd/ \
  /var/lib/etcd/ \
  /etc/kubernetes/config/ \
  /var/lib/kubernetes/

# etcd
curl -fsSL -o /tmp/etcd.tgz "https://github.com/etcd-io/etcd/releases/download/v$ETCD_VERSION/etcd-v$ETCD_VERSION-linux-amd64.tar.gz"
tar xvf /tmp/etcd.tgz -C /tmp
sudo cp /tmp/etcd-v$ETCD_VERSION-linux-amd64/etcd* /usr/local/bin/

sudo cp \
  /tmp/ca-cert.pem \
  /tmp/kubernetes-key.pem \
  /tmp/kubernetes-cert.pem \
  /etc/etcd/

cat > /etc/etcd/etcd.env <<EOF
PRIVATE_IP=$PRIVATE_IP
ETCD_NAME=$HOST_NAME
EOF

sudo cp \
  /tmp/etcd.service \
  /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd

# kubernetes
for bin in kube-apiserver kube-controller-manager kube-scheduler kubectl ; do
  fetch-to-bin $bin
done

echo foo > /tmp/kube-controller-manager.kubeconfig
echo bar > /tmp/kube-scheduler.kubeconfig

sudo cp \
  /tmp/ca-cert.pem \
  /tmp/ca-key.pem \
  /tmp/kubernetes-cert.pem \
  /tmp/kubernetes-key.pem \
  /tmp/service-account-cert.pem \
  /tmp/service-account-key.pem \
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
  /tmp/kube-controller-manager.service \
  /tmp/kube-scheduler.service \
  /etc/systemd/system/