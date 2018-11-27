#!/bin/sh

echo -e "\033[1;35m---------------------Setting up K8S Demo------------------------------\033[0m"
kubectl version
echo -e "\033[1;34mInstalling Flannel CNI\033[0m"
curl -sSL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml| kubectl create -f -

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
echo -e "\033[1;34mExposing Grafana using nodeport 31000.\033[0m"
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


echo -e "\033[1;34mInstalling Jenkins.\033[0m"
USE_JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
echo "
---
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins
" | kubectl create -f - 
kubectl create -n jenkins configmap kubeconfig --from-file /home/pirate/.kube/config
echo "
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: jenkins
rules:
- apiGroups: [\"\"]
  resources: [\"pods\"]
  verbs: [\"create\",\"delete\",\"get\",\"list\",\"patch\",\"update\",\"watch\"]
- apiGroups: [\"\"]
  resources: [\"pods/exec\"]
  verbs: [\"create\",\"delete\",\"get\",\"list\",\"patch\",\"update\",\"watch\"]
- apiGroups: [\"\"]
  resources: [\"pods/log\"]
  verbs: [\"get\",\"list\",\"watch\"]
- apiGroups: [\"\"]
  resources: [\"secrets\"]
  verbs: [\"get\"]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins
subjects:
- kind: ServiceAccount
  name: jenkins
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-home
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: jenkins-config
data:
  kubectl.groovy: |
    #!groovy
    
    def procCurl = \"curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/`arch`/kubectl\".execute()
    Thread.start {System.err << procCurl.err}
    procCurl.waitFor()
    
    def procChmod = \"chmod +x kubectl \".execute()
    Thread.start {System.err << procChmod.err}
    procChmod.waitFor()
    
    def procMv = \"mv kubectl /usr/local/bin/kubectl\".execute()
    Thread.start {System.err << procMv.err}
    procMv.waitFor()
    
    def procIns = \"apk add gettext\".execute()
    Thread.start {System.err << procIns.err}
    procIns.waitFor()
 
  security.groovy: |
    #!groovy
 
    import jenkins.model.*
    import hudson.security.*
    import jenkins.security.s2m.AdminWhitelistRule
    import com.cloudbees.plugins.credentials.Credentials
    import com.cloudbees.plugins.credentials.CredentialsScope
    import com.cloudbees.plugins.credentials.common.IdCredentials
    import com.cloudbees.plugins.credentials.domains.Domain	
    import com.cloudbees.plugins.credentials.SystemCredentialsProvider
    import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
    import com.microsoft.jenkins.kubernetes.credentials.*
    
    def instance = Jenkins.getInstance()
 
    def hudsonRealm = new HudsonPrivateSecurityRealm(false)
    hudsonRealm.createAccount(\"admin\", \"admin\")
    instance.setSecurityRealm(hudsonRealm)
 
    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    instance.setAuthorizationStrategy(strategy)
    instance.save()
 
    Jenkins.instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)
    
    provider = SystemCredentialsProvider.getInstance()
    nexusCred = new UsernamePasswordCredentialsImpl(CredentialsScope.valueOf(\"GLOBAL\"), \"nexus-admin\", \"nexus-admin\", \"admin\", \"admin123\")
    provider.getCredentials().add(nexusCred)
    provider.save()
    kubeconfig = new KubeconfigCredentials.FileOnMasterKubeconfigSource(\"/var/jenkins_home/.kube/config\")
    k8sCred = new KubeconfigCredentials(CredentialsScope.valueOf(\"GLOBAL\"), \"kube_adm\", \"Kubernetes Admin\", kubeconfig)
    provider.getCredentials().add(k8sCred)
    provider.save()

  loadPlugins.groovy: |
    #!groovy

    import jenkins.model.*
    import java.util.logging.Logger
    def logger = Logger.getLogger(\"\")
    def installed = false
    def initialized = false
    def pluginParameter=\"antisamy-markup-formatter matrix-auth blueocean:latest kubernetes-cd kubernetes-cli copyartifact ws-cleanup hp-application-automation-tools-plugin promoted-builds-simple\"
    def plugins = pluginParameter.split()
    logger.info(\"\" + plugins)
    def instance = Jenkins.getInstance()
    def pm = instance.getPluginManager()
    def uc = instance.getUpdateCenter()
    plugins.each {
      logger.info(\"Checking \" + it)
      if (!pm.getPlugin(it)) {
        logger.info(\"Looking UpdateCenter for \" + it)
        if (!initialized) {
          uc.updateAllSites()
          initialized = true
        }
        def plugin = uc.getPlugin(it)
        if (plugin) {
          logger.info(\"Installing \" + it)
            def installFuture = plugin.deploy()
          while(!installFuture.isDone()) {
            logger.info(\"Waiting for plugin install: \" + it)
            sleep(3000)
          }
          installed = true
        }
      }
    }
    if (installed) {
      logger.info(\"Plugins installed, initializing a restart!\")
      instance.save()
      instance.restart()
    }	
  setExecutorCount.groovy: |
    #!groovy
    import groovy.xml.XmlUtil
    import jenkins.model.*

    configFilePath = '/var/jenkins_home/config.xml'
    configFileContents = new File(configFilePath).text

    def config = new XmlSlurper().parseText(configFileContents)

    config.numExecutors = 6

    def writer = new FileWriter(configFilePath)
    XmlUtil.serialize(config, writer)
    Jenkins.instance.reload()
  setProxy.groovy: |
    import jenkins.*
    import jenkins.model.*
    import hudson.*
    import hudson.model.*
    instance = Jenkins.getInstance()
    globalNodeProperties = instance.getGlobalNodeProperties()
    envVarsNodePropertyList = globalNodeProperties.getAll(hudson.slaves.EnvironmentVariablesNodeProperty.class)
    newEnvVarsNodeProperty = null
    envVars = null
    if ( envVarsNodePropertyList == null || envVarsNodePropertyList.size() == 0 ) {
      newEnvVarsNodeProperty = new hudson.slaves.EnvironmentVariablesNodeProperty();
      globalNodeProperties.add(newEnvVarsNodeProperty)
      envVars = newEnvVarsNodeProperty.getEnvVars()
    } else {
      envVars = envVarsNodePropertyList.get(0).getEnvVars()
    }
    envVars.put(\"http_proxy\", \"$HTTP_PROXY\")
    envVars.put(\"https_proxy\", \"$HTTPS_PROXY\")
    envVars.put(\"no_proxy\", \"$NO_PROXY\")
    instance.save()
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: jenkins
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      serviceAccount: jenkins
      securityContext:
        runAsUser: 0
        fsGroup: 1000
      containers:
      - name: jenkins
        image: wroney/rpi-jenkins-alpine:latest
        env:
        - name: JAVA_OPTS
          value: \"$USE_JAVA_OPTS\"
        - name: HTTP_PROXY
          value: $HTTP_PROXY
        - name: HTTPS_PROXY
          value: $HTTPS_PROXY
        - name: NO_PROXY
          value: $NO_PROXY
        - name: http_proxy
          value: $HTTP_PROXY
        - name: https_proxy
          value: $HTTPS_PROXY
        - name: no_proxy
          value: $NO_PROXY
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        - name: jenkins-config
          mountPath: /var/jenkins_home/init.groovy.d/security.groovy
          mountPath: /usr/share/jenkins/ref/init.groovy.d/security.groovy
          subPath: security.groovy
        - name: jenkins-config
          mountPath: /var/jenkins_home/init.groovy.d/loadPlugins.groovy
          subPath: loadPlugins.groovy
        - name: jenkins-config
          mountPath: /var/jenkins_home/init.groovy.d/setExecutorCount.groovy
          subPath: setExecutorCount.groovy
        - name: jenkins-config
          mountPath: /var/jenkins_home/init.groovy.d/setProxy.groovy
          subPath: setProxy.groovy
        - name: jenkins-config
          mountPath: /var/jenkins_home/init.groovy.d/kubectl.groovy
          subPath: kubectl.groovy
        - name: docker-port
          mountPath: /var/run/docker.sock
        - name: kubeconfig
          mountPath: /var/jenkins_home/.kube/config
          subPath: config
        ports:
        - containerPort: 8080
        - containerPort: 50000
      volumes:
        - name: jenkins-home
          persistentVolumeClaim:
            claimName: jenkins-home
        - name: jenkins-config
          configMap:
            name: jenkins-config
        - name: docker-port
          hostPath:
            path: /var/run/docker.sock
            type: File
        - name: kubeconfig
          configMap:
            name: kubeconfig

---
apiVersion: v1
kind: Service
metadata:
  name: jenkins
spec:
  type: NodePort
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30003
  selector:
    app: jenkins
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins-slaveport
spec:
  ports:
    - port: 50000
      targetPort: 50000
  selector:
    app: jenkins

" | kubectl create -n jenkins -f -



echo -e "\033[1;35m---------------------K8S Demo Setup Complete------------------------------\033[0m"
