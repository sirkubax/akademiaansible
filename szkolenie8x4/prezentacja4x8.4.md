# Automatyzacja z Ansible
### Szkolenie 8 spotkan x 4h · Spotkanie 4
## Zmienne, warunki i petle

---

# Agenda spotkania 4 (4h)

| Czas        | Blok        | Temat                                              |
|-------------|-------------|----------------------------------------------------|
| 0:00 – 0:15 | Recap       | Powtorka spotkania 3, pytania                      |
| 0:15 – 0:50 | **Modul 1** | Praca ze zmiennymi — gdzie i jak je definiowac     |
| 0:50 – 1:20 | **Modul 2** | Variable precedence — co wygrywa i dlaczego        |
| 1:20 – 1:35 | ☕ Przerwa  |                                                    |
| 1:35 – 2:10 | **Modul 3** | Warunkowe wykonywanie zadan: when                  |
| 2:10 – 2:40 | **Modul 4** | Cykliczne wykonywanie zadan: loop                  |
| 2:40 – 3:05 | **Modul 5** | Parametryzacja i konfiguracja per srodowisko       |
| 3:05 – 4:00 | **Lab 4**   | Playbooki z warunkami, petlami i zmiennymi per env |

> Po dzisiejszym spotkaniu Twoje playbooki przestana byc "skryptami" —
> stana sie PARAMETRYZOWANYM kodem, ktory dziala w kazdym srodowisku.

---

# Recap spotkania 3

```
Co juz umiemy:

  ✅ Pakiety: apt / dnf / package, present vs latest
  ✅ Aktualizacje: upgrade safe/dist, reboot, serial
  ✅ Dyski: parted → LVM → filesystem → mount
  ✅ Pliki: template / lineinfile / blockinfile + validate
  ✅ Transfer: copy, fetch, synchronize, get_url
  ✅ Lab: "standard firmowy" serwera + LVM na loop device

Dzis — logika i parametryzacja:

  ● Zmienne: wszystkie miejsca definicji + zasieg
  ● Precedence: 10 poziomow, ale wystarczy zapamietac 4 reguly
  ● when: warunki na faktach, zmiennych i wynikach taskow
  ● loop: listy, slowniki, register w petli, loop_control
  ● Jeden playbook — wiele srodowisk (dev/prod)
```

---

---
# MODUL 1
# Praca ze zmiennymi
---

---

# Gdzie mozna zdefiniowac zmienna — przeglad

```
  INVENTORY                          PLAYBOOK
  ─────────────────────────          ─────────────────────────
  group_vars/all.yml                 vars:            (w play)
  group_vars/webservers.yml          vars_files:      (z plikow)
  host_vars/web01.yml                vars_prompt:     (pyta usera)
  hosts.yml (inline)                 vars: przy tasku

  W TRAKCIE WYKONANIA                Z ZEWNATRZ
  ─────────────────────────          ─────────────────────────
  set_fact                           -e "port=9090"   (CLI)
  register                           -e @plik.yml     (CLI, z pliku)
  fakty (gather_facts)               zmienne srodowiskowe AWX/CI
```

**Nazewnictwo — dobre praktyki:**
```yaml
app_port: 8080              # ✅ snake_case, prefiks komponentu
apache_max_workers: 50      # ✅ od razu wiadomo czyja to zmienna
port: 8080                  # ❌ czyj port? konflikt murowany
AppPort: 8080               # ❌ nie mieszaj konwencji
```

---

# vars, vars_files, vars_prompt

```yaml
- name: Rozne zrodla zmiennych
  hosts: webservers

  vars:                              # 1. wprost w play
    app_port: 8080

  vars_files:                        # 2. z plikow YAML
    - vars/wspolne.yml
    - vars/aplikacja.yml

  vars_prompt:                       # 3. pytanie do operatora
    - name: wersja_do_wdrozenia
      prompt: "Ktora wersje wdrazamy?"
      private: false                 # false = widac co wpisujesz

  tasks:
    - name: Pokaz co mamy
      debug:
        msg: "Wdrazam {{ app_name }} {{ wersja_do_wdrozenia }} na port {{ app_port }}"
```

