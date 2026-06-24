# Automatyzacja z Ansible
### Szkolenie 2-dniowe · od podstaw do produkcji

---

# Agenda szkolenia

| Dzien | Godziny      | Tematy                                           |
|-------|--------------|--------------------------------------------------|
| 1     | 8:00 – 14:00 | Intro, Inventory, Ad-hoc, Playbooki, Petli, Lab1 |
| 2     | 8:00 – 13:00 | Jinja2, Zmienne, Role, Galaxy, Lab2              |

> **Forma:** 35% teoria · 65% warsztaty praktyczne
> **Poziom:** podstawowy / sredniozaawansowany
> **Srodowisko:** Linux + Ansible CLI

---

# Cele szkolenia

Po zakonczeniu szkolenia uczestnik:

- Tworzy i zarzadza plikami inventory (INI i YAML)
- Wykonuje zadania ad-hoc i korzysta z modulow
- Pisze i uruchamia playbooki z petlami, warunkami i szablonami Jinja2
- Organizuje kod z uzyciem rol i korzysta z Ansible Galaxy

---

---
# DZIEN 1 (8:00–14:00)
# Wprowadzenie, Inventory, Ad-hoc, Playbooki
---

---

# Czym jest Ansible?

**Ansible to silnik automatyzacji IT** — jeden jezyk do zarzadzania calym stosem:

```
  Konfiguracja       Wdrozenia        Orkiestracja
  systemow           aplikacji        zadan
  ┌──────────┐       ┌──────────┐     ┌──────────┐
  │ package  │       │ deploy   │     │ rolling  │
  │ service  │  ───► │ webapp   │ ──► │ update   │
  │ file     │       │ v2.5     │     │ 50 hosts │
  └──────────┘       └──────────┘     └──────────┘
```

**Trzy cechy, ktore definiuja Ansible:**

| Cecha          | Co to oznacza w praktyce                               |
|----------------|--------------------------------------------------------|
| Agentless      | Brak agenta na hostach — tylko SSH                     |
| Idempotentnosc | Uruchom 10 razy — wynik ten sam jak po pierwszym razie |
| YAML           | Czytelny dla czlowieka, latwiejszy niz skrypt bash     |

---

# Ansible vs alternatywy

```
               Prostota  │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░│ Ansible
                         │▓▓▓▓▓▓▓▓░░░░░░░░░░░│ Salt
                         │▓▓▓▓▓░░░░░░░░░░░░░░│ Puppet
                         │▓▓▓░░░░░░░░░░░░░░░░│ Chef
```

**Kiedy Ansible wygrywa:**
- Nie chcesz instalowac agentow
- Masz heterogeniczne srodowisko (Linux, Windows, sieciowe)
- Twoj zespol pisze YAML, nie Ruby/Python
- Zaczynasz od zera i chcesz szybkich wynikow

---

# Architektura Ansible

```
┌─────────────────────────────────────────────────────────┐
│                    CONTROL NODE                         │
│                                                         │
│   ┌──────────┐   ┌──────────┐   ┌──────────────────┐  │
│   │Inventory │   │ Playbook │   │   ansible.cfg    │  │
│   │(kto?)    │   │  (co?)   │   │   (jak?)         │  │
│   └────┬─────┘   └────┬─────┘   └──────────────────┘  │
│        │              │                                  │
└────────┼──────────────┼──────────────────────────────────┘
         │   SSH/WinRM  │
    ┌────▼──────────────▼────────────────────────┐
    │              MANAGED HOSTS                  │
    │   ┌────────┐  ┌────────┐  ┌────────────┐  │
    │   │ web01  │  │ web02  │  │   db01     │  │
    │   │ Linux  │  │ Linux  │  │  Linux     │  │
    │   └────────┘  └────────┘  └────────────┘  │
    └────────────────────────────────────────────┘
```

> Nie instalujesz niczego na hostach. Ansible laczy sie przez SSH,
> kopiuje tymczasowy modul, wykonuje go i usuwa.

---

# Struktura projektu

```
moj_projekt/
│
├── ansible.cfg              ← konfiguracja polaczenia
├── inventory/
│   ├── hosts                ← lista hostow
│   ├── group_vars/
│   │   ├── all.yml          ← zmienne dla WSZYSTKICH
│   │   └── webservers.yml   ← zmienne dla grupy
│   └── host_vars/
│       └── web01.yml        ← zmienne dla jednego hosta
│
├── playbooks/
│   └── site.yml             ← glowny punkt wejscia
│
└── roles/
    ├── nginx/               ← rola webservera
    └── database/            ← rola bazy danych
```

