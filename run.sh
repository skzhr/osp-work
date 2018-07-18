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


sh -x pv1.sh
sh -x pv2.sh
sh -x pv3.sh

oc create -f template.yaml -n default

ansible masters -m shell -a"sed -i -e \"\:projectRequestTemplate: s:'':'default/project-request':\" /etc/origin/master/master-config.yaml"
ansible masters -m shell  -a"systemctl stop atomic-openshift-master-api"
ansible masters -m shell -a"systemctl stop atomic-openshift-master-controllers"
ansible nodes -m shell -a"systemctl stop atomic-openshift-node"
ansible masters -m shell -a"systemctl start atomic-openshift-master-api"
ansible masters -m shell -a"systemctl start atomic-openshift-master-controllers"
ansible masters -m shell -a"systemctl start atomic-openshift-node"
ansible nodes -m shell -a"systemctl start atomic-openshift-node"

date
