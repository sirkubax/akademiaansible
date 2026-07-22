# Automatyzacja z Ansible
### Szkolenie 8 spotkan x 4h · Spotkanie 6
## Projekt "od zera do bohatera"

---

# Agenda spotkania 6 (4h)

| Czas        | Blok        | Temat                                              |
|-------------|-------------|----------------------------------------------------|
| 0:00 – 0:15 | Recap       | Powtorka spotkan 1-5, cel projektu                 |
| 0:15 – 0:45 | **Modul 1** | Architektura wdrozenia 3-warstwowego               |
| 0:45 – 1:20 | **Modul 2** | Warstwa bazy danych (rola z Galaxy)                |
| 1:20 – 1:35 | ☕ Przerwa  |                                                    |
| 1:35 – 2:15 | **Modul 3** | Warstwa aplikacji (rola wlasna + szablony)         |
| 2:15 – 2:45 | **Modul 4** | Load balancer i spiecie warstw (hostvars/groups)   |
| 2:45 – 3:05 | **Modul 5** | Prototypowanie i debugging z AI                    |
| 3:05 – 4:00 | **Lab 6**   | Pair-programming: cale srodowisko w jednym przebiegu |

> Dzis nie ma nowej teorii dla samej teorii — LACZYMY wszystko,
> co poznalismy, w jeden dzialajacy system.

---

# Recap — z czego zbudujemy projekt

```
  Spotkanie 1  │ YAML, Jinja, komponenty        │ jezyk
  Spotkanie 2  │ inventory, ad-hoc, playbooki   │ podstawy
  Spotkanie 3  │ pakiety, pliki, template       │ operacje
  Spotkanie 4  │ zmienne, when, loop, hostvars  │ logika
  Spotkanie 5  │ role, Galaxy, FQCN             │ organizacja
  ─────────────┼────────────────────────────────┼──────────────
  Spotkanie 6  │ WSZYSTKO RAZEM                 │ PROJEKT
```

**Cel: jednym poleceniem postawic kompletne srodowisko:**
```bash
ansible-playbook -i inventory/hosts.yml site.yml
```

```
  ...i po ~3 minutach:
  curl http://<load-balancer>/   →   dziala aplikacja,
                                     ruch rozklada sie na serwery app,
                                     kazdy polaczony z baza danych.
```

---

---
# MODUL 1
# Architektura wdrozenia 3-warstwowego
---

---

# Klasyczny stack 3-warstwowy

```
                      klient (curl / przegladarka)
                              │
                              ▼
                   ┌────────────────────┐
                   │   LOAD BALANCER    │  nginx  :80
                   │       lb01         │  (rola: loadbalancer)
                   └─────────┬──────────┘
                   round-robin nad backendami
              ┌──────────────┴──────────────┐
              ▼                              ▼
      ┌───────────────┐             ┌───────────────┐
      │  APPSERVER    │             │  APPSERVER    │  apache+mod_wsgi
      │    app01      │             │    app02      │  Flask  :8080
      └───────┬───────┘             └───────┬───────┘  (rola: aplikacja)
              └──────────────┬──────────────┘
                             ▼
                     ┌───────────────┐
                     │   DATABASE    │  MySQL  :3306
                     │     db01      │  (rola: geerlingguy.mysql)
                     └───────────────┘
```

> Kazda warstwa = osobna grupa w inventory = osobny "play" w site.yml.
> Rola per warstwa: 2 wlasne (aplikacja, loadbalancer) + 1 z Galaxy (mysql).

---

# Inventory odzwierciedla architekture

```yaml
all:
  children:
    loadbalancers:
      hosts:
        lb01:
    appservers:
      hosts:
        app01:
        app02:
    databases:
      hosts:
        db01:
```

**Grupy = warstwy.** Playbook celuje w grupy, nie w konkretne hosty:
```yaml
- hosts: databases      → geerlingguy.mysql
- hosts: appservers     → rola aplikacja
- hosts: loadbalancers  → rola loadbalancer
```

```
  Skalowanie bez zmian w kodzie:
  dodajesz app03 do grupy appservers → nastepny run:
   - stawia aplikacje na app03
   - load balancer AUTOMATYCZNIE dodaje go do backendow
  (jak? — hostvars + groups, patrz Modul 4)
```

