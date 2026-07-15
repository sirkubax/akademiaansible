# LAB 2 — Spotkanie 2: struktury danych YAML i pierwsze kroki z Jinja (45 min)

## Cel
Przećwiczyć czytanie i używanie struktur danych YAML (listy, słowniki, zagnieżdżenia)
oraz podstawy Jinja2: dostęp do danych, filtry i pętle w szablonie.

## Środowisko
```
Ten lab wykonujemy LOKALNIE (hosts: localhost) — nie potrzebujesz zdalnych hostów.
Ćwiczymy sam język: YAML + Jinja2.
```

Przygotowanie (jeśli venv nie jest aktywny):
```bash
source ~/venv-ansible/bin/activate
cd szkolenie8x4/lab2
```

> Przy uruchamianiu bez inventory Ansible wypisze ostrzeżenie
> `provided hosts list is empty, only localhost is available` — to oczekiwane.

---

## Krok 1 — Analiza struktur danych

Otwórz plik `dane.yml` i odpowiedz na pytania (na papierze / w głowie):

1. Co jest **listą**, a co **słownikiem**?
2. Czym jest `uzytkownicy` — lista? słownik? lista słowników?
3. Czym jest `srodowiska` — jak dostać się do `db_host` środowiska `prod`?
4. Dlaczego `wersja: "2.5.1"` jest w cudzysłowie, a `port: 8080` nie?
5. Ilu użytkowników jest aktywnych (`aktywny: true`)?

Zweryfikuj, że plik jest poprawnym YAML-em:
```bash
python3 -c "import yaml; print(yaml.safe_load(open('dane.yml')))"
```

## Krok 2 — Dostęp do struktur danych

Otwórz `struktury_danych.yml` i uzupełnij miejsca oznaczone `# TODO` —
zastąp teksty `"TODO"` właściwymi wyrażeniami Jinja2.

```bash
# Playbook działa od razu (wyświetla TODO) — uruchamiaj po każdej zmianie
ansible-playbook struktury_danych.yml
```

Wskazówki:
```yaml
{{ slownik.klucz }}          # dostęp do klucza słownika
{{ slownik['klucz'] }}       # zapis alternatywny (równoważny)
{{ lista[0] }}               # pierwszy element listy (liczymy od 0!)
{{ lista_slownikow[1].pole } # pole drugiego elementu
```

## Krok 3 — Filtry Jinja2

Otwórz `jinja_filtry.yml` i uzupełnij miejsca oznaczone `# TODO`.

```bash
ansible-playbook jinja_filtry.yml
```

Filtry, których będziesz potrzebować:
```yaml
| default('wartość')          # gdy zmienna nie istnieje
| join(', ')                  # lista → tekst
| length                      # ilość elementów
| upper                       # wielkie litery
| map(attribute='pole')       # wyciągnij pole z listy słowników
| selectattr('pole')          # przefiltruj listę słowników
| list                        # domknięcie map/selectattr do listy
```

## Krok 4 — Pętla w szablonie: generowanie raportu

Otwórz `templates/raport.txt.j2` i uzupełnij miejsca oznaczone `TODO`.
Playbook `generuj_raport.yml` wygeneruje z szablonu plik tekstowy.

```bash
ansible-playbook generuj_raport.yml
cat /tmp/szkolenie8x4/raport.txt
```

Składnia pętli w szablonie:
```jinja2
{% for element in lista %}
 - {{ element.pole }}
{% endfor %}

{% for klucz, wartosc in slownik.items() %}
 - {{ klucz }}: {{ wartosc.pole }}
{% endfor %}
```

Oczekiwany raport zawiera:
- nagłówek z nazwą i wersją aplikacji,
- listę pakietów w jednej linii,
- listę użytkowników z rolą (nieaktywni oznaczeni `[NIEAKTYWNY]`),
- listę środowisk z `db_host` i liczbą replik.

## Krok 5 (bonus) — asystent AI

1. Poproś Copilota / asystenta AI o dodanie do raportu sekcji
   "Aktywni użytkownicy" (tylko `aktywny: true`, użyj `selectattr`).
2. Zweryfikuj wygenerowany kod i przetestuj ponownym uruchomieniem playbooka.
3. Zapytaj asystenta: "wyjaśnij różnicę między `map` a `selectattr` w Jinja2"
   — porównaj odpowiedź z tym, co zrobiłeś w Kroku 3.

---

## Sprawdzenie

Po labie powinieneś umieć odpowiedzieć:
- Jak dostać się do elementu listy, a jak do klucza słownika w Jinja2?
- Co zwraca `uzytkownicy | map(attribute='name')` i po co na końcu `| list`?
- Czym różni się `{{ }}` od `{% %}` w szablonie?
- Po co filtr `default()` i przed jakim błędem chroni?
- Gdzie w prawdziwym projekcie użyjesz szablonu `.j2`? (podpowiedź: spotkanie 3 —
  pliki konfiguracyjne usług)

## Odpowiedzi

- `struktury_danych_odpowiedz.yml`
- `jinja_filtry_odpowiedz.yml`
- `templates/raport_odpowiedz.txt.j2` — przetestuj:
  ```bash
  ansible-playbook generuj_raport.yml -e szablon=raport_odpowiedz.txt.j2
  ```
