
Port of K8S-TESTBED to the Raspberry Pi

# Installation - 32 bit (for all Pi versions prior to v3 which has the A53 CPU, for v3 skip down to the 64 bit instructions)
Hypriot suggests using their flash tool to burn the SD image.  While other IMG burning tools are available,
the one from [Hypriot](https://github.com/hypriot/flash) is OS aware and able to perform a few nice to have operations from the commandline like
setting the hostname.  Unfortunately, it is for MAC and Linux users only.  For Windows users you have to use a [different set](https://blog.hypriot.com/getting-started-with-docker-and-windows-on-the-raspberry-pi/) which requires you to manually edit the /user-data file on the SD since Hypriot uses [cloud-init](https://cloud-init.io) on the first boot (at the very least, hostname).
1. [Hypriot has an option](https://blog.hypriot.com/post/setup-kubernetes-raspberry-pi-cluster/) which sets up repos and uses kubeadm and flanneld (only option for ARM)
      - curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
      - echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
      - apt-get update && apt-get install -y kubeadm
      - kubeadm init --pod-network-cidr=10.244.0.0/16
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
