# Agenda szkolenia Ansible – 8 spotkań × 4h

**Poziom:** podstawowy / średni  
**Format:** 8 spotkań po 4 godziny (32h łącznie)  
**Forma:** wykłady + laboratoria (pair-programming, ćwiczenia praktyczne)

---

## Spotkanie 1 – Wprowadzenie do Ansible (4h)

- Omówienie systemów orkiestracji
- Kiedy warto używać Ansible, (a kiedy Terraform) – z przykładami
- Czym jest Ansible
- Podstawy YAML i Jinja
- Struktury danych i ich znaczenie w playbookach
- Omówienie komponentów – zmienne, inventory, playbooki, moduły, zadania
- **Asystent do generowania kodu** - konfiguracja VS Code + copilot, stan narzędzi na dzisiaj, korzyści i pułapki generowania kodu przez AI 
- **Lab:** instalacja Ansible, konfiguracja inventory, uruchamianie pierwszych poleceń ad-hoc i playbooków

---

## Spotkanie 2 – Przygotowanie środowiska i pierwsze playbooki (4h)

- Sposoby instalacji Ansible
- Instalacja Ansible w 'sandbox', kwestie utrzymania środowiska przez wiele lat
- Konfiguracja połączenia do serwerów, konfiguracja Ansible inventory
- Praca z modułami uruchamianymi z linii komend (ad-hoc commands)
- Tworzenie pierwszych playbooków
- **Lab:** analiza przykładowych struktur danych YAML, pierwsze kroki z Jinja

---

## Spotkanie 3 – Operacje na systemach (4h)

*Skupienie na potrzebach klienta: zarządzanie pakietami, aktualizacje, partycjonowanie, konfiguracja, pliki*

- Instalacja i deinstalacja pakietów (moduły: `apt`, `yum`, `dnf`, `package`)
- Aktualizacja systemów
- Partycjonowanie dysków (moduły: `parted`, `filesystem`, `mount`, `lvg`, `lvol`)
- Konfiguracja pakietów – szablony (`template`), edycja plików (`lineinfile`, `blockinfile`)
- Kopiowanie i wysyłanie plików na serwer (`copy`, `template`, `synchronize`, `fetch`)
- **Lab:** playbooki realizujące typowe operacje administracyjne na systemach Linux

---

## Spotkanie 4 – Zmienne, warunki i pętle (4h)

- Praca ze zmiennymi (variables)
- Znaczenie umiejscowienia zmiennych względem ich 'zasięgu' w projekcie (variable precedence)
- Warunkowe wykonywanie zadań (`when`)
- Cykliczne wykonywanie zadań (`loop`)
- Parametryzacja zadań
- Dostosowywanie konfiguracji per środowisko
- **Lab:** budowa playbooków z logiką warunkową, pętlami i zmiennymi per środowisko

---

## Spotkanie 5 – Role i Ansible Galaxy (4h)

- Role – koncepcja, struktura, tworzenie
- Re-użycie wytworzonych komponentów
- Ansible Galaxy – omówienie repozytorium ról i kolekcji
- Użycie gotowych rozwiązań do szybkiego wdrażania kompletnych rozwiązań (np. klaster MySQL, Elasticsearch – z gotowych szablonów)
- Poznanie siły społeczności i sposobów na przyspieszenie pracy
- **Lab:** tworzenie własnej roli, instalacja i użycie ról z Ansible Galaxy

---

## Spotkanie 6 – Projekt "od zera do bohatera" (4h)

*Kompleksowe ćwiczenie łączące dotychczasową wiedzę*

- Przygotowanie deploymentu aplikacji od podstaw
- Tworzenie playbooków i przygotowywanie szablonów (template) konfiguracji
- Połączenie w całość wdrożenia aplikacji z bazą danych i loadbalancerem – w jednym przebiegu
- Prototypowanie i rozwiązywanie problemów z AI (ChatGPT/Copilot)
- **Lab:** pair-programming – budowa kompletnego środowiska aplikacyjnego

---

## Spotkanie 7 – Inventory, sekrety i debugging (4h)

- **Inventory** – statyczne, dynamiczne, hybrydowe
  - Układ inventory, podział na podfoldery
  - Dynamiczne inventory – przykłady użycia
- **Sekrety w IaaC**
  - Ansible-Vault i przykłady automatycznego ładowania sekretów
  - Koncepcja utrzymania sekretów w systemach zewnętrznych
- **Debugging**
  - Debugging pracy z Ansible (brakujące zmienne, błędy wykonania, błędy w zadaniach)
  - Analiza raportów wykonania, znaczenie trybu check-mode (i potencjalne pułapki)
- **Koncepcje pracy z wieloma środowiskami**
  - dev, test, QA, UAT, PROD – jak to wszystko połączyć i utrzymać
  - Kwestia lokalizacji zmiennych – gdzie je definiować
- **Lab:** konfiguracja inventory, vault, debugging przykładowych błędów

---

## Spotkanie 8 – AWX/Tower i dobre praktyki (4h)

- **Interfejs graficzny AWX/Tower**
  - Koncepcja pracy w małej i dużej organizacji
  - Omówienie modelu uprawnień RBAC
  - Przykłady uruchamiania kodu IaaC za pomocą interfejsu graficznego (web)
- **Ciekawostki i dobre praktyki**
  - Lookupy
  - Delegowanie zadań
  - Powtarzanie wykonania zadań
  - Orkiestracja systemu Windows – omówienie
- **Konsultacje** – wymiana doświadczeń, dyskusja, rozwiązywanie problemów zgłoszonych przez uczestników
- Podsumowanie szkolenia

---

### Uwagi

- Program może być dostosowany dynamicznie do potrzeb grupy/klienta
- Możliwość przeprowadzenia części laboratoriów w środowisku testowym (AWS lub Azure) klienta
- Tematy zgłoszone przez uczestników mogą rozszerzyć zakres poszczególnych spotkań
