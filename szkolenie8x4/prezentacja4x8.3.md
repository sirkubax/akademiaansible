# Automatyzacja z Ansible
### Szkolenie 8 spotkan x 4h · Spotkanie 3
## Operacje na systemach

---

# Agenda spotkania 3 (4h)

| Czas        | Blok        | Temat                                              |
|-------------|-------------|----------------------------------------------------|
| 0:00 – 0:15 | Recap       | Powtorka spotkania 2, pytania                      |
| 0:15 – 0:55 | **Modul 1** | Instalacja i deinstalacja pakietow                 |
| 0:55 – 1:25 | **Modul 2** | Aktualizacja systemow                              |
| 1:25 – 1:40 | ☕ Przerwa  |                                                    |
| 1:40 – 2:15 | **Modul 3** | Partycjonowanie dyskow: parted, filesystem, LVM    |
| 2:15 – 2:45 | **Modul 4** | Konfiguracja: template, lineinfile, blockinfile    |
| 2:45 – 3:05 | **Modul 5** | Kopiowanie plikow: copy, fetch, synchronize        |
| 3:05 – 4:00 | **Lab 3**   | Typowe operacje administracyjne na Linuksie        |

> Dzisiejsze spotkanie to "chleb powszedni" administratora:
> wszystko, co robisz recznie na serwerach — zrobimy playbookami.

---

# Recap spotkania 2

```
Co juz umiemy:

  ✅ Instalacja Ansible: pip+venv, pinowanie wersji, EE
  ✅ SSH: klucze, become, ansible.cfg
  ✅ Inventory: grupy, group_vars/host_vars, patterns
  ✅ Ad-hoc: command vs shell vs raw
  ✅ Playbooki: PLAY RECAP, --check --diff, register + debug
  ✅ Lab: struktury danych YAML + filtry i petle Jinja2

Dzis — operacje na systemach:

  ● Pakiety: apt / yum / dnf / package
  ● Aktualizacje systemow (i kiedy restart)
  ● Dyski: parted, filesystem, mount, LVM
  ● Konfiguracja: template, lineinfile, blockinfile
  ● Transfer plikow: copy, fetch, synchronize, get_url
```

---

---
# MODUL 1
# Instalacja i deinstalacja pakietow
---

---

# Modul apt — Debian/Ubuntu

**Instalacja:**
```yaml
- name: Zainstaluj narzedzia
  apt:
    name:
      - htop
      - vim
      - curl
    state: present
    update_cache: true          # apt update przed instalacja
    cache_valid_time: 3600      # ...ale nie czesciej niz raz na godzine
```

**Deinstalacja:**
```yaml
- name: Usun pakiet
  apt:
    name: nano
    state: absent               # usun pakiet
    purge: true                 # + pliki konfiguracyjne (apt purge)
    autoremove: true            # + osierocone zaleznosci
```

**Konkretna wersja i pakiet z pliku .deb:**
```yaml
- apt:
    name: nginx=1.24.*          # przypiecie wersji
- apt:
    deb: /tmp/pakiet_firmowy.deb
```

---

# Moduly yum / dnf — RedHat/CentOS/Rocky

```yaml
- name: Zainstaluj narzedzia (RHEL 8+/Rocky/Alma)
  dnf:
    name:
      - htop
      - vim-enhanced            # uwaga: INNE nazwy pakietow niz Debian!
    state: present

- name: Usun pakiet
  dnf:
    name: nano
    state: absent
    autoremove: true

- name: Zainstaluj grupe pakietow
  dnf:
    name: "@Development Tools"  # grupy — tylko w swiecie RPM
    state: present
```

```
  yum  — starsze systemy (RHEL/CentOS 7)
  dnf  — RHEL 8+, Fedora, Rocky, Alma (nastepca yum)

  W praktyce: modul yum na nowych systemach i tak
  deleguje do dnf — uzywaj dnf.
```

---

# Modul package — uniwersalny (z gwiazdka)

