# Ansible Server Baseline

Ansible project that turns a freshly installed **Debian / Ubuntu** server into a secured, consistently configured host, for several environments: **dev**, **stage** and **prod**.

All environments use the same roles. Only the variables differ, so dev, stage and prod do not drift apart.

## What it does

| Role | Purpose |
| :--- | :--- |
| [`system_bootstrap`](roles/system_bootstrap/README.md) | First run on a new server: installs Python, creates the automation user, its SSH key and passwordless sudo |
| [`common`](roles/common/README.md) | Baseline packages, hostname, timezone, NTP (chrony), locale, kernel `sysctl` hardening, journald retention, MOTD |
| [`users`](roles/users/README.md) | Admin accounts, SSH keys, sudo rights; also removes accounts |
| [`ssh_hardening`](roles/ssh_hardening/README.md) | Key-only SSH, no root login, sane timeouts; guards against locking yourself out |
| [`firewall`](roles/firewall/README.md) | UFW: deny inbound by default; SSH is always allowed before the policy is applied |
| [`fail2ban`](roles/fail2ban/README.md) | Brute-force protection (sshd jail, extensible) |
| [`unattended_upgrades`](roles/unattended_upgrades/README.md) | Automatic security updates, optional automatic reboot |

**Supported OS:** Ubuntu 22.04 / 24.04, Debian 12 / 13.
**Requirements on the control node:** `ansible-core >= 2.15`, Python 3, SSH access to the servers.

## Project layout

```text
.
├── ansible.cfg                  # Project settings (default inventory = dev)
├── requirements.yml             # Required Ansible collections
├── Makefile                     # Shortcuts: make check / deploy / bootstrap ...
├── inventories/
│   ├── dev/
│   │   ├── hosts.yml            # Hosts of the environment, grouped by function
│   │   └── group_vars/
│   │       ├── all/
│   │       │   ├── main.yml     # Settings for the whole environment
│   │       │   └── vault.yml    # Encrypted secrets (you create it, see "Secrets")
│   │       ├── web.yml          # Settings for the "web" group
│   │       └── db.yml           # Settings for the "db" group
│   ├── stage/                   # Same structure
│   └── prod/                    # Same structure
├── playbooks/
│   ├── bootstrap.yml            # Run once per new server (as root / cloud user)
│   ├── base.yml                 # Baseline roles for every server
│   └── site.yml                 # Main entry point (imports base.yml + future playbooks)
└── roles/
    └── <role>/
        ├── defaults/main.yml    # Safe defaults, meant to be overridden
        ├── tasks/main.yml
        ├── handlers/main.yml
        ├── templates/
        ├── meta/main.yml
        ├── meta/argument_specs.yml  # Variable types, validated on every run
        └── README.md
```

### How environments work

- **One inventory directory per environment.** You choose the environment with `-i inventories/<env>/hosts.yml`. Without `-i`, `ansible.cfg` falls back to **dev**, so you cannot hit prod by accident.
- **Group names are the same everywhere** (`web`, `db`, ...). Playbooks target groups and never need to know which environment they run in.
- **Where to put variables** (lowest to highest priority):
  1. `roles/<role>/defaults/main.yml`: secure baseline shared by all environments
  2. `inventories/<env>/group_vars/all/`: environment-wide settings
  3. `inventories/<env>/group_vars/<group>.yml`: settings for one group, e.g. open ports 80/443 on `web`
  4. `inventories/<env>/host_vars/<host>.yml`: one-off settings for a single host (create when needed)

Out of the box the environments differ as follows:

| Setting | dev | stage | prod |
| :--- | :--- | :--- | :--- |
| Debug tools (`strace`, `tcpdump`, ...) | yes | no | no |
| SSH TCP forwarding | allowed | denied | denied |
| fail2ban | 10 retries / 10m ban | 5 / 1h | 3 / 24h |
| Automatic reboot after updates | yes (05:00) | yes (03:00) | **no**, planned manually |
| journald size | 200M | 500M | 2G, 3 months |
| MOTD banner | DEV | STAGE | PROD + warning |

## Quick start

### 1. Install dependencies

```bash
python3 -m pip install ansible-core       # or: brew install ansible
make deps                                 # ansible-galaxy collection install -r requirements.yml
```

### 2. Describe your servers

Edit `inventories/<env>/hosts.yml`:

```yaml
all:
  children:
    web:
      hosts:
        dev-web-01:
          ansible_host: 10.0.0.11
    db:
      hosts:
        dev-db-01:
          ansible_host: 10.0.0.21
```

Use valid DNS names for hosts (letters, digits, `-`). The inventory name becomes the server's hostname.

### 3. Add your SSH key (required)

In `inventories/<env>/group_vars/all/main.yml`:

```yaml
admin_ssh_keys:
  - "ssh-ed25519 AAAAC3Nza... you@laptop"
```

Without at least one key the bootstrap stops on purpose, because password login is disabled later.

### 4. Bootstrap new servers (once per server)

