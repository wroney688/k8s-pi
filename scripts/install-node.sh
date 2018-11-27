#!/bin/sh
echo "---------------------Beginning Node Configuration------------------------------"
clusternet=$1
echo "Disabling SELINUX"
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sysctl net.ipv4.conf.all.forwarding=1
sysctl net.ipv6.conf.all.forwarding=1
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --permanent --add-port=6783/tcp
firewall-cmd --reload
modprobe br_netfilter
sysctl net.bridge.bridge-nf-call-iptables=1

echo "K8s doesn't like swap"
swapoff -a

modprobe ip_vs_sh
modprobe ip_vs_wrr
modprobe ip_vs_rr
modprobe ip_vs
kubeadm join --token 123456.1234567890abcdef $clusternet:6443 --discovery-token-unsafe-skip-ca-verification --ignore-preflight-errors=SystemVerification
kubectl label nodes `hostname` cputype=x86
mkdir /home/vagrant/.kube
cp -i /vagrant/kubeconfig.yaml /home/vagrant/.kube/config
chown -R vagrant /home/vagrant/.kube/config
cat /vagrant/masterkey.pub >> /home/vagrant/.ssh/authorized_keys

echo "---------------------Completed Node Configuration------------------------------"





