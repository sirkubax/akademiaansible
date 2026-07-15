# Automatyzacja z Ansible
### Szkolenie 8 spotkan x 4h · Spotkanie 1
## Wprowadzenie do Ansible

---

# Agenda spotkania 1 (4h)

| Czas        | Blok        | Temat                                              |
|-------------|-------------|----------------------------------------------------|
| 0:00 – 0:30 | **Modul 1** | Systemy orkiestracji, Ansible vs Terraform         |
| 0:30 – 1:00 | **Modul 2** | Czym jest Ansible — architektura i zasada dzialania|
| 1:00 – 1:45 | **Modul 3** | Podstawy YAML i struktury danych                   |
| 1:45 – 2:00 | ☕ Przerwa  |                                                    |
| 2:00 – 2:20 | **Modul 4** | Podstawy Jinja2                                    |
| 2:20 – 2:50 | **Modul 5** | Komponenty Ansible: inventory, playbooki, moduly   |
| 2:50 – 3:15 | **Modul 6** | Asystent AI: VS Code + Copilot                     |
| 3:15 – 4:00 | **Lab 1**   | Instalacja, inventory, ad-hoc, pierwszy playbook   |

---

# Cele spotkania 1

Po tym spotkaniu uczestnik:

- Rozumie, gdzie Ansible pasuje w krajobrazie narzedzi automatyzacji
  (i kiedy lepszy bedzie Terraform)
- Zna architekture Ansible i zasade dzialania (agentless, SSH, idempotencja)
- Czyta i pisze poprawny YAML, rozumie struktury danych w playbookach
- Zna podstawy skladni Jinja2: `{{ zmienna }}` i filtry
- Rozroznia komponenty: inventory, playbook, task, modul, zmienne
- Ma skonfigurowane srodowisko: Ansible + VS Code + asystent AI
- **Lab:** instaluje Ansible, konfiguruje inventory, uruchamia
  pierwsze polecenia ad-hoc i pierwszy playbook

---

---
# MODUL 1
# Systemy orkiestracji i automatyzacji
---

---

# Po co automatyzacja?

```
  Bez automatyzacji:                Z automatyzacja:
  ─────────────────────────         ─────────────────────────
  Reczna konfiguracja               Kod opisuje stan systemu
  kazdego serwera                   (Infrastructure as Code)

  "U mnie dziala"                   Kazde srodowisko identyczne
  snowflake servers                 dev = test = prod

  Wiedza w glowie admina            Wiedza w repozytorium Git
  (urlop = problem)                 (code review, historia zmian)

  Skalowanie = wiecej ludzi         Skalowanie = ta sama praca
  10 serwerow = 10x praca           10 czy 1000 hostow — 1 playbook
```

> **Infrastructure as Code (IaC):** infrastruktura i konfiguracja
> opisane w plikach tekstowych, wersjonowane jak kazdy inny kod.

---

# Krajobraz narzedzi automatyzacji

| Narzedzie      | Typ                  | Agent?    | Jezyk       | Model      |
|----------------|----------------------|-----------|-------------|------------|
| **Ansible**    | konfiguracja + orkiestracja | brak (SSH) | YAML   | push       |
| Puppet         | konfiguracja         | agent     | Puppet DSL  | pull       |
| Chef           | konfiguracja         | agent     | Ruby        | pull       |
| Salt           | konfiguracja         | agent/SSH | YAML        | push/pull  |
| **Terraform**  | provisioning infrastruktury | brak | HCL       | deklaratywny + stan |
| CloudFormation | provisioning (AWS)   | brak      | JSON/YAML   | deklaratywny |

```
  push:  control node ──► wypycha zmiany na hosty (Ansible)
  pull:  agent na hoscie ──► cyklicznie pyta serwer o konfiguracje (Puppet)
```

---

# Ansible vs alternatywy

```
               Prostota  │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░│ Ansible
                         │▓▓▓▓▓▓▓▓░░░░░░░░░░░│ Salt
                         │▓▓▓▓▓░░░░░░░░░░░░░░│ Puppet
                         │▓▓▓░░░░░░░░░░░░░░░░│ Chef
```