```
  vars:        stale playbooka (rzadko zmieniane)
  vars_files:  wieksze zestawy danych, wspoldzielone miedzy playbookami
  vars_prompt: dane jednorazowe od operatora (wersja, potwierdzenie)
               — w automatyce (CI/AWX) zastepowane przez -e!
```

---

# set_fact i register — zmienne w trakcie wykonania

**`set_fact` — obliczasz i zapisujesz:**
```yaml
- name: Ustal rozmiar cache na podstawie RAM hosta
  set_fact:
    cache_mb: "{{ (ansible_memtotal_mb * 0.25) | int }}"

- name: Zbuduj pelna nazwe wydania
  set_fact:
    release_name: "{{ app_name }}-{{ app_version }}-{{ ansible_date_time.date }}"
```

**`register` — przechwytujesz wynik taska:**
```yaml
- name: Sprawdz aktywne polaczenia
  command: ss -tln
  register: porty
  changed_when: false

- name: Pokaz liczbe nasluchujacych portow
  debug:
    msg: "Portow: {{ porty.stdout_lines | length - 1 }}"
```

> Roznica zasiegow: `set_fact`/`register` zyja per HOST
> do konca playbooka. Zmienna ustawiona na web01
> nie istnieje na web02 (chyba ze przez hostvars).

---

# Zmienne specjalne — magia wbudowana

```yaml
inventory_hostname      # nazwa hosta Z INVENTORY (web01)
ansible_hostname        # hostname zgloszony przez system (fakt)

group_names             # grupy AKTUALNEGO hosta
                        # → ['webservers', 'prod']

groups                  # CALE inventory jako slownik
                        # groups['webservers'] → ['web01', 'web02']
groups['all']           # lista wszystkich hostow

hostvars                # zmienne INNYCH hostow!
hostvars['db01']['ansible_default_ipv4']['address']
```

**Praktyczne uzycie — np. konfiguracja aplikacji wskazujaca na baze:**
```jinja2
# app.conf.j2 — host laczy sie z PIERWSZA baza z grupy databases
db_host = {{ hostvars[groups['databases'][0]]['ansible_default_ipv4']['address'] }}
```

**Czy jestem w prod? — `group_names`:**
```yaml
- name: Task tylko dla srodowiska produkcyjnego
  debug:
    msg: "Jestem na produkcji!"
  when: "'prod' in group_names"
```

---

---
# MODUL 2
# Variable precedence — co wygrywa
---

---

# Hierarchia — od najslabszej do najsilniejszej

```
  Priorytet (od NAJNIZSZEGO do NAJWYZSZEGO):
  ─────────────────────────────────────────────────────────
   1.  defaults roli (defaults/main.yml)      ← spotkanie 5
   2.  group_vars/all.yml
   3.  group_vars/<grupa>.yml
   4.  host_vars/<host>.yml
   5.  fakty hosta (gather_facts)
   6.  vars: w play
   7.  vars_files: w play
   8.  vars roli (vars/main.yml)              ← spotkanie 5
   9.  vars: przy tasku
  10.  set_fact / register
  11.  -e "zmienna=wartosc"                   ← NAJWYZSZY, zawsze
  ─────────────────────────────────────────────────────────
```

**4 reguly, ktore wystarcza w praktyce:**
```
  1. Bardziej SZCZEGOLOWE bije ogolne     (host > grupa > all)
  2. Blizsze WYKONANIU bije statyczne     (set_fact > vars > inventory)
  3. -e z CLI bije WSZYSTKO               (dlatego uzywaj oszczednie!)
  4. defaults roli przegrywa ze wszystkim (dlatego to "defaults")
```

---

# Precedence na przykladzie

```
  Zmienna app_port zdefiniowana w 4 miejscach:

  group_vars/all.yml           app_port: 80
  group_vars/webservers.yml    app_port: 8080
  host_vars/web01.yml          app_port: 8081
  CLI:  -e "app_port=9999"

  ┌──────────────────────────────────────────────────┐
  │ ansible-playbook site.yml                        │
  │   → web01 dostaje 8081   (host_vars wygrywa)     │
  │   → web02 dostaje 8080   (brak host_vars,        │
  │                           grupa wygrywa z all)   │
  │                                                  │
  │ ansible-playbook site.yml -e "app_port=9999"     │
  │   → WSZYSCY dostaja 9999 (extra vars rzadzi)     │
  └──────────────────────────────────────────────────┘
```