> Kazdy element ma swoje miejsce.
> Osoba, ktora widzi projekt po raz pierwszy, wie gdzie szukac.

---

---
# MODUL 1
# Inventory — kto bedzie zarzadzany
---

---

# Inventory — format INI

```ini
[webservers]
web01 ansible_host=192.168.1.10
web02 ansible_host=192.168.1.11

[databases]
db01 ansible_host=192.168.1.20

[produkcja:children]
webservers
databases
```

**Zmienne na poziomie hosta w INI:**
```ini
[webservers]
web01 ansible_host=192.168.1.10 ansible_user=deploy nginx_port=80
web02 ansible_host=192.168.1.11 ansible_user=deploy nginx_port=8080

[webservers:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

> Format INI — szybki start dla malych projektow.

---

# Inventory — format YAML

```yaml
all:
  vars:
    ansible_user: deploy
  children:
    webservers:
      hosts:
        web01:
          ansible_host: 192.168.1.10
          nginx_port: 80
        web02:
          ansible_host: 192.168.1.11
          nginx_port: 8080
    databases:
      hosts:
        db01:
          ansible_host: 192.168.1.20
    produkcja:
      children:
        webservers:
        databases:
```

> Format YAML — czytelniejszy, latwiej wersjonowac, zalecany.

---

# Grupy i hierarchia

```
all
├── produkcja
│   ├── webservers
│   │   ├── web01
│   │   └── web02
│   └── databases
│       └── db01
└── staging
    └── webservers_stg
        └── web-stg01
```

**Przydatne wzorce targetowania:**

```bash
ansible all -m ping                    # wszyscy
ansible webservers -m ping             # tylko webservers
ansible 'webservers:databases' -m ping # suma grup
ansible 'produkcja:!databases' -m ping # produkcja bez databases
ansible 'web*' -m ping                 # wildcard
```

---

# group_vars i host_vars

**Struktura katalogow:**
```
inventory/
├── group_vars/
│   ├── all.yml          ← wspolne dla wszystkich hostow
│   ├── webservers.yml   ← tylko dla grupy webservers
│   └── databases.yml
└── host_vars/
    ├── web01.yml        ← nadpisanie dla jednego hosta
    └── db01.yml
```

**`group_vars/webservers.yml`:**
```yaml
nginx_port: 80
nginx_worker_processes: auto
app_log_level: warning
```

**`host_vars/web01.yml`** (nadpisuje grupe):
```yaml
nginx_port: 8080          # ten host slucha na innym porcie
app_log_level: debug      # wiecej logow na tym hoscie
```

---

# ansible.cfg — konfiguracja polaczenia

```ini
[defaults]
inventory       = ./inventory/hosts
remote_user     = deploy
host_key_checking = False
forks           = 10
gathering       = smart

[privilege_escalation]
become          = False
become_method   = sudo

[ssh_connection]
pipelining      = True
```

> `ansible.cfg` w katalogu projektu ma najwyzszy priorytet.
> Nie wersjonuj wpisow z haslem!

---

---
# MODUL 2
# Zadania ad-hoc i moduly
---

---

# Zadania ad-hoc — skladnia

```
ansible  <PATTERN>  -m <MODULE>  -a "<ARGUMENTS>"  [opcje]
```

**Pierwsze kroki:**
```bash
# Test polaczenia
ansible all -m ping

# Uruchom komende na hostach
ansible webservers -m command -a "uptime"

# Zbierz informacje o systemie
ansible web01 -m setup -a "filter=ansible_distribution*"

# Zainstaluj pakiet (z sudo)
ansible webservers -m package -a "name=htop state=present" --become

# Restart uslugi
ansible webservers -m service -a "name=nginx state=restarted" --become

# Skopiuj plik
ansible web01 -m copy -a "src=./index.html dest=/var/www/html/index.html"
```

---

# Najwazniejsze moduly

```
  ┌──────────────────────────────────────────────────────┐
  │                 MODULY ANSIBLE                        │
  │                                                       │
  │  Pakiety       Pliki          Uslugi     Uzytk.       │
  │  ─────────     ─────────      ───────    ──────       │
  │  package       file           service    user         │
  │  apt           copy           systemd    group        │
  │  yum           template       cron       authorized.. │
  │  pip           fetch                                  │
  │                                                       │
  │  Siec          Bazy danych    System     Inne         │
  │  ─────────     ─────────      ───────    ─────        │
  │  uri           mysql_db       command    debug        │
  │  get_url       postgresql_db  shell      assert       │
  │  firewalld     redis          raw        set_fact     │
  └──────────────────────────────────────────────────────┘