**Kiedy Ansible wygrywa:**
- Nie chcesz instalowac agentow na hostach
- Masz heterogeniczne srodowisko (Linux, Windows, urzadzenia sieciowe)
- Twoj zespol pisze YAML, nie Ruby/Python
- Zaczynasz od zera i chcesz szybkich wynikow

---

# Ansible vs Terraform — inne zadania

```
  ┌─────────────────────────────┬─────────────────────────────┐
  │         TERRAFORM           │           ANSIBLE           │
  │   "postaw infrastrukture"   │   "skonfiguruj systemy"     │
  ├─────────────────────────────┼─────────────────────────────┤
  │  Tworzy VM, siec, LB, DNS   │  Instaluje pakiety          │
  │  w chmurze (AWS/Azure/GCP)  │  Konfiguruje uslugi         │
  │                             │  Wdraza aplikacje           │
  │  Trzyma STATE FILE          │  Bez pliku stanu —          │
  │  (wie co stworzyl,          │  sprawdza stan hosta        │
  │   umie to usunac)           │  przy kazdym uruchomieniu   │
  │                             │                             │
  │  Immutable: zmiana czesto   │  Mutable: modyfikuje        │
  │  = zniszcz i stworz od nowa │  istniejacy system          │
  └─────────────────────────────┴─────────────────────────────┘
```

---

# Ansible vs Terraform — przyklady

**Zadanie: nowe srodowisko aplikacji w AWS**

```
  Terraform:                        Ansible:
  ──────────────────────            ──────────────────────
  ✓ VPC + subnety                   ✓ apt install nginx
  ✓ 3x EC2 instance                 ✓ konfiguracja vhostow
  ✓ Load balancer                   ✓ deploy aplikacji
  ✓ Security groups                 ✓ uzytkownicy i klucze SSH
  ✓ Baza RDS                        ✓ crony, backupy, monitoring
```

**Najlepszy wzorzec — oba narzedzia razem:**

```
  Terraform ──► tworzy infrastrukture ──► oddaje liste IP
                                              │
  Ansible   ◄── dynamiczne inventory      ◄───┘
            ──► konfiguruje systemy i wdraza aplikacje
```

> Ansible POTRAFI tworzyc zasoby w chmurze (moduly amazon.aws),
> a Terraform POTRAFI odpalic skrypt na VM (provisioner) —
> ale kazde z nich blyszczy w swojej roli.

---

# Kiedy co wybrac — sciagawka

| Scenariusz                                       | Narzedzie          |
|--------------------------------------------------|--------------------|
| Konfiguracja 50 istniejacych serwerow Linux      | Ansible            |
| Utworzenie infrastruktury w AWS od zera          | Terraform          |
| Deploy aplikacji + restart uslug w kolejnosci    | Ansible            |
| Zarzadzanie cyklem zycia chmury (create/destroy) | Terraform          |
| Patchowanie i aktualizacje systemow              | Ansible            |
| Orkiestracja Windows + Linux + sieciowki         | Ansible            |
| Kompletna platforma: infra + konfiguracja        | Terraform + Ansible|

---

---
# MODUL 2
# Czym jest Ansible
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

# Jak przebiega wykonanie zadania

```
  1. Ansible czyta inventory        "na jakich hostach?"
  2. Ansible czyta playbook/task    "co zrobic?"
  3. Laczy sie przez SSH            (rownolegle, domyslnie 5 hostow)
  4. Kopiuje modul (kod Python)     do katalogu tymczasowego hosta
  5. Wykonuje modul                 modul sprawdza stan i zmienia
                                    TYLKO gdy trzeba
  6. Usuwa pliki tymczasowe
  7. Zwraca wynik JSON              ok / changed / failed
```

**Wymagania:**

| Gdzie         | Co jest potrzebne                          |
|---------------|--------------------------------------------|
| Control node  | Linux/macOS, Python 3, pakiet `ansible`   |
| Managed host  | SSH + Python (Windows: WinRM/SSH + PowerShell) |

---

