# Rola: aplikacja_www

Instaluje Apache i wdraża sparametryzowaną stronę główną.

## Zmienne (defaults)

| Zmienna                 | Domyślnie                | Opis                    |
|-------------------------|--------------------------|-------------------------|
| `aplikacja_www_port`    | `80`                     | port nasłuchu Apache    |
| `aplikacja_www_tytul`   | `Aplikacja szkoleniowa`  | tytuł strony głównej    |
| `aplikacja_www_docroot` | `/var/www/html`          | katalog strony          |

## Przykład użycia

```yaml
- hosts: webservers
  become: true
  roles:
    - role: aplikacja_www
      aplikacja_www_port: 8080
      aplikacja_www_tytul: "Moja aplikacja"
```

## Wymagania

Ubuntu (moduł apt). Handler `restart apache` restartuje usługę po zmianie portu.
