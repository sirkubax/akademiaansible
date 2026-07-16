# LAB 4 — Spotkanie 4: warunki, pętle i zmienne per środowisko (55 min)

## Cel
Zbudować playbooki z logiką warunkową (`when`), pętlami (`loop`)
i zmiennymi per środowisko (`group_vars`) — jeden kod dla dev i prod.

## Scenariusz
Masz dwa serwery: `web01` to środowisko **dev**, `web02` to **prod**.
Ten sam playbook ma skonfigurować oba — różnice opisują wyłącznie zmienne.

## Środowisko
```
Control node : maszyna lokalna (venv z Ansible)
Managed hosts: dostarczone przez prowadzącego (2 hosty, Ubuntu)
```

---

## Krok 1 — Inventory z grupami środowisk

1. Uzupełnij adresy IP w `inventory/hosts.yml` — zwróć uwagę, że hosty
   są w grupach `dev` i `prod` (obie są dziećmi `webservers`).
2. Obejrzyj gotowe pliki `inventory/group_vars/all.yml` (wspólne wartości
   domyślne) i `inventory/group_vars/dev.yml`.
3. **Uzupełnij `inventory/group_vars/prod.yml`** według TODO w pliku
   (na wzór dev.yml).

Sprawdź, co dostanie każdy host — zanim uruchomisz cokolwiek:
```bash
ansible-inventory -i inventory/hosts.yml --graph
ansible-inventory -i inventory/hosts.yml --host web01
ansible-inventory -i inventory/hosts.yml --host web02
ansible all -i inventory/hosts.yml -m ping
```

> `--host` pokazuje finalny zestaw zmiennych hosta — widać, jak
> `dev.yml`/`prod.yml` nadpisują `all.yml` (variable precedence!).

## Krok 2 — Pętle

Otwórz `petle.yml` i uzupełnij miejsca oznaczone `# TODO`:

1. Katalogi aplikacji z listy `katalogi_aplikacji` (moduł `file` + `loop`)
2. Użytkownicy z listy słowników `uzytkownicy_aplikacji`
   (moduł `user`, `item.name` / `item.comment` / `item.shell`),
   ale **tylko aktywni** (`when: item.aktywny | bool`)
   i z czytelnym logiem (`loop_control: label`)
3. Task `stat` + `register` jest gotowy — dopisz raport brakujących
   plików: pętla po `konfigi.results`, warunek `not item.stat.exists`

```bash
ansible-playbook -i inventory/hosts.yml petle.yml --syntax-check
ansible-playbook -i inventory/hosts.yml petle.yml --check
ansible-playbook -i inventory/hosts.yml petle.yml
```

Weryfikacja:
```bash
ansible all -i inventory/hosts.yml -m command -a "ls -la /opt/sklep"
ansible all -i inventory/hosts.yml -m command -a "id deploy"
ansible all -i inventory/hosts.yml -m command -a "id stazysta"  # oczekiwany błąd!
```

## Krok 3 — Warunki

Otwórz `warunki.yml` i uzupełnij miejsca oznaczone `# TODO`:

1. Instalacja `ncdu` tylko na rodzinie Debian (`when` + fakt `ansible_os_family`)
2. Komunikat trybu debug — tylko gdy `app_debug` jest prawdą
   (pamiętaj o `| default(false) | bool`!)
3. Znacznik `PRODUKCJA` — tylko na hostach z grupy `prod`
   (zmienna specjalna `group_names`)
4. Ostrzeżenie o małym RAM na prod — **lista warunków** (działa jak AND)

```bash
ansible-playbook -i inventory/hosts.yml warunki.yml
```

Przeanalizuj wynik: które taski są `skipped` na web01, a które na web02 — i dlaczego?

## Krok 4 — Konfiguracja per środowisko

Otwórz `konfiguracja_srodowisk.yml` i uzupełnij `# TODO`:

1. Wygeneruj `/etc/szkolenie/app_env.conf` z **wspólnego** szablonu
   `templates/app_env.conf.j2` (obejrzyj go — zwróć uwagę na `default()`
   i `ternary()`)
2. Flaga backupu — tylko na prod

```bash
ansible-playbook -i inventory/hosts.yml konfiguracja_srodowisk.yml
```

Porównaj wyniki na obu hostach:
```bash
ansible all -i inventory/hosts.yml -m command -a "cat /etc/szkolenie/app_env.conf"
```

**Eksperyment — variable precedence w akcji:**
```bash
# -e bije WSZYSTKO — oba hosty dostana port 9999:
ansible-playbook -i inventory/hosts.yml konfiguracja_srodowisk.yml -e "app_port=9999"
ansible all -i inventory/hosts.yml -m command -a "grep port /etc/szkolenie/app_env.conf"

# Wroc do stanu z inventory:
ansible-playbook -i inventory/hosts.yml konfiguracja_srodowisk.yml
```

## Krok 5 — Idempotencja

Uruchom wszystkie trzy playbooki drugi raz — w `PLAY RECAP` oczekujemy `changed=0`.

## Krok 6 (bonus) — asystent AI

1. Poproś asystenta AI o dodanie do `konfiguracja_srodowisk.yml` obsługi
   nowego środowiska `qa` (2 repliki, log_level `info`).
2. Sprawdź jego odpowiedź: czy kazał Ci edytować playbook?
   Prawidłowa odpowiedź to **tylko** nowa grupa w inventory +
   `group_vars/qa.yml` — playbook ma zostać nietknięty
   (test dojrzałości z prezentacji!).

---

## Sprawdzenie

Po labie powinieneś umieć odpowiedzieć:
- Skąd web02 „wie", że jest produkcją? (dwie odpowiedzi: grupa + zmienna)
- Co wygrywa: `group_vars/all.yml`, `group_vars/prod.yml` czy `-e`?
- Dlaczego `when: app_debug` bez `| bool` to pułapka?
- Co zawiera `item.item` w pętli po `wynik.results`?
- Po co `loop_control: label` i co się dzieje w logu bez niego?

## Odpowiedzi

- `petle_odpowiedz.yml`
- `warunki_odpowiedz.yml`
- `konfiguracja_srodowisk_odpowiedz.yml`
- `inventory/group_vars/prod_odpowiedz.yml` (wzór dla prod.yml)