> W labie hosty sa WSPOLDZIELONE miedzy grupami (co-location) —
> bo macie 2 maszyny, nie 4. W produkcji: warstwa = osobne maszyny.

---

# site.yml — dyrygent calego wdrozenia

```yaml
---
# 1. NAJPIERW baza — aplikacja musi miec sie z czym polaczyc
- name: Warstwa bazy danych
  hosts: databases
  become: true
  roles:
    - geerlingguy.mysql

# 2. POTEM aplikacja — laczy sie z gotowa baza
- name: Warstwa aplikacji
  hosts: appservers
  become: true
  roles:
    - aplikacja

# 3. NA KONIEC load balancer — potrzebuje listy dzialajacych app
- name: Warstwa load balancera
  hosts: loadbalancers
  become: true
  roles:
    - loadbalancer
```

```
  KOLEJNOSC MA ZNACZENIE:
  Playbook wykonuje "play" po "play", z gory na dol.
  db → app → lb  to nie przypadek — to zaleznosci warstw.
```

---

# Przeplyw zmiennych miedzy warstwami

```
  group_vars/all.yml           ← wspolne: nazwy, porty, dane bazy
        │
        ├──► databases.yml     ← mysql_databases, mysql_users (dla roli mysql)
        │
        ├──► app czyta:        db_host = ADRES hosta z grupy databases
        │                              (hostvars + groups)
        │
        └──► lb czyta:         backendy = ADRESY hostow z grupy appservers
                                       (hostvars + groups)
```

**Klucz do spiecia warstw — dane JEDNEGO hosta widziane z INNEGO:**
```jinja2
{# w konfiguracji aplikacji: gdzie jest baza? #}
db_host = {{ hostvars[groups['databases'][0]].ansible_default_ipv4.address }}

{# w konfiguracji load balancera: gdzie sa aplikacje? #}
{% for h in groups['appservers'] %}
server {{ hostvars[h].ansible_default_ipv4.address }}:{{ app_port }};
{% endfor %}
```

> To jest cala "magia" orkiestracji: warstwy nie znaja swoich adresow
> na sztywno — odczytuja je z inventory w czasie wykonania.

---

---
# MODUL 2
# Warstwa bazy danych
---

---

# MySQL z gotowej roli (geerlingguy.mysql)

**Nie piszemy instalacji MySQL recznie — bierzemy sprawdzona role:**

```yaml
# requirements.yml
roles:
  - name: geerlingguy.mysql
    version: "4.3.5"
collections:
  - name: community.mysql
    version: ">=3.0.0"
```

```bash
ansible-galaxy role install -r requirements.yml
ansible-galaxy collection install -r requirements.yml
```

**Konfiguracja przez zmienne — `group_vars/databases.yml`:**
```yaml
mysql_bind_address: "0.0.0.0"        # nasluchuj tez na sieci (nie tylko localhost)

mysql_databases:
  - name: "{{ db_nazwa }}"
    encoding: utf8mb4

mysql_users:
  - name: "{{ db_user }}"
    password: "{{ db_haslo }}"
    priv: "{{ db_nazwa }}.*:ALL"
    host: "%"                        # polaczenia z innych hostow (app servers)
```

---

# Dlaczego rola z Galaxy, a nie wlasna?

```
  Instalacja MySQL "recznie" to nie jeden pakiet:
  ─────────────────────────────────────────────────────
  - instalacja serwera + klienta + biblioteki Pythona
  - mysql_secure_installation (root pass, anon users, test db)
  - konfiguracja bind-address, my.cnf
  - tworzenie baz z wlasciwym encoding
  - uzytkownicy + uprawnienia + hosty
  - obsluga roznic Debian/RedHat
  ─────────────────────────────────────────────────────
  geerlingguy.mysql: to wszystko + testy + lata uzycia w tysiacach firm
```

**Nasza rola aplikacji i tak jest wlasna** — bo to LOGIKA NASZEJ firmy.
Standard (MySQL) bierzemy gotowy, specyfike (aplikacja) piszemy sami.

```
  ⚠ Haslo bazy w group_vars jawnym tekstem — na razie.
    Na spotkaniu 7 przeniesiemy je do ansible-vault.
    W projekcie uzywamy zmiennej {{ db_haslo }}, wiec zmiana
    zrodla hasla nie dotknie zadnego szablonu ani roli.
```

