# Automatyzacja z Ansible
### Szkolenie 8 spotkan x 4h · Spotkanie 8 (ostatnie)
## AWX/Tower i dobre praktyki

---

# Agenda spotkania 8 (4h)

| Czas        | Blok        | Temat                                              |
|-------------|-------------|----------------------------------------------------|
| 0:00 – 0:15 | Recap       | Powtorka spotkania 7                               |
| 0:15 – 1:00 | **Modul 1** | AWX/Tower: interfejs graficzny i model RBAC        |
| 1:00 – 1:30 | **Modul 2** | Lookupy                                            |
| 1:30 – 1:45 | ☕ Przerwa  |                                                    |
| 1:45 – 2:15 | **Modul 3** | Delegowanie zadan                                  |
| 2:15 – 2:40 | **Modul 4** | Powtarzanie i asynchronicznosc                     |
| 2:40 – 3:00 | **Modul 5** | Orkiestracja Windows — omowienie                   |
| 3:00 – 3:20 | **Lab 8**   | Lookupy, delegacja, retry (lokalnie)               |
| 3:20 – 4:00 | Konsultacje | Dyskusja, Q&A, podsumowanie szkolenia              |

---

# Recap spotkania 7

```
Co juz umiemy:

  ✅ Inventory: statyczne / dynamiczne (aws_ec2) / hybrydowe
  ✅ ansible-vault + wzorzec vars→vault_ (sekrety w repo)
  ✅ Sekrety zewnetrzne przez lookup
  ✅ Debugging: -vvv, debug, assert, changed_when/failed_when
  ✅ Check-mode i jego pulapki
  ✅ Wiele srodowisk: dev/test/QA/UAT/PROD

Dzis — ostatni krok: od CLI do PLATFORMY + dobre praktyki:

  ● AWX/Tower — Ansible z interfejsem web i RBAC dla zespolu
  ● Lookupy, delegowanie, powtarzanie — "ciekawostki" z praktyki
  ● Orkiestracja Windows
  ● Podsumowanie calego szkolenia
```

---

---
# MODUL 1
# AWX / Tower — interfejs graficzny
---

---

# Od CLI do platformy — po co AWX?

```
  ansible-playbook z terminala           AWX / Ansible Tower / AAP
  ──────────────────────────             ──────────────────────────
  dziala na TWOIM laptopie               centralny serwer (web UI + API)
  Twoje klucze, Twoj vault               poswiadczenia w jednym miejscu
  "u mnie zadzialalo"                    ten sam przebieg dla calego zespolu
  brak historii kto/co/kiedy             pelny audyt i logi z kazdego uruchomienia
  sekrety u kazdego lokalnie             RBAC — kto co moze uruchomic
  cron na czyims kompie                  wbudowany scheduler
```

```
  AWX  = darmowy, open-source (upstream)
  Ansible Automation Platform (AAP) / "Tower" = wersja komercyjna Red Hat
  Ten sam model pojec — róznica to wsparcie i dodatki enterprise.
```

> AWX to nadbudowa NAD Ansible — pod spodem to te same playbooki, role,
> inventory i vault, ktore piszemy przez cale szkolenie.

---

# Mala vs duza organizacja

```
  MALY ZESPOL (2-5 osob)              DUZA ORGANIZACJA (dziesiatki zespolow)
  ────────────────────────           ──────────────────────────────────────
  Ansible z CLI + Git                AWX/AAP obowiazkowo
  wspolny repo, code review          Organizacje i Teamy (RBAC)
  vault w repo                       centralne poswiadczenia + magazyn sekretow
  cron / CI do harmonogramu          scheduler + workflow + powiadomienia
                                     samoobsluga: dev odpala gotowe szablony
                                     bez dostepu do produkcyjnych sekretow
```

```
  Kiedy wchodzi AWX:
   - wielu ludzi uruchamia te same automatyzacje
   - trzeba ODDZIELIC "kto pisze kod" od "kto moze go uruchomic na prod"
   - audyt/compliance wymaga historii i kontroli dostepu
   - operatorzy (nie-programisci) maja klikac, nie pisac CLI
```

---

# Elementy AWX — slownik pojec

