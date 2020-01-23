[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
EnvironmentFile=/etc/etcd/etcd.env
ExecStart=/usr/local/bin/etcd \
  --cert-file=/etc/etcd/kubernetes-cert.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --peer-cert-file=/etc/etcd/kubernetes-cert.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --trusted-ca-file=/etc/etcd/ca-cert.pem \
  --peer-trusted-ca-file=/etc/etcd/ca-cert.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --initial-advertise-peer-urls https://$${PRIVATE_IP}:2380 \
  --listen-peer-urls https://$${PRIVATE_IP}:2380 \
  --listen-client-urls https://$${PRIVATE_IP}:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://$${PRIVATE_IP}:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster ${CONTROLLER_IP_CONFIG} \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
