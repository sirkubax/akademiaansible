# LAB 1 — Playbook instalacji Apache (45 min)

## Cel
Napisać idempotentny playbook instalujący i konfigurujący Apache na grupie `webservers`.

## Uruchomienie

```bash
# Sprawdź składnię
ansible-playbook -i ../lab0_w1/inventory/hosts.yml install_apache.yml --syntax-check

# Symulacja bez zmian
ansible-playbook -i ../lab0_w1/inventory/hosts.yml install_apache.yml --check --diff

# Uruchomienie właściwe
ansible-playbook -i ../lab0_w1/inventory/hosts.yml install_apache.yml

# Weryfikacja
curl http://<IP_HOSTA>/app/
```

## Zadania

Otwórz plik `install_apache.yml` i uzupełnij miejsca oznaczone `# TODO`.

### Krok 1 — Instalacja Apache
Zainstaluj pakiet `apache2` z aktualizacją cache.  
Wskazówka: moduł `apt`, parametry `update_cache`, `cache_valid_time`.

### Krok 2 — Uruchomienie usługi
Upewnij się że Apache jest uruchomiony i startuje przy restarcie systemu.  
Wskazówka: moduł `service`, parametry `state: started`, `enabled: true`.

### Krok 3 — Katalog aplikacji
Utwórz katalog `/var/www/html/app/` z właścicielem `www-data`.  
Wskazówka: moduł `file`, `state: directory`.

### Krok 4 — Strona główna
Skopiuj plik `files/index.html` do `/var/www/html/app/index.html`.  
Wskazówka: moduł `copy`.

### Krok 5 — Handler
Dodaj handler, który przeładuje Apache gdy zmieni się konfiguracja.  
Powiąż go z taskiem kopiowania przez `notify`.

### Krok 6 — Warunek (rozszerzenie)
Dodaj wsparcie dla RedHat: nazwa pakietu to `httpd`, usługi też `httpd`.  
Wskazówka: `when: ansible_os_family == "Debian"` / `"RedHat"`.

## Sprawdzenie idempotencji

```bash
# Drugie uruchomienie powinno pokazać CHANGED = 0
ansible-playbook -i ../lab0_w1/inventory/hosts.yml install_apache.yml
```

## Odpowiedź

Gotowe rozwiązanie znajdziesz w `install_apache_odpowiedz.yml`.
