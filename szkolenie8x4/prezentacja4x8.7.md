# Automatyzacja z Ansible
### Szkolenie 8 spotkan x 4h · Spotkanie 7
## Inventory, sekrety i debugging

---

# Agenda spotkania 7 (4h)

| Czas        | Blok        | Temat                                              |
|-------------|-------------|----------------------------------------------------|
| 0:00 – 0:15 | Recap       | Powtorka spotkania 6, pytania                      |
| 0:15 – 0:55 | **Modul 1** | Inventory: statyczne, dynamiczne, hybrydowe        |
| 0:55 – 1:25 | **Modul 2** | Uklad inventory i podzial na podfoldery            |
| 1:25 – 1:40 | ☕ Przerwa  |                                                    |
| 1:40 – 2:25 | **Modul 3** | Sekrety: ansible-vault i systemy zewnetrzne        |
| 2:25 – 3:05 | **Modul 4** | Debugging i check-mode                             |
| 3:05 – 3:25 | **Modul 5** | Wiele srodowisk: dev/test/QA/UAT/PROD              |
| 3:25 – 4:00 | **Lab 7**   | Inventory hybrydowe, vault, debugging bledow       |

---

# Recap spotkania 6

```
Co osiagnelismy:

  ✅ Architektura 3-warstwowa: LB → app → baza
  ✅ site.yml: 3 play, jedno uruchomienie stawia cale srodowisko
  ✅ Spiecie warstw przez hostvars + groups
  ✅ Rola z Galaxy (mysql) + role wlasne (aplikacja, loadbalancer)

  ⚠ Zostawilismy DLUG: db_haslo lezy jawnym tekstem w group_vars!

Dzis domykamy produkcyjne braki:

  ● Inventory na serio: dynamiczne (chmura) i hybrydowe
  ● Sekrety: db_haslo z projektu 6 → do ansible-vault
  ● Debugging: jak szybko znalezc przyczyne bledu
  ● Wiele srodowisk i gdzie trzymac zmienne
```

---

---
# MODUL 1
# Inventory: statyczne, dynamiczne, hybrydowe
---

---

# Trzy rodzaje inventory

```
  STATYCZNE                DYNAMICZNE               HYBRYDOWE
  ─────────────            ──────────────           ──────────────
  plik(i) YAML/INI         wtyczka odpytuje         katalog laczacy
  reczna edycja            zrodlo w czasie          oba zrodla naraz
                           uruchomienia
  hosts.yml                aws_ec2, azure_rm,       inventory/
  ├─ web01                 gcp_compute, vmware,     ├─ 01-static.yml
  └─ db01                  netbox, k8s...           └─ 02-aws_ec2.yml

  ✅ proste, wersjonowane   ✅ zawsze aktualne        ✅ chmura + maszyny
  ❌ recznie utrzymywane    ❌ zalezne od API         spoza chmury razem
     (dryf: kod != rzecz.)     i uprawnien
```

```
  Regula: hosty, ktore SAM tworzysz (chmura) → dynamicznie.
          Hosty stale/spoza chmury (on-prem, sprzet) → statycznie.
          Realny projekt czesto ma OBA → hybryda (katalog).
```

---

# Dynamiczne inventory — wtyczka aws_ec2

**`inventory/aws_ec2.yml` (wzorzec z tego repo):**
```yaml
plugin: amazon.aws.aws_ec2
regions:
  - eu-west-2
filters:
  tag:Environment: prod            # tylko hosty z tagiem Environment=prod
  instance-state-name: running
keyed_groups:
  - prefix: tag                    # grupy z TAGOW: tag_Role_apache...
    key: tags
  - prefix: instance_type          # grupy z typu: instance_type_t3_micro
    key: instance_type
hostnames:
  - private-ip-address
```

```bash
# Uzycie: -i wskazuje PLIK KONFIGURACJI wtyczki (konczy sie na aws_ec2.yml)
ansible-inventory -i inventory/aws_ec2.yml --graph
ansible-playbook  -i inventory/aws_ec2.yml site.yml
```

```
  keyed_groups = grupy TWORZA SIE SAME z metadanych chmury.
  Otagujesz EC2 jako Role=apache → host laduje w grupie tag_Role_apache.
  Twoj playbook celuje w grupy — nie musi znac adresow IP.
```

