#!bin/bash

export GUID=`hostname|awk -F. '{print $2}'`
echo "export GUID=$GUID" >> ~/.bashrc
echo $GUID

sed -i s/GUID/${GUID}/g inventory/hosts

cp -fp inventory/hosts /etc/ansible/hosts
cp -fp files/htpasswd.openshift /root/htpasswd.openshift


ansible-playbook -f 20 /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

ansible-playbook -f 20 /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

ansible masters[0] -b -m fetch -a "src=/root/.kube/config dest=/root/.kube/config flat=yes"

oc login -u system:admin


sh -x files/pv1.sh
sh -x files/pv2.sh
sh -x files/pv3.sh

cat /root/pvs/* | oc create -f -

oc create -f files/template.yaml -n default

oc label namespace default name=default

ansible masters -m shell -a"sed -i -e \"\:projectRequestTemplate: s:'':'default/project-request':\" /etc/origin/master/master-config.yaml"

ansible masters -m shell -a"sed -i -e 3i\"\    ProjectRequestLimit:\n      configuration:\n        apiVersion: v1\n        kind: ProjectRequestLimitConfig\n        limits:\n        - selector:\n            client: alpha\n          maxProjects: 2\n        - selector:\n            client: beta \n          maxProjects: 2\n        - maxProjects: 1\" /etc/origin/master/master-config.yaml"



ansible masters -m shell  -a"systemctl stop atomic-openshift-master-api"
ansible masters -m shell -a"systemctl stop atomic-openshift-master-controllers"
ansible nodes -m shell -a"systemctl stop atomic-openshift-node"
ansible masters -m shell -a"systemctl start atomic-openshift-master-api"
ansible masters -m shell -a"systemctl start atomic-openshift-master-controllers"
ansible masters -m shell -a"systemctl start atomic-openshift-node"
ansible nodes -m shell -a"systemctl start atomic-openshift-node"

sleep 1m

oc login -u Amy -p Amy
oc login -u Andrew -p Andrew
oc login -u Betty -p Betty
oc login -u Brian -p Brian
oc login -u common -p common

oc login -u system:admin
oc label user Amy client=alpha
oc label user Andrew client=alpha
oc label user Betty client=beta
oc label user Brian client=beta
oc label user common client=common

oc login -u system:admin
oc get all -o wide | grep po/docker-registry
oc get pv | grep registry
oc get all -o wide | grep po/router
oc get pv
oc new-project testnodejs
oc new-app nodejs-mongo-persistent
sleep 10m
curl -D - -s  -o /dev/null nodejs-mongo-persistent-testnodejs.apps.$GUID.example.opentlc.com

oc project default
oc get nodes --show-labels | grep master
ansible etcd -m shell -a"systemctl status etcd | grep Active"

oc login https://loadbalancer.$GUID.internal:443 -u system:admin
oc get route --all-namespaces
oc get nodes --show-labels | grep env=infra


oc get clusternetwork
ansible masters -m shell -a"cat /etc/origin/master/master-config.yaml | grep projectRequestTemplate"
oc describe template project-request | grep NetworkPolicy

oc get pod --all-namespaces | grep logging
oc get pod --all-namespaces | grep metrics
oc get all -o wide | grep -e po/docker-registry -e po/router
oc get all -o wide -n logging | grep po/
oc get all -o wide -n openshift-metrics | grep po/
oc get pod --all-namespaces | grep service


oc project cicd
oc new-app jenkins-persistent
sleep 15m
oc get pod | grep jenkins
oc get pv | grep jenkins

cd ~

git clone https://github.com/OpenShiftDemos/openshift-tasks.git
sed -i s/jboss-eap64-openshift:latest/jboss-eap64-openshift:1.7/ openshift-tasks/app-template.yaml
oc new-app -f openshift-tasks/app-template.yaml
oc create -f openshift-tasks/pipeline-bc.yaml
oc start-build tasks-pipeline
sleep 15m
oc describe buildconfig tasks-pipeline
oc autoscale dc/tasks --min 1 --max 2 --cpu-percent=80
oc describe deploymentconfig tasks | grep Autoscaling

oc get users --show-labels
oc get nodes --show-labels | grep client
ansible masters -m shell -a"cat /etc/origin/master/master-config.yaml | grep -A 12 ProjectRequestLimit:"
ansible masters -m shell -a"cat /etc/origin/master/master-config.yaml | grep projectRequestTemplate"
oc describe template project-request | grep LimitRange
