# Automatyzacja z Ansible
### Szkolenie 8 spotkan x 4h · Spotkanie 2
## Przygotowanie srodowiska i pierwsze playbooki

---

# Agenda spotkania 2 (4h)

| Czas        | Blok        | Temat                                              |
|-------------|-------------|----------------------------------------------------|
| 0:00 – 0:15 | Recap       | Powtorka spotkania 1, pytania                      |
| 0:15 – 0:50 | **Modul 1** | Sposoby instalacji Ansible                         |
| 0:50 – 1:20 | **Modul 2** | Sandbox i utrzymanie srodowiska przez lata         |
| 1:20 – 1:50 | **Modul 3** | Konfiguracja polaczenia do serwerow (SSH)          |
| 1:50 – 2:05 | ☕ Przerwa  |                                                    |
| 2:05 – 2:35 | **Modul 4** | Inventory w praktyce                               |
| 2:35 – 2:55 | **Modul 5** | Ad-hoc commands w praktyce                         |
| 2:55 – 3:15 | **Modul 6** | Pierwsze playbooki — uruchamianie i diagnostyka    |
| 3:15 – 4:00 | **Lab 2**   | Struktury danych YAML, pierwsze kroki z Jinja      |

---

# Recap spotkania 1

```
Co juz umiemy:

  ✅ Ansible vs Terraform — konfiguracja vs provisioning
  ✅ Architektura: control node, managed hosts, agentless
  ✅ Idempotentnosc — opisujemy STAN, nie kroki
  ✅ YAML: listy, slowniki, zagniezdzanie
  ✅ Jinja2: {{ zmienne }} i filtry
  ✅ Lab: instalacja, inventory, ping, pierwszy playbook

Dzis:

  ● Instalacja Ansible — wszystkie warianty i ktory wybrac
  ● Srodowisko, ktore przezyje lata (venv, pinowanie wersji, EE)
  ● Polaczenia SSH: klucze, become, ansible.cfg
  ● Inventory na powaznie: grupy, group_vars, patterns
  ● Ad-hoc i playbooki — wiecej praktyki
  ● Lab: struktury danych YAML + Jinja
```

---

---
# MODUL 1
# Sposoby instalacji Ansible
---

---

# ansible vs ansible-core — co wlasciwie instalujesz

```
  ┌───────────────────────────────────────────────────┐
  │              pakiet "ansible"                     │
  │   (community bundle — duzy, wygodny)              │
  │                                                   │
  │   ┌───────────────────────────────┐               │
  │   │       ansible-core            │               │
  │   │  silnik + ~70 modulow bazowych│               │
  │   │  (ansible.builtin)            │               │
  │   └───────────────────────────────┘               │
  │                                                   │
  │   + ~100 kolekcji community:                      │
  │     community.general, amazon.aws,                │
  │     ansible.posix, community.mysql, ...           │
  └───────────────────────────────────────────────────┘
```

| Pakiet         | Rozmiar | Kiedy wybrac                                  |
|----------------|---------|-----------------------------------------------|
| `ansible-core` | maly    | produkcja — doinstalujesz TYLKO potrzebne kolekcje |
| `ansible`      | duzy    | nauka, szybki start — wszystko od razu        |

---

# Warianty instalacji — przeglad

| Metoda            | Komenda                              | Zalety / Wady               |
|-------------------|--------------------------------------|------------------------------|
| **pip + venv**    | `pip install ansible`                | ✅ dowolna wersja, izolacja / wymaga aktywacji |
| pipx              | `pipx install --include-deps ansible`| ✅ izolacja, globalnie dostepny / jedna wersja na usera |
| Pakiet systemowy  | `apt/dnf install ansible`            | ✅ proste / ❌ czesto stara wersja, zalezna od OS |
| Kontener (EE)     | `ansible-navigator` + obraz          | ✅ pelna powtarzalnosc / wymaga podmana/dockera |

```
  Rekomendacja na tym szkoleniu (i w wiekszosci projektow):

     python3 -m venv + pip install
     — pelna kontrola nad wersja, izolacja per projekt
```