```
  ┌─────────────────────────────────────────────────────────────┐
  │  PROJECT       ← kod z Gita (Twoje repo z playbookami/rolami)│
  │  INVENTORY     ← hosty (statyczne lub dynamiczne, jak w CLI) │
  │  CREDENTIAL    ← klucze SSH, hasla, vault, tokeny chmury     │
  │  JOB TEMPLATE  ← "przycisk": playbook + inventory + creds    │
  │  SURVEY        ← formularz pytan (zmienne -e przez web)      │
  │  SCHEDULE      ← harmonogram (cron) dla job template         │
  │  WORKFLOW      ← graf laczacy wiele job templates            │
  └─────────────────────────────────────────────────────────────┘
```

```
  Job Template = to samo co:
    ansible-playbook -i INVENTORY site.yml --ask-vault-pass -e "..."
  ...ale jako klikalny przycisk z uprawnieniami, logiem i historia.

  Project synchronizuje sie z Gita → uruchamiasz ZAWSZE aktualny kod
  (nikt nie odpala "swojej lokalnej wersji").
```

---

# Model RBAC — kto co moze

```
  ORGANIZATION  (np. "Platforma", "Klient-X")
    │
    ├── TEAMS            (grupy uzytkownikow: sysadmini, deweloperzy)
    │     └── USERS
    │
    └── zasoby: Projects, Inventories, Credentials, Job Templates
          │
          └── ROLE nadawane na zasobie:
              Admin    — pelna kontrola nad zasobem
              Execute  — moze URUCHOMIC (ale nie edytowac)
              Read     — tylko podglad
              Use      — moze uzyc (np. credentiala w job template)
```

```
  Kluczowa wartosc RBAC — rozdzielenie odpowiedzialnosci:

  Deweloper:  Execute na "Deploy DEV", Read na PROD
  SysAdmin:   Admin wszedzie
  Operator:   Execute na wybranych szablonach, ZERO dostepu do sekretow
              (credential jest "Use", nie widzi hasla!)
```

> To odpowiedz na "jak dac ludziom uruchamiac automatyzacje,
> nie dajac im hasel do produkcji".

---

# AWX jako kod — automation-as-code

**Sam AWX tez konfiguruje sie... Ansiblem (kolekcja awx.awx):**

```yaml
- name: Skonfiguruj AWX
  hosts: localhost
  tasks:
    - name: Projekt z Gita
      awx.awx.project:
        name: "szkolenie_playbook"
        scm_type: git
        scm_url: "https://github.com/sirkubax/for_awx.git"
        scm_branch: main
        controller_host: "{{ awx_url }}"
        controller_oauthtoken: "{{ awx_token }}"

    - name: Job template (klikalny przycisk)
      awx.awx.job_template:
        name: "Deploy DEV"
        project: "szkolenie_playbook"
        playbook: "site.yml"
        inventory: "DEV"
        credentials: ["ssh-dev"]
        state: present
```

```
  Wzorzec z tego repo (playbooks/towerjob.yml): credential → project →
  job template, wszystko przez API. Konfiguracja platformy tez w Git.
```

> Uruchamianie kodu IaaC przez web (klik "Launch") lub API (CI woła AWX)
> — playbook jest ten sam, zmienia sie tylko SPOSOB uruchomienia.

---

---
# MODUL 2
# Lookupy
---

---

# Lookup — pobieranie danych Z ZEWNATRZ

```
  Lookup wykonuje sie NA CONTROL NODE (nie na hostach docelowych!)
  i wciaga dane do zmiennych/szablonow w czasie wykonania.

  {{ lookup('WTYCZKA', 'ARGUMENT') }}
```

**Najczestsze lookupy (statystyka z tego repo):**
```yaml
{{ lookup('env', 'HOME') }}                 # zmienna srodowiskowa
{{ lookup('file', '/etc/hostname') }}       # zawartosc pliku
{{ lookup('pipe', 'git rev-parse HEAD') }}  # STDOUT komendy lokalnej
{{ lookup('password', '/tmp/pass length=16 chars=ascii_letters') }}
{{ lookup('template', 'plik.j2') }}         # wyrenderowany szablon
{{ lookup('first_found', kandydaci) }}      # pierwszy istniejacy plik
```

```
  Kluczowa intuicja: lookup czyta ze srodowiska CONTROL NODE.
  lookup('file', ...) czyta plik na TWOIM laptopie/serwerze AWX,
  a NIE na hoscie zarzadzanym. (Do plikow zdalnych: slurp/fetch.)
```

