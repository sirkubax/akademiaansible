# Warsztat 2 — Szablony Jinja2 i zmienne (25 min)

## Cel
Wygenerować dynamiczny plik konfiguracyjny Apache Virtual Host przy użyciu szablonu Jinja2.
Różne hosty mają różne wartości zmiennych — efekt widoczny przez `--diff`.

## Uruchomienie

```bash
# Symulacja — sprawdź jakie pliki zostaną wygenerowane
ansible-playbook -i inventory/hosts.yml configure_vhost.yml --check --diff

# Uruchomienie właściwe
ansible-playbook -i inventory/hosts.yml configure_vhost.yml

# Sprawdzenie na hoście
ansible webservers -i inventory/hosts.yml -m command \
  -a "cat /etc/apache2/sites-available/myapp.conf" --become
```

## Zadania

### Krok 1 — Uzupełnij szablon

Otwórz `templates/apache_vhost.conf.j2` i uzupełnij miejsca `# TODO`.

Szablon ma używać:
- `ansible_fqdn` — pełna nazwa hosta (fakt Ansible)
- `ansible_hostname` — krótka nazwa (fakt Ansible)
- `apache_docroot` — katalog DocumentRoot (zmienna z group_vars)
- `apache_port` — port nasłuchu (zmienna z group_vars, domyślnie 80)

### Krok 2 — Uzupełnij group_vars

Edytuj `inventory/group_vars/webservers.yml`:
```yaml
apache_docroot: /var/www/myapp
apache_port: 80
```

### Krok 3 — Nadpisz zmienną dla jednego hosta

Edytuj `inventory/host_vars/web01.yml`:
```yaml
apache_docroot: /var/www/myapp_v2
```

### Krok 4 — Uzupełnij playbook

Otwórz `configure_vhost.yml` i uzupełnij task używający modułu `template`.

### Krok 5 — Weryfikacja różnic

```bash
# Uruchom --check --diff — powinieneś zobaczyć RÓŻNE DocumentRoot dla web01 i web02
ansible-playbook -i inventory/hosts.yml configure_vhost.yml --check --diff
```

## Odpowiedź

Gotowe rozwiązanie: `configure_vhost_odpowiedz.yml` i `templates/apache_vhost_odpowiedz.conf.j2`.