**Jeden task dla wielu dystrybucji:**
```yaml
- name: Zainstaluj htop (dziala na Debian I RedHat)
  package:
    name: htop
    state: present
```

**Gwiazdka: nazwy pakietow ROZNIA sie miedzy dystrybucjami:**

| Debian/Ubuntu    | RHEL/Rocky        |
|------------------|-------------------|
| apache2          | httpd             |
| vim              | vim-enhanced      |
| openssh-server   | openssh-server ✓  |
| python3-pip      | python3-pip ✓     |

**Rozwiazanie — zmienna per rodzina systemu:**
```yaml
vars:
  apache_pkg: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"
tasks:
  - name: Zainstaluj Apache niezaleznie od dystrybucji
    package:
      name: "{{ apache_pkg }}"
      state: present
```

> `package` ujednolica MODUL, ale nie NAZWY pakietow.
> Pelny wzorzec (vars per os_family) — na spotkaniu 4.

---

# Pakiety spoza repozytoriow systemowych

```yaml
# Pakiety Pythona
- name: Zainstaluj biblioteki Pythona
  pip:
    name:
      - requests
      - jmespath==1.0.1
    virtualenv: /opt/app/venv      # najlepiej w venv aplikacji

# Snap (Ubuntu)
- name: Zainstaluj certbota
  community.general.snap:
    name: certbot
    classic: true

# Klucz i repozytorium zewnetrzne (np. Docker)
- name: Dodaj repozytorium Dockera
  apt_repository:
    repo: "deb https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present
```

**Jak znalezc wlasciwy modul:**
```bash
ansible-doc -l | grep -i pakiet_czy_narzedzie
ansible-doc apt          # pelna dokumentacja + przyklady na dole!
```

---

---
# MODUL 2
# Aktualizacja systemow
---

---

# Aktualizacja — Debian/Ubuntu

```yaml
- name: Odswiez liste pakietow
  apt:
    update_cache: true
    cache_valid_time: 3600

- name: Aktualizacja bezpieczna (bez usuwania pakietow)
  apt:
    upgrade: safe               # odpowiednik: apt upgrade

- name: Pelna aktualizacja (moze usuwac/wymieniac pakiety)
  apt:
    upgrade: dist               # odpowiednik: apt full-upgrade
```

**Aktualizacja pojedynczego pakietu do najnowszej wersji:**
```yaml
- name: Najnowszy openssl (np. po CVE)
  apt:
    name: openssl
    state: latest               # UWAGA: latest w zwyklym playbooku
                                # psuje powtarzalnosc — uzywaj swiadomie
```

```
  present  = "ma byc zainstalowany"     (idempotentne, przewidywalne)
  latest   = "ma byc najnowszy"         (kazdy run moze cos zmienic!)

  Regula: w playbookach konfiguracyjnych present,
          latest tylko w dedykowanych playbookach patchowania.
```

---

# Aktualizacja — RedHat + czy potrzebny restart?

```yaml
- name: Aktualizacja wszystkich pakietow (RHEL/Rocky)
  dnf:
    name: "*"
    state: latest

- name: Tylko poprawki bezpieczenstwa
  dnf:
    name: "*"
    state: latest
    security: true
```

**Debian: czy jadro/libc wymagaja restartu?**
```yaml
- name: Sprawdz czy system wymaga restartu
  stat:
    path: /var/run/reboot-required     # Debian tworzy ten plik
  register: reboot_required

- name: Zrestartuj hosta (tylko gdy trzeba)
  reboot:
    reboot_timeout: 600                # czekaj az host wstanie
  when: reboot_required.stat.exists
```

**RedHat — analogicznie:**
```bash
dnf needs-restarting -r    # rc=1 → wymagany restart
```

> Modul `reboot` sam czeka, az host wroci i SSH odpowie —
> playbook kontynuuje dopiero po podniesieniu maszyny.

---

# Patchowanie floty — bezpiecznie

```yaml
- name: Aktualizacja serwerow www — po jednym naraz
  hosts: webservers
  become: true
  serial: 1                     # ← rolling update: host po hoscie
  tasks:
    - name: Aktualizuj pakiety
      apt:
        upgrade: safe
        update_cache: true

    - name: Restart jesli wymagany
      reboot:
      when: reboot_required.stat.exists
```