**Jak sprawdzic, co host NAPRAWDE dostanie:**
```bash
ansible-inventory --host web01            # zmienne z inventory
ansible web01 -m debug -a "var=app_port"  # finalna wartosc
```

---

# Gdzie umieszczac zmienne — decyzje projektowe

| Co opisuje zmienna                       | Gdzie ja polozyc            |
|------------------------------------------|-----------------------------|
| Cecha srodowiska (dev/prod: adresy, rozmiary) | `group_vars/<srodowisko>.yml` |
| Cecha grupy funkcyjnej (port www, wersja PHP) | `group_vars/<rola-grupy>.yml` |
| Wyjatek jednego hosta                    | `host_vars/<host>.yml`      |
| Wspolne dla calego projektu              | `group_vars/all.yml`        |
| Domyslna wartosc komponentu (nadpisywalna) | `defaults/` roli (spotkanie 5) |
| Jednorazowa decyzja operatora            | `-e` przy uruchomieniu      |

```
  Zasada "najnizszego sensownego poziomu":

  Definiuj zmienna na NAJOGOLNIEJSZYM poziomie, na ktorym
  jest prawdziwa. Nadpisuj TYLKO tam, gdzie jest inaczej.

  ❌ app_port powtorzony w host_vars 20 hostow
  ✅ app_port w group_vars/webservers.yml
     + jeden wyjatek w host_vars/web-specjalny.yml
```

---

---
# MODUL 3
# Warunkowe wykonywanie zadan: when
---

---

# when — podstawy

```yaml
- name: Zainstaluj apache2 (tylko Debian/Ubuntu)
  apt:
    name: apache2
    state: present
  when: ansible_os_family == "Debian"
```

```
  Zasady when:
  ─────────────────────────────────────────────────────
  1. To wyrazenie Jinja2 — ale BEZ {{ }} !
  2. Sprawdzane per HOST (i per item w petli)
  3. Niespelnione → task SKIPPED (nie failed)
```

**Operatory:**
```yaml
when: app_port == 8080               # rownosc
when: app_env != "prod"              # nierownosc
when: ansible_memtotal_mb > 4096     # porownania liczb
when: "'prod' in group_names"        # zawieranie w liscie
when: not app_debug                  # negacja
```

> Uwaga na YAML: warunek zaczynajacy sie od stringa w cudzyslowie
> (`'prod' in ...`) musi byc CALY w cudzyslowie — inaczej blad parsera.

---

# when — laczenie warunkow

**`and` — wszystkie musza byc spelnione:**
```yaml
- name: Duzy serwer produkcyjny
  debug:
    msg: "Wdrazam konfiguracje high-performance"
  when: ansible_memtotal_mb >= 8192 and "'prod' in group_names"
```

**Lista = czytelniejszy zapis `and`:**
```yaml
  when:
    - ansible_os_family == "Debian"
    - ansible_distribution_version is version('22.04', '>=')
    - app_enabled | bool
```

**`or` i nawiasy:**
```yaml
  when: >
    (ansible_os_family == "Debian" and ansible_distribution_version is version('12', '>='))
    or
    (ansible_os_family == "RedHat" and ansible_distribution_major_version | int >= 9)
```

> Test `is version()` porownuje wersje POPRAWNIE:
> "9.10" > "9.9" (zwykle porownanie stringow tu klamie!).

---

# when — zmienne opcjonalne i testy

**Problem: zmienna moze NIE istniec → blad "undefined variable"**

```yaml
- name: Wykonaj tylko gdy zmienna ustawiona
  debug:
    msg: "Tryb migracji: {{ tryb_migracji }}"
  when: tryb_migracji is defined

- name: Wykonaj gdy zmiennej BRAK
  debug:
    msg: "Standardowe wdrozenie (bez migracji)"
  when: tryb_migracji is not defined
```

