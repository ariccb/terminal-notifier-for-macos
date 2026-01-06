# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terminal Notifier for macOS - sends native macOS notifications when terminal commands complete, including over SSH connections.

## Architecture

```
bin/
  notify-server    # Daemon listening on port 9999, displays notifications via osascript
  tnotify          # Client that sends JSON notifications to the server
  ssh-notify       # SSH wrapper with reverse port forwarding (-R 9999:localhost:9999)

lib/
  shell-hooks.zsh  # Zsh preexec/precmd hooks for auto-detection
  shell-hooks.bash # Bash DEBUG trap + PROMPT_COMMAND for auto-detection

launchd/
  com.terminal-notifier.plist  # LaunchAgent for auto-starting notify-server
```

## Key Design Decisions

- **Pure bash** - No external dependencies beyond macOS built-ins (nc, osascript)
- **JSON protocol** - Server accepts `{"cmd":"...", "exit":0, "duration":45, "tmux":"session:window.pane"}`
- **Non-blocking** - tnotify sends with 1s timeout, shell hooks run in background
- **Port 9999** - Configurable via `TNOTIFY_PORT` env var

## Testing Changes

```bash
# Start server manually (foreground)
./bin/notify-server

# Send test notification
./bin/tnotify --cmd "test" --exit 0 --duration 5

# Test with different exit codes
./bin/tnotify --cmd "failed build" --exit 1 --duration 30
```

## Common Modifications

- **Add ignored commands**: Edit `__tnotify_ignore_cmds` in shell-hooks.{zsh,bash}
- **Change sounds**: Edit `show_notification()` in notify-server (Glass/Basso)
- **Change threshold**: Set `TNOTIFY_THRESHOLD` environment variable
