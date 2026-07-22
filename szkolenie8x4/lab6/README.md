# LAB 6 — Projekt "od zera do bohatera" (55 min, pair-programming)

## Cel
Jednym uruchomieniem `site.yml` postawić kompletne, 3-warstwowe środowisko:
**load balancer (nginx) → serwery aplikacji (Flask/apache) → baza danych (MySQL)**.
To capstone — łączy role, szablony, zmienne, `hostvars`/`groups`, handlery
i rolę z Galaxy z poprzednich pięciu spotkań.

## Architektura

```
   klient ──► nginx (LB, :80) ──► apache+Flask (:8080) x N ──► MySQL (:3306)
              loadbalancers        appservers                  databases
```

## Środowisko i CO-LOCATION
```
Control node : maszyna lokalna (venv z Ansible)
Managed hosts: 2 hosty od prowadzącego (Ubuntu)
```
Warstwy są 3, hosty 2 — dlatego w labie **hosty należą do kilku grup naraz**:
- `web01` = load balancer **+** baza **+** serwer aplikacji
- `web02` = serwer aplikacji

W produkcji każda warstwa to osobne maszyny. Szczegóły w `inventory/hosts.yml`.

Przygotowanie:
```bash
source ~/venv-ansible/bin/activate
cd szkolenie8x4/lab6
vi inventory/hosts.yml          # uzupełnij adresy IP (sekcja "wszystkie")
ansible all -i inventory/hosts.yml -m ping
```

---

## Krok 1 — Zainstaluj rolę bazy z Galaxy

```bash
ansible-galaxy role install -r requirements.yml
ansible-galaxy collection install -r requirements.yml
ansible-galaxy role list | grep mysql
```

Obejrzyj, jak `inventory/group_vars/databases.yml` (gotowe) wiąże zmienne
z `all.yml` (`db_nazwa`, `db_user`, `db_haslo`) z rolą `geerlingguy.mysql`.

## Krok 2 — Złóż orkiestrację: `site.yml`

Otwórz `site.yml` i uzupełnij trzy `# TODO` — **trzy play we właściwej
kolejności**: `databases` → `appservers` → `loadbalancers`.

> Dlaczego ta kolejność? Aplikacja przy starcie łączy się z bazą, a load
> balancer potrzebuje działających serwerów aplikacji. Warstwa niżej musi
> istnieć, zanim postawimy warstwę wyżej.

## Krok 3 — Spięcie aplikacja → baza (`hostvars`)

Otwórz `roles/aplikacja/templates/config.py.j2` i uzupełnij `DB_HOST` —
adres IP pierwszego hosta z grupy `databases`, odczytany z inventory:

```jinja2
DB_HOST = "{{ hostvars[groups['databases'][0]].ansible_default_ipv4.address }}"
```

## Krok 4 — Spięcie load balancer → aplikacje (`groups` + pętla)

Otwórz `roles/loadbalancer/templates/upstream.conf.j2` i zastąp linię
`server TODO:TODO;` pętlą budującą listę backendów z grupy `appservers`:

```jinja2
{% for h in groups['appservers'] %}
    server {{ hostvars[h].ansible_default_ipv4.address }}:{{ app_port }};
{% endfor %}
```

## Krok 5 — Postaw całe środowisko jednym poleceniem

```bash
ansible-playbook -i inventory/hosts.yml site.yml --syntax-check
ansible-playbook -i inventory/hosts.yml site.yml
```

Pierwsze uruchomienie potrwa dłużej (instalacja MySQL, apache, nginx, venv).
Obserwuj kolejność warstw w logu i handlery `restart apache` + `czekaj na port`.

## Krok 6 — Sprawdź, że działa (round-robin!)

```bash
# Adres load balancera = IP hosta web01 (grupa loadbalancers)
for i in $(seq 6); do curl -s http://<IP_WEB01>/ | grep -E 'Serwer|Baza'; done
```

Oczekiwany efekt: kolejne odpowiedzi pokazują na przemian `web01` i `web02`
jako "Serwer aplikacji", a każda linia "Baza: connected to ...".
To dowód, że cały stos działa z jednego uruchomienia.

## Krok 7 — Skalowanie bez zmian w kodzie

1. Gdyby prowadzący dał trzeci host — dodaj go do grupy `appservers`
   w `inventory/hosts.yml` (oraz adres w sekcji `wszystkie`).
2. Uruchom `site.yml` ponownie.
3. Zauważ: rola `aplikacja` stawia app na nowym hoście, a load balancer
   **sam** dodaje go do `upstream` (bo pętla iteruje po `groups['appservers']`).
   Zero ręcznej edycji konfiguracji nginx.

## Krok 8 — Debugging warstwami (z pomocą AI)

Zepsuj coś świadomie (np. w `group_vars/all.yml` ustaw `app_port: 8081`
tylko w LB, albo zatrzymaj MySQL) i diagnozuj **od dołu**:

```bash
# 1. Baza
ansible databases -i inventory/hosts.yml -m command -a "systemctl is-active mysql" --become
# 2. Aplikacja (z pominięciem LB — bezpośrednio na serwerze app)
ansible appservers -i inventory/hosts.yml -m uri -a "url=http://localhost:8080/" --become
# 3. Load balancer
ansible loadbalancers -i inventory/hosts.yml -m command -a "nginx -t" --become
```

Wklej komunikat błędu (Ansible lub `/var/log/apache2/error.log`) do asystenta AI
i poproś o wskazanie prawdopodobnej przyczyny — potem **zweryfikuj** jego trop
sam, zanim wprowadzisz poprawkę.

---

## Uruchomienie rozwiązania

Gotowy wariant (role `*_odpowiedz`, kompletne szablony):
```bash
ansible-playbook -i inventory/hosts.yml site_odpowiedz.yml
```

## Sprawdzenie

Po labie powinieneś umieć odpowiedzieć:
- Dlaczego kolejność play w `site.yml` to `databases → appservers → loadbalancers`?
- Jak aplikacja "wie", pod jakim adresem jest baza, skoro nigdzie go nie wpisujemy na sztywno?
- Jak lista backendów w nginx buduje się sama? Co się stanie po dodaniu `app03`?
- Po co `wait_for` w handlerze `restart apache`?
- Czemu apache słucha na 8080, a nie 80? (podpowiedź: co jeszcze działa na web01?)
- Gdzie w tym projekcie trafi hasło bazy po spotkaniu 7?

## Pliki TODO i odpowiedzi

| TODO                                             | Odpowiedź                                        |
|--------------------------------------------------|--------------------------------------------------|
| `site.yml`                                       | `site_odpowiedz.yml`                             |
| `roles/aplikacja/templates/config.py.j2`         | `roles/aplikacja_odpowiedz/templates/config.py.j2` |
| `roles/loadbalancer/templates/upstream.conf.j2`  | `roles/loadbalancer_odpowiedz/templates/upstream.conf.j2` |
