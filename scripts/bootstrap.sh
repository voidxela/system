#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Reattach standard input to the terminal so interactive prompts work
exec < /dev/tty

REPO_URL="https://github.com/voidxela/system.git"
DEST_DIR="$HOME/.local/share/system-config"
mkdir -p "${DEST_DIR%/*}"

echo "🚀 Bootstrapping system environment..."

# 1. Gain sudo privileges upfront if needed
echo "🔑 Checking privilege escalation..."
if sudo -n true 2>/dev/null; then
    echo "🔓 Passwordless sudo active."
    BECOME_FLAG=""
else
    echo "🔒 Sudo password required for initial setup."
    sudo -v
    BECOME_FLAG="--ask-become-pass"
fi

# Keep sudo timestamp alive in the background while the script runs
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 2. Ensure prerequisites are installed via dnf
if ! command -v ansible-playbook &> /dev/null || ! command -v git &> /dev/null; then
    echo "📦 Installing prerequisites (Ansible, Git)..."
    sudo dnf install -y ansible-core git
fi

# 3. Clone or pull the latest repository
if [ -d "$DEST_DIR" ]; then
    echo "🔄 Updating existing repository at $DEST_DIR..."
    env GIT_TERMINAL_PROMPT=0 git -c credential.helper= -C "$DEST_DIR" pull --quiet
else
    echo "📥 Cloning repository to $DEST_DIR..."
    env GIT_TERMINAL_PROMPT=0 git -c credential.helper= clone --quiet "$REPO_URL" "$DEST_DIR"
fi

# 4. Execute the playbook interactively
echo "⚙️ Executing Ansible playbook locally..."
cd "$DEST_DIR"

ansible-playbook -i "localhost," -c local playbooks/host_workstation.yml \
    -e "interactive=true" \
    ${BECOME_FLAG}

echo "✅ System standardization complete!"