```

> Zasada: **zawsze preferuj modul nad komenda shell**.
> Moduly sa idempotentne. Shell — zwykle nie.

---

# Moduly — przyklady uzycia

**Instalacja pakietow:**
```yaml
- name: Zainstaluj nginx i curl
  package:
    name:
      - nginx
      - curl
    state: present
```

**Kopiowanie pliku z uprawnieniami:**
```yaml
- name: Wgraj konfiguracje
  copy:
    src: files/app.conf
    dest: /etc/app/app.conf
    owner: root
    group: root
    mode: '0644'
```

**Zarzadzanie uzytkownikiem:**
```yaml
- name: Stworz uzytkownika deploy
  user:
    name: deploy
    groups: www-data
    shell: /bin/bash
    state: present
```

---

# Zbieranie faktow przez setup

```bash
# Wszystkie fakty hosta:
ansible web01 -m setup

# Tylko wybrane:
ansible web01 -m setup -a "filter=ansible_*ipv4*"
ansible web01 -m setup -a "filter=ansible_distribution*"
```

**Najczesciej uzywane fakty:**

```yaml
ansible_hostname              # → "web01"
ansible_fqdn                  # → "web01.example.com"
ansible_os_family             # → "Debian" / "RedHat"
ansible_distribution          # → "Ubuntu"
ansible_distribution_version  # → "22.04"
ansible_default_ipv4.address  # → "192.168.1.10"
ansible_memtotal_mb           # → 4096
ansible_processor_count       # → 4
ansible_architecture          # → "x86_64"
```

---

# Warsztat 1 — pierwsze polaczenia (20 min)

```
Cwiczenie:

1. Skonfiguruj inventory z 2 hostami w formacie YAML
   Plik: inventory/hosts.yml

2. Przetestuj polaczenie
   $ ansible all -m ping

3. Sprawdz dystrybucje na hostach
   $ ansible all -m setup -a "filter=ansible_distribution*"

4. Uruchom komende bez playbooka
   $ ansible all -m command -a "df -h"

5. Wylistuj grupy i hosty w inventory
   $ ansible-inventory --list
   $ ansible-inventory --graph
```

---

---
# MODUL 3
# Playbooki — struktura i uruchamianie
---

---

# Budowa playbooka — anatomia

```yaml
---
- name: Wdrozenie serwera webowego      # ← nazwa play
  hosts: webservers                      # ← docelowe hosty
  become: true                           # ← sudo
  gather_facts: true                     # ← zbierz fakty

  vars:
    nginx_port: 80                       # ← zmienne play

  pre_tasks:                             # ← przed rolami
    - name: Sprawdz polaczenie
      ping:

  tasks:                                 # ← glowne zadania
    - name: Zainstaluj nginx
      package:
        name: nginx
        state: present

  handlers:                              # ← reaguja na notify
    - name: restart nginx
      service:
        name: nginx
        state: restarted
```

---

# Handlers — reagowanie na zmiany

```
  task: "Zmien konfiguracje nginx"
         │
         │ notify: "restart nginx"
         ▼
  ┌─────────────────────────────────────────────┐
  │  Czy task zglosil CHANGED?                  │
  │                                             │
  │  TAK ──► handler uruchomi sie               │
  │          po WSZYSTKICH taskach              │
  │                                             │
  │  NIE ──► handler jest pomijany              │
  └─────────────────────────────────────────────┘
```

```yaml
  tasks:
    - name: Aktualizuj konfiguracje nginx
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: restart nginx         # ← tylko gdy zmiana

    - name: Aktualizuj strone glowna
      copy:
        src: index.html
        dest: /var/www/html/index.html
      notify: reload nginx

  handlers:
    - name: restart nginx
      service: name=nginx state=restarted

    - name: reload nginx
      service: name=nginx state=reloaded
```

---

# Check mode i diff mode

```
  Normalny tryb:          Check mode:             Diff mode:
  ─────────────           ──────────────          ──────────────
  Wprowadza zmiany        Tylko symuluje          Pokazuje roznice
  na hostach              nie zmienia nic         w plikach

  ✓ nginx installed       ✓ nginx would be        --- /etc/nginx.conf
  ✓ config updated          installed             +++ /etc/nginx.conf
  ✓ service started       ✓ config would          @@ -1,5 +1,5 @@
                            be updated             worker_processes 2;
                          ✓ service would         -listen 80;
                            be started            +listen 8080;