> Wtyczka wymaga kolekcji `amazon.aws` + poswiadczen AWS (env/profile).
> To spina sie ze spotkaniem 6: Terraform tworzy EC2, aws_ec2 je "widzi".

---

# Dynamiczne inventory — skrypt (kontrakt)

**Kazdy program zwracajacy JSON w odpowiednim formacie = inventory:**

```bash
./moj_inventory.py --list        # caly stan: grupy, hosty, zmienne
./moj_inventory.py --host web01  # zmienne jednego hosta (moze byc {})
```

**Minimalny format `--list`:**
```json
{
  "webservers": { "hosts": ["web01", "web02"] },
  "databases":  { "hosts": ["db01"] },
  "_meta": {
    "hostvars": {
      "web01": { "ansible_host": "10.0.0.11" }
    }
  }
}
```

```
  Plik wykonywalny (chmod +x) → Ansible uruchamia go jak wtyczke.
  Tak dziala wiekszosc "legacy" dynamicznych inventory (np. ec2.py).
  Dzis preferujemy wtyczki YAML (aws_ec2.yml) — latwiejsze, cache'owane.
```

> W labie zbudujemy MALY skrypt dynamiczny i polaczymy go ze statycznym
> plikiem w jednym katalogu (hybryda) — bez chmury.

---

# constructed — grupy z faktow i zmiennych

**Wtyczka `constructed` tworzy grupy z tego, co JUZ wiesz o hostach:**

```yaml
# inventory/03-constructed.yml
plugin: ansible.builtin.constructed
strict: false
keyed_groups:
  - prefix: os
    key: ansible_facts.distribution        # grupa: os_Ubuntu, os_Rocky
  - prefix: env
    key: system_env                        # grupa z Twojej zmiennej
groups:
  duze_ramy: ansible_facts.memtotal_mb | int > 8000   # grupa warunkowa
```

```
  Po co? Grupujesz hosty wg CECH, nie wg recznych list:
   - "wszystkie Ubuntu"        → os_Ubuntu
   - "wszystkie z duzym RAM"   → duze_ramy
   - "wszystkie w env=prod"    → env_prod

  constructed dziala na juz-zaladowanym inventory (statycznym LUB
  dynamicznym) → czesty element hybrydy.
```

---

---
# MODUL 2
# Uklad inventory i podfoldery
---

---

# Inventory jako KATALOG — laczenie zrodel

```
inventory/
├── 01-static.yml         ← hosty on-prem / sprzet (recznie)
├── 02-aws_ec2.yml        ← dynamiczne z AWS (wtyczka)
├── 03-constructed.yml    ← grupy z faktow/tagow
├── group_vars/
│   ├── all.yml
│   ├── webservers.yml
│   └── prod.yml
└── host_vars/
    └── web01.yml
```

```bash
ansible-inventory -i inventory/ --graph     # -i KATALOG = polacz wszystko
```

```
  Ansible laduje pliki z katalogu ALFABETYCZNIE i SCALA wynik:
   - hosty ze statycznego + hosty z AWS = jedno wspolne inventory
   - group_vars/ i host_vars/ obok = zmienne doladowane automatycznie
  Prefiksy 01-, 02- steruja kolejnoscia ladowania.
```

---

# group_vars i host_vars — katalog zamiast pliku

**Zmienne grupy moga byc PLIKIEM albo KATALOGIEM:**

```
group_vars/
├── all.yml                    ← wariant: jeden plik
└── prod/                      ← wariant: katalog (ladowane wszystkie pliki)
    ├── vars.yml               ← zmienne jawne
    └── vault.yml              ← sekrety (zaszyfrowane vaultem)
```

```
  Wzorzec sekretow (branzowy standard, jest w tym repo):
  group_vars/<grupa>/
    ├── vars.yml    → db_haslo: "{{ vault_db_haslo }}"   (wskaznik)
    └── vault.yml   → vault_db_haslo: "tajne"            (ZASZYFROWANE)

  Kod widzi db_haslo, sekret siedzi w vault.yml.
  Rozdzielenie = mozesz code-review'owac vars.yml bez odszyfrowywania.
```

> Wiecej o tym wzorcu w Module 3 (sekrety).

---

# Ktore inventory wygrywa i jak sprawdzic

```
  Diagnostyka inventory — ZANIM uruchomisz playbook:

  ansible-inventory -i inventory/ --graph      drzewo grup i hostow
  ansible-inventory -i inventory/ --list       pelny JSON (hosty+zmienne)
  ansible-inventory -i inventory/ --host web01 finalne zmienne hosta
  ansible-inventory -i inventory/ --graph --vars   graf ZE zmiennymi
```

