# LAB 8 — Lookupy, delegacja, retry + AWX/Windows (20 min)

## Cel
Przećwiczyć praktyczne „ciekawostki": lookupy, delegowanie zadań (`delegate_to`,
`run_once`) i powtarzanie (`until`/`retries`). Na koniec — przeczytać, jak
wygląda AWX jako kod i orkiestracja Windows.

## Środowisko
```
Części A i B działają LOKALNIE (localhost + 2 lokalne hosty). Bez zdalnych maszyn.
Część C to pliki DO CZYTANIA (AWX i Windows wymagają osobnej infrastruktury).
```

Przygotowanie:
```bash
source ~/venv-ansible/bin/activate
cd szkolenie8x4/lab8
```

---

## Część A — lookupy (7 min)

Kluczowa intuicja: **lookup wykonuje się na CONTROL NODE** (Twojej maszynie /
serwerze AWX), a nie na hoście docelowym.

Otwórz `lookupy.yml` i uzupełnij `# TODO` (`file`, `password`, `first_found`):
```bash
ansible-playbook lookupy.yml
```

Obserwacje:
- `env` / `pipe` czytają środowisko i komendy Twojej maszyny
- `password` generuje hasło i **zapisuje je** — drugie uruchomienie zwróci to samo
- `first_found` wybiera pierwszy istniejący plik z listy kandydatów
  (typowe: `config-{{ env }}.j2` → `config-default.j2`)

Sprawdź się: `ansible-playbook lookupy_odpowiedz.yml`

## Część B — delegacja i powtarzanie (8 min)

Otwórz `delegacja.yml` i uzupełnij `# TODO`:
- `run_once: true` + `delegate_to: "{{ groups['appservers'][0] }}"` — zadanie
  (np. migracja bazy) wykona się **raz**, nie z każdego app-hosta
- `delegate_to: localhost` — rejestracja w monitoringu z control node
- `until` / `retries` / `delay` — pętla powtarzająca aż warunek spełniony

```bash
ansible-playbook -i inventory/hosts.yml delegacja.yml
```

Obserwacje:
- task „Migracja" pojawia się **raz**, mimo że w grupie są 2 hosty
- task monitoringu tworzy pliki dla `app-a` i `app-b`, ale wykonanie idzie
  przez control node (`delegate_to: localhost`)
- task `until` „udaje się za 3. razem" — zobacz w logu ponawianie
  (`FAILED - RETRYING ... (5 retries left)` aż licznik = 3)

Sprawdź się: `ansible-playbook -i inventory/hosts.yml delegacja_odpowiedz.yml`

## Część C — czytanie: AWX i Windows (5 min)

Te pliki **czytamy** (nie uruchamiamy — wymagają AWX / hosta Windows):

- `awx_jako_kod.PRZYKLAD.yml` — konfiguracja AWX jako kod (`awx.awx`):
  credential → project → inventory → job template → rola RBAC (`execute`).
- `windows.PRZYKLAD.yml` — moduły `win_*` i połączenie WinRM.

**Ćwiczenie (na papierze / w dyskusji):** weź swój projekt ze spotkania 6
(`site.yml` + role + inventory) i zmapuj go na pojęcia AWX:

| Twój projekt (spotkanie 6)      | Odpowiednik w AWX        |
|---------------------------------|--------------------------|
| repozytorium z `site.yml`+role  | **Project** (sync z Git) |
| `inventory/hosts.yml`           | **Inventory**            |
| klucz SSH + hasło vaulta        | **Credential**           |
| `ansible-playbook ... site.yml` | **Job Template** (Launch)|
| `-e "app_port=..."`             | **Survey** / extra vars  |
| „kto może odpalić na prod"      | **RBAC** (rola Execute)  |

---

## Sprawdzenie

Po labie powinieneś umieć odpowiedzieć:
- Gdzie wykonuje się lookup — na hoście docelowym czy control node?
- Czym różni się `lookup` od `query` przy pętlach?
- Do czego `run_once` i typowe użycie `delegate_to: localhost`?
- Jak `until`/`retries`/`delay` różni się od `loop`?
- Co w AWX odpowiada Twojemu `ansible-playbook ... site.yml`?
- Dlaczego operator z rolą **Execute** może uruchomić wdrożenie, nie widząc haseł?

## Pliki TODO i odpowiedzi

| TODO             | Odpowiedź                    |
|------------------|------------------------------|
| `lookupy.yml`    | `lookupy_odpowiedz.yml`      |
| `delegacja.yml`  | `delegacja_odpowiedz.yml`    |

---

## To ostatni lab — gratulacje!

Przeszedłeś drogę od `ansible all -m ping` (spotkanie 1) do 3-warstwowego
wdrożenia zarządzanego przez AWX (spotkanie 8). Dobrej automatyzacji!