> Ansible instalujesz TYLKO na control node.
> Na zarzadzanych hostach wystarczy SSH + Python.

---

# Instalacja pip + venv — krok po kroku

```bash
# 1. Srodowisko wirtualne (izolowany Python)
python3 -m venv ~/venv-ansible

# 2. Aktywacja (w kazdym nowym terminalu!)
source ~/venv-ansible/bin/activate

# 3. Instalacja
pip install --upgrade pip
pip install ansible            # albo: pip install ansible-core

# 4. Weryfikacja
ansible --version
which ansible                  # → ~/venv-ansible/bin/ansible
```

**Konkretna wersja (o tym wiecej za chwile):**
```bash
pip install 'ansible-core==2.17.*'
pip install 'ansible==10.*'
```

**Dezaktywacja / usuniecie:**
```bash
deactivate                     # wyjscie z venv
rm -rf ~/venv-ansible          # "odinstalowanie" — po prostu skasuj katalog
```

---

# Wersjonowanie — jak czytac numery

```
  ansible 10.x  ──zawiera──►  ansible-core 2.17
  ansible 9.x   ──zawiera──►  ansible-core 2.16
  ansible 8.x   ──zawiera──►  ansible-core 2.15
```

**Sprawdz co masz:**
```bash
ansible --version
# ansible [core 2.17.x]        ← wersja SILNIKA (najwazniejsza)
#   python version = 3.12.x    ← wersja Pythona control node

ansible-galaxy collection list # wersje zainstalowanych kolekcji
```

**Dlaczego to wazne:**
- Kazda wersja core wspiera okreslone wersje Pythona
- Kolekcje deklaruja minimalna wersje core
- Playbook pisany pod 2.9 moze nie dzialac na 2.17 (i odwrotnie)

> Zawsze zapisuj w repo, na jakiej wersji projekt byl testowany.

---

---
# MODUL 2
# Sandbox i utrzymanie srodowiska przez lata
---

---

# Problem: "playbook z 2022 nie dziala w 2026"

```
  Co sie psuje z czasem:

  ┌──────────────────────────────────────────────────────┐
  │  moduly zmieniaja parametry     (deprecation → usuniecie) │
  │  moduly przenosza sie do kolekcji  (yum → ansible.builtin.dnf) │
  │  nowy Python na control node    (stary core nie wspiera)  │
  │  kolekcja zmienia zachowanie    (major version bump)   │
  │  apt upgrade podmienia ansible  (systemowy pakiet!)    │
  └──────────────────────────────────────────────────────┘

  Skutek: kod NIE ZMIENIONY od 2 lat nagle przestaje dzialac,
          bo zmienilo sie SRODOWISKO wokol niego.
```

**Rozwiazanie: srodowisko tez traktujemy jak kod.**
Wersje Ansible, kolekcji i Pythona sa czescia projektu — zapisane,
pinowane i odtwarzalne.

---

# Sandbox per projekt — venv + pinowane wersje

```
moj_projekt/
├── requirements.txt        ← wersje pakietow Pythona
├── requirements.yml        ← wersje kolekcji Ansible
├── source_me.sh            ← aktywacja srodowiska jedna komenda
├── inventory/
└── playbooks/
```

**`requirements.txt` — pinujemy dokladnie:**
```
ansible-core==2.17.7
jmespath==1.0.1
netaddr==1.3.0
```

**`requirements.yml` — kolekcje tez maja wersje:**
```yaml
collections:
  - name: community.general
    version: ">=9.0.0,<10.0.0"
  - name: amazon.aws
    version: "8.2.1"
```

**Odtworzenie srodowiska na NOWEJ maszynie = 3 komendy:**
```bash
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml
```

---

# source_me.sh — jedna komenda i pracujesz

**Wzorzec z zycia — plik w katalogu projektu:**

```bash
#!/bin/bash
# source_me.sh — przygotowanie srodowiska projektu
# Uzycie:  source ./source_me.sh

source ./venv/bin/activate

export ANSIBLE_CONFIG=./ansible.cfg
export ANSIBLE_INVENTORY=./inventory/

echo "Srodowisko gotowe: $(ansible --version | head -1)"
```

