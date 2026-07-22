# Rola: aplikacja

Wdraża aplikację Flask przez Apache + mod_wsgi (Python 3, virtualenv).
Aplikacja łączy się z bazą MySQL i wyświetla nazwę serwera oraz status bazy.

## Zmienne (defaults)

| Zmienna       | Domyślnie              | Opis                          |
|---------------|------------------------|-------------------------------|
| `app_nazwa`   | `Aplikacja`            | tytuł strony                  |
| `app_port`    | `8080`                 | port nasłuchu Apache/aplikacji|
| `app_katalog` | `/var/www/aplikacja`   | katalog kodu aplikacji        |
| `app_venv`    | `.../venv`             | virtualenv aplikacji          |
| `app_log_dir` | `/var/log/aplikacja`   | katalog logów                 |

## Zmienne wymagane (z projektu / group_vars)

`db_user`, `db_haslo`, `db_nazwa` — dane logowania do bazy.
Adres bazy rola ustala sama: pierwszy host z grupy `databases` (przez `hostvars`).

## Wymagania

Ubuntu, host w grupie `databases` w inventory (dla adresu bazy),
zebrane fakty (`gather_facts: true`).
