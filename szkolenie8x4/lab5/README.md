# LAB 5 — Spotkanie 5: własna rola + Ansible Galaxy (65 min)

## Cel
Zbudować własną rolę `aplikacja_www` (struktura, defaults, tasks, handlers,
templates), użyć jej w playbooku, a następnie zainstalować gotową rolę
z Ansible Galaxy i porównać ją ze swoją.

## Środowisko
```
Control node : maszyna lokalna (venv z Ansible)
Managed hosts: dostarczone przez prowadzącego (2 hosty, Ubuntu)
               web01 = dev, web02 = prod (jak w Lab 4)
```

Przygotowanie:
```bash
source ~/venv-ansible/bin/activate
cd szkolenie8x4/lab5
vi inventory/hosts.yml     # uzupełnij adresy IP
ansible all -i inventory/hosts.yml -m ping
```

> Od tego labu piszemy moduły pełnymi nazwami (FQCN):
> `ansible.builtin.apt` zamiast `apt` — patrz prezentacja, Moduł 4.

---

## Część A — własna rola

### Krok 1 — Poznaj szkielet roli

Katalog `roles/aplikacja_www/` ma strukturę wygenerowaną przez
`ansible-galaxy role init` (możesz porównać, generując własny szkielet
na boku: `ansible-galaxy role init /tmp/proba_roli`).

```bash
tree roles/aplikacja_www
```

Zwróć uwagę:
- `templates/index.html.j2` — gotowy szablon; zauważ, że taski roli
  odwołują się do niego **bez** ścieżki `templates/`
- `vars/main.yml` — gotowe **stałe wewnętrzne** roli (nazwa pakietu
  i usługi). Dlaczego to nie jest w `defaults/`? (pytanie w Sprawdzeniu)

### Krok 2 — Uzupełnij rolę (miejsca `# TODO`)

1. `roles/aplikacja_www/defaults/main.yml` — trzy **parametry** roli
   (wszystkie z prefiksem `aplikacja_www_`!)
2. `roles/aplikacja_www/tasks/main.yml` — cztery taski:
   instalacja pakietu, port nasłuchu (lineinfile + notify),
   strona główna z szablonu, uruchomienie usługi
3. `roles/aplikacja_www/handlers/main.yml` — handler `restart apache`

### Krok 3 — Użyj roli w playbooku

Uzupełnij `site.yml` (sekcja `roles:`) i uruchom:

```bash
ansible-playbook -i inventory/hosts.yml site.yml --syntax-check
ansible-playbook -i inventory/hosts.yml site.yml --check --diff
ansible-playbook -i inventory/hosts.yml site.yml
```

Weryfikacja:
```bash
curl http://<IP_WEB01>/
curl http://<IP_WEB02>/
```

Porównaj strony: web01 ma tytuł z `group_vars/dev.yml`
(nadpisuje defaults roli!), web02 — domyślny z `defaults/main.yml`.

### Krok 4 — Handler w akcji

1. W `inventory/group_vars/dev.yml` odkomentuj `aplikacja_www_port: 8081`
2. Uruchom playbook ponownie — obserwuj: task portu zgłasza `changed`,
   a na końcu wykonuje się handler `restart apache` (tylko na web01!)
3. Sprawdź: `curl http://<IP_WEB01>:8081/`
4. Uruchom trzeci raz — `changed=0`, handler się NIE wykonuje. Dlaczego?

---

## Część B — Ansible Galaxy

### Krok 5 — Zainstaluj gotowe role

Obejrzyj `requirements.yml` (pinowane wersje!), potem:

```bash
ansible-galaxy role install -r requirements.yml
ansible-galaxy collection install -r requirements.yml
ansible-galaxy role list
```

### Krok 6 — Przeczytaj cudzy kod przed użyciem

```bash
tree ~/.ansible/roles/geerlingguy.apache
less ~/.ansible/roles/geerlingguy.apache/README.md
less ~/.ansible/roles/geerlingguy.apache/defaults/main.yml
less ~/.ansible/roles/geerlingguy.apache/tasks/main.yml
```

Porównaj ze swoją rolą i zapisz 3 rzeczy, które geerlingguy.apache
robi lepiej. Podpowiedzi: obsługa wielu dystrybucji (jak rozwiązano
apache2 vs httpd?), vhosty z listy słowników, rozdzielenie taskow
na pliki (`setup-Debian.yml`, `configure-Debian.yml`).

### Krok 7 (bonus) — Uruchom rolę z Galaxy

`site_galaxy.yml` jest kompletny — konfiguruje Apache przez
geerlingguy.apache na porcie 8082. Najpierw **tylko symulacja**:

```bash
ansible-playbook -i inventory/hosts.yml site_galaxy.yml --check --diff
```

Przeanalizuj plan zmian. Jeśli prowadzący potwierdzi — uruchom na ostro
i sprawdź `curl http://<IP>:8082/`.

### Krok 8 (bonus) — asystent AI

Poproś asystenta AI o rozszerzenie Twojej roli o zmienną
`aplikacja_www_admin_email` wyświetlaną w stopce strony.
Zweryfikuj: czy dodał ją do `defaults/main.yml` (nie `vars/`)?
Czy zachował prefiks roli? Czy zaktualizował szablon?

---

## Sprawdzenie

Po labie powinieneś umieć odpowiedzieć:
- Czym różni się `defaults/main.yml` od `vars/main.yml` i co trafia gdzie?
- Dlaczego zmienne roli mają prefiks `aplikacja_www_`?
- Skąd task roli „wie", gdzie szukać `index.html.j2` bez ścieżki?
- Kiedy handler się wykonuje, a kiedy nie — i po których taskach?
- Po co pinować wersje w `requirements.yml`?
- Czego zabrakło Twojej roli w porównaniu z geerlingguy.apache?

## Odpowiedzi

- `roles/aplikacja_www_odpowiedz/` — kompletna rola
- `site_odpowiedz.yml` — playbook używający roli z odpowiedzi
