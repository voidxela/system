# Set the default shell for command execution
set shell := ["bash", "-c"]

# --- Dynamic Versioning Variables ---
# Get current git SHA (fallback to 'dev' if not a git repo)
git_sha := `git rev-parse --short HEAD 2>/dev/null || echo "local"`
# Read the semantic version (fallback to 0.0.0 if file is missing)
app_version := `cat VERSION 2>/dev/null || echo "0.0.0"`
# Default container registry path for local builds
# Override on the command line, e.g.: just target_registry=ghcr.io/owner/system build-app
target_registry := "localhost/system"

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
    ansible-playbook -i "localhost," -c local playbooks/build_container_dev.yml \
        -e "image_version={{app_version}}" \
        -e "git_sha={{git_sha}}" \
        -e "image_variant=dev" \
        {{args}}

# Build the lean app base layer via Buildah
build-app +args='':
    ansible-playbook -i "localhost," -c local playbooks/build_container_app.yml \
        -e "image_version={{app_version}}" \
        -e "git_sha={{git_sha}}" \
        -e "image_variant=app" \
        {{args}}