---

# Lookupy w praktyce

```yaml
- name: Sekret ze zmiennej srodowiskowej (CI/CD)
  ansible.builtin.debug:
    msg: "Token: {{ lookup('env', 'API_TOKEN') }}"

- name: Wersja z Gita jako etykieta wdrozenia
  ansible.builtin.set_fact:
    wersja: "{{ lookup('pipe', 'git describe --tags --always') }}"

- name: Wybierz konfiguracje per srodowisko (first_found)
  ansible.builtin.template:
    src: "{{ lookup('first_found', opcje) }}"
    dest: /etc/app/config
  vars:
    opcje:
      - "config-{{ srodowisko }}.j2"     # config-prod.j2, jesli jest
      - "config-default.j2"              # inaczej domyslny
```

**Lookup vs query — dla petli uzyj query (zwraca liste):**
```yaml
- ansible.builtin.debug:
    msg: "{{ item }}"
  loop: "{{ query('lines', 'cat /etc/passwd') }}"   # query = list zawsze
```

```
  lookup(...)  → zwykle zwraca STRING (elementy sklejone)
  query(...)   → zwraca LISTE (do loop) — to samo, ale bez niespodzianek
```

---

---
# MODUL 3
# Delegowanie zadan
---

---

# delegate_to — wykonaj gdzie indziej

```
  Domyslnie task wykonuje sie NA HOSCIE z play.
  delegate_to mowi: "wykonaj to zadanie na INNYM hoscie",
  zachowujac kontekst (zmienne) hosta oryginalnego.
```

```yaml
- name: Wypnij hosta z load balancera PRZED aktualizacja
  ansible.builtin.command: "remove-from-lb {{ inventory_hostname }}"
  delegate_to: "{{ groups['loadbalancers'][0] }}"   # wykonaj NA LB...
                                                    # ...dla KAZDEGO app-hosta

- name: Dodaj wpis DNS dla nowego serwera
  ansible.builtin.command: "dns-add {{ inventory_hostname }} {{ ansible_host }}"
  delegate_to: dns01

- name: Zadanie lokalne (na control node)
  ansible.builtin.uri:
    url: "https://monitoring/api/silence/{{ inventory_hostname }}"
  delegate_to: localhost          # czeste: odpytaj API z control node
```

```
  Typowe zastosowania:
   - LB: wypnij/wepnij host podczas rolling update
   - DNS/monitoring: zarejestruj/wycisz host z poziomu innej maszyny
   - localhost: wywolania API, ktore maja isc z control node
```

---

# run_once i delegate_facts

**`run_once` — wykonaj RAZ dla calej grupy (nie per host):**
```yaml
- name: Migracja bazy — tylko raz, nie z kazdego app-hosta
  ansible.builtin.command: /opt/app/migrate.sh
  run_once: true
  delegate_to: "{{ groups['appservers'][0] }}"
```

**Zbieranie faktow z jednego hosta, uzycie na innym:**
```yaml
- name: Pobierz fakty z bazy
  ansible.builtin.setup:
  delegate_to: db01
  delegate_facts: true            # zapisz fakty JAKO db01 (nie biezacego)

- name: Uzyj adresu bazy na app-hostach
  ansible.builtin.debug:
    msg: "Baza: {{ hostvars['db01'].ansible_default_ipv4.address }}"
```

```
  local_action: skrot na delegate_to: localhost
  Wzorzec rolling update (lamp_haproxy w tym repo):
    serial + delegate_to LB = aktualizacja bez przerwy uslugi.
```

---

---
# MODUL 4
# Powtarzanie i asynchronicznosc
---

---

# until — powtarzaj az do skutku

```yaml
- name: Czekaj az aplikacja odpowie 200
  ansible.builtin.uri:
    url: "http://localhost:{{ app_port }}/health"
    status_code: 200
  register: wynik
  until: wynik.status == 200        # warunek sukcesu
  retries: 10                       # maks. prob
  delay: 5                          # odstep miedzy probami (s)
```

```
  Dziala: uruchom → sprawdz until → jesli falsz, czekaj delay, powtorz
          → az until=prawda LUB wyczerpiesz retries (wtedy failed).

  Typowe uzycia:
   - czekanie az usluga wstanie (health check)
   - czekanie na status w API chmury ("instance running")
   - ponawianie flaky operacji sieciowej
```