```

```bash
# Przed wdrozeniem ZAWSZE przetestuj:
ansible-playbook site.yml --check --diff

# Sprawdz skladnie bez laczenia z hostami:
ansible-playbook site.yml --syntax-check
```

> **Regula:** jesli `--check` konczy sie bledem,
> nie wdrazaj na produkcje.

---

---
# MODUL 4
# Kontrola przeplywu: petle i warunki
---

---

# Warunek: when

**Wykonuj task warunkowo:**

```yaml
- name: Zainstaluj apache2 (tylko Debian/Ubuntu)
  package:
    name: apache2
    state: present
  when: ansible_os_family == "Debian"

- name: Zainstaluj httpd (tylko RedHat/CentOS)
  package:
    name: httpd
    state: present
  when: ansible_os_family == "RedHat"

- name: Uruchom backup tylko w nocy
  shell: /usr/local/bin/backup.sh
  when:
    - ansible_date_time.hour | int >= 2
    - ansible_date_time.hour | int <= 4

- name: Wykonaj tylko gdy zmienna jest ustawiona
  debug:
    msg: "Tryb debug!"
  when: debug_mode is defined and debug_mode | bool
```

---

# Petla: loop

**Petla po prostej liscie:**
```yaml
- name: Stworz katalogi aplikacji
  file:
    path: "/opt/myapp/{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - logs
    - config
    - data
    - tmp
```

**Petla po slownikach:**
```yaml
- name: Stworz uzytkownikow z UID
  user:
    name: "{{ item.name }}"
    uid:  "{{ item.uid }}"
    groups: "{{ item.groups }}"
    state: present
  loop:
    - { name: deploy,  uid: 1500, groups: "www-data,sudo" }
    - { name: monitor, uid: 1501, groups: "www-data"      }
    - { name: backup,  uid: 1502, groups: "backup"        }
```

---

# Petla: loop z register

**Przechwytywanie wynikow petli:**
```yaml
- name: Sprawdz czy pakiety sa zainstalowane
  command: "dpkg -l {{ item }}"
  register: pkg_check
  loop:
    - nginx
    - curl
    - htop
  ignore_errors: true

- name: Pokaz wynik dla kazdego pakietu
  debug:
    msg: "{{ item.item }}: {{ 'OK' if item.rc == 0 else 'BRAK' }}"
  loop: "{{ pkg_check.results }}"
```

**Petla po zakresie liczbowym:**
```yaml
- name: Stworz 5 plikow testowych
  file:
    path: "/tmp/test_{{ item }}.txt"
    state: touch
  loop: "{{ range(1, 6) | list }}"
```

---

# Obsluga bledow: block / rescue / always

```yaml
- name: Instalacja i konfiguracja aplikacji
  block:
    - name: Zainstaluj pakiet
      package:
        name: myapp
        state: present

    - name: Skopiuj konfiguracje
      template:
        src: myapp.conf.j2
        dest: /etc/myapp/myapp.conf

    - name: Uruchom usluge
      service:
        name: myapp
        state: started

  rescue:
    # Wykonuje sie TYLKO gdy cos w block sie wywali
    - name: Powiadom o bledzie
      debug:
        msg: "Instalacja myapp nie powiodla sie na {{ inventory_hostname }}"

  always:
    # Wykonuje sie ZAWSZE (success lub failure)
    - name: Wyczysc pliki tymczasowe
      file:
        path: /tmp/myapp_install
        state: absent
```

---

# Tagowanie — uruchamiaj co chcesz

**Oznaczanie taskow:**
```yaml
- name: Zainstaluj nginx
  package:
    name: nginx
    state: present
  tags:
    - install
    - nginx

- name: Skonfiguruj nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  tags:
    - configure
    - nginx

- name: Uruchom nginx
  service:
    name: nginx
    state: started
    enabled: true
  tags:
    - service
    - nginx
```

**Uruchamianie wybranych tagow:**
```bash
ansible-playbook site.yml --tags install
ansible-playbook site.yml --skip-tags configure
ansible-playbook site.yml --tags nginx
```

---

# LAB 1 — Warsztat: playbook instalacji Apache (45 min)

```
Zadanie:

1. Napisz playbook playbooks/install_apache.yml
   - hosts: webservers, become: true

2. Taski (po kolejnosci):
   a) Zainstaluj apache2 (apt, update_cache=yes)
   b) Uruchom i wlacz autostart uslugi apache2
   c) Stworz katalog /var/www/html/app/
   d) Skopiuj index.html z treacia "Hello {{ inventory_hostname }}"
   e) Dodaj handler reloadu apache po zmianie konfiguracji

