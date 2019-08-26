#!/usr/bin/env python

import sys
import os
import subprocess
import argparse
import uuid

parser = argparse.ArgumentParser(description='Create some certs!')


parser.add_argument(
    '--worker_public_ips',
    dest='worker_public_ips',
    help='Public ips of workers',
)
parser.add_argument(
    '--controller_public_ips',
    dest='controller_public_ips',
    help='Public ips of controllers',
)
parser.add_argument(
    '--worker_private_ips',
    dest='worker_private_ips',
    help='private ips of workers',
)
parser.add_argument(
    '--controller_private_ips',
    dest='controller_private_ips',
    help='private ips of controllers',
)

args = parser.parse_args()

outputs = {
    'worker': {
        'public': args.worker_public_ips.split(','),
        'private': args.worker_private_ips.split(','),
    },
    'controller': {
        'public': args.controller_public_ips.split(','),
        'private': args.controller_private_ips.split(','),
    }
}

instances = {}

for t in ['worker', 'controller']:
    for i in range(0, 3):
        instances['kube-{}-{}'.format(t, i+1)] = {
            'public_ip': outputs[t]['public'][i],
            'private_ip': outputs[t]['private'][i]
        }

print(instances)

def shell(cmd, silent=False):
    result = subprocess.check_output(cmd, shell=True)
    if not silent:
        print(result)
    return result


shell('rm -rf cert-files')
try:
    os.mkdir('cert-files')
except:
    pass

shell('rm -rf tmp')
try:
    os.mkdir('tmp')
except:
    pass

def run_gen_cert_script(script, fileDir='tmp'):
    fileName = str(uuid.uuid4())
    f = open('{}/{}.sh'.format(fileDir, fileName), 'w')
    f.write(script)
    f.close()
    shell('chmod +x {}/{}.sh'.format(fileDir, fileName))
    shell('docker run -v $(pwd):/code -w /code --rm kube-hard-way  sh -c "cd cert-files && ../{}/{}.sh"'.format(fileDir, fileName))

shell('cd .. && docker build  . -t kube-hard-way')

ca_cert = """
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca
"""

admin_cert = """
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
"""

controller_manager = """
cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manage
"""

def get_worker_script(instance, externalIp, internalIp):
    return """
cat > {instance}-csr.json <<EOF
{{
  "CN": "system:node:{instance}",
  "key": {{
    "algo": "rsa",
    "size": 2048
  }},
  "names": [
    {{
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }}
  ]
}}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname={instance},{externalIp},{internalIp} \
  -profile=kubernetes \
  {instance}-csr.json | cfssljson -bare {instance}
""".format( instance=instance, externalIp=externalIp, internalIp=internalIp)

kube_proxy = """
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
"""
kube_scheduler = """
cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler
"""

kubernetes_api_server = """
cat > kubernetes-csr.json <<EOF
{{
  "CN": "kubernetes",
  "key": {{
    "algo": "rsa",
    "size": 2048
  }},
  "names": [
    {{
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }}
  ]
}}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,{public_ips},127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes
""".format(public_ips=','.join(map(lambda x: str(x[1]['public_ip']), instances.items())))

service_account = """
cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account
"""

def gen_certs():
    run_gen_cert_script(ca_cert)
    run_gen_cert_script(admin_cert)

    for t in ('worker', ):
        for i in range (0, 3):
            name = 'kube-{}-{}'.format(t, i+1)

            run_gen_cert_script(
                get_worker_script(name, instances[name]['public_ip'], instances[name]['private_ip'])
            )

    run_gen_cert_script(controller_manager)
    run_gen_cert_script(kube_proxy)
    run_gen_cert_script(kube_scheduler)
    run_gen_cert_script(kubernetes_api_server)
    run_gen_cert_script(service_account)

def main():
    gen_certs()
    shell('rm -rf tmp')

main()
