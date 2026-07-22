# Rola: loadbalancer

Instaluje nginx i konfiguruje go jako load balancer (round-robin) nad serwerami
aplikacji. Lista backendów budowana jest automatycznie z grupy `appservers`
w inventory (`groups` + `hostvars`).

## Zmienne (defaults)

| Zmienna   | Domyślnie | Opis                          |
|-----------|-----------|-------------------------------|
| `lb_port` | `80`      | port, na którym słucha nginx  |

## Zmienne wymagane (z projektu)

`app_port` — port serwerów aplikacji (backendów).
Grupa `appservers` w inventory — źródło listy backendów.

## Wymagania

Ubuntu, zebrane fakty na hostach `appservers` (dla ich adresów IP).