```
  Gdy host jest w wielu zrodlach/grupach:
   - hosty o tej samej nazwie ze roznych plikow = SCALANE
   - zmienne: obowiazuje znane precedence (host_vars > group_vars > all)
   - grupy laczenie sumuja przynaleznosc

  Zloty nawyk: przy KAZDYM problemie ze zmiennymi zacznij od
  `ansible-inventory --host <host>` — zobaczysz, co host NAPRAWDE dostaje.
```

---

---
# MODUL 3
# Sekrety w IaaC
---

---

# Problem: sekrety w kodzie

```
  ❌ TAK NIE WOLNO:

  group_vars/all.yml
    db_haslo: "Szkolenie123!"        ← w Git, jawnym tekstem, na zawsze
                                        (historia Git pamieta nawet po
                                         usunieciu!)

  Sekrety w repozytorium to:
   - wyciek przy kazdym dostepie do repo (staz, fork, backup, CI logi)
   - brak rotacji (wszyscy znaja to samo haslo)
   - audyt niemozliwy (kto i kiedy uzyl?)
```

**Rozwiazanie 1 (dzis): ansible-vault — szyfrowanie w repo**
**Rozwiazanie 2 (koncepcja): sekrety w systemie zewnetrznym**

```
  Domykamy dlug ze spotkania 6:
  db_haslo z projektu 6 → zaszyfrowane vaultem.
  Zmienna zostaje ta sama — kod (szablony, role) sie NIE zmienia.
```

---

# ansible-vault — podstawowe operacje

```bash
# Utworz nowy zaszyfrowany plik (otwiera edytor)
ansible-vault create group_vars/prod/vault.yml

# Zaszyfruj istniejacy plik
ansible-vault encrypt secrets.yml

# Podejrzyj bez odszyfrowywania na dysk
ansible-vault view group_vars/prod/vault.yml

# Edytuj (odszyfruj → edytor → zaszyfruj z powrotem)
ansible-vault edit group_vars/prod/vault.yml

# Zmien haslo szyfrujace (rotacja klucza vaulta)
ansible-vault rekey group_vars/prod/vault.yml

# Odszyfruj na stale (ostroznie!)
ansible-vault decrypt secrets.yml
```

**Jak wyglada zaszyfrowany plik (z tego repo):**
```
$ANSIBLE_VAULT;1.1;AES256
38386636316635656561623635613239356430613634...
3462366163343566383330393233393164356664...
```

> Caly plik to jeden blok AES256. Git widzi tylko szyfrogram —
> mozesz go bezpiecznie commitowac.

---

# Uruchamianie z sekretami — podawanie hasla

```bash
# Zapyta o haslo interaktywnie
ansible-playbook site.yml --ask-vault-pass

# Haslo z pliku (CI/CD, automatyzacja)
ansible-playbook site.yml --vault-password-file ~/.vault_pass

# Skrot: skonfiguruj raz w ansible.cfg / zmiennej srodowiskowej
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
ansible-playbook site.yml           # juz bez flag
```

```
  ⚠ Plik z haslem (.vault_pass) NIGDY do repozytorium!
     → .gitignore + uprawnienia 600

  Plik moze byc tez SKRYPTEM (wykonywalny) — wtedy Ansible bierze
  haslo z jego STDOUT. Tak podpina sie menedzery hasel / KMS:
     ~/.vault_pass.sh  →  echo "$(aws secretsmanager get-secret-value ...)"
```

---

# Wzorzec vars + vault (auto-load z group_vars)

**Struktura — sekret rozdzielony od kodu:**
```
inventory/group_vars/prod/
├── vars.yml         ← JAWNE (do code-review)
└── vault.yml        ← ZASZYFROWANE
```

**`vars.yml` — publiczne nazwy wskazuja na sekrety:**
```yaml
db_user: sklep
db_haslo: "{{ vault_db_haslo }}"       # wskaznik na zmienna z vaulta
```

**`vault.yml` — zaszyfrowane wartosci (prefiks vault_ = konwencja):**
```yaml
vault_db_haslo: "prawdziwe-tajne-haslo"
```

