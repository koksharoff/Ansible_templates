# Role: fail2ban

Brute-force protection with fail2ban. The `sshd` jail is enabled by default. Other jails can be added through a variable.

Settings go to `/etc/fail2ban/jail.local`. Package files are not modified. The `systemd` backend is used because Debian 12+ no longer writes `/var/log/auth.log` by default.

## Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `fail2ban_bantime` | `1h` | Ban duration |
| `fail2ban_findtime` | `10m` | Window for counting failures |
| `fail2ban_maxretry` | `5` | Failures before a ban |
| `fail2ban_bantime_increment` | `true` | Longer bans for repeat offenders |
| `fail2ban_ignoreip` | `[127.0.0.1/8, ::1]` | Never banned. Add your VPN/office networks |
| `fail2ban_backend` | `systemd` | Log backend |
| `fail2ban_banaction` | `ufw` | Ban action; `nftables-multiport` without UFW |
| `fail2ban_sshd_enabled` | `true` | Enable the sshd jail |
| `fail2ban_sshd_port` | `22` | SSH port |
| `fail2ban_sshd_mode` | `normal` | `normal`, `ddos`, `extra`, `aggressive` |
| `fail2ban_jails` | `[]` | Extra jails, every key except `name` is written as-is |

## Example

```yaml
fail2ban_jails:
  - name: nginx-http-auth
    enabled: "true"
    port: "http,https"
    logpath: /var/log/nginx/error.log
```

Check status on a server with `sudo fail2ban-client status sshd`.