```bash
$ source ./source_me.sh
Srodowisko gotowe: ansible [core 2.17.7]
```

**Zasady utrzymania przez lata:**
```
  ✅ venv NIE trafia do gita (.gitignore) — trafiaja requirements
  ✅ aktualizacja wersji = osobny commit + testy (--check na dev)
  ✅ czytaj changelog/porting guide przed podbiciem core
  ✅ ansible-lint wylapie deprecated skladnie ZANIM przestanie dzialac
```

---

# Poziom wyzej: Execution Environments (kontenery)

```
  venv:                          Execution Environment:
  ────────────────────           ────────────────────────────
  izoluje pakiety Pythona        izoluje WSZYSTKO:
                                 ┌─────────────────────────┐
  ale wciaz zalezy od:           │  kontener (podman/docker)│
  - wersji Pythona w OS          │  ├── Python 3.x          │
  - bibliotek systemowych        │  ├── ansible-core 2.17   │
  - narzedzi (sshpass, git)      │  ├── kolekcje            │
                                 │  └── zaleznosci systemowe│
                                 └─────────────────────────┘
```

**Narzedzia:**
```bash
ansible-builder build -t moje-ee:1.0   # buduje obraz EE z definicji
ansible-navigator run site.yml \
  --execution-environment-image moje-ee:1.0
```

> Ten sam obraz EE dziala u Ciebie, u kolegi i w AWX/AAP (spotkanie 8).
> To odpowiedz na pytanie "jak utrzymac srodowisko przez 5 lat":
> obraz z 2024 uruchomisz identycznie w 2029.

---

---
# MODUL 3
# Konfiguracja polaczenia do serwerow
---

---

# SSH — fundament polaczenia

```
  control node                        managed host
  ────────────                        ────────────
  klucz prywatny   ──── SSH ────►     klucz publiczny
  ~/.ssh/id_ed25519                   ~/.ssh/authorized_keys
```

**Przygotowanie kluczy:**
```bash
# 1. Wygeneruj pare kluczy (jesli nie masz)
ssh-keygen -t ed25519 -C "ansible@szkolenie"

# 2. Wgraj klucz publiczny na hosta
ssh-copy-id -i ~/.ssh/id_ed25519.pub ubuntu@192.168.1.10

# 3. Test — logowanie BEZ hasla
ssh ubuntu@192.168.1.10 hostname
```

**Zasada:** jesli dziala `ssh user@host` — zadziala i Ansible.
Jesli nie dziala SSH — zaden playbook nie pomoze.

> Klucz z haslem (passphrase)? Uzyj `ssh-agent`:
> ```bash
> eval $(ssh-agent) && ssh-add ~/.ssh/id_ed25519
> ```

---

# Zmienne polaczenia w inventory

```yaml
all:
  vars:
    ansible_user: ubuntu                         # jako kto sie logujemy
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519
  children:
    webservers:
      hosts:
        web01:
          ansible_host: 192.168.1.10             # rzeczywisty adres
          ansible_port: 22                       # niestandardowy port SSH
        stary-serwer:
          ansible_host: 10.0.0.5
          ansible_user: root                     # nadpisanie per host
          ansible_python_interpreter: /usr/bin/python3.6
```

**Najwazniejsze zmienne polaczenia:**

| Zmienna                         | Znaczenie                        |
|---------------------------------|----------------------------------|
| `ansible_host`                  | adres IP/FQDN (gdy nazwa != adres) |
| `ansible_user`                  | uzytkownik SSH                   |
| `ansible_port`                  | port SSH (domyslnie 22)          |
| `ansible_ssh_private_key_file`  | klucz prywatny                   |
| `ansible_connection`            | ssh / local / winrm / docker     |
| `ansible_python_interpreter`    | sciezka Pythona na hoscie        |

---

# become — eskalacja uprawnien (sudo)

**Logujemy sie jako zwykly user, ale zadania wymagaja roota:**