```
  Dlaczego prefiks vault_ i osobny plik?
  ✅ w vars.yml widac, KTORE zmienne sa sekretami (grep vault_)
  ✅ code-review vars.yml bez odszyfrowywania vault.yml
  ✅ rola/szablon uzywa {{ db_haslo }} — nie wie, ze to z vaulta

  Oba pliki w group_vars/prod/ = Ansible laduje je AUTOMATYCZNIE
  dla grupy prod. Zero zmian w playbooku.
```

---

# encrypt_string — pojedynczy sekret inline

**Gdy nie chcesz calego pliku — zaszyfruj JEDNA wartosc:**

```bash
ansible-vault encrypt_string 'tajne-haslo' --name 'vault_db_haslo'
```

```yaml
vault_db_haslo: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66386439653...
          3234626439...
```

```
  Taki blok wklejasz WPROST do zwyklego (niezaszyfrowanego) pliku YAML.
  Reszta pliku jawna, tylko ta jedna wartosc zaszyfrowana.

  Kiedy co:
   - caly plik sekretow      → ansible-vault create/encrypt (vault.yml)
   - jeden sekret w jawnym pliku → encrypt_string
```

---

# Sekrety w systemach zewnetrznych (koncepcja)

```
  Vault plik = sekret w REPO (zaszyfrowany).
  Kolejny poziom = sekret NIGDY nie dotyka repo — pobierany w locie
  z dedykowanego systemu:

  ┌─────────────────────────────────────────────────────────┐
  │  HashiCorp Vault · AWS Secrets Manager · Azure Key Vault │
  │  CyberArk · GCP Secret Manager                          │
  └─────────────────────────────────────────────────────────┘
        │  lookup w czasie wykonania (nic nie ladujemy na dysk)
        ▼
  db_haslo: "{{ lookup('community.hashi_vault.vault_kv2_get',
                        'sekret/db').secret.haslo }}"

  db_haslo: "{{ lookup('amazon.aws.aws_secret', 'prod/db/haslo') }}"
```

```
  Zalety vs plik vault:
  ✅ centralna rotacja (zmieniasz w jednym miejscu)
  ✅ audyt: kto/kiedy pobral sekret
  ✅ dostep czasowy i granularny (RBAC)
  ❌ zaleznosc od dostepnosci systemu sekretow w czasie wdrozenia
```

> Wybor: maly zespol → vault plik wystarcza. Organizacja z compliance
> → zewnetrzny magazyn sekretow. Kod (`{{ db_haslo }}`) bywa ten sam.

---

---
# MODUL 4
# Debugging
---

---

# Trzy rodziny bledow

```
  1. BRAKUJACE / ZLE ZMIENNE
     "'xxx' is undefined"
     → literowka w nazwie, brak group_vars, zly zasieg

  2. BLEDY WYKONANIA (host/polaczenie)
     UNREACHABLE, permission denied, brak pakietu
     → SSH, become, brakujaca zaleznosc na hoscie

  3. BLEDY W ZADANIACH (logika)
     modul zwraca failed, zly wynik, brak idempotencji
     → zle parametry, zle zalozenia o stanie hosta
```

```
  Metoda uniwersalna:
   1. przeczytaj komunikat DO KONCA (Ansible mowi, co i gdzie)
   2. zawez: --limit jeden host, --tags jeden fragment
   3. zajrzyj do srodka: debug / -vvv / register
   4. sprawdz zalozenia: --check --diff, ansible-inventory --host
```

---

# Poziomy szczegolowosci i debug

```bash
ansible-playbook site.yml -v      # wyniki taskow
ansible-playbook site.yml -vv     # + informacje o konfiguracji
ansible-playbook site.yml -vvv    # + szczegoly polaczen (SSH)
ansible-playbook site.yml -vvvv   # + debug connection pluginow
```

**Modul debug — Twoj `print()`:**
```yaml
- name: Pokaz wartosc zmiennej
  ansible.builtin.debug:
    var: app_port                    # var: NIE uzywa {{ }}

- name: Pokaz zlozony komunikat
  ansible.builtin.debug:
    msg: "Host {{ inventory_hostname }} → port {{ app_port }}"

- name: Pokaz CALA zarejestrowana strukture
  ansible.builtin.debug:
    var: wynik                       # cd. register — cala odpowiedz modulu
    verbosity: 2                     # pokaz tylko przy -vv (nie zasmieca)
```

---

# assert — walidacja zalozen wprost

