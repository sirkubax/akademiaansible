# Automatyzacja z Ansible
### Szkolenie 8 spotkan x 4h · Spotkanie 5
## Role i Ansible Galaxy

---

# Agenda spotkania 5 (4h)

| Czas        | Blok        | Temat                                              |
|-------------|-------------|----------------------------------------------------|
| 0:00 – 0:15 | Recap       | Powtorka spotkania 4, pytania                      |
| 0:15 – 0:40 | **Modul 1** | Role — koncepcja i po co nam re-uzycie kodu        |
| 0:40 – 1:20 | **Modul 2** | Struktura roli, defaults vs vars, tworzenie        |
| 1:20 – 1:35 | ☕ Przerwa  |                                                    |
| 1:35 – 2:05 | **Modul 3** | Uzycie rol: import/include, zaleznosci, refaktoryzacja |
| 2:05 – 2:35 | **Modul 4** | Ansible Galaxy i kolekcje (+ FQCN)                 |
| 2:35 – 2:55 | **Modul 5** | Gotowe rozwiazania — sila spolecznosci             |
| 2:55 – 4:00 | **Lab 5**   | Wlasna rola + instalacja i uzycie rol z Galaxy     |

---

# Recap spotkania 4

```
Co juz umiemy:

  ✅ Zmienne: wszystkie miejsca definicji + precedence
  ✅ when: fakty, register, | bool, listy warunkow
  ✅ loop: listy slownikow, dict2items, .results, loop_control
  ✅ Parametryzacja: group_vars per srodowisko (dev/prod)
  ✅ Lab: jeden playbook — dwa srodowiska

Dzis — organizacja i re-uzycie kodu:

  ● Role: z playbookow-tasiemcow do modularnych komponentow
  ● defaults vs vars — domkniecie ukladanki precedence
  ● ansible-galaxy role init, import_role / include_role
  ● Galaxy: tysiace gotowych rol i kolekcji
  ● FQCN — pelne nazwy modulow (nowy nawyk!)
  ● Kompletne wdrozenia (MySQL, Elasticsearch) z gotowych rol
```

---

---
# MODUL 1
# Role — koncepcja
---

---

# Problem: playbook-tasiemiec

```
  Bez rol:                     Z rolami:
  ─────────────────────        ─────────────────────────────
  site.yml                     site.yml (10 linii!)
  │                            │
  └── 500 linii taskow         ├── roles/
      wszystko razem           │   ├── apache/      (100 linii)
                               │   ├── mysql/       (80 linii)
      nie da sie uzyc          │   └── monitoring/  (60 linii)
      w innym projekcie        │
                               └── Kazdej roli mozna uzyc
      zmiana = szukanie            w 10 innych projektach
      po calym pliku
```

**Rola = zamknieta, wielokrotnego uzytku jednostka automatyzacji:**
- swoje taski, handlery, szablony, pliki i zmienne — w komplecie
- jasny "interfejs": zmienne w `defaults/` to parametry roli
- testowalna i wersjonowalna niezaleznie od projektu

```
  Analogia programistyczna:
  playbook z taskami  =  skrypt              (dziala, ale raz)
  rola                =  funkcja/biblioteka  (piszesz raz, uzywasz wszedzie)
```

---

# Re-uzycie w praktyce — ten sam kod, wiele projektow

```
                    ┌──────────────────┐
                    │  rola: apache    │
                    │  (Git / Galaxy)  │
                    └────────┬─────────┘
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
   projekt SKLEP       projekt INTRANET   projekt KLIENT-X
   apache_port: 80     apache_port: 8080  apache_port: 443
   3 hosty prod        1 host             20 hostow
```

**Co zyskujesz:**

| Bez rol                          | Z rolami                          |
|----------------------------------|-----------------------------------|
| Poprawka bledu w 3 projektach    | Poprawka RAZ, nowa wersja roli    |
| Copy-paste miedzy projektami     | `requirements.yml` + wersja       |
| Kazdy projekt "trochę inny"      | Roznice TYLKO w zmiennych         |
| Wiedza w glowie autora           | README + defaults = dokumentacja  |

---