3. Uzyj when, zeby dzialalo na Debian i RedHat:
   apache2 vs httpd

4. Przetestuj:
   $ ansible-playbook playbooks/install_apache.yml --check --diff
   $ ansible-playbook playbooks/install_apache.yml
   $ curl http://web01/app/

5. Uruchom ponownie — sprawdz czy CHANGED = 0
```

---

---
# DZIEN 2 (8:00–13:00)
# Jinja2, Zmienne, Role, Galaxy
---

---

# Recap dnia 1

```
Co juz umiemy:

  ✅ Inventory (INI i YAML) z grupami i group_vars
  ✅ Zadania ad-hoc: ansible <hosty> -m <modul> -a "args"
  ✅ Budowa playbooka: hosts / vars / tasks / handlers
  ✅ Warunki: when
  ✅ Petla: loop
  ✅ Testy: --check --diff --syntax-check

Dzis:

  ● Szablony Jinja2 — dynamiczne pliki konfiguracyjne
  ● Zmienne: hierarchia, group_vars, host_vars, set_fact
  ● Role — organizacja kodu w wielokrotnie uzywalne jednostki
  ● Ansible Galaxy — gotowe role z ekosystemu
```

---

---
# MODUL 5
# Szablony Jinja2 i zmienne
---

---

# Zrodla zmiennych — hierarchia

```
  Priorytet (od NAJNIZSZEGO do NAJWYZSZEGO):
  ─────────────────────────────────────────────────────────
  1.  defaults/main.yml         (rola — domyslne)
  2.  group_vars/all.yml        (dla wszystkich hostow)
  3.  group_vars/webservers.yml (dla grupy)
  4.  host_vars/web01.yml       (dla konkretnego hosta)
  5.  vars: w playbooku         (sekcja vars)
  6.  vars_files:               (zewnetrzne pliki yaml)
  7.  set_fact                  (tworzony w trakcie)
  8.  -e "zmienna=wartosc"      ← NAJWYZSZY PRIORYTET
  ─────────────────────────────────────────────────────────

  Zasada: bardziej szczegolowe nadpisuje ogolne.
```

---

# set_fact — tworzenie zmiennych dynamicznie

```yaml
- name: Ustaw nazwe serwisu na podstawie roli
  set_fact:
    service_name: "{{ 'nginx' if web_role == 'proxy' else 'apache2' }}"

- name: Zbuduj liste pakietow do instalacji
  set_fact:
    packages_to_install: "{{ base_packages + extra_packages }}"
  vars:
    base_packages:
      - curl
      - wget
      - vim
    extra_packages: "{{ ['nginx'] if install_web else [] }}"

- name: Oblicz rozmiar cache na podstawie RAM
  set_fact:
    cache_size_mb: "{{ (ansible_memtotal_mb * 0.25) | int }}"

- debug:
    msg: "Cache ustawiony na {{ cache_size_mb }} MB"
```

---

# Szablony Jinja2 — modul template

**Podstawowe uzycie:**
```yaml
- name: Wygeneruj konfiguracje nginx
  template:
    src: templates/nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
    validate: 'nginx -t -c %s'
  notify: reload nginx
```

**Szablon `templates/nginx.conf.j2`:**
```nginx
# Wygenerowano przez Ansible — nie edytuj recznie!
# Host: {{ ansible_hostname }} | IP: {{ ansible_default_ipv4.address }}

worker_processes {{ ansible_processor_count }};

server {
    listen {{ nginx_port | default(80) }};
    server_name {{ ansible_fqdn }};
    root {{ nginx_document_root | default('/var/www/html') }};

    access_log /var/log/nginx/{{ ansible_hostname }}_access.log;
}
```

---

# Jinja2 — warunki i petla w szablonie

**Warunek if/else:**
```jinja2
{% if ansible_os_family == "Debian" %}
PidFile /var/run/apache2/apache2.pid
{% else %}
PidFile /var/run/httpd/httpd.pid
{% endif %}
```

**Petla po liscie zmiennych:**
```jinja2
# Wirtualne hosty aplikacji
{% for vhost in nginx_vhosts %}
server {
    listen {{ vhost.port | default(80) }};
    server_name {{ vhost.name }};
    root {{ vhost.docroot }};
}
{% endfor %}
```

**Warunek inline:**
```jinja2
worker_processes {{ nginx_workers | default(ansible_processor_count) }};
log_level {{ 'debug' if debug_mode | default(false) else 'warn' }};
```

---

# Filtry Jinja2 — przetwarzanie danych

**Podstawowe filtry:**
```yaml
# Wartosc domyslna jesli zmienna niezdefiniowana
{{ timeout | default(30) }}
{{ server_name | default(ansible_hostname) }}