**Pulapka bool — zmienne z CLI i inventory INI to STRINGI:**
```yaml
# ansible-playbook site.yml -e "czyszczenie=false"
- name: To wykona sie ZAWSZE (blad!)
  file: { path: /tmp/cache, state: absent }
  when: czyszczenie              # ❌ "false" (string) jest truthy!

- name: Poprawnie — jawna konwersja
  file: { path: /tmp/cache, state: absent }
  when: czyszczenie | default(false) | bool     # ✅
```

```
  Nawyk: kazda zmienna logiczna w when
         → | default(false) | bool
```

---

# when + register — decyzje na podstawie wynikow

```yaml
- name: Sprawdz czy aplikacja jest juz zainstalowana
  stat:
    path: /opt/app/wersja.txt
  register: instalacja

- name: Pierwsza instalacja (pelna)
  include_tasks: instalacja_pelna.yml
  when: not instalacja.stat.exists

- name: Sprawdz status uslugi
  command: systemctl is-active aplikacja
  register: status_uslugi
  changed_when: false
  failed_when: false             # rc != 0 to dla nas INFORMACJA, nie blad

- name: Uruchom jesli lezy
  service:
    name: aplikacja
    state: started
  when: status_uslugi.rc != 0
```

**Co mozna sprawdzac w zarejestrowanej zmiennej:**
```yaml
when: wynik.rc == 0                    # kod wyjscia
when: "'ERROR' in wynik.stdout"        # zawartosc wyjscia
when: wynik.stat.exists                # stat: istnienie pliku
when: wynik is changed                 # czy task cos zmienil
when: wynik is failed                  # czy sie nie powiodl
```

---

---
# MODUL 4
# Cykliczne wykonywanie zadan: loop
---

---

# loop — listy proste i listy slownikow

**Po prostej liscie:**
```yaml
- name: Stworz katalogi aplikacji
  file:
    path: "/opt/app/{{ item }}"
    state: directory
  loop:
    - logs
    - config
    - data
```

**Po liscie slownikow — struktury z group_vars:**
```yaml
# group_vars/all.yml:
#   uzytkownicy:
#     - { name: deploy,  uid: 1500, grupy: "www-data" }
#     - { name: monitor, uid: 1501, grupy: "monitoring" }

- name: Stworz uzytkownikow
  user:
    name: "{{ item.name }}"
    uid: "{{ item.uid }}"
    groups: "{{ item.grupy }}"
    state: present
  loop: "{{ uzytkownicy }}"
```

> Dane trzymaj w inventory (group_vars), petle w playbooku.
> Dodanie uzytkownika = edycja YAML z danymi, nie kodu.

---

# loop po slowniku — dict2items

**Slownika nie mozna iterowac wprost — najpierw filtr `dict2items`:**

```yaml
vars:
  limity_srodowisk:
    dev:  { cpu: 1, ram_mb: 1024 }
    test: { cpu: 2, ram_mb: 2048 }
    prod: { cpu: 8, ram_mb: 16384 }

tasks:
  - name: Pokaz limity kazdego srodowiska
    debug:
      msg: "{{ item.key }}: cpu={{ item.value.cpu }}, ram={{ item.value.ram_mb }}"
    loop: "{{ limity_srodowisk | dict2items }}"
```

```
  dict2items zamienia slownik na liste par:

  { dev: {...}, prod: {...} }
        │ dict2items
        ▼
  [ { key: 'dev',  value: {...} },
    { key: 'prod', value: {...} } ]

  Dostep w petli:  item.key  /  item.value.pole
```

---

# loop + register i loop + when

**`register` w petli — wyniki laduja w `.results`:**
```yaml
- name: Sprawdz obecnosc plikow konfiguracyjnych
  stat:
    path: "/etc/app/{{ item }}"
  register: konfigi
  loop: [app.conf, db.conf, cache.conf]

- name: Zglos brakujace pliki
  debug:
    msg: "BRAK pliku: {{ item.item }}"      # item.item = element oryginalnej petli
  loop: "{{ konfigi.results }}"
  when: not item.stat.exists                # when dziala PER ITEM!
```

