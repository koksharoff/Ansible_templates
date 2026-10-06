# Role: users

Manages local admin accounts, their SSH keys and sudo rights.

## Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `users_list` | `[]` | Accounts to manage (see below) |
| `users_default_shell` | `/bin/bash` | Shell when a user sets none |
| `users_default_groups` | `[]` | Groups when a user sets none |
| `users_ssh_keys_exclusive` | `true` | Remove keys not listed for the user |
| `users_remove_home` | `false` | Delete home directories of removed users |

Fields of a `users_list` item:

| Field | Required | Description |
| :--- | :--- | :--- |
| `name` | yes | Login name |
| `state` | no | `present` (default) or `absent` |
| `comment` | no | Full name |
| `shell` | no | Login shell |
| `groups` | no | Supplementary groups, e.g. `[sudo]` |
| `ssh_keys` | no | List of public keys |
| `sudo_nopasswd` | no | Passwordless sudo (default `false`) |
| `password_hash` | no | SHA-512 hash, set only when the user is created. Keep it in vault |

## Example

```yaml
users_list:
  - name: alice
    comment: "Alice Smith"
    groups: [sudo]
    ssh_keys:
      - "ssh-ed25519 AAAAC3Nza... alice@laptop"
    password_hash: "{{ vault_users_alice_password_hash }}"
  - name: deploy
    ssh_keys:
      - "ssh-ed25519 AAAAC3Nza... ci"
    sudo_nopasswd: true
  - name: bob
    state: absent
```

> Do not list the automation user (`bootstrap_agent`) here. It is managed by `system_bootstrap`, and this role would revoke its sudo rights.

A user in the `sudo` group without `password_hash` and without `sudo_nopasswd` cannot use sudo, because there is no password to type.