# Idempotentnosc — najwazniejsza cecha

**Skrypt bash (NIE-idempotentny):**
```bash
useradd deploy            # 2. uruchomienie: ERROR user exists
echo "port 8080" >> app.conf   # 2. uruchomienie: zdublowany wpis!
```

**Ansible (idempotentny):**
```yaml
- name: Stworz uzytkownika deploy
  user:
    name: deploy
    state: present        # "ma istniec" — nie "utworz"
```

```
  1. uruchomienie:  changed  (uzytkownik utworzony)
  2. uruchomienie:  ok       (juz istnieje — nic nie robi)
  3. uruchomienie:  ok
```

> Opisujesz STAN DOCELOWY, a nie kroki do wykonania.
> Dzieki temu playbook mozna bezpiecznie uruchamiac wielokrotnie.

---

---
# MODUL 3
# Podstawy YAML i struktury danych
---

---

# YAML — fundament Ansible

**YAML = YAML Ain't Markup Language** — format danych czytelny dla czlowieka.

```yaml
---                          # poczatek dokumentu
# To jest komentarz

klucz: wartosc               # para klucz-wartosc (slownik/mapa)
liczba: 42                   # int
zmiennoprzecinkowa: 3.14     # float
prawda: true                 # boolean
tekst: "hello world"         # string (cudzyslow opcjonalny)
nic: null                    # brak wartosci
```

**Zasady:**
- Wciecia = struktura. **Zawsze spacje, NIGDY tabulatory**
- Standard: 2 spacje na poziom
- Wielkosc liter ma znaczenie (`Name` ≠ `name`)
- Rozszerzenie pliku: `.yml` lub `.yaml`

---

# YAML — listy i slowniki

**Lista (sekwencja):**
```yaml
pakiety:
  - nginx
  - curl
  - htop
```

**Slownik (mapa):**
```yaml
serwer:
  nazwa: web01
  ip: 192.168.1.10
  port: 80
```

**To samo w jednej linii (flow style):**
```yaml
pakiety: [nginx, curl, htop]
serwer: { nazwa: web01, ip: 192.168.1.10, port: 80 }
```

> Cala skladnia Ansible to kombinacje list i slownikow.

---

# YAML — struktury zagniezdzone

**Lista slownikow — najczestsza struktura w Ansible:**

```yaml
uzytkownicy:
  - name: jan
    uid: 1501
    grupy: [admins, docker]
  - name: anna
    uid: 1502
    grupy: [developers]
```

**Slownik ze slownikami:**

```yaml
srodowiska:
  dev:
    db_host: dev-db.local
    debug: true
  prod:
    db_host: prod-db.local
    debug: false
```

**Dostep w Ansible:**
```yaml
{{ uzytkownicy[0].name }}          # → jan
{{ srodowiska.prod.db_host }}      # → prod-db.local
{{ srodowiska['prod']['debug'] }}  # → false (zapis alternatywny)
```

---

# YAML — teksty wieloliniowe i cytowanie

**Blok `|` — zachowuje znaki nowej linii:**
```yaml
skrypt: |
  #!/bin/bash
  echo "linia 1"
  echo "linia 2"
```

**Blok `>` — sklada w jedna linie:**
```yaml
opis: >
  To jest dlugi opis,
  ktory w wyniku bedzie
  jedna linia tekstu.
```

**Kiedy cudzyslow jest KONIECZNY:**
```yaml
mode: '0644'          # bez '' YAML zrobi z tego liczbe 420 (octal)!
wersja: '3.10'        # bez '' zostanie float 3.1
msg: "port: 8080"     # dwukropek + spacja w wartosci
zmienna: "{{ var }}"  # wartosc ZACZYNA sie od {{ — wymagany cudzyslow
```

---

# YAML — typowe pulapki

```
  ❌ Tabulator zamiast spacji        → blad parsowania
  ❌ Nierowne wciecia                → inna struktura niz myslisz
  ❌ Brak spacji po dwukropku        → klucz:wartosc to JEDEN string
  ❌ yes/no/on/off bez cudzyslowu    → staja sie boolean!
```

