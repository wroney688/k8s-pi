#!/bin/sh

echo -e "\033[1;35m---------------------Setting up K8S Demo------------------------------\033[0m"
kubectl version
echo -e "\033[1;34mInstalling Flannel CNI\033[0m"
curl -sSL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml| sed "s/amd64/arm/g" | kubectl create -f -

echo -e "\033[1;34mInstalling K8S Dashboard\033[0m"
curl -s https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml | sed "s/amd64/arm64/g" | kubectl apply -f -
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard

echo -e "\033[1;34mInstalling Metric Server\033[0m"
curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/aggregated-metrics-reader.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/auth-delegator.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/auth-reader.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-apiservice.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-server-deployment.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/metrics-server-service.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
curl -s https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/resource-reader.yaml | sed "s/amd64/arm/g" | kubectl apply -f -

echo -e "\033[1;34mCreating NFS PVs from 192.168.10.8 for future use.\033[0m"
echo "
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0001
spec:
  capacity: 
    storage: 100Gi
  accessModes:
  - ReadWriteMany
  nfs:
    server: 192.168.10.8
    path: \"/data/pi-k8s/data1\"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0002
spec:
  capacity: 
    storage: 100Gi
  accessModes:
  - ReadWriteOnce
  nfs:
    server: 192.168.10.8
    path: \"/data/pi-k8s/data2\"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0003
spec:
  capacity: 
    storage: 100Gi
  accessModes:
  - ReadWriteOnce
  nfs:
    server: 192.168.10.8
    path: \"/data/pi-k8s/data3\"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0004
spec:
  capacity: 
    storage: 100Gi
  accessModes:
  - ReadWriteOnce
  nfs:
    server: 192.168.10.8
    path: \"/data/pi-k8s/data4\"
---
" | kubectl create -f -
echo -e "\033[1;34mDeploying Prometheus Operator.\033[0m"
git clone https://github.com/carlosedp/prometheus-operator-ARM
cd prometheus-operator-ARM
./deploy
echo "
apiVersion: v1
kind: Service
metadata:
  name: grafana-ext
spec:
  type: NodePort
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 31000
  selector:
    app: grafana
" | kubectl create -n monitoring -f -
echo -e "\033[1;35m---------------------K8S Demo Setup Complete------------------------------\033[0m"
