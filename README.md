
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

For  Pi versions prior to v3 which has the A53 CPU, you need to install using armhf/32bit.  That is [documented here.](32bit.md)


Hypriot suggests using their flash tool to burn the SD image.  While other IMG burning tools are available,
the one from [Hypriot](https://github.com/hypriot/flash) is OS aware and able to perform a few nice to have operations from the commandline like
setting the hostname.  Unfortunately, it is for MAC and Linux users only.  For Windows users you have to use a [different set](https://blog.hypriot.com/getting-started-with-docker-and-windows-on-the-raspberry-pi/) which requires you to manually edit the /user-data file on the SD since Hypriot uses [cloud-init](https://cloud-init.io) on the first boot (at the very least, hostname).


## 64 bit
Under x86, 64 bit causes a performance hit specifically because storage increases.  For ARM, you actually may see a speed increase of 15%; therefore, why not try?  SIMPLE!  Because Kubernetes and the embedded etcd in the control plane are built on Go, for v1.12.1 it's go 1.8.6.  Guess what: it has a performance problem for math prior to go 1.11 and as a result the kube-apiserver won't stay up.  No log messages, no errors jump out except an innocuous looking TLS handshake timeout amidst all the connection refused messages.  If you catch this:
 >12604 pod_workers.go:186] Error syncing pod c2f2a67aa6f9932cfdab011c76aeb5e5 ("kube-apiserver-pi-master_kube-system(c2f2a67aa6f9932cfdab011c76aeb5e5)", skipping: failed to "StartContainer" for "kube-apiserver" with CrashLoopBackOff: )

And notice how high CPU is going in `docker stats` , you might eventually google your way to [this article explaining the problem.](https://gitlab.com/daylight/kubernetes/commit/05876fa66a2d465d5181e3ef744dbfd05ad5ec48)  The extended timeout isn't enough though if using the Hypriot ARM64 image.  As a result, health check/readiness fails so docker purges and restarts the api-server container endlessly.  So, a hybrid cluster is in order:  master at arm32, workers at arm64 since really the performance you are focused on improving is on the workers.

Setting up a 64 bit follows this recipe:
- pi-master build
  1.  Burn the [Hypriot 1.9.0 (32 bit/armhf) image](http://blog.hypriot.com/downloads/) to an SD card.  In the cloud-init folder of this repo, is a user-data.master to reflect the setup beyond the base Hypriot 1.9.0, armhf image.  /etc/hosts is written out by this file so you'll need to modify to match your IP assignments.  Put this on the SD card replacing /user-data
- pi-node build.  A meta-data.master is provided as well to replace /meta-data if you want to customize the instance name for cloud-init.
  1.  Grab the latest 64 bit image built by [Dieter which was v20180429-184538 (prior didn't burn correctly for me)](https://github.com/DieterReuter/image-builder-rpi64/releases/tag/v20180429-184538)  and burn it to an SD as with the 32 bit image.  
    - Bring over the meta-data.node and user-data.node from the cloud-init folder in this repo.  Modify meta-data to change instance name and user-data to change the hostname.  /etc/hosts is written out by this file.  You'll notice that it removes and reinstalls docker-ce, this is to upgrade the version from 18.04.  Put this on the SD card replacing /user-data
    - Modify the /cmdline.txt file on the SD card and add cgroup_enable=memory (it has cgroup_memory=1 which was changed along the way).  cmdline.edited64.txt is provided in the cloud-init folder for reference.
- Software Installation
  1.  Grab this repo and run setup.sh to begin installing all of the k8s packages.  The easiest is to do this from the pi-master node.  This setup script does a lot of sed commands to get rid of the hard-coded amd64 specs on images embedded in the various yaml files.

# Blended K8s
If you are going to add amd64 nodes, then you may want to use the wroney/metrics-server:v0.3.1 image instead of the k8s.gcr.io one.  This is just a manifest built with the command below so you don't have to constantly edit the yaml based upon which node takes the pod.

>./manifest-tool push from-spec manifest-metrics-server.yaml


# Clean Alpine 64 setup
- This is TBD.  A clean Alpine based setup is another viable option.  This would reduce the footprint on the Pi nodes to the bare minimum and also provide an opportunity to rebuild the K8s components with GoLang >= v1.11 to fix the big number/math problem faced in Etcd as well.

# Multi-arch Docker build
- This is TBD as a result of this testbed becoming a hybrid of armv7 and armv8 (32/64 bit).  The idea is to use this in combination with the wroney/rpi-blueocean project to build arm and arm64 images and push them to docker hub.  This will allow a true arm64 build of Jenkins instead of running the armv7 version (since it's just a Java app) on the armv8 nodes.

# Setup of CGroups and Fix for Prometheus
- This is TBD.  Prometheus will crash a node over time due to unbounded memory consumption.  The correction is to adjust cgroup usage so that evictions occur sooner.  The eviction "should" reset the memory consumption.  Another option is to adjust Prometheus metric collection; however, this involves digging into the missing/incorrect/gappy open-source documentation to figure out how to limit appropriately for a microcloud.

# Quicklinks
[Assumes you have run kubectl proxy]

Package | Login Info | Full URL
------- | ---------- | -----------------------------------
K8s Dashboard | n/a | http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
Grafana | admin/admin | [http:// << your master IP>> :31000](http://192.168.10.20:31000)
Jenkins | admin/admin | [http:// << your master IP>> :30003](http://192.168.10.20:30003)
Prometheus | n/a | [http:// << your master IP>> :30900](http://192.168.10.20:30900)
