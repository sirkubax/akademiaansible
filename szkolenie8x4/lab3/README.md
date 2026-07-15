# LAB 3 — Spotkanie 3: typowe operacje administracyjne na Linuksie (55 min)

## Cel
Napisać playbooki realizujące codzienne zadania administratora: instalację
i usuwanie pakietów, aktualizację systemu, zarządzanie plikami konfiguracyjnymi
(template / lineinfile / blockinfile) i pobieranie plików z hostów.

## Scenariusz
Firma ma standard: każdy serwer ma zestaw narzędzi, aktualne pakiety,
firmowy MOTD i skonfigurowaną aplikację. Doprowadź hosty do tego standardu.

## Środowisko
```
Control node : maszyna lokalna (venv z Ansible)
Managed hosts: dostarczone przez prowadzącego (2 hosty, Ubuntu) — jak w Lab 1
```

Przygotowanie:
```bash
source ~/venv-ansible/bin/activate
cd szkolenie8x4/lab3
vi inventory/hosts.yml     # uzupełnij dane hostów (jak w Lab 1)
ansible all -i inventory/hosts.yml -m ping
```

---

## Krok 1 — Pakiety i aktualizacja systemu

Otwórz `operacje_pakiety.yml` i uzupełnij miejsca oznaczone `# TODO`:

1. Instalacja narzędzi: `htop`, `vim`, `curl`, `tree`
   (moduł `apt`, `update_cache`, `cache_valid_time`)
2. Usunięcie `nano` wraz z plikami konfiguracyjnymi
   (`state: absent`, `purge`, `autoremove`)
3. Bezpieczna aktualizacja systemu (`upgrade: safe`)
4. Task sprawdzający `/var/run/reboot-required` jest gotowy — przeanalizuj
   go: `stat` + `register` + `when` (zajawka spotkania 4)

Testowanie — zawsze w tej kolejności:
```bash
ansible-playbook -i inventory/hosts.yml operacje_pakiety.yml --syntax-check
ansible-playbook -i inventory/hosts.yml operacje_pakiety.yml --check --diff
ansible-playbook -i inventory/hosts.yml operacje_pakiety.yml
```

Weryfikacja ad-hoc:
```bash
ansible all -i inventory/hosts.yml -m command -a "htop --version"
ansible all -i inventory/hosts.yml -m command -a "which nano" # oczekiwany: błąd (rc=1)
```

## Krok 2 — Pliki konfiguracyjne

Otwórz `operacje_pliki.yml` i uzupełnij miejsca oznaczone `# TODO`:

1. MOTD z szablonu `templates/motd.j2` — task gotowy, przeanalizuj
   (`template` + `backup`)
2. Konfiguracja początkowa aplikacji — task gotowy, zwróć uwagę na
   `force: false` (dlaczego jest kluczowe? — pytanie w Sprawdzeniu)
3. **TODO:** zmień `log_level=info` na `log_level=debug`
   (`lineinfile` z `regexp`)
4. **TODO:** dopisz sekcję monitoringu (`blockinfile` z własnym `marker`)
5. **TODO:** pobierz gotowy plik konfiguracyjny ze wszystkich hostów
   do katalogu `pobrane/` (`fetch`)

```bash
ansible-playbook -i inventory/hosts.yml operacje_pliki.yml --check --diff
ansible-playbook -i inventory/hosts.yml operacje_pliki.yml
```

Weryfikacja:
```bash
ansible all -i inventory/hosts.yml -m command -a "cat /etc/motd"
ansible all -i inventory/hosts.yml -m command -a "cat /etc/szkolenie/app.conf"
find pobrane/ -type f        # struktura: pobrane/<host>/etc/szkolenie/app.conf
```

## Krok 3 — Idempotencja

Uruchom OBA playbooki drugi raz:
```bash
ansible-playbook -i inventory/hosts.yml operacje_pakiety.yml
ansible-playbook -i inventory/hosts.yml operacje_pliki.yml
```

W `PLAY RECAP` oczekujemy `changed=0` (wyjątek: task aktualizacji może
pokazać zmianę, jeśli w międzyczasie wyszły nowe pakiety — przedyskutuj
z prowadzącym dlaczego).

## Krok 4 (bonus) — Dyski: LVM na urządzeniu loop

Playbook `dyski_bonus.yml` jest **kompletny** — Twoim zadaniem jest go
przeczytać, zrozumieć i uruchomić. Pokazuje cały stos storage:
plik-dysk → loop device → LVM (`lvg`, `lvol`) → `filesystem` → `mount`.

„Dyskiem" jest zwykły plik 300 MB — ćwiczysz bez ryzyka dla danych.

```bash
ansible-playbook -i inventory/hosts.yml dyski_bonus.yml
ansible all -i inventory/hosts.yml -m command -a "df -h /mnt/lab_dysk"
ansible all -i inventory/hosts.yml -m command -a "lsblk"

# Sprzątanie po ćwiczeniu:
ansible-playbook -i inventory/hosts.yml dyski_sprzatanie.yml
```

Pytania do analizy:
- Dlaczego tworzenie pliku-dysku używa `creates:`?
- Dlaczego sprawdzamy `losetup -j` przed podpięciem?
- Co się stanie z danymi przy DRUGIM uruchomieniu playbooka? (podpowiedź:
  `filesystem` jest idempotentny)

## Krok 5 (bonus) — asystent AI

Poproś asystenta AI o task, który w `/etc/szkolenie/app.conf` zmieni
`port=8080` na `port=9090`. Zweryfikuj: czy użył `lineinfile` z sensownym
`regexp`? Czy `regexp` nie złapie przypadkiem linii `monitoring_port`?
Przetestuj `--check --diff` zanim uruchomisz.

---

## Sprawdzenie

Po labie powinieneś umieć odpowiedzieć:
- Czym różni się `state: present` od `state: latest` i które psuje powtarzalność?
- Po co `force: false` w tasku `copy` z konfiguracją początkową?
  (podpowiedź: co by się działo z `log_level` przy każdym uruchomieniu?)
- Kiedy `template`, kiedy `lineinfile`, a kiedy `blockinfile`?
- Jak wygląda struktura katalogów po `fetch` i dlaczego host jest w ścieżce?
- Które moduły dyskowe pochodzą z kolekcji `community.general`?

## Odpowiedzi

- `operacje_pakiety_odpowiedz.yml`
- `operacje_pliki_odpowiedz.yml`
- `dyski_bonus.yml` jest kompletny (to ćwiczenie z czytania kodu)
