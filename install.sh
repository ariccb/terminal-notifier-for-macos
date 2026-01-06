#!/bin/bash
# install.sh - Install terminal-notifier-for-macos
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${TNOTIFY_INSTALL_DIR:-$HOME/.local/share/terminal-notifier}"
BIN_DIR="${TNOTIFY_BIN_DIR:-$HOME/.local/bin}"
LAUNCHAGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCHAGENT_NAME="com.terminal-notifier.plist"

echo "Terminal Notifier for macOS - Installer"
echo "========================================"
echo ""

# Create directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR"/{bin,lib,config}
mkdir -p "$BIN_DIR"
mkdir -p "$LAUNCHAGENT_DIR"

# Copy files
echo "Installing files to $INSTALL_DIR..."
cp "$SCRIPT_DIR"/bin/* "$INSTALL_DIR/bin/"
cp "$SCRIPT_DIR"/lib/* "$INSTALL_DIR/lib/"
cp "$SCRIPT_DIR"/config/* "$INSTALL_DIR/config/"

# Make scripts executable
chmod +x "$INSTALL_DIR"/bin/*

# Create symlinks in BIN_DIR
echo "Creating symlinks in $BIN_DIR..."
ln -sf "$INSTALL_DIR/bin/notify-server" "$BIN_DIR/notify-server"
ln -sf "$INSTALL_DIR/bin/tnotify" "$BIN_DIR/tnotify"
ln -sf "$INSTALL_DIR/bin/ssh-notify" "$BIN_DIR/ssh-notify"

# Install LaunchAgent
echo "Installing LaunchAgent..."
sed "s|__INSTALL_DIR__|$INSTALL_DIR|g" "$SCRIPT_DIR/launchd/$LAUNCHAGENT_NAME" > "$LAUNCHAGENT_DIR/$LAUNCHAGENT_NAME"

# Stop existing service if running
launchctl unload "$LAUNCHAGENT_DIR/$LAUNCHAGENT_NAME" 2>/dev/null || true

# Start the service
echo "Starting notify-server..."
launchctl load "$LAUNCHAGENT_DIR/$LAUNCHAGENT_NAME"

# Detect shell and provide instructions
echo ""
echo "Installation complete!"
echo ""
echo "Add the following to your shell configuration:"
echo ""

if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
    HOOKS_FILE="shell-hooks.zsh"
else
    SHELL_RC="$HOME/.bashrc"
    HOOKS_FILE="shell-hooks.bash"
fi

echo "  # Terminal Notifier"
echo "  export PATH=\"$BIN_DIR:\$PATH\""
echo "  source \"$INSTALL_DIR/lib/$HOOKS_FILE\""
echo ""

# Offer to add automatically
read -p "Add these lines to $SHELL_RC automatically? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if already added
    if grep -q "terminal-notifier" "$SHELL_RC" 2>/dev/null; then
        echo "Shell hooks already present in $SHELL_RC"
    else
        echo "" >> "$SHELL_RC"
        echo "# Terminal Notifier" >> "$SHELL_RC"
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
        echo "source \"$INSTALL_DIR/lib/$HOOKS_FILE\"" >> "$SHELL_RC"
        echo "Added to $SHELL_RC"
    fi
fi

echo ""
echo "Verifying installation..."

# Check if server is running
sleep 1
if nc -z localhost 9999 2>/dev/null; then
    echo "  [OK] notify-server is running on port 9999"
else
    echo "  [!!] notify-server may not be running. Check: launchctl list | grep terminal-notifier"
fi

# Check if binaries are accessible
if command -v tnotify &>/dev/null; then
    echo "  [OK] tnotify is in PATH"
else
    echo "  [!!] tnotify not in PATH. Make sure $BIN_DIR is in your PATH"
fi

echo ""
echo "Test with: tnotify-test"
echo "For SSH, use: ssh-notify user@host"
echo ""
echo "Restart your terminal or run: source $SHELL_RC"
