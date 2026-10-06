# Role: unattended_upgrades

Automatic installation of **security** updates with `unattended-upgrades`.

## What it does

- Installs `unattended-upgrades` and `apt-listchanges`.
- Enables the daily apt timer (`20auto-upgrades`).
- Configures `50unattended-upgrades`: allowed origins (security only by default, chosen per distribution), blacklist, cleanup, automatic reboot and mail report.

## Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `unattended_upgrades_enabled` | `true` | Enable automatic upgrades |
| `unattended_upgrades_origins` | security origins of the distro | `Origins-Pattern` entries |
| `unattended_upgrades_package_blacklist` | `[]` | Packages (regex) never upgraded automatically |
| `unattended_upgrades_remove_unused_dependencies` | `true` | Autoremove after upgrade |
| `unattended_upgrades_remove_unused_kernels` | `true` | Remove old kernels |
| `unattended_upgrades_automatic_reboot` | `false` | Reboot when required |
| `unattended_upgrades_automatic_reboot_time` | `04:00` | Reboot time |
| `unattended_upgrades_mail` | `""` | Report recipient (needs an MTA) |
| `unattended_upgrades_mail_report` | `on-change` | `always`, `only-on-error`, `on-change` |

## Example

```yaml
# Do not touch the database engine automatically
unattended_upgrades_package_blacklist:
  - "postgresql-.*"
```

Test the configuration on a server with `sudo unattended-upgrade --dry-run --debug`.