---
# MODUL 2
# Struktura roli
---

---

# Struktura roli — kazdy element ma cel

```
roles/aplikacja_www/
│
├── tasks/
│   └── main.yml       ← CO robimy, krok po kroku (punkt wejscia)
│
├── handlers/
│   └── main.yml       ← reakcje na notify (restart, reload)
│
├── templates/
│   └── index.html.j2  ← szablony Jinja2
│
├── files/
│   └── logo.png       ← pliki statyczne (bez szablonowania)
│
├── defaults/
│   └── main.yml       ← PARAMETRY roli (latwo nadpisac!)
│
├── vars/
│   └── main.yml       ← stale wewnetrzne (trudno nadpisac)
│
├── meta/
│   └── main.yml       ← autor, platformy, zaleznosci od innych rol
│
└── README.md          ← jak uzyc roli + przyklad!
```

> Ansible laduje `tasks/main.yml` automatycznie. Szablonow z
> `templates/` uzywasz bez sciezki: `src: index.html.j2` — rola
> szuka najpierw u siebie.

---

# defaults vs vars — domkniecie precedence

```
  Precedence (spotkanie 4) — teraz z rolami w komplecie:

   1. defaults roli          ← NAJSLABSZE — po to sa!
   2. group_vars / host_vars
   3. vars playa
   8. vars roli (vars/main.yml)   ← silniejsze niz play!
  10. set_fact
  11. -e                     ← najsilniejsze
```

**`defaults/main.yml` — publiczny interfejs roli:**
```yaml
# Wszystko, co uzytkownik roli MOZE chciec zmienic:
aplikacja_www_port: 80
aplikacja_www_tytul: "Aplikacja szkoleniowa"
aplikacja_www_docroot: /var/www/html
```

**`vars/main.yml` — wewnetrzne stale roli:**
```yaml
# Rzeczy, ktorych uzytkownik NIE powinien zmieniac:
aplikacja_www_pakiet: apache2
aplikacja_www_usluga: apache2
```

```
  Regula: parametr → defaults/ · stala implementacji → vars/
  Prefiks nazwy roli w KAZDEJ zmiennej = zero konfliktow
  miedzy rolami w jednym playbooku.
```

---

# Tworzenie roli — ansible-galaxy role init

```bash
ansible-galaxy role init roles/aplikacja_www
```

```
roles/aplikacja_www/
├── defaults/main.yml     ← wygenerowane, puste w srodku
├── files/
├── handlers/main.yml
├── meta/main.yml         ← szkielet galaxy_info do uzupelnienia
├── tasks/main.yml
├── templates/
├── tests/                ← proste testy (inventory + test.yml)
├── vars/main.yml
└── README.md             ← szablon dokumentacji
```

**Gdzie playbook szuka rol (w kolejnosci):**
```
  1. ./roles/                        ← katalog projektu (standard)
  2. roles_path z ansible.cfg
  3. ~/.ansible/roles                ← tu instaluje ansible-galaxy
  4. /usr/share/ansible/roles
```

> Wlasne role trzymaj w `./roles/` w repo projektu.
> Pobrane z Galaxy — poza repo (o tym za chwile).

---

# Anatomia roli — tasks i handlers

**`roles/aplikacja_www/tasks/main.yml`:**
```yaml
---
- name: Zainstaluj serwer www
  ansible.builtin.apt:
    name: apache2
    state: present
    update_cache: true
    cache_valid_time: 3600

- name: Ustaw port nasluchu
  ansible.builtin.lineinfile:
    path: /etc/apache2/ports.conf
    regexp: '^Listen '
    line: "Listen {{ aplikacja_www_port }}"
  notify: restart apache

- name: Wgraj strone glowna
  ansible.builtin.template:
    src: index.html.j2                  # ← szuka w templates/ ROLI
    dest: "{{ aplikacja_www_docroot }}/index.html"

- name: Upewnij sie ze apache dziala
  ansible.builtin.service:
    name: apache2
    state: started
    enabled: true
```

**`roles/aplikacja_www/handlers/main.yml`:**
```yaml
---
- name: restart apache
  ansible.builtin.service:
    name: apache2
    state: restarted
```

