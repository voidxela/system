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

Here is the updated **Manual Execution** section for your `README.md`. It incorporates the standard commands alongside the new first-run bootstrap scenarios, keeping the documentation clean and comprehensive.

You can replace the existing "Manual Execution" section with this block:

---

### 3. Manual Execution

If you need to run the playbook manually from within the repository, use the following commands depending on your target environment.

#### Standard Updates

Use these commands for machines that have already been provisioned with your primary user and SSH keys.

**Update Local Workstation:**

```bash
ansible-playbook -i "localhost," -c local site.yml -e "interactive_dotfiles=true" -e "dev_node=true" --ask-become-pass

```

**Update Fully Configured Server:**

```bash
ansible-playbook -i "198.51.100.10," site.yml --tags base

```

#### Bootstrapping a Fresh Dedicated Server

When you receive a raw dedicated server or VPS, your primary user and SSH keys do not exist yet. You must use the provider's default credentials to bridge the gap.

*Prerequisite: Your local machine must have `sshpass` installed (`sudo dnf install sshpass`) to allow Ansible to prompt for plain-text passwords.*

**Scenario A: Provided with `root` and a password**
Pass `-u root` to override the SSH user, and `-k` to prompt for the SSH password.

```bash
ansible-playbook -i "198.51.100.10," site.yml \
    --tags base \
    -e "interactive_dotfiles=false" \
    -u root \
    -k

```

**Scenario B: Provided with a default user (e.g., `admin`, `rocky`) and a password**
Pass `-u rocky` for the user, `-k` for the SSH password, and `-K` to prompt for the `sudo` privilege escalation password.

```bash
ansible-playbook -i "198.51.100.10," site.yml \
    --tags base \
    -e "interactive_dotfiles=false" \
    -u rocky \
    -k -K

```

> **Note:** Once this initial bootstrap command finishes successfully, your cryptographic key is installed, SSH is locked down, and the default user is evicted. Future runs against this server will only require the standard "Update Fully Configured Server" command.