**Recap petli (spotkanie 4) — powtarzanie po DANYCH:**
```yaml
loop: "{{ lista }}"                 # powtorz task dla kazdego elementu
loop: "{{ slownik | dict2items }}"  # po slowniku
```

> Rozroznienie: `loop` = powtarzanie po DANYCH (znane z gory),
> `until` = powtarzanie az WARUNEK spelniony (nie wiesz ile prob).

---

# async — zadania dlugie i rownolegle

```yaml
- name: Dluga operacja bez blokowania (fire-and-forget lub polling)
  ansible.builtin.command: /opt/app/long_import.sh
  async: 600            # maks. czas dzialania (s)
  poll: 5               # co ile sprawdzac status (0 = nie czekaj)
  register: zadanie

- name: Rob cos innego w miedzyczasie...
  ansible.builtin.debug: { msg: "import leci w tle" }

- name: Poczekaj na zakonczenie asynchronicznego zadania
  ansible.builtin.async_status:
    jid: "{{ zadanie.ansible_job_id }}"
  register: status
  until: status.finished
  retries: 100
  delay: 6
```

```
  poll: 0  = odpal i NIE czekaj (fire-and-forget), sprawdzisz pozniej
  poll: >0 = czekaj, ale omijaj limit czasu SSH dla dlugich zadan

  Po co: reboot + czekanie, dlugie migracje, operacje >SSH timeout,
  rownolegle uruchomienie na wielu hostach bez blokowania.
```

---

---
# MODUL 5
# Orkiestracja Windows — omowienie
---

---

# Windows w Ansible — czym sie rozni

```
  LINUX                              WINDOWS
  ─────────────────                  ──────────────────────────────
  polaczenie: SSH                    polaczenie: WinRM (lub SSH od nowszych)
  moduly: ansible.builtin.*          moduly: ansible.windows.win_*,
  jezyk modulow: Python                     community.windows.*
  become: sudo                       become: runas
  sciezki: /etc/...                  sciezki: C:\...
  pakiety: apt/dnf                   pakiety: win_chocolatey, win_package
```

```
  Control node ZAWSZE Linux/macOS (Windows tylko jako host zarzadzany).
  Na hoscie Windows: WinRM wlaczony + PowerShell (nie potrzeba Pythona!).
```

**Konfiguracja polaczenia (inventory):**
```yaml
windows:
  hosts:
    win01:
      ansible_host: 10.0.0.50
  vars:
    ansible_connection: winrm
    ansible_user: Administrator
    ansible_password: "{{ vault_win_haslo }}"
    ansible_winrm_transport: ntlm
    ansible_port: 5986
```

---

# Moduly win_* — przyklady (wzorzec z repo)

```yaml
- hosts: windows
  gather_facts: no
  tasks:
    - name: Zainstaluj 7-Zip przez Chocolatey
      ansible.windows.win_chocolatey:
        name: 7zip
        state: present

    - name: Uruchom program
      ansible.windows.win_command: whoami.exe

    - name: Komendy PowerShell
      ansible.windows.win_shell: |
        New-Item -Path C:\temp -ItemType Directory -Force
        Get-Service -Name Spooler

    - name: Usluga Windows
      ansible.windows.win_service:
        name: Spooler
        state: started
        start_mode: auto

    - name: Uzytkownik lokalny
      ansible.windows.win_user:
        name: deploy
        password: "{{ vault_win_haslo }}"
        groups: [Users]
```

```
  Odpowiedniosci: win_copy, win_template, win_file, win_regedit,
  win_updates (Windows Update), win_feature (role serwera).
  Ta sama filozofia: idempotentne moduly, nie skrypty.
```

---

---
# PODSUMOWANIE SZKOLENIA
---

---

# Cala droga — 8 spotkan

```
  1. Wprowadzenie      YAML, Jinja, komponenty, AI
  2. Srodowisko        instalacja, inventory, ad-hoc, playbooki
  3. Operacje          pakiety, dyski, pliki (template/lineinfile)
  4. Logika            zmienne, precedence, when, loop, hostvars
  5. Role              struktura, Galaxy, FQCN
  6. Projekt           3-warstwowy stack w jednym przebiegu
  7. Produkcja         inventory dynamiczne, vault, debugging, srodowiska
  8. Platforma         AWX/RBAC, lookupy, delegacja, Windows
```