**Klasyczny przyklad — kraj "Norwegia":**
```yaml
kraj: NO         # ← to jest boolean FALSE, nie string "NO"!
kraj: 'NO'       # ← poprawnie: string
```

**Weryfikacja skladni:**
```bash
# Szybki test parsowania YAML
python3 -c "import yaml,sys; yaml.safe_load(open('plik.yml'))"

# Skladnia playbooka (nie laczy sie z hostami)
ansible-playbook playbook.yml --syntax-check

# Linter — wylapie tez zle praktyki
ansible-lint playbook.yml
```

---

# Struktury danych w playbookach

**Playbook to... lista slownikow.** Zobacz sam:

```yaml
---
- name: Moj pierwszy play          # ┐ element listy = slownik
  hosts: webservers                # │ z kluczami: name, hosts,
  become: true                     # │ become, tasks
  tasks:                           # │
    - name: Zainstaluj nginx       # │  ┐ tasks to LISTA slownikow
      package:                     # │  │ kazdy task = slownik
        name: nginx                # │  │ z kluczem-modulem,
        state: present             # │  │ ktorego wartoscia jest
                                   # │  │ slownik parametrow
    - name: Uruchom nginx          # │  │
      service:                     # │  │
        name: nginx                # │  │
        state: started             # │  ┘
                                   # ┘
```

> Gdy rozumiesz listy i slowniki — rozumiesz kazdy playbook.
> Blad wciecia = task laduje w zlym miejscu struktury.

---

---
# MODUL 4
# Podstawy Jinja2
---

---

# Jinja2 — silnik szablonow

**Jinja2 wstawia wartosci zmiennych do tekstu.** Ansible uzywa go wszedzie.

```
  {{ zmienna }}      wstaw wartosc wyrazenia
  {% logika %}       instrukcje: if, for
  {# komentarz #}    komentarz (nie trafia do wyniku)
```

**W playbooku:**
```yaml
- name: Przywitaj hosta
  debug:
    msg: "Czesc, jestem {{ inventory_hostname }} ({{ ansible_default_ipv4.address }})"
```

**W szablonie pliku (`template`):**
```jinja2
# app.conf — wygenerowano przez Ansible
server_name {{ ansible_fqdn }}
listen      {{ app_port }}
workers     {{ ansible_processor_count }}
```

---

# Jinja2 — filtry, czyli przetwarzanie wartosci

**Filtr = funkcja za znakiem `|`:**

```yaml
{{ timeout | default(30) }}          # wartosc domyslna gdy brak zmiennej
{{ "42" | int }}                     # konwersja typu
{{ app_name | upper }}               # "myapp" → "MYAPP"
{{ ["a","b","c"] | join(", ") }}     # → "a, b, c"
{{ lista | length }}                 # ilosc elementow
{{ lista | unique | sort }}          # unikalne, posortowane
```

**Filtry mozna laczyc w potok:**
```yaml
{{ users | map(attribute="name") | list | join(", ") }}
```

**Warunek inline:**
```yaml
{{ 'debug' if debug_mode | default(false) else 'warn' }}
```

> Na spotkaniu 2 bedziemy cwiczyc Jinja2 na strukturach danych,
> a szablony `template` poznamy przy operacjach na plikach.

---

# Gdzie Jinja2 dziala w Ansible

```yaml
- name: Przyklad — Jinja2 w roznych miejscach
  hosts: webservers
  vars:
    app_port: 8080
    app_root: "/opt/app"                     # ← w definicji zmiennych
  tasks:
    - name: Katalog wersji {{ app_version }}  # ← w nazwie taska
      file:
        path: "{{ app_root }}/{{ app_version }}"   # ← w parametrach
        state: directory

    - name: Wygeneruj konfiguracje
      template:
        src: app.conf.j2                     # ← caly plik .j2 to Jinja2
        dest: "{{ app_root }}/app.conf"
```

**Wazna zasada:**
```yaml
when: app_port == 8080          # w when/warunkach BEZ {{ }} —
                                # to juz jest wyrazenie Jinja2
```

---