---

---
# MODUL 3
# Warstwa aplikacji
---

---

# Rola aplikacja — co robi

```
  roles/aplikacja/
  ├── defaults/main.yml    app_port: 8080, app_nazwa, katalogi
  ├── vars/main.yml        pakiety systemowe (apache2, mod-wsgi-py3...)
  ├── tasks/main.yml       instalacja → venv → szablony → apache
  ├── handlers/main.yml    restart apache + wait_for portu
  ├── templates/
  │   ├── app.py.j2        minimalna aplikacja Flask
  │   ├── wsgi.py.j2       punkt wejscia dla mod_wsgi
  │   ├── config.py.j2     ← TU adres bazy (hostvars!)
  │   ├── vhost.conf.j2    virtualhost apache + WSGIDaemonProcess
  │   └── ports.conf.j2    Listen {{ app_port }}
  └── files/               (statyczne, jesli potrzebne)
```

**Warstwy technologiczne aplikacji:**
```
  Flask (app.py)  ──  WSGI (wsgi.py)  ──  mod_wsgi  ──  Apache  :8080
        │
        └── config.py → laczy sie z MySQL (PyMySQL) w warstwie bazy
```

---

# Kluczowe taski roli aplikacja

```yaml
- name: Zainstaluj pakiety serwera aplikacji
  ansible.builtin.apt:
    name: "{{ app_pakiety }}"        # apache2, libapache2-mod-wsgi-py3, python3-venv
    state: present
    update_cache: true

- name: Utworz virtualenv i zainstaluj zaleznosci Pythona
  ansible.builtin.pip:
    name: [Flask, PyMySQL]
    virtualenv: "{{ app_venv }}"
    virtualenv_command: python3 -m venv

- name: Wgraj konfiguracje aplikacji (adres bazy!)
  ansible.builtin.template:
    src: config.py.j2
    dest: "{{ app_katalog }}/config.py"
  notify: restart apache

- name: Wgraj virtualhost apache
  ansible.builtin.template:
    src: vhost.conf.j2
    dest: /etc/apache2/sites-available/aplikacja.conf
  notify: restart apache
```

> Wszystkie pliki aplikacji to SZABLONY — port, adres bazy, katalogi
> pochodza ze zmiennych. Ten sam kod stawia app na 1 i na 100 hostach.

---

# config.py.j2 — spiecie z baza (hostvars)

**Szablon konfiguracji aplikacji:**
```jinja2
# Wygenerowano przez Ansible — rola: aplikacja
DB_HOST = "{{ hostvars[groups['databases'][0]].ansible_default_ipv4.address }}"
DB_USER = "{{ db_user }}"
DB_PASS = "{{ db_haslo }}"
DB_NAME = "{{ db_nazwa }}"
```

```
  Rozlozmy to wyrazenie na czynniki:

  groups['databases']              → ['db01']            (lista hostow grupy)
  groups['databases'][0]           → 'db01'              (pierwszy host)
  hostvars['db01']                 → wszystkie fakty db01
  hostvars['db01'].ansible_default_ipv4.address → '10.0.0.20'
```

> Aplikacja na app01 i app02 dostaje IDENTYCZNY config wskazujacy
> na db01 — mimo ze zadna z nich nie ma adresu bazy "na sztywno".
> Przeniesiesz baze na inny host? Zmieni sie inventory, nie kod.

---

# Handler z wait_for — pewnosc, ze wstalo

```yaml
handlers:
  - name: restart apache
    ansible.builtin.service:
      name: apache2
      state: restarted
    notify: czekaj na port aplikacji

  - name: czekaj na port aplikacji
    ansible.builtin.wait_for:
      host: 127.0.0.1
      port: "{{ app_port }}"
      state: started
      timeout: 20
      delay: 2
```

```
  Handler moze wywolac KOLEJNY handler (notify w handlerze).
  Wzorzec: restart uslugi → poczekaj az realnie nasluchuje.

  Bez wait_for: playbook "konczy sie sukcesem", ale usluga
  jeszcze wstaje → load balancer dostaje martwy backend.
  Z wait_for: kolejny play (LB) rusza dopiero, gdy app odpowiada.
```

