# LAB 1 — Spotkanie 1: instalacja Ansible, inventory, ad-hoc, pierwszy playbook (45 min)

## Cel
Zainstalować Ansible, skonfigurować inventory, przetestować komunikację z hostami
poleceniami ad-hoc i uruchomić pierwszy playbook.

## Środowisko
```
Control node : maszyna lokalna (ten komputer)
Managed hosts: dostarczone przez prowadzącego (2 hosty)
```

---

## Krok 1 — Instalacja Ansible

Instalujemy w wirtualnym środowisku Pythona (venv) — nie zaśmieca systemu
i pozwala mieć różne wersje Ansible dla różnych projektów.

```bash
# Utwórz i aktywuj venv
python3 -m venv ~/venv-ansible
source ~/venv-ansible/bin/activate

# Zainstaluj Ansible
pip install --upgrade pip
pip install ansible

# Weryfikacja
ansible --version
ansible-playbook --version
```

Oczekiwany wynik (wersje mogą się różnić):
```
ansible [core 2.xx.x]
  python version = 3.x.x
```

> **Uwaga:** po otwarciu nowego terminala trzeba ponownie wykonać
> `source ~/venv-ansible/bin/activate`.

Alternatywne sposoby instalacji (do wiadomości — szczegóły na spotkaniu 2):
```bash
pipx install --include-deps ansible   # izolowana instalacja narzędzia
sudo apt install ansible              # pakiet systemowy (zwykle starsza wersja)
```

## Krok 2 — Utwórz inventory

Uzupełnij plik `inventory/hosts.yml` — dane hostów dostaniesz od prowadzącego.

```bash
vi inventory/hosts.yml    # albo otwórz w VS Code
```

Sprawdź strukturę inventory:
```bash
ansible-inventory -i inventory/hosts.yml --graph
ansible-inventory -i inventory/hosts.yml --list
```

## Krok 3 — Przetestuj połączenie

```bash
# Ping do wszystkich hostów
ansible all -i inventory/hosts.yml -m ping

# Ping tylko do grupy webservers
ansible webservers -i inventory/hosts.yml -m ping
```

Oczekiwany wynik:
```
web01 | SUCCESS => { "ping": "pong" }
web02 | SUCCESS => { "ping": "pong" }
```

> Jeśli dostajesz `UNREACHABLE` — sprawdź adres IP, użytkownika i klucz SSH
> w inventory. Pomocna jest flaga `-vvv` (szczegółowe logi połączenia).

## Krok 4 — Zbierz fakty o hostach

```bash
# Dystrybucja systemu
ansible all -i inventory/hosts.yml -m setup -a "filter=ansible_distribution*"

# Adres IP
ansible all -i inventory/hosts.yml -m setup -a "filter=ansible_default_ipv4"

# Ile RAM
ansible all -i inventory/hosts.yml -m setup -a "filter=ansible_memtotal_mb"
```

## Krok 5 — Zadania ad-hoc

```bash
# Sprawdź uptime hostów
ansible all -i inventory/hosts.yml -m command -a "uptime"

# Zajętość dysków
ansible all -i inventory/hosts.yml -m command -a "df -h"

# Utwórz katalog na hostach (z sudo)
ansible all -i inventory/hosts.yml -m file \
  -a "path=/tmp/szkolenie8x4 state=directory mode=0755" \
  --become

# Sprawdź że katalog istnieje
ansible all -i inventory/hosts.yml -m stat -a "path=/tmp/szkolenie8x4"

# Uruchom to samo polecenie file DRUGI raz — zwróć uwagę na
# kolor/status: za pierwszym razem CHANGED, za drugim SUCCESS (ok).
# To jest idempotencja w praktyce.
```

## Krok 6 — Pierwszy playbook

Otwórz plik `pierwszy_playbook.yml` i uzupełnij miejsca oznaczone `# TODO`.

```bash
# Sprawdź składnię
ansible-playbook -i inventory/hosts.yml pierwszy_playbook.yml --syntax-check

# Symulacja bez zmian na hostach
ansible-playbook -i inventory/hosts.yml pierwszy_playbook.yml --check --diff

# Uruchomienie właściwe
ansible-playbook -i inventory/hosts.yml pierwszy_playbook.yml
```

## Krok 7 — Sprawdzenie idempotencji

```bash
# Drugie uruchomienie powinno pokazać changed=0
ansible-playbook -i inventory/hosts.yml pierwszy_playbook.yml
```

Spójrz na podsumowanie `PLAY RECAP` — porównaj wartości `ok=` i `changed=`
z pierwszym uruchomieniem.

## Krok 8 (bonus) — asystent AI

Jeśli masz skonfigurowanego Copilota / asystenta AI w VS Code:

1. Poproś go o dodanie do playbooka taska instalującego pakiet `htop`.
2. Zweryfikuj wygenerowany kod: czy używa modułu (a nie `shell`)?
   Czy jest idempotentny?
3. Sprawdź parametry w dokumentacji: `ansible-doc package`.
4. Przetestuj: `--syntax-check`, `--check --diff`, uruchomienie.

---

## Sprawdzenie

Po labie powinieneś umieć odpowiedzieć:
- Czym różni się polecenie ad-hoc od playbooka?
- Co robi flaga `--become`?
- Jaka jest dystrybucja systemu na hostach i skąd to wiesz bez logowania się na nie?
- Po czym poznajesz, że playbook jest idempotentny?
- Co pokazuje `--check --diff` i dlaczego warto go używać przed wdrożeniem?

## Odpowiedź

Gotowe rozwiązanie playbooka znajdziesz w `pierwszy_playbook_odpowiedz.yml`.
