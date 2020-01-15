[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
EnvironmentFile=/etc/etcd/etcd.env
ExecStart=/usr/local/bin/etcd \
  --advertise-client-urls https://$${PRIVATE_IP}:2379 \
  --cert-file=/etc/etcd/kubernetes-cert.pem \
  --client-cert-auth \
  --data-dir=/var/lib/etcd \
  --discovery ${ETCD_DISCOVERY_URL} \
  --initial-advertise-peer-urls https://$${PRIVATE_IP}:2380 \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --listen-peer-urls https://$${PRIVATE_IP}:2380 \
  --listen-client-urls https://$${PRIVATE_IP}:2379,https://127.0.0.1:2379 \
  --logger=zap \
  --peer-cert-file=/etc/etcd/kubernetes-cert.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --peer-trusted-ca-file=/etc/etcd/ca-cert.pem \
  --peer-client-cert-auth \
  --trusted-ca-file=/etc/etcd/ca-cert.pem
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
