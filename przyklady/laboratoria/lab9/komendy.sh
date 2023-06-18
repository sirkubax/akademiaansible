#!/bin/bash

cd /katalog/webinaryansible2023/playbooks/chatgpt_szablony

ansible-playbook playbook_i_szablon_html/szablonuj.yml

ansible-playbook playbook_generowanie_dokumentu/szablonuj.yml

ansible-playbook playbook_konfiguracja_uslugi/szablonuj.yml



ansible-playbook szablon_inne_przyklady/przyklady_w_playbook.yml

#python3 -c "from jinja2 import Template; print(Template('<html><head><title>{{ title }}</title></head><body><h1>{{ title }}</h1><p>Welcome to my website. Enjoy your stay</p></body></html>').render(title='Welcome to My Website'))"
