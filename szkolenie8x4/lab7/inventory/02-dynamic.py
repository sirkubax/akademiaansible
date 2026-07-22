#!/usr/bin/env python3
"""Minimalne DYNAMICZNE inventory (skrypt).

Kontrakt skryptowego inventory:
  --list          → cale inventory jako JSON (grupy, hosty, _meta/hostvars)
  --host <nazwa>  → zmienne jednego hosta (tu: puste, bo damy je w _meta)

W realnym zyciu tutaj byloby odpytanie API chmury/CMDB. Na potrzeby labu
zwracamy dwa "wykryte" hosty (lokalne, wiec da sie na nich odpalic ping).
"""
import json
import sys

INVENTORY = {
    "dynamiczne": {
        "hosts": ["app-dyn-01", "app-dyn-02"],
    },
    "_meta": {
        "hostvars": {
            "app-dyn-01": {"ansible_host": "127.0.0.1", "ansible_connection": "local"},
            "app-dyn-02": {"ansible_host": "127.0.0.1", "ansible_connection": "local"},
        }
    },
}


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--list":
        print(json.dumps(INVENTORY, indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] == "--host":
        # Zmienne trzymamy w _meta, wiec per-host zwracamy pusty slownik
        print(json.dumps({}))
    else:
        sys.stderr.write("Uzycie: %s --list | --host <nazwa>\n" % sys.argv[0])
        sys.exit(1)


if __name__ == "__main__":
    main()
