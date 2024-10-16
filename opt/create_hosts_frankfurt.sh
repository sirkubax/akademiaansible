set -x

ansible-playbook playbooks/create_aws_instance.yml -e "type=t3.nano hostname=apache03 role=frontend" -i inventory/inventory_akademiaansible_frankfurt
ansible-playbook playbooks/create_aws_instance.yml -e "type=t3.nano hostname=apache02 role=frontend" -i inventory/inventory_akademiaansible_frankfurt
ansible-playbook playbooks/create_aws_instance.yml -e "type=t3.nano hostname=apache01 role=frontend" -i inventory/inventory_akademiaansible_frankfurt
ansible-playbook playbooks/create_aws_instance.yml -e "type=t3.nano hostname=backend01 role=backend" -i inventory/inventory_akademiaansible_frankfurt
ansible-playbook playbooks/create_aws_instance.yml -e "type=t3.small hostname=db01 role=db" -i inventory/inventory_akademiaansible_frankfurt
ansible-playbook playbooks/create_aws_instance.yml -e "type=t3.small hostname=db02 role=db" -i inventory/inventory_akademiaansible_frankfurt

#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress01_szk16 role=wordpress"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress01_szk01 role=wordpress"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress01_szk02 role=wordpress"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress01_szk03 role=wordpress"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress01_szk04 role=wordpress"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress01_szk05 role=wordpress"
#
#
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=mysql01_szk16 role=mysql"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=mysql01_szk01 role=mysql"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=mysql01_szk02 role=mysql"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=mysql01_szk03 role=mysql"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=mysql01_szk04 role=mysql"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=mysql01_szk05 role=mysql"
#
#
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=loadbalancer01_szk16 role=loadbalancer"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=loadbalancer01_szk01 role=loadbalancer"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=loadbalancer01_szk02 role=loadbalancer"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=loadbalancer01_szk03 role=loadbalancer"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=loadbalancer01_szk04 role=loadbalancer"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=loadbalancer01_szk05 role=loadbalancer"
#
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress02_szk16 role=wordpress"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress02_szk01 role=wordpress"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress02_szk02 role=wordpress"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress02_szk03 role=wordpress"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress02_szk04 role=wordpress"
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wodrpress02_szk05 role=wordpress"
#
#for i in `seq -w 01 15`; do ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wordpress01_szk$i role=wordpress"; done
#for i in `seq -w 01 15`; do ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=mysql01_szk$i role=mysql"; done
#for i in `seq -w 01 15`; do ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=loadbalancer01_szk$i role=loadbalancer"; done
#for i in `seq -w 01 15`; do ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.nano hostname=wordpress02_szk$i role=wordpress"; done
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t2.large hostname=awx role=awx disk=20"

for i in `seq -w 01 7`; do ansible-playbook playbooks/create_aws_instance.yml -i inventory/inventory_akademiaansible_frankfurt -e "type=t3.nano hostname=naszaaplikacja01-szk$i role=naszaaplikacja"; done
for i in `seq -w 01 7`; do ansible-playbook playbooks/create_aws_instance.yml -i inventory/inventory_akademiaansible_frankfurt -e "type=t3.small hostname=naszaaplikacja02-szk$i role=naszaaplikacja"; done
for i in `seq -w 01 7`; do ansible-playbook playbooks/create_aws_instance.yml -i inventory/inventory_akademiaansible_frankfurt -e "type=t3.small hostname=naszaaplikacja01-DB-szk$i role=naszaaplikacja"; done
#for i in `seq -w 01 11`; do ansible-playbook playbooks/create_aws_instance.yml -e "type=t3.medium hostname=awx-szk$i role=awx"; done
#
#ansible-playbook playbooks/create_aws_instance.yml -e "type=t3.medium hostname=awx01 role=awx disk=20"

#if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
#    tmux a -t default || exec tmux new -s default && exit;
#fi