```
  serial: 1        po jednym hoscie
  serial: "25%"    cwiartkami floty
  serial: [1, 5]   najpierw 1 (kanarek), potem po 5

  Bez serial: Ansible aktualizuje WSZYSTKIE hosty rownolegle —
  przy patchowaniu klastra to przepis na przestoj calej uslugi.
```

> Orkiestracje (serial, delegowanie, max_fail_percentage)
> rozwiniemy na spotkaniu 8.

---

---
# MODUL 3
# Partycjonowanie dyskow
---

---

# Stos storage — co konfigurujemy po kolei

```
  ┌───────────────────────────────────────────────┐
  │   /dane          ← mount        (ansible.posix.mount)
  ├───────────────────────────────────────────────┤
  │   ext4 / xfs     ← filesystem   (community.general.filesystem)
  ├───────────────────────────────────────────────┤
  │   lv_dane        ← wolumen LVM  (community.general.lvol)
  │   vg_dane        ← grupa LVM    (community.general.lvg)
  ├───────────────────────────────────────────────┤
  │   /dev/sdb1      ← partycja     (community.general.parted)
  ├───────────────────────────────────────────────┤
  │   /dev/sdb       ← fizyczny dysk
  └───────────────────────────────────────────────┘
```

> Moduly dyskowe pochodza z kolekcji `community.general`
> i `ansible.posix` — pakiet `ansible` zawiera je od razu.
> LVM mozna pominac (partycja → filesystem → mount),
> ale LVM daje mozliwosc POWIEKSZANIA w locie.

---

# parted — partycje

**Najpierw zobacz, co system widzi (fakty!):**
```yaml
- name: Jakie dyski widzi host?
  debug:
    var: ansible_devices.keys() | list      # sda, sdb, nvme0n1...

- name: Co jest zamontowane?
  debug:
    var: ansible_mounts | map(attribute='mount') | list
```

**Partycja na calym dysku:**
```yaml
- name: Stworz partycje sdb1 na calym dysku
  community.general.parted:
    device: /dev/sdb
    number: 1
    state: present
    part_end: "100%"
```

```
  ⚠ ZASADY BEZPIECZENSTWA (dyski to nie motd!):

  1. NIGDY nie testuj playbookow dyskowych na produkcji
  2. Zawsze celuj w KONKRETNE urzadzenie (zmienna, nie "sdb" na sztywno)
  3. parted/filesystem NIE nadpisza istniejacych danych bez
     wymuszenia — ale mount w zle miejsce potrafi "schowac" dane
```

---

# filesystem + mount — system plikow i montowanie

```yaml
- name: Zaloz system plikow ext4
  community.general.filesystem:
    fstype: ext4
    dev: /dev/sdb1
    # force: true  ← wymusza nadpisanie istniejacego FS. NIE uzywaj domyslnie!

- name: Zamontuj i dopisz do /etc/fstab
  ansible.posix.mount:
    path: /dane
    src: /dev/sdb1
    fstype: ext4
    opts: defaults,noatime
    state: mounted            # zamontuj TERAZ + wpis do fstab
```

**Stany modulu mount:**

| state       | Co robi                                         |
|-------------|-------------------------------------------------|
| `mounted`   | montuje teraz + dodaje do fstab (najczestszy)   |
| `present`   | tylko wpis w fstab (bez montowania)             |
| `unmounted` | odmontowuje (fstab zostaje)                     |
| `absent`    | odmontowuje + usuwa z fstab                     |

> `filesystem` jest idempotentny: jesli FS juz istnieje — nic nie robi.
> Dlatego drugi run playbooka nie sformatuje danych.

---

# LVM — lvg i lvol

