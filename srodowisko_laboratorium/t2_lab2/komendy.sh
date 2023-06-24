#!/bin/bash

# Kroki do wykonania w kontenerze
# podlaczenie sie do kontenera
# docker exec -ti nasz_kontener bash

cd /katalog
git clone https://github.com/sirkubax/akademiaansible.git

cd /katalog/akademiaansible/
ansible-playbook playbooks/010_pierwszy_playbook.yaml

ansible-playbook playbooks/011_doinstalujemy_aplikacje.yml
