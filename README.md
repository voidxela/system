# System Standardization Playbook

This repository contains an idempotent, automated Ansible architecture for standardizing Linux environments. It is designed to scale seamlessly from local development workstations (Ultramarine/Fedora) to headless cloud infrastructure (Rocky/RHEL), providing a lean, highly performant, and deeply customized CLI experience.

## 🏗 Architecture

The playbook uses a decoupled, single-responsibility role architecture to guarantee clean deployments across bare-metal environments and rootless container layers.

* **`core` & `user`:** Handles agnostic software deployments (`zsh`, `starship`, `eza`) and account provisioning.
* **`system`:** Manages kernel optimizations, daemons (`firewalld`, `fail2ban`, `sshd`), and UID collision resolution.
* **`dev` & `container_tools`:** Injects heavy development tooling (`helix`, `mise`) and native container build stacks (`buildah`, `podman`) onto local workstations.
* **`container_host`:** Configures subuid/subgid namespaces and runtime prerequisites for remote rootless container hosts.

## 🧪 Testing & CI/CD

This repository leverages [Molecule](https://ansible.readthedocs.io/projects/molecule/) with the **Podman** driver to validate all Ansible roles against idempotency guarantees and prevent regressions across target environments. Each role is tested idempotently in disposable containers for both **Fedora** (workstation) and **Rocky Linux** (server) runtimes.

Initialize the local testing environment:

~~~bash
just test-init
~~~

Execute the full test suite across every role containing a `molecule/` configuration:

~~~bash
just test
~~~

Run tests for a single role (e.g., `container_host`):

~~~bash
just test container_host
~~~

## 🚀 Deployment

### 1. Local Workstation Bootstrap

To provision a fresh desktop or update your existing local environment for the first time, run the bootstrap script. This will install prerequisites (`ansible`, `git`), clone the repository into `~/.local/share/system-config`, and execute the workstation playbook interactively.

~~~bash
curl -fsSL https://raw.githubusercontent.com/voidxela/system/main/scripts/bootstrap.sh | bash
~~~

### 2. Cloud VPS Provisioning (Zero-Touch)

To deploy this configuration to a fresh cloud server automatically on boot, paste the following YAML into the **User Data / cloud-init** field. We install `epel-release` first to ensure `just` is available in Enterprise Linux environments.

~~~yaml
#cloud-config
package_update: true
packages:
  - epel-release
  - git
  - ansible-core
  - just
runcmd:
  - git clone --quiet https://github.com/voidxela/system.git /root/system-config
  - cd /root/system-config
  - just server localhost -c local -e "interactive=false"
~~~

## 🛠 Task Runner (Manual Execution)

This repository utilizes `just` as a central command runner. From the root of the repository, you can manage the environment using the following commands. Any trailing flags will be passed directly to Ansible.

#### Standard Updates
Use these commands for machines that have already been provisioned with your primary user and SSH keys.

**Update Local Workstation:**
~~~bash
just bootstrap
~~~
*Note: Using the bootstrap command locally ensures that your local environment pulls the latest changes from Git and executes from the standardized `~/.local/share/system-config` directory, rather than your current working directory.*

**Update Remote Workstation:**
~~~bash
just workstation 198.51.100.11
~~~

**Update Remote Server:**
~~~bash
just server 198.51.100.10
~~~

#### Bootstrapping a Fresh Dedicated Machine
When you receive a raw dedicated server or workstation, your primary user and keys do not exist yet. You must use the provider's default credentials to bridge the gap.

*Prerequisite: Your local machine must have `sshpass` installed (`sudo dnf install sshpass`) to allow plain-text password prompts.*

**Scenario A: Provided with `root` and a password**
Pass `-u root` to override the SSH user, and `-k` to prompt for the password.
~~~bash
just server 198.51.100.10 -e "interactive=false" -u root -k
~~~

**Scenario B: Provided with a default user (e.g., `admin`, `rocky`) and a password**
Pass `-u rocky` for the user, `-k` for the SSH password, and `-K` for the `sudo` password.
~~~bash
just server 198.51.100.10 -e "interactive=false" -u rocky -k -K
~~~

#### Container Management
Build rootless, OCI-compliant Buildah images directly from the repository playbooks using a native Ansible connection plugin. 

This repository enforces an **Immutable + Floating** versioning matrix. Container builds automatically read the semantic version from the `VERSION` file and the current Git SHA to generate three distinct tags per build:

1. **Immutable Tag (`1.0.0-app-a1b2c3d`):** The absolute source of truth. Use this in production manifests to guarantee idempotent deployments.
2. **Major Floating Tag (`v1-app`):** Automatically rolls forward with minor patches. Use this for downstream CI pipelines that need safe, non-breaking updates.
3. **Latest Tag (`app-latest`):** A strict convenience tag. Only use this for local testing and quick pulls.

**Build the heavy CI/CD variant:**
~~~bash
just build-dev
~~~

**Build the lean app base layer:**
~~~bash
just build-app
~~~