```yaml
- name: Grupa wolumenow z dwoch dyskow
  community.general.lvg:
    vg: vg_dane
    pvs: /dev/sdb,/dev/sdc

- name: Wolumen logiczny 10 GB
  community.general.lvol:
    vg: vg_dane
    lv: lv_aplikacja
    size: 10g

- name: System plikow + montowanie (jak poprzednio)
  community.general.filesystem:
    fstype: xfs
    dev: /dev/vg_dane/lv_aplikacja

- name: Zamontuj
  ansible.posix.mount:
    path: /opt/aplikacja
    src: /dev/vg_dane/lv_aplikacja
    fstype: xfs
    state: mounted
```

**Po co LVM? Powiekszanie BEZ przestoju:**
```yaml
- name: Powieksz wolumen do 20 GB razem z systemem plikow
  community.general.lvol:
    vg: vg_dane
    lv: lv_aplikacja
    size: 20g
    resizefs: true            # ← rozciaga tez filesystem!
```

---

---
# MODUL 4
# Konfiguracja pakietow — pliki konfiguracyjne
---

---

# Trzy podejscia do plikow konfiguracyjnych

```
  ┌─────────────────────────────────────────────────────────────┐
  │  template     "TEN PLIK JEST MOJ"                            │
  │               Ansible generuje CALY plik z szablonu .j2      │
  │               → nginx.conf, vhost, konfiguracja aplikacji    │
  │                                                              │
  │  lineinfile   "zmien JEDNA LINIE w cudzym pliku"             │
  │               → PermitRootLogin w sshd_config                │
  │                                                              │
  │  blockinfile  "dopisz BLOK do cudzego pliku"                 │
  │               → sekcja w /etc/hosts, fragment configu        │
  └─────────────────────────────────────────────────────────────┘
```

**Ktore wybrac?**

| Sytuacja                                       | Modul       |
|------------------------------------------------|-------------|
| Plik w calosci pod kontrola Ansible            | template    |
| Plik zarzadzany przez pakiet/OS, zmieniasz opcje| lineinfile  |
| Dopisujesz swoja sekcje do wspolnego pliku     | blockinfile |

> Najbezpieczniejszy dlugoterminowo jest **template** — stan pliku
> jest w 100% przewidywalny. Uzywaj go, gdy tylko mozesz.

---

# template — pelna kontrola nad plikiem

```yaml
- name: Wygeneruj konfiguracje aplikacji
  template:
    src: app.conf.j2
    dest: /etc/app/app.conf
    owner: root
    group: root
    mode: '0644'
    backup: true                     # kopia starej wersji przed nadpisaniem
    validate: /usr/sbin/nginx -t -c %s   # test PRZED podmiana pliku!
  notify: restart app
```

**`templates/app.conf.j2`:**
```jinja2
# Plik zarzadzany przez Ansible — zmiany reczne zostana NADPISANE
# Host: {{ ansible_hostname }} | wygenerowano dla: {{ inventory_hostname }}

port      = {{ app_port }}
workers   = {{ ansible_processor_count }}
log_level = {{ app_log_level | default('warning') }}
```

```
  validate:  jesli komenda zwroci blad — STARY plik zostaje.
             Skladnia %s = sciezka pliku tymczasowego.
  backup:    /etc/app/app.conf.2026-07-13@11:22:33~ — latwy powrot.
```

> Zawsze zaczynaj szablon od komentarza "zarzadzane przez Ansible" —
> oszczedzisz koledze godziny debugowania "czemu moje zmiany znikaja".

---

# lineinfile — chirurgiczna zmiana linii

```yaml
- name: Zablokuj logowanie roota po SSH
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^#?PermitRootLogin'     # znajdz linie (nawet zakomentowana)
    line: 'PermitRootLogin no'       # i zamien na ta
    validate: sshd -t -f %s
  notify: restart sshd
```

**Jak dziala regexp + line:**
```
  regexp znajduje linie:            po wykonaniu:
  ─────────────────────             ─────────────────────
  #PermitRootLogin yes        →     PermitRootLogin no
  PermitRootLogin yes         →     PermitRootLogin no
  (brak dopasowania)          →     linia DOPISANA na koncu
```

