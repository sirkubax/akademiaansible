# LAB 2 — Warsztat końcowy: aplikacja z rolami (60 min)

## Cel
Zrefaktoryzować playbook z LAB 1 do projektu opartego na rolach.
Na końcu wywołać rolę z parametrem (inny port dla różnych hostów).

## Struktura projektu (do zbudowania)

```
lab2/
├── inventory/
│   ├── hosts.yml
│   ├── group_vars/webservers.yml
│   └── host_vars/web01.yml
├── roles/
│   └── webserver/
│       ├── defaults/main.yml     ← zmienne domyslne roli
│       ├── handlers/main.yml     ← handler reload
│       ├── tasks/main.yml        ← logika instalacji
│       ├── templates/
│       │   └── vhost.conf.j2     ← szablon (z Warsztatu 2)
│       ├── files/
│       │   └── index.html        ← strona (z LAB 1)
│       └── meta/main.yml         ← metadane roli
├── requirements.yml              ← zaleznosci Galaxy
└── site.yml                      ← punkt wejscia
```

## Kroki

### Krok 1 — Zainicjalizuj rolę

```bash
cd lab2
ansible-galaxy role init roles/webserver
```

### Krok 2 — Uzupełnij defaults roli

Edytuj `roles/webserver/defaults/main.yml` — zdefiniuj zmienne z sensownymi domyślnymi:
- `webserver_port` (domyślnie 80)
- `webserver_docroot` (domyślnie `/var/www/html`)
- `webserver_package` (domyślnie `apache2`)
- `webserver_service` (domyślnie `apache2`)

### Krok 3 — Przenieś taski do roli

Skopiuj taski z LAB 1 do `roles/webserver/tasks/main.yml`.  
Zastąp hardcodowane wartości zmiennymi z `defaults/`.

### Krok 4 — Przenieś handler

Skopiuj handler z LAB 1 do `roles/webserver/handlers/main.yml`.

### Krok 5 — Przenieś szablon i plik

- Skopiuj `templates/apache_vhost.conf.j2` z lab_w2 do `roles/webserver/templates/vhost.conf.j2`
- Skopiuj `files/index.html` z LAB 1 do `roles/webserver/files/index.html`

### Krok 6 — Wywołaj rolę z site.yml

Uzupełnij `site.yml` — wywołaj rolę `webserver` dla grupy `webservers`.

### Krok 7 — Różne porty dla hostów

W `inventory/host_vars/web01.yml` nadpisz port:
```yaml
webserver_port: 8080
```

### Krok 8 — Dodaj wymagania Galaxy

Uzupełnij `requirements.yml` i zainstaluj rolę geerlingguy.apache:
```bash
ansible-galaxy install -r requirements.yml
```

### Krok 9 — Uruchom i zweryfikuj

```bash
ansible-playbook -i inventory/hosts.yml site.yml --check --diff
ansible-playbook -i inventory/hosts.yml site.yml

# Sprawdz porty
curl http://web01:80/
curl http://web01:8080/    # jesli web01 ma webserver_port: 8080
curl http://web02:80/
```

## Sprawdzenie idempotencji

```bash
# Drugie uruchomienie — CHANGED powinno byc 0
ansible-playbook -i inventory/hosts.yml site.yml
```

## Odpowiedź

Gotowe rozwiązanie: rola `roles/webserver_odpowiedz/` i `site_odpowiedz.yml`.
