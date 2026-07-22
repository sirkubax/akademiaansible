# LAB 7 — Inventory hybrydowe, vault, debugging (35 min)

## Cel
Zbudować inventory hybrydowe (statyczne + dynamiczne), zabezpieczyć sekret
w `ansible-vault` (domknięcie długu z projektu 6) i przećwiczyć debugging
typowych błędów.

## Środowisko
```
Ten lab działa w całości LOKALNIE (localhost). Nie potrzebujesz zdalnych
hostów ani konta w chmurze.
```

Przygotowanie:
```bash
source ~/venv-ansible/bin/activate
cd szkolenie8x4/lab7
```

---

## Część A — inventory hybrydowe (10 min)

Katalog `inventory/` łączy dwa źródła:
- `01-static.yml` — hosty wpisane ręcznie (statyczne)
- `02-dynamic.py` — skrypt zwracający hosty jako JSON (dynamiczne)

### Krok 1 — Obejrzyj oba źródła osobno
```bash
# Skrypt dynamiczny to zwykły program — uruchom go ręcznie:
./inventory/02-dynamic.py --list

# Cały katalog jako jedno inventory (Ansible SCALA źródła):
ansible-inventory -i inventory/ --graph
```
Zobacz, że w grafie są i hosty statyczne (`serwer-onprem-01`), i dynamiczne
(`app-dyn-01`, `app-dyn-02`) — z dwóch różnych źródeł, w jednym inventory.

### Krok 2 — Odpytaj hosty z obu źródeł
```bash
ansible -i inventory/ statyczne  -m ping
ansible -i inventory/ dynamiczne -m ping
ansible -i inventory/ all        -m debug -a "var=opis"   # z group_vars/all.yml
```

### Krok 3 — Rozbuduj (TODO)
1. W `inventory/01-static.yml` dopisz host `serwer-onprem-02` (patrz `# TODO`).
2. Sprawdź: `ansible-inventory -i inventory/ --graph` — host się pojawił.
3. (Do przeczytania) `inventory_aws_ec2.PRZYKLAD.yml` — jak wygląda prawdziwe
   dynamiczne inventory AWS (`keyed_groups`, `filters`). Nie uruchamiamy —
   wymaga kolekcji `amazon.aws` i poświadczeń AWS.

---

## Część B — vault: sekret z projektu 6 (15 min)

Domykamy dług ze spotkania 6: hasło bazy nie może leżeć jawnym tekstem.

### Krok 4 — Podaj hasło vaulta
Hasło do plików vault w tym labie to: **`szkolenie`** (jest w `.vault_pass.example`).
```bash
cp .vault_pass.example .vault_pass     # .vault_pass jest w .gitignore!
```

### Krok 5 — Obejrzyj wzorzec vars → vault
- `vault_demo/vars.yml` — JAWNE: `db_haslo: "{{ vault_db_haslo }}"`
- `vault_demo/vault.yml` — ZASZYFROWANE: zawiera `vault_db_haslo`

```bash
# Podejrzyj zaszyfrowany plik (nie zapisuje odszyfrowanego na dysk):
ansible-vault view vault_demo/vault.yml --vault-password-file .vault_pass

# Zobacz, że na dysku to szyfrogram AES256:
head -1 vault_demo/vault.yml
```

### Krok 6 — Uruchom playbook czytający sekret
```bash
cd vault_demo
ansible-playbook czytaj_sekret.yml --vault-password-file ../.vault_pass
# albo interaktywnie (wpisz: szkolenie):
ansible-playbook czytaj_sekret.yml --ask-vault-pass
cd ..
```
Zwróć uwagę: playbook potwierdza długość hasła, ale **nigdzie nie drukuje
jego wartości**; zapis pliku ma `no_log: true`. Sprawdź, że sekret trafił
do pliku, ale nie do logu:
```bash
sudo cat /tmp/szkolenie8x4/db_config.ini   # albo: cat (jeśli masz prawa)
```

### Krok 7 — encrypt_string (TODO)
Zaszyfruj pojedynczą wartość i wepnij ją do projektu:
```bash
ansible-vault encrypt_string 'super-tajny-klucz-api' --name 'vault_api_klucz' \
  --vault-password-file .vault_pass
```
Wklej wynikowy blok `vault_api_klucz: !vault | ...` do `vault_demo/vault.yml`
(przez `ansible-vault edit vault_demo/vault.yml --vault-password-file .vault_pass`),
odkomentuj `api_klucz` w `vars.yml` i uruchom ponownie `czytaj_sekret.yml`.

Ćwiczenia dodatkowe:
```bash
# Rotacja hasła vaulta:
ansible-vault rekey vault_demo/vault.yml --vault-password-file .vault_pass
# (potem podaj nowe hasło; pamiętaj zaktualizować .vault_pass)
```

---

## Część C — debugging (10 min)

`debuguj.yml` ma **3 zasiane błędy**. Debuguj iteracyjnie: napraw pierwszy,
uruchom ponownie, napraw kolejny.

```bash
ansible-playbook debuguj.yml
ansible-playbook debuguj.yml -vvv      # gdy potrzebujesz szczegółów
```

### Krok 8 — Znajdź i napraw
Podpowiedzi (nie patrz w odpowiedź od razu):

- **Błąd 1 — `'serwer_port' is undefined`.** Porównaj nazwę zmiennej w `vars:`
  z nazwą użytą w tasku. Klasyczna literówka.
- **Błąd 2 — task „TRYB DEBUG" wykonuje się mimo `wlacz_debug: "false"`.**
  Jakiego TYPU jest `"false"`? Przypomnij sobie pułapkę `| bool` ze spotkania 4.
- **Błąd 3 — task z `grep` kończy się `failed` (rc=1).** `grep -c` bez trafień
  zwraca 0 i kod wyjścia 1. Czy to naprawdę błąd? Przypomnij `failed_when`
  i `changed_when` ze spotkania 7 (Moduł 4).

Sprawdź się:
```bash
ansible-playbook debuguj_odpowiedz.yml
```

Dodatkowo — check-mode i jego pułapki:
```bash
ansible-playbook debuguj_odpowiedz.yml --check
```
Zastanów się: dlaczego task z `shell` może zachowywać się inaczej w `--check`?
(patrz prezentacja: Moduł 4, pułapki check-mode)

---

## Sprawdzenie

Po labie powinieneś umieć odpowiedzieć:
- Czym różni się inventory statyczne od dynamicznego? Kiedy hybryda?
- Jak Ansible scala kilka źródeł inventory w jednym katalogu?
- Dlaczego sekret rozdzielamy na `vars.yml` (jawne) + `vault.yml` (szyfrowane)?
- Czym różni się `ansible-vault encrypt` od `encrypt_string`?
- Po co `no_log: true`?
- Wymień 3 pułapki check-mode.
- Kiedy potrzebujesz `failed_when` / `changed_when`?

## Pliki TODO i odpowiedzi

| TODO                                    | Odpowiedź / weryfikacja                |
|-----------------------------------------|----------------------------------------|
| `inventory/01-static.yml` (host)        | `ansible-inventory -i inventory/ --graph` |
| `vault_demo/vars.yml` (api_klucz)       | Krok 7 (encrypt_string)                |
| `debuguj.yml`                           | `debuguj_odpowiedz.yml`                |