# Konwersja typow
{{ "42" | int }}
{{ "true" | bool }}
{{ 3.14 | round(1) }}

# Operacje na stringach
{{ app_name | upper }}        # → "MYAPP"
{{ path | basename }}         # → "nginx.conf"
{{ path | dirname }}          # → "/etc/nginx"
```

**Filtry na listach:**
```yaml
# Polacz liste w string
{{ ["a","b","c"] | join(", ") }}     # → "a, b, c"

# Filtruj liste slownikow
{{ users | selectattr("active", "true") | list }}

# Wyciagnij pole ze slownikow
{{ users | map(attribute="name") | list }}
# → ["jan", "anna", "piotr"]

# Unikalne elementy
{{ lista | unique | sort }}
```

---

# ansible-vault — ochrona sekretow

```
  Jak dziala vault:
  ─────────────────────────────────────────────────────────
  Tekst jawny → [AES-256] → Szyfrogram w pliku YAML
  ─────────────────────────────────────────────────────────
```

**Podstawowe operacje:**
```bash
# Szyfrowanie nowego pliku z sekretami
ansible-vault create group_vars/all/vault.yml

# Szyfrowanie istniejacego pliku
ansible-vault encrypt secrets.yml

# Edycja zaszyfrowanego pliku (otwiera edytor)
ansible-vault edit group_vars/all/vault.yml

# Odszyfrowanie do odczytu
ansible-vault view secrets.yml
```

**Uruchamianie playbooka z sekretami:**
```bash
# Zapyta o haslo interaktywnie
ansible-playbook site.yml --ask-vault-pass

# Haslo w pliku (np. dla CI/CD)
ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

> **Dobra praktyka:** `vault.yml` zawiera tylko zaszyfrowane zmienne,
> `vars.yml` zawiera jawne nazwy zmiennych wskazujace na vault.

---

# Warsztat 2 — szablon Jinja2 (25 min)

```
Zadanie:

1. Stworz szablon templates/apache_vhost.conf.j2:
   - ServerName z faktu ansible_fqdn
   - DocumentRoot z zmiennej (z defaultem)
   - CustomLog z ansible_hostname w nazwie pliku

2. Dodaj do playbooka task uzywajacy template:
   - dest: /etc/apache2/sites-available/myapp.conf
   - notify: reload apache

3. Zdefiniuj zmienne w group_vars/webservers.yml:
   apache_docroot: /var/www/myapp

4. Nadpisz dla jednego hosta w host_vars/<host>.yml:
   apache_docroot: /var/www/myapp_v2

5. Przetestuj --check --diff — sprawdz ze widac roznice
```

---

---
# MODUL 6
# Role — organizacja kodu
---

---

# Dlaczego role?

```
  Bez rol:                     Z rolami:
  ─────────────────────        ─────────────────────────────
  site.yml                     site.yml
  │                            │
  └── 500 linii taskow         ├── roles/
      wszystko razem           │   ├── nginx/       (100 linii)
      nie da sie ponownie      │   ├── database/    (80 linii)
      uzyc w innym             │   └── monitoring/  (60 linii)
      projekcie                │
                               └── Kazdej roli mozna uzyc
                                   w 10 innych projektach
```

**Rola = zamknieta, testowalna jednostka automatyzacji.**

---

# Struktura roli — kazdy element ma cel

```
roles/nginx/
│
├── tasks/
│   └── main.yml       ← Co robimy krok po kroku
│
├── handlers/
│   └── main.yml       ← Reakcje na zdarzenia (notify)
│
├── templates/
│   └── nginx.conf.j2  ← Szablony Jinja2 dla konfiguracji
│
├── files/
│   └── index.html     ← Pliki statyczne (bez szablonow)
│
├── defaults/
│   └── main.yml       ← Zmienne domyslne (latwo nadpisac)
│
├── vars/
│   └── main.yml       ← Zmienne wewnetrzne (trudno nadpisac)
│
├── meta/
│   └── main.yml       ← Zaleznosci od innych rol
│
└── README.md          ← Przyklad uzycia!
```

---

# Rola apache — przyklad implementacji

