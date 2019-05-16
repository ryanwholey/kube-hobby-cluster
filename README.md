# Hobby Cluster

This is my hobby cluster! It's a project for me to experiment with tools like terraform, aws, ansbile and kubernetes. It's originally based off of a kubernetes-from-scratch approach, outlined in this [blog post](https://blog.inkubate.io/install-and-configure-a-multi-master-kubernetes-cluster-with-kubeadm/) but I will likely move on to the slightly more in depth version of this idea with [kubernetes the hard way](https://github.com/kelseyhightower/kubernetes-the-hard-way) soon. Open issues if you have any cool suggestions or ideas!

## Dependencies

- node
- python3
- terraform
- docker-compose / docker
- aws account access key and secret

## Setup

```
python3 -m venv venv
. venv/bin/activate
pip install -r requirements.txt
```

Add aws client and secret to file called `terraform/secrets.tfvars`

## Creation

Run the following scripts. Warning, running these blindly will overwrite your ssh config, be careful.

```
pushd terraform && terraform init && terraform apply -var-file="secrets.tfvars" -auto-approve && popd
./scripts/writeHosts > hosts
./scripts/writeSshConfig > ~/.ssh/config
ansible-playbook -i hosts playbooks/init.yml
ansible-playbook -i hosts playbooks/load-balancer.yml
./scripts/gencerts
ansible-playbook -i hosts playbooks/etcd.yml
ansible-playbook -i hosts playbooks/kube-dependencies.yml
ansible-playbook -i hosts playbooks/kube-config.yml
./scripts/kube-init.sh
```

ssh into master 2 & 3

```
sudo kubeadm join 10.10.40.93:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
  --experimental-control-plane
```

ssh into workers 1,2 & 3

```
sudo kubeadm join 10.10.40.93:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

To enable kubectl on master nodes:

```
mkdir -p /home/ubuntu/.kube && \
yes | sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config &&  \
sudo chown $(id -u):$(id -g) /home/ubuntu/.kube/config
```

Deploy weave CNI 

```
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

Fix coredns loopback issue

```
ssh kube-master-1
$ kubectl edit cm coredns -n kube-system
```
delete ‘loop’ 
save and exit


## Destroy

pushd terraform && terraform destroy -auto-approve && popd

## TODOS

- Add nginx ingress controller
- Configure local kubectl
- Automate joining and patching cluster
- Full script to bring up cluster (vs individual steps)
- Move away from ansible directly and use the terraform ansible provider
- Remove haproxy lb in favor of managed NLB