```yaml
- name: Instalacja pakietow wymaga roota
  hosts: webservers
  become: true                  # caly play przez sudo
  tasks:
    - name: Zainstaluj nginx
      package:
        name: nginx
```

```yaml
    - name: Tylko ten task przez sudo
      package:
        name: htop
      become: true              # become mozna wlaczyc per task

    - name: Wykonaj jako uzytkownik aplikacji
      command: whoami
      become: true
      become_user: appuser      # sudo do INNEGO usera niz root
```

**Z linii komend:**
```bash
ansible all -m package -a "name=htop state=present" --become
ansible all -m command -a "whoami" --become -K   # -K pyta o haslo sudo
```

---

# ansible.cfg — konfiguracja projektu

```ini
[defaults]
inventory          = ./inventory/hosts.yml
remote_user        = ubuntu
private_key_file   = ~/.ssh/id_ed25519
host_key_checking  = False        ; wygodne w labie — patrz nizej!
forks              = 10           ; ile hostow rownolegle
gathering          = smart        ; fakty: zbieraj raz, potem cache
interpreter_python = auto_silent

[privilege_escalation]
become         = False
become_method  = sudo

[ssh_connection]
pipelining     = True             ; szybsze wykonanie modulow
```

**Kolejnosc szukania konfiguracji (pierwszy wygrywa):**
```
  1. $ANSIBLE_CONFIG          (zmienna srodowiskowa)
  2. ./ansible.cfg            (katalog biezacy — standard w projektach)
  3. ~/.ansible.cfg           (katalog domowy)
  4. /etc/ansible/ansible.cfg (systemowy)
```

> `host_key_checking = False` przyspiesza w labie, ale na produkcji
> oznacza brak weryfikacji tozsamosci hosta. Lepiej: wgraj known_hosts.

---

# Diagnostyka polaczen

```
  UNREACHABLE  =  problem z POLACZENIEM (SSH, siec, DNS, klucz)
  FAILED       =  polaczenie OK, ale ZADANIE sie nie powiodlo
```

**Narzedzia diagnostyczne:**
```bash
# Ping przez Ansible (nie ICMP! — to test SSH + Pythona)
ansible web01 -m ping

# Szczegolowe logi polaczenia — kazde -v to wiecej detali
ansible web01 -m ping -vvv

# Test czystym SSH (z pominieciem Ansible)
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.1.10 echo OK
```

**Najczestsze przyczyny UNREACHABLE:**
```
  ❌ zly adres / firewall           → sprawdz: ssh user@host
  ❌ zly uzytkownik                 → sprawdz: ansible_user
  ❌ klucz nie wgrany na hosta      → sprawdz: ssh-copy-id
  ❌ host key niezaufany            → sprawdz: known_hosts / cfg
  ❌ brak Pythona na hoscie         → modul raw dziala bez Pythona
```

---

---
# MODUL 4
# Inventory w praktyce
---

---

# Grupy i hierarchia — projektowanie inventory

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

**Host moze byc w WIELU grupach naraz:**

```yaml
webservers:        # grupa po ROLI (co robi)
  hosts:
    web01:
produkcja:         # grupa po SRODOWISKU (gdzie stoi)
  children:
    webservers:
frankfurt:         # grupa po LOKALIZACJI
  hosts:
    web01:
```

> Dobre inventory odzwierciedla, JAK MYSLISZ o infrastrukturze:
> role, srodowiska, lokalizacje. Grupy nic nie kosztuja — uzywaj ich.

---

# group_vars i host_vars — zmienne przy inventory

```
inventory/
├── hosts.yml
├── group_vars/
│   ├── all.yml            ← wspolne dla wszystkich
│   ├── webservers.yml     ← dla grupy webservers
│   └── produkcja.yml      ← dla srodowiska
└── host_vars/
    └── web01.yml          ← nadpisania dla jednego hosta
```

**`group_vars/webservers.yml`:**
```yaml
app_port: 80
app_log_level: warning
```

**`host_vars/web01.yml`** (wygrywa z grupa):
```yaml
app_port: 8080
app_log_level: debug
```