**`when` + `loop` w jednym tasku — warunek per element:**
```yaml
- name: Stworz tylko aktywnych uzytkownikow
  user:
    name: "{{ item.name }}"
    state: present
  loop: "{{ uzytkownicy }}"
  when: item.aktywny | bool
```

```
  Kolejnosc: Ansible NAJPIERW rozwija loop,
  POTEM sprawdza when dla kazdego item osobno.
  (niespelnione → item pokazany jako "skipped")
```

---

# loop_control — panowanie nad petla

**Problem: przy duzych slownikach log jest nieczytelny:**
```
ok: [web01] => (item={'name': 'deploy', 'uid': 1500, 'shell': ..., 
    'grupy': [...], 'klucze_ssh': [...jeszcze 30 linii...]})
```

**`label` — pokazuj tylko to, co istotne:**
```yaml
- name: Stworz uzytkownikow
  user:
    name: "{{ item.name }}"
    uid: "{{ item.uid }}"
  loop: "{{ uzytkownicy }}"
  loop_control:
    label: "{{ item.name }}"        # → (item=deploy) — czysto!
```

**`index_var` — numer iteracji:**
```yaml
- name: Ponumeruj serwery aplikacji
  lineinfile:
    path: /etc/app/cluster.conf
    line: "node{{ moj_index }} = {{ item }}"
  loop: "{{ groups['webservers'] }}"
  loop_control:
    index_var: moj_index            # 0, 1, 2...
```

> Jest tez `pause: 5` (odstep miedzy iteracjami) —
> przydatne przy rolling restartach w petli.

---

---
# MODUL 5
# Parametryzacja i konfiguracja per srodowisko
---

---

# Parametryzacja — jeden kod, rozne dane

**Wzorzec: nazwy pakietow per rodzina systemu (obiecany na spotkaniu 3):**

```yaml
vars:
  apache:
    Debian:
      pakiet: apache2
      usluga: apache2
      docroot: /var/www/html
    RedHat:
      pakiet: httpd
      usluga: httpd
      docroot: /var/www/html

tasks:
  - name: Zainstaluj Apache (kazda dystrybucja)
    package:
      name: "{{ apache[ansible_os_family].pakiet }}"
      state: present

  - name: Uruchom Apache
    service:
      name: "{{ apache[ansible_os_family].usluga }}"
      state: started
```

```
  Zero taskow z when per dystrybucja — SLOWNIK wybiera dane,
  fakty hosta sa kluczem. Dodanie Suse = dopisanie galezi w vars.
```

---

# Srodowiska dev/test/prod — dwa wzorce

**Wzorzec A — grupy srodowisk w JEDNYM inventory:**
```
inventory/
├── hosts.yml            #  dev: [web01]   prod: [web02, web03]
└── group_vars/
    ├── all.yml          #  wspolne wartosci domyslne
    ├── dev.yml          #  app_debug: true,  replicas: 1
    └── prod.yml         #  app_debug: false, replicas: 3
```

**Wzorzec B — OSOBNE inventory per srodowisko (spotkanie 2):**
```
inventories/
├── dev/    ├── hosts.yml  └── group_vars/all.yml
└── prod/   ├── hosts.yml  └── group_vars/all.yml
```

| Kryterium              | A: grupy               | B: osobne inventory     |
|------------------------|------------------------|-------------------------|
| Prostota startu        | ✅ jeden plik          | wiecej katalogow        |
| Ochrona przed pomylka  | ❌ latwo trafic w prod | ✅ -i wybiera srodowisko|
| Wspolne zmienne        | ✅ naturalnie w all    | wymagaja duplikacji     |

> Male projekty: A. Powazna produkcja: B (+ osobne uprawnienia).
> Wzorzec B pelniej — na spotkaniu 7.

---

# Konfiguracja per srodowisko — kompletny przyklad

**`group_vars/all.yml`** (bezpieczne wartosci domyslne):
```yaml
app_name: sklep
app_port: 8080
app_debug: false
app_replicas: 1
```

**`group_vars/dev.yml`:**          **`group_vars/prod.yml`:**
```yaml                             
app_debug: true                     # app_debug: false (z all)
app_log_level: debug                app_log_level: warning
                                    app_replicas: 3
```

