# Set the default shell for command execution
set shell := ["bash", "-c"]

# --- Dynamic Versioning Variables ---
# Get current git SHA (fallback to 'dev' if not a git repo)
git_sha := `git rev-parse --short HEAD 2>/dev/null || echo "local"`
# Read the semantic version (fallback to 0.0.0 if file is missing)
app_version := `cat VERSION 2>/dev/null || echo "0.0.0"`

# List available commands if `just` is run without arguments
default:
    @just --list

# --- Scripts ---

@bootstrap:
    ./scripts/bootstrap.sh

@bundle:
    npx repomix

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

# --- Testing ---

# Install Python testing dependencies for local Molecule development
test-init:
    @which podman > /dev/null 2>&1 || { echo "Error: podman is not installed. Please install Podman first."; exit 1; }
    @which molecule > /dev/null 2>&1 && echo "molecule is already installed." || echo "molecule will be installed from requirements.txt."
    @pip install -r requirements.txt
    @ansible-galaxy collection install ansible.posix containers.podman

# Run Molecule tests for all roles or a specific role
test target_role="all":
    @if [ "{{target_role}}" = "all" ]; then \
        for role in roles/*/; do \
            role_name="$(basename "$role")"; \
            if [ -d "roles/$role_name/molecule" ]; then \
                echo "🧪 Testing role: $role_name..."; \
                (cd "roles/$role_name" && molecule test) || exit 1; \
            fi; \
        done; \
    else \
        echo "🧪 Testing role: {{target_role}}..."; \
        (cd "roles/{{target_role}}" && molecule test) || exit 1; \
    fi