```
  Zasada: bardziej szczegolowe nadpisuje ogolne
  all  →  grupa  →  host        (host wygrywa)
```

> Katalogi `group_vars/` i `host_vars/` Ansible laduje AUTOMATYCZNIE —
> wystarczy, ze leza obok pliku inventory.

---

# Patterns — celowanie w hosty

```bash
ansible all -m ping                       # wszyscy
ansible webservers -m ping                # grupa
ansible web01 -m ping                     # jeden host
ansible 'webservers:databases' -m ping    # suma grup (LUB)
ansible 'webservers:&produkcja' -m ping   # przeciecie (I) — web + prod
ansible 'produkcja:!databases' -m ping    # wykluczenie (BEZ)
ansible 'web*' -m ping                    # wildcard
```

**`--limit` — zawezanie w playbookach:**
```bash
# Playbook celuje w webservers, ale wykonaj tylko na web01
ansible-playbook site.yml --limit web01

# Wszystko oprocz jednego, chorego hosta
ansible-playbook site.yml --limit '!web02'
```

**Weryfikacja inventory:**
```bash
ansible-inventory --graph                 # drzewo grup
ansible-inventory --list                  # pelny JSON ze zmiennymi
ansible-inventory --host web01            # zmienne jednego hosta
ansible webservers --list-hosts           # kogo trafi pattern
```

---

# Inventory jako katalog — wiele plikow

**Zamiast jednego pliku — katalog laczacy zrodla:**

```
inventory/
├── 01-static.yml         ← hosty wpisane recznie
├── 02-aws_ec2.yml        ← dynamiczne z AWS (spotkanie 7)
├── group_vars/
└── host_vars/
```

```bash
ansible-playbook -i inventory/ site.yml    # -i wskazuje KATALOG
```

**Osobne inventory per srodowisko — czesty wzorzec:**

```
inventories/
├── dev/
│   ├── hosts.yml
│   └── group_vars/
└── prod/
    ├── hosts.yml
    └── group_vars/
```

```bash
ansible-playbook -i inventories/dev/  site.yml   # to samo wdrozenie...
ansible-playbook -i inventories/prod/ site.yml   # ...inne srodowisko
```

> Ten wzorzec rozwiniemy na spotkaniu 7 (dev/test/QA/UAT/PROD).

---

---
# MODUL 5
# Ad-hoc commands w praktyce
---

---

# Ad-hoc — skladnia i opcje

```
ansible  <PATTERN>  -m <MODULE>  -a "<ARGUMENTS>"  [opcje]
```

| Opcja          | Znaczenie                                    |
|----------------|----------------------------------------------|
| `-m MODULE`    | modul do uzycia (domyslnie: `command`)       |
| `-a "ARGS"`    | argumenty modulu                             |
| `-i PLIK/KATALOG` | inventory                                 |
| `--become` / `-b` | wykonaj przez sudo                        |
| `-K`           | zapytaj o haslo sudo                         |
| `-f 20`        | rownoleglosc (forks) — domyslnie 5           |
| `--limit web01`| zawez do hosta/grupy                         |
| `-o`           | wynik w jednej linii per host (czytelne logi)|
| `-vvv`         | diagnostyka                                  |

```bash
# Przyklad: szybki przeglad calej farmy, 20 hostow naraz
ansible all -m command -a "uptime" -f 20 -o
```

---

# command vs shell vs raw

| Modul     | Co robi                                | Kiedy uzyc            |
|-----------|----------------------------------------|-----------------------|
| `command` | uruchamia program BEZ shella           | domyslny wybor        |
| `shell`   | uruchamia przez `/bin/sh`              | gdy trzeba: `|`, `>`, `$VAR`, `*` |
| `raw`     | goly SSH, bez Pythona                  | bootstrap: instalacja Pythona |

```bash
# command NIE zrozumie pipe:
ansible all -m command -a "ps aux | grep nginx"     # ❌ blad!

# shell — tak:
ansible all -m shell -a "ps aux | grep nginx"       # ✅

# raw — na hoscie bez Pythona:
ansible nowy-host -m raw -a "apt install -y python3" --become
```

