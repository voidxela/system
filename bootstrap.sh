#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Reattach standard input to the terminal so interactive prompts (sudo, ansible pause) work!
exec < /dev/tty

# Define your repository URL (Update this with your actual GitHub repo)
REPO_URL="https://github.com/voidxela/system-config.git"
DEST_DIR="$HOME/.local/share/system-config"

echo "🚀 Bootstrapping system environment..."

# 1. Gain sudo privileges upfront
echo "🔑 Please enter your sudo password to authorize installation:"
sudo -v

# Keep sudo timestamp alive in the background while the script runs
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 2. Ensure prerequisites are installed via dnf
if ! command -v ansible-playbook &> /dev/null || ! command -v git &> /dev/null; then
    echo "📦 Installing Ansible and Git..."
    sudo dnf install -y ansible-core git
fi

# 3. Clone or pull the latest repository
if [ -d "$DEST_DIR" ]; then
    echo "🔄 Updating existing repository at $DEST_DIR..."
    git -C "$DEST_DIR" pull --quiet
else
    echo "📥 Cloning repository to $DEST_DIR..."
    git clone --quiet "$REPO_URL" "$DEST_DIR"
fi

# 4. Execute the playbook interactively
echo "⚙️ Executing Ansible playbook..."
cd "$DEST_DIR"

# Run with interactive_dotfiles enabled, targeting the local machine
# --ask-become-pass ensures Ansible can escalate privileges if passwordless sudo isn't set up yet
ansible-playbook -i "localhost," -c local site.yml \
    -e "interactive_dotfiles=true" \
    -e "dev_node=true" \
    --ask-become-pass

echo "✅ System standardization complete!"