**`roles/apache/defaults/main.yml`:**
```yaml
apache_port: 80
apache_server_name: "{{ ansible_hostname }}"
apache_document_root: /var/www/html
apache_packages:
  - apache2     # Debian
```

**`roles/apache/tasks/main.yml`:**
```yaml
---
- name: Zainstaluj apache
  package:
    name: "{{ apache_packages }}"
    state: present

- name: Wgraj konfiguracje virtualhost
  template:
    src: vhost.conf.j2
    dest: /etc/apache2/sites-available/default.conf
  notify: reload apache

- name: Upewnij sie ze apache jest uruchomiony
  service:
    name: apache2
    state: started
    enabled: true
```

---

# Rola apache — handlers i template

**`roles/apache/handlers/main.yml`:**
```yaml
---
- name: reload apache
  service:
    name: apache2
    state: reloaded

- name: restart apache
  service:
    name: apache2
    state: restarted
```

**`roles/apache/templates/vhost.conf.j2`:**
```apache
<VirtualHost *:{{ apache_port }}>
    ServerName {{ apache_server_name }}
    DocumentRoot {{ apache_document_root }}

    ErrorLog  /var/log/apache2/{{ ansible_hostname }}_error.log
    CustomLog /var/log/apache2/{{ ansible_hostname }}_access.log combined
</VirtualHost>
```

---

# Uzycie roli w playbooku

**Najprostszy sposob:**
```yaml
- hosts: webservers
  become: true
  roles:
    - apache
    - { role: apache, apache_port: 8080 }
```

**Z warunkami i parametrami:**
```yaml
- hosts: webservers
  become: true
  tasks:
    - name: Zainstaluj i skonfiguruj apache
      import_role:
        name: apache
      vars:
        apache_port: 8080

    - name: Zainstaluj PHP jesli wymagane
      include_role:
        name: php
      when: install_php | default(false) | bool
```

> `import_role` = statyczny (ladowany przy parsowaniu)
> `include_role` = dynamiczny (ladowany w czasie wykonania)

---

# Tworzenie nowej roli

```bash
# Szkielet roli — stworzony przez Galaxy CLI
ansible-galaxy role init roles/moja_rola
```

```
roles/moja_rola/
├── defaults/
│   └── main.yml      ← ansible-galaxy wypelnia
├── files/
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml      ← galaxy_info: author, description, platforms
├── tasks/
│   └── main.yml
├── templates/
├── tests/
│   ├── inventory
│   └── test.yml
└── README.md
```

> `defaults/main.yml` — wszystkie zmienne roli z sensownymi domyslnymi.
> `meta/main.yml` — autor, opis, zaleznosci od innych rol.

---

---
# MODUL 7
# Ansible Galaxy — gotowe role
---

---

# Ansible Galaxy i kolekcje

**Pobierz gotowa role:**
```bash
# Instalacja roli z Galaxy
ansible-galaxy install geerlingguy.apache

# Lista zainstalowanych rol
ansible-galaxy list

# Instalacja z pliku wymagan
ansible-galaxy install -r requirements.yml
```

**`requirements.yml`:**
```yaml
roles:
  - name: geerlingguy.apache
    version: "3.2.0"
  - name: geerlingguy.mysql
    version: "4.1.0"

collections:
  - name: community.general
    version: ">=8.0.0"
  - name: amazon.aws
    version: ">=7.0.0"
```

```bash
# Instalacja wszystkich zaleznosci
ansible-galaxy install -r requirements.yml
ansible-galaxy collection install -r requirements.yml
```

---

# Galaxy — uzycie pobranej roli

**Przyklad z geerlingguy.apache:**
```yaml
- hosts: webservers
  become: true
  vars:
    apache_vhosts:
      - servername: "myapp.example.com"
        documentroot: "/var/www/myapp"
    apache_mods_enabled:
      - rewrite.load
      - ssl.load

  roles:
    - geerlingguy.apache
```

> Zmienne konfiguracyjne roli — zawsze w `defaults/main.yml` roli.
> Sprawdz README zanim zaczniesz konfiguracja!

---

# Zaleznosci miedzy rolami

**`roles/webapp/meta/main.yml`:**
```yaml
galaxy_info:
  author: twoje_imie
  description: Kompletna aplikacja webowa
  min_ansible_version: "2.15"

dependencies:
  - role: geerlingguy.apache
    vars:
      apache_port: 8080

  - role: geerlingguy.mysql
    vars:
      mysql_databases:
        - name: webapp_prod
      mysql_users:
        - name: webapp
          password: "{{ vault_db_password }}"
          priv: "webapp_prod.*:ALL"
```