**Inne warianty:**
```yaml
- lineinfile:
    path: /etc/fstab
    regexp: '/mnt/stary_dysk'
    state: absent                    # usun pasujace linie

- lineinfile:
    path: /etc/hosts
    line: '10.0.0.5  backup.firma.local'
    insertafter: EOF                 # albo: regexp linii-kotwicy
```

> ⚠ Pulapka: zbyt ogolny `regexp` zmieni INNA linie niz myslisz.
> Testuj na kopii pliku i zawsze --check --diff.

---

# blockinfile — zarzadzany blok w cudzym pliku

```yaml
- name: Dodaj wpisy klastra do /etc/hosts
  blockinfile:
    path: /etc/hosts
    marker: "# {mark} ANSIBLE MANAGED — klaster aplikacji"
    block: |
      10.0.0.11  app01.firma.local app01
      10.0.0.12  app02.firma.local app02
      10.0.0.13  app03.firma.local app03
```

**Wynik w pliku:**
```
127.0.0.1 localhost
# BEGIN ANSIBLE MANAGED — klaster aplikacji
10.0.0.11  app01.firma.local app01
10.0.0.12  app02.firma.local app02
10.0.0.13  app03.firma.local app03
# END ANSIBLE MANAGED — klaster aplikacji
```

```
  Markery BEGIN/END to "wlasnosc" Ansible:
  - zmiana bloku  → podmienia zawartosc MIEDZY markerami
  - state: absent → usuwa caly blok z markerami
  - reszta pliku  → nietknieta

  ⚠ Dwa taski blockinfile do jednego pliku?
    KAZDY musi miec INNY marker — inaczej nadpisza sie nawzajem.
```

---

---
# MODUL 5
# Kopiowanie i wysylanie plikow
---

---

# copy — z control node na hosty

```yaml
- name: Wgraj plik statyczny
  copy:
    src: files/logo.png              # sciezka wzgledem playbooka/roli
    dest: /var/www/html/logo.png
    owner: www-data
    mode: '0644'

- name: Stworz maly plik z tresci (bez pliku zrodlowego)
  copy:
    content: |
      app=sklep
      env=produkcja
    dest: /etc/app/info.txt
    force: false                     # NIE nadpisuj, jesli juz istnieje

- name: Skopiuj plik LOKALNIE na hoscie (nie z control node)
  copy:
    src: /etc/app/app.conf
    dest: /etc/app/app.conf.przed_zmiana
    remote_src: true                 # zrodlo JEST na hoscie
```

```
  copy vs template:
  copy      → pliki statyczne, bajt w bajt (obrazki, binarki, certy)
  template  → wszystko co ma {{ zmienne }} w srodku
```

---

# fetch — z hostow na control node

**Kierunek ODWROTNY niz copy — zbieranie plikow z hostow:**

```yaml
- name: Pobierz logi aplikacji ze wszystkich hostow
  fetch:
    src: /var/log/app/error.log
    dest: zebrane_logi/              # katalog na CONTROL NODE
```

**Struktura wyniku — po jednym podkatalogu na hosta:**
```
zebrane_logi/
├── web01/
│   └── var/log/app/error.log
├── web02/
│   └── var/log/app/error.log
└── db01/
    └── var/log/app/error.log
```

**Typowe zastosowania:**
- zbieranie logow/raportow do analizy w jednym miejscu
- backup plikow konfiguracyjnych przed zmiana
- audyt: sciagnij configi ze 100 hostow i porownaj

> `flat: true` — bez struktury katalogow (uwaga na nadpisywanie
> przy wielu hostach!).

---

# synchronize, get_url, unarchive

**`synchronize` (rsync) — duze drzewa katalogow:**
```yaml
- name: Wgraj katalog aplikacji (tylko roznice!)
  ansible.posix.synchronize:
    src: build/aplikacja/            # lokalnie
    dest: /opt/aplikacja/            # na hoscie
    delete: true                     # usun pliki, ktorych nie ma w zrodle
```