```
  Pamietaj: command/shell/raw NIE SA idempotentne.
  Ansible nie wie, co robi Twoja komenda — zawsze zglosi "changed".
  Do zadan konfiguracyjnych — uzywaj wlasciwych modulow.
```

---

# Ad-hoc — przydatny niezbednik

```bash
# Zbierz fakty
ansible all -m setup -a "filter=ansible_distribution*"

# Zarzadzanie pakietami
ansible all -m package -a "name=htop state=present" --become

# Uslugi
ansible webservers -m service -a "name=nginx state=restarted" --become

# Pliki i katalogi
ansible all -m file -a "path=/opt/app state=directory mode=0755" --become
ansible all -m copy -a "src=motd dest=/etc/motd" --become

# Pobierz plik Z hostow (np. logi do analizy)
ansible web01 -m fetch -a "src=/var/log/nginx/error.log dest=./logi/"

# Uzytkownicy
ansible all -m user -a "name=deploy state=present" --become

# Restart hostow (z czekaniem az wstana)
ansible webservers -m reboot --become
```

```
  ad-hoc:    diagnoza, jednorazowe akcje, szybkie sprawdzenia
  playbook:  wszystko, co ma byc powtarzalne i w repozytorium
```

---

---
# MODUL 6
# Pierwsze playbooki — uruchamianie i diagnostyka
---

---

# Playbook — od ad-hoc do kodu

**Te same operacje co ad-hoc — ale zapisane, powtarzalne, w Git:**

```yaml
---
- name: Przygotowanie serwerow www          # play 1
  hosts: webservers
  become: true
  tasks:
    - name: Zainstaluj nginx
      package:
        name: nginx
        state: present

    - name: Uruchom nginx
      service:
        name: nginx
        state: started
        enabled: true

- name: Przygotowanie baz danych            # play 2 — inny zbior hostow
  hosts: databases
  become: true
  tasks:
    - name: Zainstaluj postgresql
      package:
        name: postgresql
        state: present
```

> Jeden plik moze zawierac WIELE play — kazdy dla innych hostow.
> Wykonuja sie po kolei, z gory na dol.

---

# Czytanie wyniku — PLAY RECAP

```
PLAY RECAP ─────────────────────────────────────────────────
web01 : ok=5  changed=2  unreachable=0  failed=0  skipped=1
web02 : ok=5  changed=0  unreachable=0  failed=0  skipped=1
```

| Licznik       | Znaczenie                                        |
|---------------|--------------------------------------------------|
| `ok`          | task wykonany (w tym: bez zmian)                 |
| `changed`     | task COS ZMIENIL na hoscie                       |
| `unreachable` | nie udalo sie polaczyc (SSH)                     |
| `failed`      | task zakonczyl sie bledem                        |
| `skipped`     | pominiety (np. warunek `when` niespelniony)      |

```
  Interpretacja:
  web01: changed=2  → playbook COS poprawil (pierwsze uruchomienie?)
  web02: changed=0  → stan zgodny z opisem — nic do roboty
                      (tak wyglada idempotencja)
  failed>0 lub unreachable>0 → zatrzymaj sie i przeanalizuj
```

---

# Zanim uruchomisz "na ostro" — tryby testowe

```bash
# 1. Skladnia (bez laczenia z hostami)
ansible-playbook site.yml --syntax-check

# 2. Ktore taski sie wykonaja?
ansible-playbook site.yml --list-tasks
ansible-playbook site.yml --list-hosts

# 3. Symulacja — co by sie zmienilo (bez zmian!)
ansible-playbook site.yml --check

# 4. Symulacja + roznice w plikach
ansible-playbook site.yml --check --diff

# 5. Wykonanie z podgladem zmian
ansible-playbook site.yml --diff

# 6. Diagnoza problemow
ansible-playbook site.yml -v      # wyniki taskow
ansible-playbook site.yml -vvv    # + szczegoly polaczen
```

```
  Nawyk profesjonalisty:
  --syntax-check  →  --check --diff  →  wykonanie
```

