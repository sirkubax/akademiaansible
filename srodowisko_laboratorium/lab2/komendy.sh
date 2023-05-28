#!/bin/bash

# Kroki do wykonania w kontenerze
# podlaczenie sie do kontenera
# docker exec -ti nasz_kontener bash

git clone https://github.com/sirkubax/akademiaansible.git

ansible-playbook playbooks/pierwszy_playbook.yaml

ansible-playbook playbooks/doinstalujemy_aplikacje.yml