The first run connects as `root` (or the image's default user) and creates the automation user `bootstrap_agent`:

```bash
# root with an SSH key
ansible-playbook -i inventories/dev/hosts.yml playbooks/bootstrap.yml

# root with a password (needs sshpass on the control node)
ansible-playbook -i inventories/dev/hosts.yml playbooks/bootstrap.yml --ask-pass

# cloud images that ship with a sudo user instead of root
ansible-playbook -i inventories/dev/hosts.yml playbooks/bootstrap.yml -e bootstrap_remote_user=ubuntu
```

### 5. Apply the baseline

From now on Ansible connects as `bootstrap_agent`:

```bash
make check ENV=dev        # dry run with diff, changes nothing
make deploy ENV=dev       # apply
```

Run in this order: **dev → stage → prod**.

## Everyday usage

### Make targets

| Command | What it does |
| :--- | :--- |
| `make deps` | Install required collections |
| `make lint` | `yamllint` + `ansible-lint` |
| `make syntax ENV=stage` | Syntax-check playbooks against an environment |
| `make ping ENV=stage` | Check connectivity |
| `make check ENV=stage` | Dry run (`--check --diff`) |
| `make deploy ENV=stage` | Apply `site.yml` |
| `make bootstrap ENV=stage` | Run `bootstrap.yml` |
| `make deploy ENV=prod CONFIRM=yes` | Prod requires explicit confirmation |

Optional arguments: `LIMIT=<host|group>`, `TAGS=<tag,...>`, `ARGS='<any ansible-playbook flags>'`.

```bash
make deploy ENV=stage LIMIT=web TAGS=firewall
make check  ENV=prod  LIMIT=prod-db-01 ARGS='-vv'
```

### Plain ansible-playbook

```bash
ansible-playbook -i inventories/prod/hosts.yml playbooks/site.yml --check --diff
ansible-playbook -i inventories/prod/hosts.yml playbooks/site.yml --limit prod-web-01
ansible-playbook -i inventories/prod/hosts.yml playbooks/site.yml --tags ssh,firewall
```

### Tags

| Tag | Scope |
| :--- | :--- |
| `common` | Whole `common` role; sub-tags: `packages`, `hostname`, `time`, `locale`, `sysctl`, `journald`, `motd` |
| `users` | User accounts |
| `ssh` | SSH server hardening |
| `firewall` | UFW |
| `fail2ban` | fail2ban |
| `updates` | unattended-upgrades |
| `bootstrap` | `system_bootstrap` (only in `bootstrap.yml`) |

## Secrets

Keep passwords, tokens and password hashes in an **encrypted** `vault.yml` next to the environment's `main.yml`. Prefix secret variables with `vault_` and reference them from the plain files, so it is always obvious where a value comes from.

```bash
# create / edit
ansible-vault create inventories/prod/group_vars/all/vault.yml
ansible-vault edit   inventories/prod/group_vars/all/vault.yml
```

```yaml
# vault.yml (encrypted)
vault_users_alice_password_hash: "$6$rounds=..."      # mkpasswd -m sha-512
```

```yaml
# main.yml (plain text)
users_list:
  - name: alice
    groups: [sudo]
    ssh_keys: "{{ admin_ssh_keys }}"
    password_hash: "{{ vault_users_alice_password_hash }}"
```

Run playbooks with `--ask-vault-pass`, or put the password in `.vault_pass` (already in `.gitignore`) and enable `vault_password_file` in `ansible.cfg`. Use a different vault password per environment if dev and prod are managed by different people.

## Extending the project

### Add an environment

```bash
cp -r inventories/stage inventories/qa
# edit inventories/qa/hosts.yml and set server_environment: qa in group_vars/all/main.yml
make check ENV=qa
```

### Add a role

```bash
ansible-galaxy role init --init-path roles nginx
```

Then:

1. Prefix every variable with the role name (`nginx_port`, not `port`).
2. Put safe defaults in `defaults/main.yml` and describe them in `meta/argument_specs.yml`.
3. Use fully qualified module names (`ansible.builtin.template`) and give every task a `name`.
4. Make it idempotent: a second run must report `changed=0`.
5. Create a playbook (e.g. `playbooks/web.yml` targeting `hosts: web`) and import it in `site.yml`.
6. Run `make lint`.

## Safety notes

- **Do not lock yourself out.** The `ssh_hardening` role refuses to run if the configuration would block the user Ansible connects with. Still, before restricting `firewall_ssh_allowed_sources` or `ssh_hardening_allow_users`, make sure the machine running Ansible is allowed.
- **Changing the SSH port** is done in one place, `server_ssh_port`. Ansible then connects on the new port right away, so first change the port with `-e ansible_port=<old port>`, then run normally.
- **Always run `make check` first**, especially on prod, and roll out in the order dev → stage → prod.
- `firewall` uses UFW. Docker writes its own iptables rules and bypasses UFW for published container ports, so plan firewalling for Docker hosts separately.

## Linting

```bash
pip install -r requirements-dev.txt
make lint
```

The project passes `ansible-lint` with the `production` profile.

### CI

[`.github/workflows/lint.yml`](.github/workflows/lint.yml) runs on every push and pull request to `main`:

| Job | Checks |
| :--- | :--- |
| `yamllint` | YAML formatting of the whole repository |
| `ansible-lint` | Ansible best practices (`production` profile) |
| `syntax-check` | `bootstrap.yml` and `site.yml` against each environment: dev, stage, prod |

Run the same checks locally with `make lint` and `make syntax ENV=<env>` before pushing.

## License

MIT
