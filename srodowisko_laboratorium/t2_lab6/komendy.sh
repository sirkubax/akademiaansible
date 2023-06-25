#!/bin/bash

ansible-galaxy install geerlingguy.apache

ansible-playbook playbooks/014_apache_rola.yml -v

ps aux
curl -v 127.0.0.1:80  
