[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \
  --authentication-kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig \
  --authorization-kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig \
  --config=/etc/kubernetes/config/kube-scheduler.yaml \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
