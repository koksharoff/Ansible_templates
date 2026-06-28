# Ansible Role: System Bootstrap

This role performs the initial configuration on a clean Debian/Ubuntu server. It secures the system, updates package caches, configures timezones, and sets up a dedicated automation user.

## Features

- Updates `apt` package cache.
- Sets the system timezone and restarts `cron`.
- Creates a dedicated bootstrap/automation user with a secure password hash.
- Configures passwordless `sudo` access via a validated custom file in `/etc/sudoers.d/`.
- Adds an authorized SSH public key for passwordless, secure access.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `system_bootstrap_update_cache` | `true` | Whether to update the apt package cache. |
| `system_bootstrap_timezone` | `"UTC"` | System timezone (e.g., `Europe/Moscow`). |
| `system_bootstrap_user` | `"bootstrap_agent"` | The name of the automation user to create. |
| `system_bootstrap_ssh_key` | `""` | The public SSH key to authorize for the bootstrap user. |

## Dependencies

None.

## Example Playbook

An example of how to use this role in a playbook (e.g., `deploy.yml`):

```yaml
---
- name: Deploy base system configuration
  hosts: all
  become: true
  roles:
    - system_bootstrap