**`get_url` — pobierz z internetu WPROST na hosta:**
```yaml
- name: Pobierz paczke narzedzia
  get_url:
    url: https://example.com/narzedzie-1.2.3.tar.gz
    dest: /tmp/narzedzie.tar.gz
    checksum: sha256:abc123...       # weryfikacja integralnosci!
```

**`unarchive` — rozpakuj (lokalne LUB zdalne archiwum):**
```yaml
- name: Rozpakuj na hoscie
  unarchive:
    src: /tmp/narzedzie.tar.gz
    dest: /opt/narzedzie/
    remote_src: true                 # archiwum JUZ jest na hoscie
    creates: /opt/narzedzie/bin/narzedzie   # idempotencja!
```

---

# Transfer plikow — ktery modul kiedy

| Potrzeba                                   | Modul         |
|--------------------------------------------|---------------|
| Maly plik statyczny na hosty               | `copy`        |
| Plik konfiguracyjny ze zmiennymi           | `template`    |
| Zmiana 1 linii w istniejacym pliku         | `lineinfile`  |
| Wlasna sekcja w istniejacym pliku          | `blockinfile` |
| Duzy katalog / czeste wdrozenia (roznice)  | `synchronize` |
| Sciagniecie pliku Z hostow                 | `fetch`       |
| Pobranie z internetu wprost na hosta       | `get_url`     |
| Rozpakowanie archiwum                      | `unarchive`   |

```
  Antywzorzec:

  ❌ shell: "scp ...", "wget ...", "rsync ..." recznie
     → nieidempotentne, bez raportowania zmian, bez --check

  Kazda z tych operacji ma swoj modul — uzywaj modulow.
```

---

# LAB 3 — Warsztat (55 min)

```
Zadanie (katalog: szkolenie8x4/lab3/):

Scenariusz: doprowadz serwery do "standardu firmowego".

1. Uzupelnij inventory (hosty od prowadzacego — jak w Lab 1)

2. operacje_pakiety.yml (miejsca # TODO):
   - zainstaluj zestaw narzedzi (htop, vim, curl, tree)
   - usun nano (z purge)
   - wykonaj bezpieczna aktualizacje (upgrade: safe)
   - sprawdz czy wymagany restart (/var/run/reboot-required)

3. operacje_pliki.yml (miejsca # TODO):
   - motd z szablonu (template + fakty)
   - konfiguracja poczatkowa (copy z force: false)
   - zmien log_level na debug        (lineinfile)
   - dopisz sekcje monitoringu       (blockinfile)
   - pobierz gotowe configi z hostow (fetch)

4. Kazdy playbook: --syntax-check → --check --diff → run → run
   (drugi run: changed=0 — idempotencja!)

5. BONUS: dyski_bonus.yml — LVM na urzadzeniu loop
   (bez ryzyka — "dyskiem" jest zwykly plik)
```

> Instrukcja: `lab3/README.md` · Rozwiazania: `*_odpowiedz.yml`

---

# Podsumowanie spotkania 3

```
Co juz umiemy:

  ✅ Pakiety: apt / dnf / package, present vs latest, purge
  ✅ Aktualizacje: upgrade safe/dist, security, reboot + serial
  ✅ Dyski: parted → (LVM: lvg/lvol) → filesystem → mount
  ✅ LVM = powiekszanie w locie (resizefs)
  ✅ Konfiguracja: template (caly plik) / lineinfile (linia)
     / blockinfile (blok) + validate i backup
  ✅ Transfer: copy, fetch, synchronize, get_url, unarchive
  ✅ Lab: kompletny playbook "standard firmowy" serwera

Na spotkaniu 4 — zmienne, warunki i petle:

  ● Variable precedence — co wygrywa i dlaczego
  ● when — logika warunkowa (pelny wyklad)
  ● loop — petle po listach, slownikach, wynikach
  ● Parametryzacja zadan i konfiguracja per srodowisko
  ● Lab: playbooki z logika warunkowa i zmiennymi per env
```

---

# Pytania?

## Do zobaczenia na spotkaniu 4!

*Materialy szkoleniowe dostepne w repozytorium Git*
