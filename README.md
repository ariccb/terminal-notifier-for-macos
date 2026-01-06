# Terminal Notifier for macOS

Get macOS system notifications when terminal commands finish - even over SSH connections.

When you run a long-running command (build, test suite, deployment), you'll get a notification when it completes so you can context-switch without constantly checking your terminal.

## Features

- Native macOS notifications using `osascript`
- Works over SSH via reverse port forwarding
- Tmux support - shows pane/window name in notifications
- Different sounds for success (Glass) vs failure (Basso)
- Configurable threshold (default: 10 seconds)
- Supports both Zsh and Bash

## Quick Start

```bash
# Install
./install.sh

# Restart your terminal, then test
tnotify-test

# Run a long command - you'll get notified when it finishes
sleep 15

# For SSH connections, use ssh-notify instead of ssh
ssh-notify user@server.com
```

## How It Works

```
┌─────────────────┐         ┌──────────────────────────────────────┐
│   Local Mac     │         │        Remote Server (SSH)           │
├─────────────────┤         ├──────────────────────────────────────┤
│                 │         │                                      │
│  notify-server  │◄────────│  localhost:9999 (via SSH -R tunnel)  │
│  (port 9999)    │         │         │                            │
│       │         │         │         │                            │
│       ▼         │         │    shell hooks detect                │
│   osascript     │         │    command completion                │
│   notification  │         │         │                            │
│                 │         │         ▼                            │
│                 │         │      tnotify                         │
└─────────────────┘         └──────────────────────────────────────┘
```

1. **notify-server** runs on your Mac, listening on port 9999
2. **Shell hooks** track when commands start and finish
3. When a command takes longer than the threshold, **tnotify** sends a notification
4. For SSH, **ssh-notify** creates a reverse tunnel so remote commands can notify your Mac

## Installation

### Local Mac

```bash
git clone https://github.com/youruser/terminal-notifier-for-macos.git
cd terminal-notifier-for-macos
./install.sh
```

The installer will:
- Copy files to `~/.local/share/terminal-notifier/`
- Create symlinks in `~/.local/bin/`
- Install and start the LaunchAgent
- Optionally add shell hooks to your `.zshrc` or `.bashrc`

### Remote Servers

When you first connect to a remote server:

```bash
ssh-notify --setup user@server.com
```

Then add to your remote shell config:

```bash
# For zsh (~/.zshrc)
source ~/.tnotify/shell-hooks.zsh

# For bash (~/.bashrc)
source ~/.tnotify/shell-hooks.bash
```

## Usage

### Basic Commands

```bash
# Send a test notification
tnotify-test

# Send a manual notification
tnotify "Build complete"
tnotify --cmd "npm build" --exit 0 --duration 45

# Check status
tnotify-status

# Disable/enable notifications temporarily
tnotify-disable
tnotify-enable
```

### SSH with Notifications

```bash
# Connect with notification forwarding
ssh-notify user@server.com

# First-time setup on a new server
ssh-notify --setup user@server.com

# Regular SSH (no notifications)
ssh-notify --no-forward user@server.com
# or just use regular ssh
ssh user@server.com
```

### With Tmux

Notifications automatically include tmux pane/window information when running inside tmux:

```
┌────────────────────────────────────────┐
│ Terminal - dev (main:0.1)              │
├────────────────────────────────────────┤
│ "npm run build" completed (47s)        │
│ ✓ Success                              │
└────────────────────────────────────────┘
```

## Configuration

Set these environment variables in your shell profile:

```bash
# Minimum seconds before notification (default: 10)
export TNOTIFY_THRESHOLD=10

# Server port (default: 9999)
export TNOTIFY_PORT=9999

# Enable/disable (default: 1)
export TNOTIFY_ENABLED=1
```

Or edit `~/.local/share/terminal-notifier/config/tnotify.conf`.

## Ignored Commands

These commands never trigger notifications (they're interactive or too quick):

- Navigation: `ls`, `cd`, `pwd`
- Editors: `vim`, `nvim`, `nano`, `code`
- Interactive: `top`, `htop`, `watch`, `less`
- Shell: `clear`, `exit`, `fg`, `bg`, `jobs`
- SSH: `ssh`, `ssh-notify`, `tmux`

## Troubleshooting

### Notifications not appearing

1. Check if server is running:
   ```bash
   tnotify-status
   # or
   nc -z localhost 9999 && echo "Server running"
   ```

2. Check LaunchAgent:
   ```bash
   launchctl list | grep terminal-notifier
   ```

3. Restart the server:
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.terminal-notifier.plist
   launchctl load ~/Library/LaunchAgents/com.terminal-notifier.plist
   ```

4. Check logs:
   ```bash
   cat /tmp/notify-server.log
   cat /tmp/notify-server.stderr.log
   ```

### SSH notifications not working

1. Verify the tunnel is established:
   ```bash
   # On remote server
   nc -z localhost 9999 && echo "Tunnel working"
   ```

2. Make sure you used `ssh-notify` instead of `ssh`

3. Check that shell hooks are loaded on remote:
   ```bash
   type __tnotify_preexec  # Should show function
   ```

### macOS notification permissions

If notifications don't appear, check System Settings → Notifications → Script Editor and ensure notifications are allowed.

## Uninstall

```bash
./uninstall.sh
```

Then remove these lines from your shell config:
```bash
# Terminal Notifier
export PATH="$HOME/.local/bin:$PATH"
source "$HOME/.local/share/terminal-notifier/lib/shell-hooks.zsh"
```

## How It Compares

| Feature | This tool | terminal-notifier | noti |
|---------|-----------|-------------------|------|
| Native macOS | ✓ (osascript) | ✓ | ✓ |
| No dependencies | ✓ | ✗ (Homebrew) | ✗ |
| SSH support | ✓ | ✗ | ✗ |
| Auto-detect completion | ✓ | ✗ | ✗ |
| Tmux integration | ✓ | ✗ | Partial |

## License

MIT