---

---
# MODUL 3
# Uzycie rol w playbookach
---

---

# Uzycie roli — trzy sposoby

**1. Sekcja `roles:` — klasyka:**
```yaml
- hosts: webservers
  become: true
  roles:
    - aplikacja_www                              # z defaults
    - { role: aplikacja_www, aplikacja_www_port: 8080 }   # z parametrem
```

**2. `import_role` — statycznie, w taskach:**
```yaml
  tasks:
    - name: Wdroz aplikacje www
      ansible.builtin.import_role:
        name: aplikacja_www
      vars:
        aplikacja_www_port: 8080
```

**3. `include_role` — dynamicznie (mozna z when/loop):**
```yaml
  tasks:
    - name: Wdroz monitoring tylko na prod
      ansible.builtin.include_role:
        name: monitoring
      when: "'prod' in group_names"
```

```
  import_role  = statyczny: znany przy STARCIE playbooka
                 (widac w --list-tasks, dziala z --start-at-task)
  include_role = dynamiczny: decyzja w TRAKCIE wykonania
                 (dziala z loop, zmiennym name, warunkami)
  Prosta zasada: domyslnie roles:/import, include gdy potrzebujesz
  dynamiki.
```

---

# Kolejnosc wykonania i zaleznosci

**Kolejnosc w play:**
```
  pre_tasks  →  handlers z pre_tasks
  roles      →  (zaleznosci z meta NAJPIERW)
  tasks      →  handlers
  post_tasks →  handlers z post_tasks
```

**Zaleznosci roli — `meta/main.yml`:**
```yaml
galaxy_info:
  author: jakub
  description: Aplikacja www ze wspolna baza
  min_ansible_version: "2.15"
  platforms:
    - name: Ubuntu
      versions: [jammy, noble]

dependencies:
  - role: wspolne_pakiety            # wykona sie PRZED ta rola
  - role: geerlingguy.mysql
    vars:
      mysql_databases:
        - name: aplikacja
```

> Zaleznosc uruchamia sie automatycznie przed rola, ktora jej wymaga.
> Uzywaj oszczednie — jawna lista rol w playbooku jest czytelniejsza
> niz ukryty lancuch zaleznosci.

---

# Refaktoryzacja: playbook → rola

**Masz playbook z lab 3/4? Przenosisz mechanicznie:**

| W playbooku bylo...            | W roli laduje w...            |
|--------------------------------|-------------------------------|
| `tasks:`                       | `tasks/main.yml`              |
| `handlers:`                    | `handlers/main.yml`           |
| `vars:` (parametry)            | `defaults/main.yml`           |
| szablony obok playbooka        | `templates/`                  |
| pliki statyczne                | `files/`                      |
| komentarz "jak uzywac"         | `README.md`                   |

**Playbook PO refaktoryzacji:**
```yaml
---
- name: Wdrozenie aplikacji
  hosts: webservers
  become: true
  roles:
    - aplikacja_www
```

```
  Uwaga przy przenoszeniu:
  - w tasks/main.yml NIE MA naglowka play (hosts/become) — tylko taski!
  - sciezki szablonow skracaja sie: templates/x.j2 → x.j2
  - zmienne dostaja prefiks roli: port → aplikacja_www_port
```

---

---
# MODUL 4
# Ansible Galaxy i kolekcje
---

---

# Galaxy — ekosystem gotowego kodu

```
  galaxy.ansible.com
  ┌─────────────────────────────────────────────────────┐
  │                                                     │
  │  ROLE                        KOLEKCJE               │
  │  ─────────────────           ─────────────────      │
  │  kompletne "przepisy"        paczki modulow,        │
  │  (zainstaluj i skonfiguruj   pluginow i rol         │
  │   apache/mysql/docker...)    (community.general,    │
  │                               amazon.aws...)        │
  │                                                     │
  │  geerlingguy.apache          community.mysql        │
  │  geerlingguy.mysql           community.docker       │
  │  geerlingguy.docker          ansible.posix          │
  └─────────────────────────────────────────────────────┘
```

