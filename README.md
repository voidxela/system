# System Standardization Playbook

This repository contains an idempotent, automated Ansible architecture for standardizing Linux environments. It is designed to scale seamlessly from local development workstations (Ultramarine/Fedora) to headless cloud infrastructure (Rocky/RHEL), providing a lean, highly performant, and deeply customized CLI experience.

## 🏗 Architecture

The playbook uses a role-based architecture combined with strict execution tags to ensure servers remain bloat-free while local workstations get the full suite of development tools.

* **`roles/base` (Runs Everywhere):** Provisions the core environment. Evicts default cloud users (UID 1000), enforces passwordless `sudo`, hardens SSH, bootstraps Zsh with Starship and Antidote, and installs modern CLI utilities (`eza`, `bat`, `fd`, `rg`, `fzf`).
* **`roles/dev` (Workstations Only):** Installs and configures development-specific tooling, including the Helix editor and `mise` for native, shim-free runtime version management.

## ✨ The Hash-Tracking Engine

This playbook features a custom dotfile tracking engine. It generates a SHA-1 hash of your configuration files (like `~/.zshrc` and Helix's `config.toml`) after deploying them.

On subsequent runs, if the playbook detects that you have modified a managed file manually outside of Ansible:

* **Headless Mode:** It will safely skip the file to protect your uncommitted changes and print a warning.
* **Interactive Mode:** It will pause execution, display a unified diff of your local changes versus the Ansible template, and prompt you to either overwrite or retain your manual edits.

## 🚀 Deployment

### 1. Local Workstation Bootstrap

To provision a fresh desktop or update your existing local environment, run the bootstrap script directly. This will install Ansible, clone the repository, and execute the playbook interactively.

```bash
curl -fsSL https://raw.githubusercontent.com/voidxela/system-config/main/bootstrap.sh | bash

```

*Note: This runs in interactive mode, so if local drift is detected in your dotfiles, you will be prompted with a diff.*

### 2. Cloud VPS Provisioning (Zero-Touch)

To deploy this configuration to a fresh cloud server automatically on boot, paste the following YAML into the **User Data / cloud-init** field when creating the instance:

```yaml
#cloud-config
package_update: true
packages:
  - git
  - ansible-core
runcmd:
  - git clone --quiet https://github.com/voidxela/system-config.git /root/system-config
  - cd /root/system-config
  - ansible-playbook -i "localhost," -c local site.yml --tags base -e "interactive_dotfiles=false"

```

*Note: This strictly applies the `base` tag and runs non-interactively, bypassing the Helix and `mise` development tools.*

## 🛠 How to Modify the System

### Updating Configuration Files (Dotfiles)

If you tweak your `~/.zshrc` or `starship.toml` locally and decide you want to keep the changes permanently:

1. Copy the changes into the respective `.j2` Jinja templates located in `roles/*/templates/`.
2. Commit and push your changes to the repository.
3. Run the playbook interactively to deploy the new template and update the hash ledger.

### Adding New Packages

* **Core Tools:** Add the package name to the `ansible.builtin.dnf` list in `roles/base/tasks/main.yml`.
* **Dev Tools:** Add the package name to the task list in `roles/dev/tasks/main.yml`.

### Manual Execution

If you need to run the playbook manually from within the repository:

**Update Base Server:**

```bash
ansible-playbook -i "target-host-ip," site.yml --tags base

```

**Interactive Workstation Update:**

```bash
ansible-playbook -i "localhost," -c local site.yml -e "interactive_dotfiles=true" -e "dev_node=true" --ask-become-pass

```