> To wprost wzorzec z materialow prowadzacego
> (naszaaplikacja: "Wait for instances to listen on port...").

---

---
# MODUL 4
# Load balancer i spiecie warstw
---

---

# Rola loadbalancer — nginx nad appservers

```yaml
- name: Zainstaluj nginx
  ansible.builtin.apt:
    name: nginx
    state: present

- name: Wgraj konfiguracje load balancera
  ansible.builtin.template:
    src: upstream.conf.j2
    dest: /etc/nginx/sites-available/aplikacja
  notify: restart nginx

- name: Aktywuj konfiguracje (symlink)
  ansible.builtin.file:
    src: /etc/nginx/sites-available/aplikacja
    dest: /etc/nginx/sites-enabled/aplikacja
    state: link
  notify: restart nginx

- name: Usun domyslny vhost nginx
  ansible.builtin.file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  notify: restart nginx
```

---

# upstream.conf.j2 — dynamiczna lista backendow

```jinja2
upstream aplikacja_backend {
{% for h in groups['appservers'] %}
    server {{ hostvars[h].ansible_default_ipv4.address }}:{{ app_port }};
{% endfor %}
}

server {
    listen {{ lb_port }} default_server;
    location / {
        proxy_pass http://aplikacja_backend;
    }
}
```

**Co wygeneruje sie dla 2 serwerow app:**
```nginx
upstream aplikacja_backend {
    server 10.0.0.11:8080;
    server 10.0.0.12:8080;
}
```

```
  Petla po groups['appservers'] = lista backendow BUDUJE SIE SAMA
  z inventory. Dodajesz app03 → nginx.conf ma 3 wpisy przy nastepnym
  uruchomieniu. Zero recznej edycji konfiguracji load balancera.
```

---

# Efekt: round-robin w akcji

```bash
# Odpytaj load balancer kilka razy:
for i in $(seq 6); do curl -s http://<LB>/ | grep 'Serwer aplikacji'; done
```

```
  Serwer aplikacji: app01
  Serwer aplikacji: app02
  Serwer aplikacji: app01
  Serwer aplikacji: app02
  Serwer aplikacji: app01
  Serwer aplikacji: app02
        │
        └── nginx rozklada ruch po kolei (round-robin) —
            kazde odswiezenie trafia na inny serwer aplikacji,
            oba pokazuja "Baza: connected".
```

**To jest dowod, ze CALY stack dziala:**
```
  ✅ load balancer zyje i rozklada ruch
  ✅ oba serwery aplikacji odpowiadaja
  ✅ kazdy z nich ma polaczenie z baza danych
  ✅ wszystko z JEDNEGO uruchomienia site.yml
```

---

---
# MODUL 5
# Prototypowanie i debugging z AI
---

---

# AI w projekcie — gdzie realnie pomaga

```
  ┌─────────────────────────────────────────────────────────┐
  │  PROTOTYPOWANIE                                          │
  │  "napisz szablon nginx upstream iterujacy po grupie      │
  │   appservers, uzyj hostvars do adresu i portu"           │
  │   → szkielet w sekundy, Ty weryfikujesz i dopasowujesz   │
  │                                                          │
  │  DEBUGGING                                               │
  │  wklej blad Ansible / apache error.log                   │
  │   → AI wskazuje prawdopodobna przyczyne i trop           │
  │                                                          │
  │  WYJASNIANIE                                             │
  │  "co robi WSGIDaemonProcess python-home?"                │
  │   → szybsze niz przekopywanie dokumentacji               │
  └─────────────────────────────────────────────────────────┘
```

> Powtorka zasady ze spotkania 1: AI pisze 80% szkieletu w 20% czasu.
> Krytyczne 20% (weryfikacja, kontekst, testy) — nadal Twoje.

---

# Debugging 3-warstwowego wdrozenia — metoda

```
  Awaria "curl http://LB/ nie dziala" — diagnozuj OD DOLU:

  1. BAZA    ansible databases -m command -a "systemctl is-active mysql"
             ansible databases -m shell -a "mysqladmin ping"

  2. APP     ansible appservers -m uri -a "url=http://localhost:8080/"
             (bezposrednio na serwerze app — z pominieciem LB)
             tail apache error.log: fetch /var/log/apache2/error.log

  3. LB      ansible loadbalancers -m command -a "nginx -t"
             ansible loadbalancers -m uri -a "url=http://localhost/"
```

