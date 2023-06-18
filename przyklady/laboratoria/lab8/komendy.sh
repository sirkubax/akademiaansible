#!/bin/bash

ansible-playbook playbooks/instaluj_i_uruchom_flask.yml

curl -kv 127.0.0.1:8080


#python3 -c "from jinja2 import Template; print(Template('<html><head><title>{{ title }}</title></head><body><h1>{{ title }}</h1><p>Welcome to my website. Enjoy your stay</p></body></html>').render(title='Welcome to My Website'))"
