#!/bin/sh
echo "---------------------Beginning Common Configuration Tasks ------------------------------"

clusternet=$1


echo "Setting up repos and installing docker-ce and kubeadm"
cp /vagrant/yum-repos/ceph-deploy.repo /etc/yum.repos.d/ceph-deploy.repo
cp /vagrant/yum-repos/kubernetes.repo /etc/yum.repos.d/kubernetes.repo
echo "Updating Image"
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y update
echo "Installing Docker, Net-tools, Git, CEPH and Kubernetes"
yum -y install docker-ce net-tools git maven ceph-common kubeadm kubectl kubelet jq ntfs-3g

echo "Correcting cgroup to match and setting hostname"
sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

#must be done after docker installation.
iptables -P FORWARD ACCEPT
 
 
echo "RBD Setup."
modprobe rbd

echo "starting up docker and kubelet"
for SERVICE in docker kubelet
do
  systemctl stop $SERVICE
  systemctl start $SERVICE
  systemctl enable $SERVICE
  systemctl status $SERVICE
done


echo "---------------------Completed Common Configuration Tasks ------------------------------"