```
  Zasada: izoluj warstwe. Nie zgaduj "cos nie dziala" —
  sprawdz kazda warstwe osobno, zaczynajac od najnizszej.
  Warstwa X moze dzialac tylko, jesli X-1 dziala.
```

**Narzedzia z poprzednich spotkan w akcji:**
```
  -vvv (polaczenia) · --check --diff (symulacja) · register+debug
  · ad-hoc uri/command (szybka diagnoza) · fetch (sciagnij logi)
```

---

# Typowe pulapki tego projektu

```
  ❌ Zla kolejnosc play      app przed baza → app nie ma sie z czym laczyc
     → w site.yml: databases, POTEM appservers, POTEM loadbalancers

  ❌ MySQL tylko na localhost mysql_bind_address domyslnie 127.0.0.1
     → ustaw 0.0.0.0 + user host '%' (inaczej app nie polaczy sie z db)

  ❌ Brak gather_facts     hostvars[...].ansible_default_ipv4 puste
     → fakty MUSZA byc zebrane (domyslnie sa; nie wylaczaj bez powodu)

  ❌ Konflikt portow (co-location)  nginx :80 vs apache :80
     → apache na 8080 (ports.conf z szablonu), nginx na 80

  ❌ "dziala u mnie"        brak wait_for → LB dostaje wstajacy backend
     → handler restart → wait_for portu
```

---

# LAB 6 — Projekt (55 min, pair-programming)

```
Zadanie (katalog: szkolenie8x4/lab6/):

Postaw CALE srodowisko jednym uruchomieniem site.yml.

1. Inventory: grupy loadbalancers / appservers / databases
   (w labie co-location na 2 hostach — instrukcja w README)

2. Zainstaluj role z Galaxy:  ansible-galaxy install -r requirements.yml

3. Uzupelnij (miejsca # TODO — 3 punkty integracji):
   - site.yml                          → 3 play, wlasciwa KOLEJNOSC
   - roles/aplikacja: config.py.j2     → adres bazy (hostvars!)
   - roles/loadbalancer: upstream.j2   → petla po appservers (hostvars!)
   (group_vars/databases.yml jest GOTOWE — przeczytaj i zrozum)

4. Uruchom:  ansible-playbook -i inventory/hosts.yml site.yml
   Weryfikacja round-robin:
     for i in $(seq 6); do curl -s http://<LB>/ | grep Serwer; done

5. Skaluj: dodaj serwer app do grupy, uruchom ponownie —
   obserwuj, jak LB sam dodaje backend

6. Debug z AI: zepsuj cos swiadomie (np. zly port),
   zdiagnozuj warstwami, popraw
```

> Instrukcja: `lab6/README.md` · Rozwiazania: `*_odpowiedz` / role `*_odpowiedz`

---

# Podsumowanie spotkania 6

```
Co osiagnelismy:

  ✅ Zaprojektowalismy architekture 3-warstwowa (LB/app/db)
  ✅ Inventory = architektura: grupy jako warstwy
  ✅ site.yml: 3 play we wlasciwej kolejnosci (zaleznosci warstw)
  ✅ Baza: gotowa rola geerlingguy.mysql z Galaxy
  ✅ Aplikacja: wlasna rola + szablony (Flask/wsgi/apache)
  ✅ Spiecie warstw: hostvars + groups (app→db, lb→app)
  ✅ Handlery z wait_for — pewnosc, ze usluga wstala
  ✅ AI do prototypowania i debugowania warstwami
  ✅ Jedno uruchomienie → dzialajacy, skalowalny system

Na spotkaniu 7 — inventory, sekrety i debugging:

  ● Inventory dynamiczne i hybrydowe
  ● ansible-vault: haslo bazy z tego projektu → do skarbca
  ● Debugging: check-mode i jego pulapki
  ● Wiele srodowisk: dev/test/QA/UAT/PROD
```

---

# Pytania?

## Do zobaczenia na spotkaniu 7!

*Materialy szkoleniowe dostepne w repozytorium Git*
