#!/bin/bash

ssh kube-master-1 "sudo kubeadm init --config=kube-config.yaml"
ssh kube-master-1 "sudo tar -zcvf pki.tar.gz /etc/kubernetes/pki"
scp kube-master-1:~/pki.tar.gz .
scp pki.tar.gz kube-master-2:~
scp pki.tar.gz kube-master-3:~
rm pki.tar.gz

ssh kube-master-2 /bin/bash << EOF
  tar -zxvf pki.tar.gz
  sudo mv etc/kubernetes/pki /etc/kubernetes/
  rm -rf /etc/kubernetes/pki/apiserver*
EOF

ssh kube-master-3 /bin/bash << EOF
  tar -zxvf pki.tar.gz
  sudo mv etc/kubernetes/pki /etc/kubernetes/
  rm -rf /etc/kubernetes/pki/apiserver*
EOF

# mkdir -p $HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# sudo chown $(id -u):$(id -g) $HOME/.kube/config
