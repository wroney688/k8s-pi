
Port of K8S-TESTBED to the Raspberry Pi

# Purpose
With the K8S-TESTBED project maturing and extending to be not only a technology testbed
and demonstration but also a demonstration platform for incorporating true performance
testing and engineering into the DevOps CI/CD pipeline, and interesting idea came about:
Can a microservice automated build and test pipeline operate within a microCloud?  This question
is heavily rooted in the [example from 2015](https://kubernetes.io/blog/2015/12/creating-raspberry-pi-cluster-running/)
but brought up to current versions since [Kubernetes](https://kubernetes.io) and [Hypriot](https://hypriot.com) have evolved substantially.

The target end-state would be a kubernetes cluster with Jenkins capable of launching the MS-DEMO and executing a simple performance test with analysis.

# Microcloud

The idea of a microcloud demonstration platform is attractive due to the idea of extremely low cost
as well as insuring scale of microservices.  If a microservice, and in fact the entire CI/CD pipeline
can operate in a microcloud, then the promise of greater efficiency and cost containment of all these
emerging technology stacks is quantitatively demonstrated.

The microcloud architecture for this experiment is a Kubernetes cluster running on a set
of 4 Raspberry Pi 3s with the following cost breakdown:

Quantity | Unit Cost | Description
------- | -------- | -----------------------------------------------
4|$40| Raspberry Pi 3 B+ (armv7, so 32 bit)
4|$9| Sumsung EVO 32GB microSD cards
4|$1| Cat6 Ethernet Cables (1 ft)
4|$1| Micro USB cables
1|$31| Multiport USB Rapid Charger
1|--| 8 port 10/100 switch
1|$34| Stackable case for 4 Rasberry Pi 3 B+

Total cost: $269 (excluding network switch)

NOTE: this build mirrors the 2015 build using a 10/100 wired switch.  The Pi3 includes build-in wifi so the need
for the Cat6 cables and switch could no longer be needed.  One to-do item would be to use the wifi on the Master to
expose the cluster to the outside world and use the wired network for all intra-cluster communication.

# Installation
Hypriot suggests using their flash tool to burn the SD image.  While other IMG burning tools are available,
the one from [Hypriot](https://github.com/hypriot/flash) is OS aware and able to perform a few nice to have operations from the commandline like
setting the hostname.  Unfortunately, it is for MAC and Linux users only.  For Windows users you have to use a [different set](https://blog.hypriot.com/getting-started-with-docker-and-windows-on-the-raspberry-pi/) which requires you to manually edit the /user-data file on the SD since Hypriot uses [cloud-init](https://cloud-init.io) on the first boot (at the very least, hostname).
1. [Hypriot has an option](https://blog.hypriot.com/post/setup-kubernetes-raspberry-pi-cluster/) which sets up repos and uses kubeadm and flanneld (only option for ARM)
      - curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
      - echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
      - apt-get update && apt-get install -y kubeadm
      - kubeadm init --pod-network-cidr 10.244.0.0/16
      - flannel setup on master:  curl -sSL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml| sed "s/amd64/arm/g" | kubectl create -f -
2.  Installing packages
    - [Dashboard](kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/alternative/kubernetes-dashboard-arm.yaml) described [here](https://gist.github.com/elafargue/a822458ab1fe7849eff0a47bb512546f)
      - Access it thru [kubectl proxy](http://localhost:8001/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy)
    - Metric server monitoring (> K8s 1.8).  Have to do all the extra work because they didn't include $ARCH but hardcoded to amd64.
      - curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/aggregated-metrics-reader.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
      - curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/auth-delegator.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
      - curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/auth-reader.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
      - curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-apiservice.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
      - curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-server-deployment.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
      - curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-server-service.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
      - curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/resource-reader.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
    - [Found this](https://itnext.io/creating-a-full-monitoring-solution-for-arm-kubernetes-cluster-53b3671186cb) version of Prom/Grafana rebuilt for ARM.  Created some static PVs on NFS to support this.  Also created a dummy storageclass called standard, set to default, so that the PVCs wouldn't hang up.  The other examples were way too clunky and pre-dated the metric-server.  Carlosedp had to recompile it all and tweak it all to use ARM vs the hardcoded AMD64 embedded in the official project's yamls.  Don't forget to patch Grafana-deployment to expose a nodeport for access (copied from my k8s-testbed, I put it on 31000)
