# Role: firewall

Host firewall based on UFW.

## What it does

1. Installs UFW.
2. Allows SSH first (rate-limited by default), optionally only from given networks.
3. Opens the configured TCP/UDP ports and custom rules.
4. Applies the default policies (deny incoming, allow outgoing, deny routed).
5. Enables UFW.

Rules are only added, never removed automatically. To delete a rule, add it with `rule: deny`, or remove it by hand with `ufw delete`.

## Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `firewall_enabled` | `true` | Enable UFW |
| `firewall_default_incoming` | `deny` | Inbound policy |
| `firewall_default_outgoing` | `allow` | Outbound policy |
| `firewall_default_routed` | `deny` | Routed/forwarded policy |
| `firewall_logging` | `low` | UFW logging level |
| `firewall_ssh_port` | `22` | SSH port, always allowed |
| `firewall_ssh_allowed_sources` | `[any]` | Networks allowed to reach SSH |
| `firewall_ssh_rate_limit` | `true` | Use `limit` instead of `allow` for SSH |
| `firewall_allowed_tcp_ports` | `[]` | TCP ports/ranges open from anywhere |
| `firewall_allowed_udp_ports` | `[]` | UDP ports/ranges open from anywhere |
| `firewall_rules` | `[]` | Custom rules: `port`, `proto`, `src`, `dest`, `rule`, `comment` |

## Example

```yaml
# group_vars/web.yml
firewall_allowed_tcp_ports: [80, 443]

# group_vars/db.yml
firewall_rules:
  - { port: 5432, proto: tcp, src: 10.0.1.0/24, comment: "PostgreSQL from app subnet" }
```

> Docker publishes container ports through its own iptables chains, which bypass UFW.
