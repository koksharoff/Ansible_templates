# Role: common

Baseline OS configuration applied to every server.

## What it does

| Area | Tag | Details |
| :--- | :--- | :--- |
| Packages | `packages` | apt cache, baseline + extra packages, optional safe upgrade, removal of unwanted packages |
| Hostname | `hostname` | Sets hostname and the `127.0.1.1` entry in `/etc/hosts` |
| Time | `time` | Timezone, chrony with configurable pools |
| Locale | `locale` | Generates the locale and sets `LANG` |
| Kernel | `sysctl` | Network hardening defaults in `/etc/sysctl.d/90-ansible.conf` |
| Journald | `journald` | Persistent journal with size and retention limits |
| MOTD | `motd` | Login banner with hostname and environment |

## Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `common_packages` | see defaults | Baseline packages |
| `common_packages_extra` | `[]` | Extra packages per environment or group |
| `common_packages_absent` | `[]` | Packages to purge |
| `common_upgrade_packages` | `false` | Run `apt upgrade` (safe) on every play |
| `common_manage_hostname` | `true` | Manage hostname |
| `common_hostname` | `inventory_hostname_short` | Short hostname |
| `common_domain` | `""` | Domain for the FQDN in `/etc/hosts` |
| `common_timezone` | `UTC` | Timezone |
| `common_ntp_enabled` | `true` | Install and configure chrony |
| `common_ntp_pools` | `[pool.ntp.org]` | NTP pools |
| `common_locale` | `en_US.UTF-8` | System locale |
| `common_sysctl_defaults` | see defaults | Baseline kernel parameters |
| `common_sysctl` | `{}` | Overrides/additions merged on top of the defaults |
| `common_journald_system_max_use` | `500M` | Max disk space for logs |
| `common_journald_max_retention` | `1month` | Max log age |
| `common_motd_enabled` | `true` | Install the MOTD banner |
| `common_motd_environment` | `server_environment` | Environment name shown at login |

## Example

```yaml
common_timezone: Europe/Moscow
common_packages_extra: [postgresql-client]
common_sysctl:
  vm.swappiness: 10
  net.core.somaxconn: 4096
```