---
# MODUL 5
# Komponenty Ansible
---

---

# Komponenty — jak to sie sklada w calosc

```
  ┌────────────┐     ┌─────────────────────────────────┐
  │ INVENTORY  │     │            PLAYBOOK             │
  │            │     │                                 │
  │ web01      │     │  play: hosts=webservers         │
  │ web02      │◄────┤   ├── task 1 → modul package    │
  │ db01       │     │   ├── task 2 → modul template   │
  │            │     │   └── task 3 → modul service    │
  │ + zmienne  │     │  + zmienne (vars, group_vars)   │
  └────────────┘     └─────────────────────────────────┘
        KTO?                        CO?

  Inventory  — lista hostow i grup (kto bedzie zarzadzany)
  Play       — polaczenie hostow z lista zadan
  Task       — pojedyncze zadanie ("zainstaluj nginx")
  Modul      — kod wykonujacy zadanie (package, copy, service...)
  Zmienne    — parametryzacja (rozne wartosci per host/grupa/srodowisko)
```

---

# Inventory — format INI i YAML

**INI — szybki start:**
```ini
[webservers]
web01 ansible_host=192.168.1.10
web02 ansible_host=192.168.1.11

[databases]
db01 ansible_host=192.168.1.20
```

**YAML — zalecany, latwiej wersjonowac:**
```yaml
all:
  vars:
    ansible_user: ubuntu
  children:
    webservers:
      hosts:
        web01:
          ansible_host: 192.168.1.10
        web02:
          ansible_host: 192.168.1.11
    databases:
      hosts:
        db01:
          ansible_host: 192.168.1.20
```

> Pelna konfiguracja inventory + group_vars/host_vars — na spotkaniu 2.

---

# Zadania ad-hoc — Ansible bez playbooka

```
ansible  <PATTERN>  -m <MODULE>  -a "<ARGUMENTS>"  [opcje]
```

```bash
# Test polaczenia
ansible all -m ping

# Uruchom komende na hostach
ansible webservers -m command -a "uptime"

# Zbierz informacje o systemie (fakty)
ansible web01 -m setup -a "filter=ansible_distribution*"

# Zainstaluj pakiet (z sudo)
ansible webservers -m package -a "name=htop state=present" --become

# Skopiuj plik
ansible web01 -m copy -a "src=./index.html dest=/tmp/index.html"
```

**Kiedy ad-hoc, kiedy playbook?**
```
  ad-hoc:    jednorazowe sprawdzenie / szybka akcja  (uptime, ping, restart)
  playbook:  wszystko co powtarzalne i wersjonowane  (konfiguracja, deploy)
```

---

# Moduly — narzedzia do zadan

```
  ┌──────────────────────────────────────────────────────┐
  │                 MODULY ANSIBLE                        │
  │                                                       │
  │  Pakiety       Pliki          Uslugi     Uzytk.       │
  │  ─────────     ─────────      ───────    ──────       │
  │  package       file           service    user         │
  │  apt           copy           systemd    group        │
  │  yum/dnf       template       cron       authorized.. │
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

**Dokumentacja modulu — bez internetu:**
```bash
ansible-doc package
ansible-doc -l | grep mysql     # szukaj modulow
```

---

# Budowa playbooka — anatomia

```yaml
---
- name: Wdrozenie serwera webowego       # ← nazwa play
  hosts: webservers                      # ← docelowe hosty (z inventory)
  become: true                           # ← sudo
  gather_facts: true                     # ← zbierz fakty o hostach

  vars:
    nginx_port: 80                       # ← zmienne play

  tasks:                                 # ← lista zadan
    - name: Zainstaluj nginx
      package:
        name: nginx
        state: present

    - name: Uruchom nginx
      service:
        name: nginx
        state: started
        enabled: true
```

```bash
ansible-playbook site.yml --syntax-check   # sprawdz skladnie
ansible-playbook site.yml --check --diff   # symulacja bez zmian
ansible-playbook site.yml                  # wykonanie
```

---

# Zmienne i fakty — pierwszy kontakt

**Zmienne definiujesz...**
```yaml
vars:                        # w playbooku
  app_port: 8080