```yaml
- name: Sprawdz, ze wymagane zmienne sa ustawione
  ansible.builtin.assert:
    that:
      - app_port is defined
      - app_port | int > 0
      - db_haslo is defined
    fail_msg: "Brak wymaganej zmiennej — sprawdz group_vars!"
    success_msg: "Konfiguracja kompletna"
```

```
  assert = wczesne, czytelne zatrzymanie z SENSOWNYM komunikatem,
  zamiast tajemniczego bledu 20 taskow pozniej.

  Wzorzec: na poczatku roli/playbooka sprawdz zalozenia (preflight),
  potem dzialaj. "Fail fast" oszczedza godziny debugowania.
```

**Diagnoza brakujacej zmiennej:**
```yaml
- ansible.builtin.debug:
    msg: "{{ app_port | default('!! ZMIENNA NIE USTAWIONA !!') }}"
```

---

# Check-mode — symulacja i jej PULAPKI

```bash
ansible-playbook site.yml --check          # symulacja, zero zmian
ansible-playbook site.yml --check --diff   # + co konkretnie by sie zmienilo
```

```
  Check-mode zglasza, CO BY zrobil — bez robienia tego.
  Bezcenny przed produkcja. Ale ma pulapki:
```

```
  ⚠ PULAPKA 1 — taski zalezne
    Task A (w check tylko UDAJE, ze utworzyl plik)
    Task B (czyta ten plik) → w check pliku NIE MA → blad/zle wyniki

  ⚠ PULAPKA 2 — command/shell
    domyslnie NIE uruchamiaja sie w check (skipped) → luki w symulacji
    (mozna wymusic: check_mode: false, ale wtedy dziala NAPRAWDE!)

  ⚠ PULAPKA 3 — register w check
    zarejestrowany wynik moze byc pusty/inny niz w realnym przebiegu
```

> Check-mode to symulacja, nie gwarancja. Traktuj wynik jako
> "prawdopodobnie" — zwlaszcza dla playbookow z command/shell i zaleznosciami.

---

# changed_when i failed_when — ujarzmianie modulow

```yaml
- name: Sprawdzenie stanu (odczyt — nie zmienia hosta)
  ansible.builtin.command: systemctl is-active nginx
  register: nginx_stan
  changed_when: false               # odczyt NIGDY nie jest "zmiana"
  failed_when: false                # rc!=0 to dla nas INFO, nie blad

- name: Reaguj na wynik
  ansible.builtin.debug:
    msg: "nginx: {{ nginx_stan.stdout }}"

- name: Wlasna definicja bledu
  ansible.builtin.command: /usr/local/bin/deploy.sh
  register: deploy
  changed_when: "'CHANGED' in deploy.stdout"
  failed_when: "'ERROR' in deploy.stdout or deploy.rc != 0"
```

```
  Dlaczego to wazne dla debugowania:
  command/shell ZAWSZE raportuja "changed" i traktuja rc!=0 jako failed.
  Bez changed_when/failed_when: falszywe "changed" psuja idempotencje,
  a poprawne rc!=0 (np. grep bez trafienia) wywala playbook.
```

---

---
# MODUL 5
# Wiele srodowisk: dev/test/QA/UAT/PROD
---

---

# Sciezka promocji przez srodowiska

```
   DEV  ──►  TEST  ──►  QA  ──►  UAT  ──►  PROD
   │         │          │        │         │
   szybko,   testy      dzial    akcept.   klienci,
   czesto    integr.    jakosci  biznesu   krytyczne

  TEN SAM kod (playbooki, role) przechodzi przez wszystkie.
  ROZNI sie tylko KONFIGURACJA (zmienne per srodowisko).
```

```
  Test dojrzalosci (ze spotkania 4):
  "Czy nowe srodowisko QA dodaje sie BEZ edycji playbookow —
   tylko przez nowe group_vars / nowe inventory?"

  Jesli tak → masz zdrowy projekt.
  Jesli nie (kopie playbookow per env, when: env==...) → dlug techniczny.
```

---

# Dwa wzorce (recap + rozwiniecie ze spotkania 4)

```
  WZORZEC A — grupy w jednym inventory
  inventory/
  ├── hosts.yml         (grupy: dev, test, qa, uat, prod)
  └── group_vars/
      ├── all.yml       wspolne domyslne
      ├── dev.yml       ├── qa.yml
      ├── test.yml      ├── uat.yml
      └── prod.yml

  WZORZEC B — osobne inventory per srodowisko  (zalecane na skale)
  inventories/
  ├── dev/    ├── hosts.yml  └── group_vars/  (+ vault.yml)
  ├── qa/     ├── hosts.yml  └── group_vars/
  └── prod/   ├── hosts.yml  └── group_vars/  (+ vault.yml, osobne haslo!)
```

