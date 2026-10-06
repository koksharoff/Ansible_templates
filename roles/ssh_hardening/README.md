# Role: ssh_hardening

Hardens the OpenSSH server with a drop-in file `/etc/ssh/sshd_config.d/00-hardening.conf`. The original `sshd_config` is not rewritten.

## What it does

- **Lockout guard:** fails before changing anything if the user Ansible connects with would be blocked (root login disabled while connecting as root, or user missing from `AllowUsers`).
- Key-only authentication, no root login, no empty passwords.
- Limits auth tries, login grace time, idle sessions; disables X11/agent/TCP forwarding.
- Every change is validated with `sshd -t` before it is written.
- Restarts `ssh`, or `ssh.socket` on socket-activated systems (Ubuntu 24.04+).

The `00-` prefix matters: sshd uses the first value it reads for each option, so this file wins over e.g. cloud-init's `50-cloud-init.conf`, which often turns `PasswordAuthentication` back on.

## Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `ssh_hardening_port` | `22` | SSH port |
| `ssh_hardening_listen_addresses` | `[]` | Bind addresses, empty = all |
| `ssh_hardening_permit_root_login` | `"no"` | `PermitRootLogin` |
| `ssh_hardening_password_authentication` | `false` | Password logins |
| `ssh_hardening_kbd_interactive_authentication` | `false` | Keyboard-interactive logins |
| `ssh_hardening_pubkey_authentication` | `true` | Public key logins |
| `ssh_hardening_max_auth_tries` | `3` | `MaxAuthTries` |
| `ssh_hardening_max_sessions` | `10` | `MaxSessions` |
| `ssh_hardening_login_grace_time` | `30` | `LoginGraceTime`, seconds |
| `ssh_hardening_client_alive_interval` | `300` | Idle check interval, seconds |
| `ssh_hardening_client_alive_count_max` | `2` | Missed checks before disconnect |
| `ssh_hardening_x11_forwarding` | `false` | X11 forwarding |
| `ssh_hardening_allow_tcp_forwarding` | `false` | TCP/port forwarding |
| `ssh_hardening_allow_agent_forwarding` | `false` | Agent forwarding |
| `ssh_hardening_log_level` | `VERBOSE` | Logs key fingerprints of logins |
| `ssh_hardening_allow_users` | `[]` | `AllowUsers`, empty = no restriction |
| `ssh_hardening_allow_groups` | `[]` | `AllowGroups`, empty = no restriction |
| `ssh_hardening_ciphers` / `_macs` / `_kex_algorithms` | `[]` | Crypto overrides, empty = distro defaults |

## Changing the port

Set `server_ssh_port` in the environment's `group_vars/all/main.yml`. It feeds sshd, UFW, fail2ban and `ansible_port`. For the first run after the change, pass the old port: `-e ansible_port=22`.