**Szablon `app.conf.j2` — jeden dla wszystkich srodowisk:**
```jinja2
# Srodowisko: {{ srodowisko | default('nieznane') }}
app={{ app_name }}
port={{ app_port }}
log_level={{ app_log_level | default('info') }}
debug={{ app_debug | ternary('true', 'false') }}
replicas={{ app_replicas }}
```

> `ternary('a','b')` = "jesli prawda to a, inaczej b" — czytelniejsze
> niz inline if dla prostych przypadkow.
> `default()` w szablonie = odpornosc na niekompletne group_vars.

---

# Antywzorce parametryzacji

```
  ❌ Kopia playbooka per srodowisko
     site_dev.yml + site_test.yml + site_prod.yml
     → poprawka biznesowa = 3 edycje, 3 szanse na blad

  ❌ Warunki zamiast zmiennych
     when: srodowisko == 'dev'  na 30 taskach
     → logika rozsmarowana po playbooku

  ❌ Wartosci na sztywno w taskach
     port: 8080 wprost w module
     → zmiana = szukanie po wszystkich plikach

  ✅ JEDEN playbook + zmienne w group_vars per srodowisko
     roznice miedzy srodowiskami widac w JEDNYM miejscu:
     diff inventory/group_vars/dev.yml inventory/group_vars/prod.yml
```

```
  Test dojrzalosci playbooka:
  "Czy moge wdrozyc na nowe srodowisko QA
   BEZ EDYCJI playbooka — tylko dodajac group_vars/qa.yml?"
```

---

# LAB 4 — Warsztat (55 min)

```
Zadanie (katalog: szkolenie8x4/lab4/):

Scenariusz: web01 to serwer DEV, web02 to PROD.
Jeden playbook ma skonfigurowac oba — roznice tylko w zmiennych.

1. Uzupelnij inventory: hosty w grupach dev i prod
   + group_vars/prod.yml (na wzor dev.yml)

2. petle.yml (miejsca # TODO):
   - katalogi aplikacji z listy (loop)
   - uzytkownicy z listy slownikow (loop + item.name)
   - czytelny log (loop_control: label)
   - raport brakujacych plikow (loop + register + when)

3. warunki.yml (miejsca # TODO):
   - task tylko dla Debiana (when + fakt)
   - task tylko gdy app_debug (| bool!)
   - task tylko na prod (group_names)
   - ostrzezenie gdy malo RAM (lista warunkow = AND)

4. konfiguracja_srodowisk.yml (miejsca # TODO):
   - app.conf z szablonu — WSPOLNY dla dev i prod
   - flaga backupu tylko na prod
   - porownaj wyniki: cat /etc/szkolenie/app_env.conf na obu hostach

5. Idempotencja: drugi run → changed=0
```

> Instrukcja: `lab4/README.md` · Rozwiazania: `*_odpowiedz.yml`

---

# Podsumowanie spotkania 4

```
Co juz umiemy:

  ✅ Zmienne: vars / vars_files / vars_prompt / set_fact / -e
  ✅ Zmienne specjalne: group_names, groups, hostvars
  ✅ Precedence: host > grupa > all, -e bije wszystko
  ✅ when: operatory, and/or/lista, is defined, | bool, is version
  ✅ when + register: decyzje na podstawie stanu hosta
  ✅ loop: listy, slowniki (dict2items), register (.results)
  ✅ loop_control: label, index_var
  ✅ Parametryzacja: slownik per os_family, group_vars per srodowisko
  ✅ Lab: jeden playbook — dwa srodowiska (dev/prod)

Na spotkaniu 5 — role i Ansible Galaxy:

  ● Rola: struktura, tasks/handlers/templates/defaults
  ● ansible-galaxy role init — szkielet wlasnej roli
  ● Refaktoryzacja playbookow do rol
  ● Galaxy i kolekcje: gotowe rozwiazania spolecznosci
  ● Lab: wlasna rola + instalacja roli z Galaxy
```

---

# Pytania?

## Do zobaczenia na spotkaniu 5!

*Materialy szkoleniowe dostepne w repozytorium Git*
