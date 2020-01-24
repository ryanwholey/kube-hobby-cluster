#!/usr/bin/env bash

set -ex -o pipefail

HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
INSTANCE_INDEX=$(cat /tmp/instance_index)
sudo hostnamectl set-hostname $HOSTNAME

sed -i "s/<%instance_index%>/$INSTANCE_INDEX/g" /tmp/kubelet-config.yaml
sed -i "s/<%instance_index%>/$INSTANCE_INDEX/g" /tmp/10-bridge.conf

sudo apt-get update
sudo apt-get -y install \
  socat \
  conntrack \
  ipset

sudo swapoff -a

sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes \
  /etc/containerd/

curl -o /tmp/crictl.tar.gz -fsSL https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.15.0/crictl-v1.15.0-linux-amd64.tar.gz
tar xfz /tmp/crictl.tar.gz -C /tmp/
sudo mv /tmp/crictl /usr/local/bin/

curl -o /tmp/runc -fsSL https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64
chmod +x /tmp/runc
sudo mv /tmp/runc /usr/local/bin/

mkdir -p /tmp/cni-plugins
curl -o /tmp/cni-plugins.tar.gz -fsSL https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz
tar xfz /tmp/cni-plugins.tar.gz -C /tmp/cni-plugins/
sudo mv /tmp/cni-plugins/* /opt/cni/bin/

mkdir -p /tmp/containerd
curl -fsSL -o /tmp/containerd.tgz https://github.com/containerd/containerd/releases/download/v1.2.9/containerd-1.2.9.linux-amd64.tar.gz
tar xfz /tmp/containerd.tgz -C /tmp/containerd/
sudo mv /tmp/containerd/bin/* /bin/

curl -o /tmp/kubectl -fsS https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl
chmod +x /tmp/kubectl
sudo mv /tmp/kubectl /usr/local/bin/

curl -o /tmp/kube-proxy -fsS https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kube-proxy
chmod +x /tmp/kube-proxy
sudo mv /tmp/kube-proxy  /usr/local/bin/
  
curl -o /tmp/kubelet -fsS https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubelet
chmod +x /tmp/kubelet
sudo mv /tmp/kubelet /usr/local/bin/

sudo cp \
  /tmp/99-loopback.conf \
  /tmp/10-bridge.conf \
  /etc/cni/net.d/

sudo cp /tmp/containerd-config.toml /etc/containerd/config.toml

sudo cp \
  /tmp/containerd.service \
  /tmp/kubelet.service \
  /tmp/kube-proxy.service \
  /etc/systemd/system/

sudo cp /tmp/kubelet-key-$INSTANCE_INDEX.pem  /var/lib/kubelet/kubelet-key.pem
sudo cp /tmp/kubelet-cert-$INSTANCE_INDEX.pem  /var/lib/kubelet/kubelet-cert.pem
sudo cp /tmp/kubelet-$INSTANCE_INDEX.kubeconfig /var/lib/kubelet/kubeconfig

sudo cp \
  /tmp/kubelet-config.yaml \
  /var/lib/kubelet/

sudo cp /tmp/ca-cert.pem /var/lib/kubernetes/

sudo cp \
  /tmp/kube-proxy.kubeconfig \
  /tmp/kube-proxy-config.yaml \
  /var/lib/kube-proxy/

sudo mv /var/lib/kube-proxy/kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

sudo systemctl daemon-reload
sudo systemctl enable containerd kubelet kube-proxy
sudo systemctl start containerd kubelet kube-proxy
