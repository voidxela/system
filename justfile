# Set the default shell for command execution
set shell := ["bash", "-c"]

# List available commands if `just` is run without arguments
default:
    @just --list

# --- Scripts ---

@bootstrap:
    ./scripts/bootstrap.sh

@bundle:
    ./scripts/bundle.sh

# --- Provisioning ---

# Provision a remote Ultramarine/Fedora workstation (Requires IP address)
workstation target_ip +args='':
    ansible-playbook -i "{{target_ip}}," playbooks/host_workstation.yml {{args}}

# Provision a headless Rocky/Enterprise server (Requires IP address)
server target_ip +args='':
    ansible-playbook -i "{{target_ip}}," playbooks/host_server.yml {{args}}

# --- Container Builds ---

# Build the heavy CI/CD dev container via Buildah
build-dev +args='':
    ansible-playbook playbooks/build_container_dev.yml {{args}}

# Build the lean app base layer via Buildah
build-app +args='':
    ansible-playbook playbooks/build_container_app.yml {{args}}
