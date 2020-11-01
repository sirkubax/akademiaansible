#PoC MVP
# https://www.facebook.com/groups/929970120367781/permalink/2821854424512665/

## Example 1
run dynamically some task for ALL groups defined in the inventory, one host per group at a time (in parallel for all groups)

It is like serial:1 - but in context of a group


This is achieved with async - you can print logs using results_file
Unfortunatelly I did not find a way to run (import_playbook) in a loop


RUN

```
cd szkolenie3
ansible-playbook playbooks/playgroups/play.yml -vvv --limit localhost -i etc/inv/inventory_groups
```


## Example 2
Simplified version that utilize import_playbook + predefined groups run_N where N should be >= MAX number of host in your biggest group.
Note if all hosts in a group are inaccessible, the play would be skipped (due to no available hosts).

```
cd szkolenie3
ansible-playbook  playbooks/playgroups/play_import_playbook.yml -i etc/inv/inventory_groups
```
