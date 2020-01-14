[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/var/lib/kubernetes/kube-apiserver.env
ExecStart=/usr/local/bin/kube-apiserver \
  --advertise-address=$${PRIVATE_IP} \
  --allow-privileged=true \
  --apiserver-count=${CONTROLLER_COUNT} \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/var/log/audit.log \
  --authorization-mode=Node,RBAC \
  --bind-address=0.0.0.0 \
  --client-ca-file=/var/lib/kubernetes/ca-cert.pem \
  --cloud-provider="aws" \
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --etcd-cafile=/var/lib/kubernetes/ca-cert.pem \
  --etcd-certfile=/var/lib/kubernetes/kubernetes-cert.pem \
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \
  --etcd-servers=${ETCD_DNS_NAME}:2379 \
  --event-ttl=1h \
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \
  --kubelet-certificate-authority=/var/lib/kubernetes/ca-cert.pem \
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes-cert.pem \
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \
  --kubelet-https=true \
  --runtime-config=api/all \
  --secure-port=${APISERVER_PORT} \
  --service-account-key-file=/var/lib/kubernetes/service-account-cert.pem \
  --service-cluster-ip-range=${KUBERNETES_SERVICE_CIDR} \
  --service-node-port-range=30000-32767 \
  --tls-cert-file=/var/lib/kubernetes/kubernetes-cert.pem \
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target