```bash
# Instalacja roli
ansible-galaxy role install geerlingguy.apache

# Instalacja kolekcji
ansible-galaxy collection install community.general

# Co mam zainstalowane?
ansible-galaxy role list
ansible-galaxy collection list
```

---

# FQCN — pelne nazwy modulow (nowy nawyk!)

```
  FQCN = Fully Qualified Collection Name

  apt                     →  ansible.builtin.apt
  lvg                     →  community.general.lvg
  mount                   →  ansible.posix.mount
  mysql_db                →  community.mysql.mysql_db

  namespace . kolekcja . modul
```

**Dlaczego warto pisac pelne nazwy:**
```
  ✅ jednoznacznosc — dwa "mysql_db" w roznych kolekcjach?
     FQCN mowi dokladnie, ktorego uzywasz
  ✅ czytelnik od razu wie, skad pochodzi modul
     (i co dopisac do requirements.yml)
  ✅ ansible-lint tego wymaga — standard branzowy
  ✅ odpornosc na zmiany aliasow miedzy wersjami
```

```yaml
# Od dzis piszemy tak:
- name: Zainstaluj pakiet
  ansible.builtin.apt:          # nie: apt
    name: htop
    state: present
```

> Krotkie nazwy z poprzednich spotkan DZIALAJA (aliasy) —
> ale nowy kod piszemy juz z FQCN.

---

# requirements.yml — zaleznosci projektu z wersjami

```yaml
---
roles:
  - name: geerlingguy.apache
    version: "3.2.0"              # ZAWSZE pinuj wersje!
  - name: geerlingguy.mysql
    version: "4.3.5"
  - name: firmowa_rola
    src: https://git.firma.local/ansible/firmowa_rola.git
    scm: git
    version: "v1.4.0"             # tag/branch/commit z Gita

collections:
  - name: community.general
    version: ">=9.0.0,<10.0.0"
  - name: community.mysql
    version: "3.10.3"
```

```bash
ansible-galaxy role install -r requirements.yml
ansible-galaxy collection install -r requirements.yml
```

```
  Pamietasz spotkanie 2 (sandbox)? requirements.yml to czesc
  "srodowiska jako kodu":
  requirements.txt  = wersje Pythona/ansible-core
  requirements.yml  = wersje rol i kolekcji
  Pobrane role NIE ida do repo — .gitignore + instalacja z pliku.
```

---

---
# MODUL 5
# Gotowe rozwiazania — sila spolecznosci
---

---

# Kompletne wdrozenie z gotowych rol — MySQL w 15 linii

```yaml
# requirements.yml:  geerlingguy.mysql (4.3.x)

- name: Serwer bazodanowy — kompletna konfiguracja
  hosts: databases
  become: true

  vars:
    mysql_root_password: "{{ vault_mysql_root }}"   # vault! (spotkanie 7)
    mysql_databases:
      - name: sklep_prod
        encoding: utf8mb4
    mysql_users:
      - name: sklep
        password: "{{ vault_mysql_sklep }}"
        priv: "sklep_prod.*:ALL"
        host: "10.0.0.%"

  roles:
    - geerlingguy.mysql
```

```
  Rola za Ciebie: instalacja, my.cnf, bezpieczenstwo (root pass,
  anonimowi uzytkownicy), bazy, uzytkownicy, uprawnienia, backup dirs.

  Analogicznie: elasticsearch, docker, nginx, postgresql, redis,
  java, node... — sprawdz geerlingguy.* i community.*
```

---

# Jak ocenic role z Galaxy ZANIM jej zaufasz

```
  Checklista oceny (galaxy.ansible.com / GitHub):

  ✅ Liczba pobran            miliony = przetestowane przez tysiace firm
  ✅ Data ostatniego commita  aktywny projekt czy porzucony 3 lata temu?
  ✅ Issues / PR na GitHubie  czy autor odpowiada?
  ✅ Wspierane platformy      jest Twoj OS w meta/main.yml?
  ✅ README                   przyklady uzycia, opis KAZDEJ zmiennej
  ✅ defaults/main.yml        przejrzyj — to interfejs roli
  ✅ Testy (molecule/CI)      badge w README = rola jest testowana
```

