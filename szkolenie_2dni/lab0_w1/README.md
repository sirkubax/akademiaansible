# Warsztat 1 — Pierwsze połączenia (20 min)

## Cel
Skonfigurowanie inventory i przetestowanie komunikacji z hostami przez polecenia ad-hoc.

## Środowisko
```
Control node : maszyna lokalna (ten komputer)
Managed hosts: dostarczone przez prowadzącego (2 hosty)
```

## Krok 1 — Utwórz inventory

Uzupełnij plik `inventory/hosts.yml` — dane hostów dostaniesz od prowadzącego.

```bash
vi inventory/hosts.yml
```

## Krok 2 — Przetestuj połączenie

```bash
# Sprawdź składnię inventory
ansible-inventory -i inventory/hosts.yml --graph

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

## Krok 3 — Zbierz fakty

```bash
# Dystrybucja systemu
ansible all -i inventory/hosts.yml -m setup -a "filter=ansible_distribution*"

# Adres IP
ansible all -i inventory/hosts.yml -m setup -a "filter=ansible_default_ipv4"

# Ile RAM
ansible all -i inventory/hosts.yml -m setup -a "filter=ansible_memtotal_mb"
```

## Krok 4 — Zadania ad-hoc

```bash
# Sprawdź uptime hostów
ansible all -i inventory/hosts.yml -m command -a "uptime"

# Wylistuj zainstalowane pakiety (bez sudo)
ansible all -i inventory/hosts.yml -m command -a "dpkg -l | grep nginx"

# Utwórz katalog na hostach (z sudo)
ansible all -i inventory/hosts.yml -m file \
  -a "path=/tmp/szkolenie_ansible state=directory mode=0755" \
  --become

# Sprawdź że katalog istnieje
ansible all -i inventory/hosts.yml -m stat -a "path=/tmp/szkolenie_ansible"
```

## Krok 5 — Wylistuj grupy

```bash
ansible-inventory -i inventory/hosts.yml --list
ansible-inventory -i inventory/hosts.yml --graph
```

## Sprawdzenie

Po warsztacie powinieneś umieć odpowiedzieć:
- Ile hostów jest w grupie `webservers`?
- Jaka jest dystrybucja systemu na hostach?
- Co robi flaga `--become`?