```
```yaml
# inventory/group_vars/webservers.yml — dla calej grupy
app_port: 8080
```
```bash
ansible-playbook site.yml -e "app_port=9090"   # z linii komend
```

**Fakty — zmienne ktore Ansible zbiera SAM (gather_facts):**
```yaml
ansible_hostname              # → "web01"
ansible_os_family             # → "Debian" / "RedHat"
ansible_distribution          # → "Ubuntu"
ansible_default_ipv4.address  # → "192.168.1.10"
ansible_memtotal_mb           # → 4096
```

> Pelna hierarchia zmiennych (variable precedence) — na spotkaniu 4.

---

# Struktura projektu

```
moj_projekt/
│
├── ansible.cfg              ← konfiguracja polaczenia
├── inventory/
│   ├── hosts.yml            ← lista hostow
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
    ├── nginx/               ← rola webservera (spotkanie 5)
    └── database/
```

> Kazdy element ma swoje miejsce.
> Osoba, ktora widzi projekt po raz pierwszy, wie gdzie szukac.

---

---
# MODUL 6
# Asystent AI do generowania kodu
---

---

# Srodowisko pracy: VS Code + rozszerzenia

**Minimalny zestaw dla Ansible:**

| Rozszerzenie             | Do czego                                     |
|--------------------------|----------------------------------------------|
| **Ansible** (Red Hat)    | podswietlanie, autouzupelnianie, ansible-lint|
| **YAML** (Red Hat)       | walidacja skladni i wciec YAML               |
| **GitHub Copilot**       | generowanie kodu w edytorze                  |
| **GitHub Copilot Chat**  | rozmowa o kodzie, wyjasnianie, refaktoryzacja|

**Konfiguracja (settings.json):**
```json
{
  "files.associations": { "*.yml": "ansible" },
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.renderWhitespace": "all"
}
```

> `renderWhitespace` — widzisz kazda spacje.
> W YAML to ratuje zycie.

---

# Stan narzedzi AI — na dzisiaj

| Narzedzie              | Forma                    | Uwagi                          |
|------------------------|--------------------------|--------------------------------|
| GitHub Copilot         | plugin VS Code/JetBrains | autouzupelnianie + chat + agent|
| Claude Code            | terminal / VS Code       | agent: czyta repo, edytuje pliki, uruchamia komendy |
| ChatGPT / Claude (web) | przegladarka             | dobre do wyjasniania i prototypow |
| Ansible Lightspeed     | plugin Ansible (Red Hat) | trenowany na kodzie Ansible    |

```
  Trend: od "podpowiadania linijki"  ──►  do "agenta, ktory sam
         (autocomplete)                    edytuje pliki i testuje"
```

> Narzedzia zmieniaja sie co kwartal — zasady pracy z nimi
> (nastepne slajdy) zmieniaja sie znacznie wolniej.

---

# AI — korzysci w pracy z Ansible

**Gdzie AI realnie przyspiesza:**

- **Boilerplate** — szkielet playbooka, roli, inventory w sekundy
- **Skladnia modulow** — nie pamietasz parametrow `lineinfile`? AI tak
- **Tlumaczenie intencji na kod** — "playbook instalujacy nginx
  z vhostem na porcie 8080" → gotowy szkic
- **Wyjasnianie cudzego kodu** — "co robi ten playbook?"
- **Refaktoryzacja** — "zamien te taski shell na moduly"
- **Debugging** — wklej blad, dostaniesz trop

```
  Regula 80/20:
  AI pisze 80% szkieletu w 20% czasu.
  Twoje jest krytyczne 20%: weryfikacja, testy, kontekst srodowiska.
```

---

# AI — pulapki (to bedzie na egzaminie z produkcji)

```
  ❌ Halucynacje         wymyslone moduly i parametry, ktore
                         nie istnieja (wygladaja wiarygodnie!)

  ❌ Przestarzale wzorce model uczony na starym kodzie:
                         stare nazwy modulow, skladnia sprzed lat

  ❌ Brak idempotencji   AI chetnie uzywa shell/command
                         zamiast wlasciwego modulu

  ❌ Sekrety w promptach NIGDY nie wklejaj hasel, kluczy,
                         danych klienta do chatu AI

  ❌ Slepe zaufanie      kod "wyglada dobrze" ≠ kod dziala
                         w TWOIM srodowisku