---

# register + debug — zagladanie do srodka

**`register` zapisuje wynik taska do zmiennej:**

```yaml
- name: Sprawdz wersje jadra
  command: uname -r
  register: kernel                # ← wynik laduje w zmiennej
  changed_when: false             # odczyt to nie zmiana

- name: Pokaz wynik
  debug:
    msg: "Host {{ inventory_hostname }} ma jadro {{ kernel.stdout }}"

- name: Pokaz CALA strukture (do nauki!)
  debug:
    var: kernel
```

**Co siedzi w zarejestrowanej zmiennej:**
```yaml
kernel:
  stdout: "6.8.0-124-generic"     # standardowe wyjscie
  stderr: ""                      # bledy
  rc: 0                           # kod powrotu (0 = sukces)
  changed: false
```

> `debug` + `register` to Twoje `print()` w Ansible —
> bedziemy z nich korzystac w kazdym labie.

---

# Dobre nawyki od pierwszego playbooka

```
  ✅ name na KAZDYM tasku          czytelny log wykonania
  ✅ moduly zamiast shell/command  idempotencja za darmo
  ✅ --check --diff przed kazda    zero niespodzianek
     zmiana na hostach
  ✅ jeden playbook = jeden cel    "site.yml robi wszystko" przyjdzie
                                   pozniej — z rolami (spotkanie 5)
  ✅ playbook w Git od 1. linii    historia zmian, code review

  ❌ hasla/IP na sztywno w kodzie  zmienne + vault (spotkanie 7)
  ❌ ignore_errors: true wszedzie  ukrywa problemy zamiast rozwiazywac
```

---

# LAB 2 — Warsztat (45 min)

```
Zadanie (katalog: szkolenie8x4/lab2/):

Lab wykonujemy LOKALNIE (hosts: localhost) — bez zdalnych hostow.
Cwiczymy jezyk: struktury danych YAML i wyrazenia Jinja2.

1. Przeanalizuj plik dane.yml
   — znajdz: listy, slowniki, liste slownikow, slownik slownikow

2. Uzupelnij struktury_danych.yml (miejsca # TODO)
   — wyswietl wybrane elementy struktur przez debug
   $ ansible-playbook struktury_danych.yml

3. Uzupelnij jinja_filtry.yml (miejsca # TODO)
   — default, join, length, map, selectattr
   $ ansible-playbook jinja_filtry.yml

4. Uzupelnij szablon templates/raport.txt.j2
   — petla {% for %} po uzytkownikach i srodowiskach
   $ ansible-playbook generuj_raport.yml
   $ cat /tmp/szkolenie8x4/raport.txt
```

> Instrukcja krok po kroku: `lab2/README.md`
> Rozwiazania: pliki `*_odpowiedz.yml`

---

# Podsumowanie spotkania 2

```
Co juz umiemy:

  ✅ Instalacja: pip+venv / pipx / pakiet / kontener (EE)
  ✅ ansible vs ansible-core, wersjonowanie
  ✅ Sandbox: requirements.txt + requirements.yml + source_me.sh
  ✅ SSH: klucze, ssh-copy-id, zmienne ansible_*, become
  ✅ ansible.cfg i kolejnosc konfiguracji
  ✅ Inventory: grupy, group_vars/host_vars, patterns, --limit
  ✅ Ad-hoc: command vs shell vs raw, opcje -f -o -K
  ✅ Playbooki: PLAY RECAP, tryby testowe, register + debug
  ✅ Lab: struktury danych YAML + filtry i petle Jinja2

Na spotkaniu 3 — operacje na systemach:

  ● Pakiety: apt, dnf, package — instalacja i aktualizacje
  ● Partycjonowanie: parted, filesystem, mount, LVM
  ● Pliki konfiguracyjne: template, lineinfile, blockinfile
  ● Kopiowanie: copy, synchronize, fetch
  ● Lab: typowe operacje administracyjne na Linuksie
```

---

# Pytania?

## Do zobaczenia na spotkaniu 3!

*Materialy szkoleniowe dostepne w repozytorium Git*
