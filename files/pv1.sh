#!bin/bash

export GUID=`hostname|awk -F. '{print $2}'`
echo "export GUID=$GUID" >> ~/.bashrc
echo $GUID

ssh support1.$GUID.internal "sudo mkdir -p /srv/nfs/user-vols/pv{1..200}"

ssh support1.$GUID.internal "sudo touch /etc/exports.d/openshift-uservols.exports"

scp /root/osp-work/files/openshift-uservols.exports support1.$GUID.internal:/home/ec2-user/openshift-uservols.exports

ssh support1.$GUID.internal "sudo chown -R nfsnobody.nfsnobody  /srv/nfs"
ssh support1.$GUID.internal "sudo chmod -R 777 /srv/nfs"
ssh support1.$GUID.internal "sudo chown -R root:root /etc/exports.d/openshift-uservols.exports"
ssh support1.$GUID.internal "sudo chmod -R 644 /etc/exports.d/openshift-uservols.exports"

ssh support1.$GUID.internal "sudo systemctl restart nfs-server"