```

**Kazdy wygenerowany kod przechodzi TEN SAM proces:**
```bash
ansible-doc <modul>                        # 1. czy modul/parametry istnieja?
ansible-playbook pb.yml --syntax-check     # 2. skladnia
ansible-lint pb.yml                        # 3. dobre praktyki
ansible-playbook pb.yml --check --diff     # 4. symulacja
ansible-playbook pb.yml                    # 5. dopiero teraz na hosty testowe
```

---

# AI — jak pisac dobre prompty do kodu Ansible

**Slaby prompt:**
```
napisz playbook do apache
```

**Dobry prompt — kontekst + wymagania + ograniczenia:**
```
Napisz playbook Ansible:
- hosty: grupa webservers, Ubuntu 24.04, become: true
- zainstaluj apache2 (apt, update_cache)
- usluga uruchomiona i enabled
- strona /var/www/html/index.html z nazwa hosta (inventory_hostname)
- handler przeladowujacy apache po zmianie pliku
- uzywaj modulow (nie shell), kod ma byc idempotentny
```

**Zasady:**
- Podawaj wersje systemu i Ansible
- Wymagaj modulow zamiast shell i idempotencji
- Proś o wyjasnienie kodu — uczysz sie przy okazji
- Male kroki: jeden task/problem na raz, nie caly projekt

---

# LAB 1 — Warsztat (45 min)

```
Zadanie (katalog: szkolenie8x4/lab1/):

1. Zainstaluj Ansible w srodowisku venv
   $ python3 -m venv ~/venv-ansible
   $ source ~/venv-ansible/bin/activate
   $ pip install ansible
   $ ansible --version

2. Skonfiguruj inventory z hostami od prowadzacego
   Plik: inventory/hosts.yml

3. Przetestuj polaczenie i zbierz fakty
   $ ansible all -m ping
   $ ansible all -m setup -a "filter=ansible_distribution*"

4. Wykonaj zadania ad-hoc
   uptime, utworzenie katalogu z --become, stat

5. Uzupelnij i uruchom pierwszy playbook
   Plik: pierwszy_playbook.yml (miejsca oznaczone # TODO)
   $ ansible-playbook -i inventory/hosts.yml pierwszy_playbook.yml

6. Uruchom playbook DRUGI raz — sprawdz idempotencje (changed=0)
```

> Instrukcja krok po kroku: `lab1/README.md`
> Rozwiazanie: `lab1/pierwszy_playbook_odpowiedz.yml`

---

# Podsumowanie spotkania 1

```
Co juz umiemy:

  ✅ Krajobraz narzedzi: Ansible vs Puppet/Chef/Salt vs Terraform
  ✅ Architektura: control node, managed hosts, agentless, SSH
  ✅ Idempotentnosc — opisujemy STAN, nie kroki
  ✅ YAML: listy, slowniki, zagniezdzanie, pulapki
  ✅ Jinja2: {{ zmienne }} i filtry
  ✅ Komponenty: inventory, play, task, modul, zmienne, fakty
  ✅ VS Code + Copilot — korzysci i pulapki AI
  ✅ Lab: instalacja, inventory, ad-hoc, pierwszy playbook

Na spotkaniu 2:

  ● Sposoby instalacji Ansible (pip, pipx, pakiety, sandbox)
  ● Utrzymanie srodowiska przez lata (venv, wersjonowanie)
  ● Konfiguracja polaczen SSH i pelne inventory
  ● Wiecej ad-hoc i pierwsze wieksze playbooki
  ● Lab: struktury danych YAML + pierwsze kroki z Jinja2
```

---

# Pytania?

## Do zobaczenia na spotkaniu 2!

*Materialy szkoleniowe dostepne w repozytorium Git*
