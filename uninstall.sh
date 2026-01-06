#!/bin/bash
# uninstall.sh - Uninstall terminal-notifier-for-macos
set -euo pipefail

INSTALL_DIR="${TNOTIFY_INSTALL_DIR:-$HOME/.local/share/terminal-notifier}"
BIN_DIR="${TNOTIFY_BIN_DIR:-$HOME/.local/bin}"
LAUNCHAGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCHAGENT_NAME="com.terminal-notifier.plist"

echo "Terminal Notifier for macOS - Uninstaller"
echo "=========================================="
echo ""

# Stop the service
echo "Stopping notify-server..."
launchctl unload "$LAUNCHAGENT_DIR/$LAUNCHAGENT_NAME" 2>/dev/null || true

# Remove LaunchAgent
if [[ -f "$LAUNCHAGENT_DIR/$LAUNCHAGENT_NAME" ]]; then
    echo "Removing LaunchAgent..."
    rm -f "$LAUNCHAGENT_DIR/$LAUNCHAGENT_NAME"
fi

# Remove symlinks
echo "Removing symlinks from $BIN_DIR..."
rm -f "$BIN_DIR/notify-server"
rm -f "$BIN_DIR/tnotify"
rm -f "$BIN_DIR/ssh-notify"

# Remove installation directory
if [[ -d "$INSTALL_DIR" ]]; then
    echo "Removing $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
fi

# Clean up log files
echo "Removing log files..."
rm -f /tmp/notify-server.log
rm -f /tmp/notify-server.stdout.log
rm -f /tmp/notify-server.stderr.log

echo ""
echo "Uninstallation complete!"
echo ""
echo "NOTE: You may want to remove these lines from your shell config (~/.zshrc or ~/.bashrc):"
echo ""
echo "  # Terminal Notifier"
echo "  export PATH=\"$BIN_DIR:\$PATH\""
echo "  source \"$INSTALL_DIR/lib/shell-hooks.zsh\"  # or shell-hooks.bash"
echo ""
echo "Also remove from remote servers: rm -rf ~/.tnotify"