```
  Od "ansible all -m ping" (spotkanie 1)
  do kompletnego, skalowalnego, bezpiecznego wdrozenia
  zarzadzanego przez zespol przez interfejs web (spotkanie 8).
```

---

# Dobre praktyki — sciaga na produkcje

```
  ┌──────────────────────────────────────────────────────────┐
  │  ✅ Moduly (FQCN) zamiast shell/command                   │
  │  ✅ Idempotencja — opisuj STAN, nie kroki                 │
  │  ✅ --check --diff przed kazda zmiana na prod             │
  │  ✅ Sekrety w vault / magazynie zewnetrznym (nigdy w Git) │
  │  ✅ Role wielokrotnego uzytku + requirements.yml z wersja │
  │  ✅ Zmienne: najnizszy sensowny poziom, group_vars per env│
  │  ✅ ansible-lint + code review przed mergem               │
  │  ✅ Srodowisko jako kod (venv/EE, pinowane wersje)        │
  │  ✅ AWX/RBAC gdy uruchamia wiele osob                     │
  │                                                          │
  │  ❌ hasla/IP na sztywno   ❌ ignore_errors masowo         │
  │  ❌ kopie playbookow per env   ❌ sekrety w logach        │
  └──────────────────────────────────────────────────────────┘
```

---

# Co dalej — kierunki rozwoju

| Temat                    | Narzedzie / kierunek                    |
|--------------------------|-----------------------------------------|
| Testowanie rol           | Molecule + pytest                       |
| Jakosc kodu              | ansible-lint, yamllint w CI             |
| CI/CD                    | GitHub Actions / GitLab CI → AWX        |
| Platforma zespolowa      | AWX / Ansible Automation Platform       |
| Automatyzacja reaktywna  | Event-Driven Ansible (rulebooks)        |
| Chmura na powaznie       | amazon.aws, azure, Terraform + Ansible  |
| Sieci                    | moduly network (cisco, arista, juniper) |
| Windows na skale         | ansible.windows, WinRM/Kerberos         |

```
  Dokumentacja:  docs.ansible.com · galaxy.ansible.com · forum.ansible.com
```

---

# LAB 8 — Warsztat (20 min)

```
Zadanie (katalog: szkolenie8x4/lab8/):
Lab dziala LOKALNIE (localhost). "Ciekawostki" w akcji.

Czesc A — lookupy:
  1. lookupy.yml (# TODO): env, pipe, file, password, first_found
  2. Zwroc uwage: lookup czyta z CONTROL NODE

Czesc B — delegacja i powtarzanie:
  3. delegacja.yml (# TODO): delegate_to localhost, run_once
  4. until/retries/delay — poczekaj az powstanie plik-znacznik

Czesc C — czytanie (bez uruchamiania):
  5. awx_jako_kod.PRZYKLAD.yml — job template jako kod (awx.awx)
  6. windows.PRZYKLAD.yml — moduly win_* i polaczenie WinRM
     Cwiczenie: zmapuj swoj playbook z projektu 6 na pojecia AWX
     (project / inventory / credential / job template)
```

> Instrukcja: `lab8/README.md` · Rozwiazania: `*_odpowiedz`

---

# Konsultacje

```
  Czas na Wasze tematy:

   ● problemy z Waszych realnych projektow
   ● przypadki brzegowe, ktore Was blokuja
   ● przeglad architektury / code review na zywo
   ● pytania o integracje (chmura, sieci, Windows, CI/CD)
   ● "jak zrobic X w naszym srodowisku?"

  To Wasz czas — pytajcie o wszystko.
```

---

# Dziekujemy!

## To koniec szkolenia — gratulacje!

```
  Przeszliscie droge od podstaw YAML
  do kompletnych, produkcyjnych wdrozen zarzadzanych przez AWX.

  Automatyzujcie madrze. Testujcie przed produkcja.
  Trzymajcie sekrety w vault. I nie piszcie shell tam,
  gdzie jest modul. :)
```

*Materialy szkoleniowe dostepne w repozytorium Git*
*docs.ansible.com · galaxy.ansible.com · forum.ansible.com*