**Przed pierwszym uzyciem — przeczytaj kod:**
```bash
ansible-galaxy role install geerlingguy.apache
tree ~/.ansible/roles/geerlingguy.apache
less ~/.ansible/roles/geerlingguy.apache/tasks/main.yml
less ~/.ansible/roles/geerlingguy.apache/defaults/main.yml
```

> To samo dotyczy kodu z AI (spotkanie 1) — cudzy kod ZAWSZE
> czytasz, zanim uruchomisz go na swoich serwerach z sudo.

---

# Wlasna rola czy Galaxy? — i ryzyka

| Sytuacja                                  | Decyzja                  |
|-------------------------------------------|--------------------------|
| Standardowy soft (apache, mysql, docker)  | Galaxy (geerlingguy itp.)|
| Logika specyficzna dla Twojej firmy       | wlasna rola              |
| Galaxy-rola robi 90% tego co chcesz       | Galaxy + zmienne/wrapper |
| Galaxy-rola wymaga glebokich zmian        | fork albo wlasna         |

**Ryzyka gotowego kodu (supply chain):**
```
  ⚠ rola moze zniknac / zmienic autora     → pinuj wersje, mirror w firmie
  ⚠ nowa wersja zmienia defaults           → changelog przed upgrade
  ⚠ zlosliwy/niechlujny kod                → code review jak dla wlasnego
  ⚠ rola porzucona                         → data commitow przed wyborem
```

```
  Zloty srodek wiekszosci zespolow:
  Galaxy dla standardow + waskie role wlasne dla logiki firmowej.
  Wszystko przez requirements.yml z wersjami.
```

---

# LAB 5 — Warsztat (65 min)

```
Zadanie (katalog: szkolenie8x4/lab5/):

Czesc A — wlasna rola:

1. Obejrzyj szkielet roli: roles/aplikacja_www/
   (tak wyglada wynik ansible-galaxy role init)

2. Uzupelnij (miejsca # TODO):
   - defaults/main.yml   → parametry roli (z prefiksem!)
   - tasks/main.yml      → instalacja, port, strona, usluga
   - handlers/main.yml   → restart apache

3. Uzupelnij site.yml — uzyj roli i uruchom
   Weryfikacja: curl http://<IP>:80/

4. Test handlera: zmien aplikacja_www_port w group_vars/dev.yml
   na 8081 → uruchom ponownie → obserwuj "restart apache"

Czesc B — Galaxy:

5. Zainstaluj role z requirements.yml (geerlingguy.apache)
6. Przejrzyj jej kod: tree, defaults, tasks — porownaj ze swoja
   Co maja lepiej? (multi-OS? vhosts? walidacja?)
7. BONUS: site_galaxy.yml --check na hostach
```

> Instrukcja: `lab5/README.md` · Rozwiazanie: `roles/aplikacja_www_odpowiedz/`

---

# Podsumowanie spotkania 5

```
Co juz umiemy:

  ✅ Rola = wielokrotnego uzytku jednostka automatyzacji
  ✅ Struktura: tasks / handlers / templates / files / defaults
     / vars / meta + README
  ✅ defaults (parametry) vs vars (stale) — pelny obraz precedence
  ✅ ansible-galaxy role init, roles: / import_role / include_role
  ✅ Zaleznosci rol w meta/main.yml
  ✅ Galaxy: instalacja, requirements.yml z wersjami
  ✅ FQCN: ansible.builtin.apt zamiast apt
  ✅ Ocena jakosci cudzych rol + ryzyka supply chain
  ✅ Lab: wlasna rola aplikacja_www + geerlingguy.apache

Na spotkaniu 6 — projekt "od zera do bohatera":

  ● Kompletny deployment: aplikacja + baza + load balancer
  ● Wszystko z dzisiejszych klockow: role, szablony, zmienne
  ● Pair-programming + prototypowanie z AI
  ● Jeden przebieg playbooka stawia cale srodowisko
```

---

# Pytania?

## Do zobaczenia na spotkaniu 6!

*Materialy szkoleniowe dostepne w repozytorium Git*
