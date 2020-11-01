ansible-inventory -i demo.aws_ec2.yml --graph
ansible-playbook -e "passed_in_hosts=tag_Name_mgmt4" playbooks/example.yaml  -i demo.aws_ec2.yml 

