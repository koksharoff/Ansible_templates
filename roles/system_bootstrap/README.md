# Role: system_bootstrap

First-run setup of a fresh Debian/Ubuntu server. It prepares the host so that all other playbooks can connect as a dedicated, key-only automation user instead of `root`.

## What it does

- Stops early if no SSH key is configured, so you cannot lock yourself out later.
- Installs `python3` with raw commands if the image does not have it, then gathers facts.
- Installs `sudo`.
- Creates the automation user (password login stays locked unless a hash is given).
- Authorizes the given SSH public keys (exclusive by default).
- Grants passwordless sudo via a validated file in `/etc/sudoers.d/`.

Timezone, packages and other OS settings moved to the [`common`](../common/README.md) role.

## Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `system_bootstrap_user` | `bootstrap_agent` | Automation user name |
| `system_bootstrap_user_shell` | `/bin/bash` | Login shell |
| `system_bootstrap_user_groups` | `[sudo]` | Supplementary groups |
| `system_bootstrap_ssh_keys` | `[]` | **Required.** Public SSH keys |
| `system_bootstrap_ssh_keys_exclusive` | `true` | Remove keys not in the list |
| `system_bootstrap_passwordless_sudo` | `true` | NOPASSWD sudo for the user |
| `system_bootstrap_user_password_hash` | `""` | Optional SHA-512 hash (keep in vault) |
| `system_bootstrap_install_python` | `true` | Install python3 if missing |

## Usage

The play must use `gather_facts: false`, because Python may not be installed yet. The role gathers facts itself.

```yaml
- name: Bootstrap fresh servers
  hosts: all
  gather_facts: false
  become: true
  vars:
    ansible_user: "{{ bootstrap_remote_user | default('root') }}"
  roles:
    - system_bootstrap
```

See [`playbooks/bootstrap.yml`](../../playbooks/bootstrap.yml).