```bash
ansible-playbook -i inventories/dev/  site.yml    # ten sam site.yml...
ansible-playbook -i inventories/prod/ site.yml    # ...inne srodowisko
```

| Kryterium              | A: grupy          | B: osobne inventory      |
|------------------------|-------------------|--------------------------|
| Izolacja / ochrona prod| ❌ latwo pomylic  | ✅ -i wybiera env         |
| Osobne sekrety per env | trudniej          | ✅ vault per katalog      |
| Male projekty          | ✅ prostsze       | narzut                   |

---

# Gdzie definiowac zmienna — mapa decyzji

```
  Pytanie: ta zmienna rozni sie miedzy...?

  ...nie rozni sie nigdzie          → group_vars/all.yml
  ...srodowiskami (dev/prod)        → group_vars/<env>.yml lub inventories/<env>/
  ...rolami hosta (web/db)          → group_vars/<grupa-funkcyjna>.yml
  ...pojedynczymi hostami           → host_vars/<host>.yml
  ...to sekret                      → vault.yml (obok odpowiednich vars)
  ...to domyslna wartosc komponentu → defaults/ roli
  ...decyzja operatora na dzis      → -e przy uruchomieniu
```

```
  Zasada najnizszego sensownego poziomu (spotkanie 4):
  definiuj NAJOGOLNIEJ jak sie da, nadpisuj TYLKO tam, gdzie inaczej.

  Najczestszy blad przy wielu srodowiskach:
  ta sama wartosc skopiowana do dev.yml, test.yml, qa.yml, prod.yml
  → powinna byc RAZ w all.yml, a nadpisana tylko tam, gdzie rozna.
```

---

# LAB 7 — Warsztat (35 min)

```
Zadanie (katalog: szkolenie8x4/lab7/):
Lab dziala LOKALNIE (localhost) — bez zdalnych hostow ani chmury.

Czesc A — inventory hybrydowe:
  1. Katalog inventory/ = plik statyczny + skrypt dynamiczny
  2. ansible-inventory -i inventory/ --graph  → hosty z OBU zrodel
  3. TODO: dopisz host do statycznego, dodaj group_vars

Czesc B — vault (domkniecie dlugu z projektu 6):
  4. Utworz vault z sekretem (haslo do .vault_pass podaje prowadzacy)
  5. Wzorzec vars.yml → {{ vault_db_haslo }}, vault.yml (zaszyfrowany)
  6. Uruchom playbook czytajacy sekret (bez ujawniania go w logu)
  7. encrypt_string — pojedyncza wartosc inline

Czesc C — debugging:
  8. debuguj.yml ma 3 zasiane bledy (undefined / bool-trap / rc)
     → znajdz (-vvv, debug, --check) i napraw
```

> Instrukcja: `lab7/README.md` · Rozwiazania: `*_odpowiedz`

---

# Podsumowanie spotkania 7

```
Co juz umiemy:

  ✅ Inventory: statyczne / dynamiczne (aws_ec2) / hybrydowe (katalog)
  ✅ constructed — grupy z faktow i tagow
  ✅ Podfoldery: group_vars/<grupa>/ z vars.yml + vault.yml
  ✅ ansible-vault: create/encrypt/view/edit/rekey/encrypt_string
  ✅ Auto-load sekretow + wzorzec vars→vault_ (dlug z projektu 6 splacony)
  ✅ Sekrety zewnetrzne: HashiCorp/AWS SM przez lookup
  ✅ Debugging: -vvv, debug, assert, changed_when/failed_when
  ✅ Check-mode i jego 3 pulapki
  ✅ Wiele srodowisk: wzorce A/B, mapa lokalizacji zmiennych

Na spotkaniu 8 — AWX/Tower i dobre praktyki:

  ● Interfejs graficzny AWX/Tower, model RBAC
  ● Lookupy, delegowanie zadan, powtarzanie, orkiestracja Windows
  ● Konsultacje i podsumowanie szkolenia
```

---

# Pytania?

## Do zobaczenia na spotkaniu 8 — ostatnim!

*Materialy szkoleniowe dostepne w repozytorium Git*