```
  Ansible wykona:

  geerlingguy.mysql ──┐
  geerlingguy.apache ─┼──► webapp
                      │
  (zaleznosci najpierw, potem docelowa rola)
```

---

# Dobre praktyki rol

```
  ZAWSZE                             NIGDY
  ─────────────────────────────      ─────────────────────────────
  README.md z przykladem uzycia      Twarda sciezka w defaults/
  Zmienne domyslne w defaults/,      Sekrety w roli — uzyj vault
    nie w vars/
  Validate plikow konfiguracji       Jeden wielki tasks/main.yml
  Jednolite nazewnictwo:             Omijanie idempotencji
    nazwa_roli_zmienna               (changed_when: false wszedzie)
  Testuj przez Molecule              ignore_errors: true jako
                                       obejscie bledow
```

---

# LAB 2 — Warsztat koncowy: aplikacja z rolami (60 min)

```
Zadanie:

Zrefaktoryzuj playbook z Lab 1 do projektu z rolami.

1. Stworz szkielet roli:
   $ ansible-galaxy role init roles/webserver

2. Przenieś elementy z playbooka do roli:
   - Taski       → roles/webserver/tasks/main.yml
   - Handler     → roles/webserver/handlers/main.yml
   - Template    → roles/webserver/templates/vhost.conf.j2
   - Zmienne     → roles/webserver/defaults/main.yml

3. Nowy playbook site.yml uzywajacy roli:
   - { role: webserver, apache_port: 80 }

4. Uruchom z Galaxy — dodaj do requirements.yml:
   - name: geerlingguy.apache
     version: "3.2.0"
   $ ansible-galaxy install -r requirements.yml

5. Porownaj swoja role z geerlingguy.apache:
   Co ma Galaxy, czego Twoja rola nie ma?
```

---

---
# Podsumowanie szkolenia
---

---

# Dobre praktyki — produkcja

```
  ┌──────────────────────────────────────────────────────┐
  │                 REGULY NA PRODUKCJI                  │
  │                                                      │
  │  ✅ Zawsze --check --diff przed wdrozeniem           │
  │  ✅ Sekrety tylko w ansible-vault                    │
  │  ✅ Testuj na hostach nieprodukcyjnych               │
  │  ✅ Wersjonuj role przez Git tags                    │
  │  ✅ README w kazdej roli                             │
  │  ✅ Jednolite nazewnictwo zmiennych                  │
  │  ✅ ansible-lint przed commitem                      │
  │                                                      │
  │  ❌ Nie uzywaj shell/command gdy jest modul          │
  │  ❌ Nie hardcoduj IP/hasel w playbookach             │
  │  ❌ Nie pushuj .vault_pass do repozytorium           │
  │  ❌ Nie ignoruj bledow przez ignore_errors masowo    │
  └──────────────────────────────────────────────────────┘
```

---

# Co potrafisz po 2 dniach

| Obszar          | Umiejetnosc                                          |
|-----------------|------------------------------------------------------|
| Inventory       | INI i YAML, grupy, group_vars, host_vars             |
| Ad-hoc          | Zadania jednorazowe, modul ping/setup/package/service|
| Playbooki       | Struktura, handlers, check mode, tagi                |
| Petlei warunki  | loop po listach i slownikach, when z faktami         |
| Jinja2          | template, filtry, warunki i petla w szablonie        |
| Zmienne         | Hierarchia priorytetow, set_fact, vault              |
| Role            | Struktura, defaults, galaxy init, import/include     |
| Galaxy          | Instalacja, requirements.yml, kolekcje               |

---

# Dalsze kroki

**Nastepny poziom — co warto poznac:**

| Temat                 | Narzedzie / Komenda                    |
|-----------------------|----------------------------------------|
| Testowanie rol        | Molecule + pytest                      |
| Lintowanie kodu       | ansible-lint                           |
| CI/CD pipeline        | GitLab CI / GitHub Actions             |
| UI dla zespolow       | AWX / Ansible Tower / AAP              |
| Chmura                | amazon.aws, azure.azcollection         |
| Dynamiczne inventory  | AWS EC2, VMware, Netbox                |
| Automatyzacja reaktywna | Event-Driven Ansible (EDA)           |

**Dokumentacja:**
- https://docs.ansible.com
- https://galaxy.ansible.com
- https://forum.ansible.com

---

# Pytania?

## Dziekujemy!

*Materialy szkoleniowe dostepne w repozytorium Git*
