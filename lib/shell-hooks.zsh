# shell-hooks.zsh - Zsh integration for terminal-notifier
# Source this file in your .zshrc:
#   source /path/to/shell-hooks.zsh

# Configuration
export TNOTIFY_THRESHOLD="${TNOTIFY_THRESHOLD:-10}"  # Minimum seconds before notification
export TNOTIFY_ENABLED="${TNOTIFY_ENABLED:-1}"       # Set to 0 to disable
export TNOTIFY_PORT="${TNOTIFY_PORT:-9999}"

# Internal state
typeset -g __tnotify_cmd=""
typeset -g __tnotify_start=0
typeset -g __tnotify_active=0

# Commands to ignore (short/interactive commands)
typeset -ga __tnotify_ignore_cmds=(
    "ls" "cd" "pwd" "echo" "cat" "less" "more" "head" "tail"
    "vim" "nvim" "vi" "nano" "emacs" "code"
    "top" "htop" "btop" "watch"
    "man" "help" "which" "type" "where"
    "clear" "reset" "exit" "logout"
    "fg" "bg" "jobs"
    "ssh" "ssh-notify"  # Don't notify on SSH itself
    "tmux"
)

# Check if command should be ignored
__tnotify_should_ignore() {
    local cmd="$1"
    local base_cmd="${cmd%% *}"  # Get first word

    for ignore in "${__tnotify_ignore_cmds[@]}"; do
        [[ "$base_cmd" == "$ignore" ]] && return 0
    done
    return 1
}

# Called before command execution
__tnotify_preexec() {
    [[ "$TNOTIFY_ENABLED" != "1" ]] && return

    local cmd="$1"

    # Skip if command should be ignored
    if __tnotify_should_ignore "$cmd"; then
        __tnotify_active=0
        return
    fi

    __tnotify_cmd="$cmd"
    __tnotify_start=$SECONDS
    __tnotify_active=1
}

# Called after command execution, before prompt
__tnotify_precmd() {
    local exit_code=$?  # Capture immediately!

    [[ "$TNOTIFY_ENABLED" != "1" ]] && return
    [[ "$__tnotify_active" != "1" ]] && return

    __tnotify_active=0

    local duration=$((SECONDS - __tnotify_start))

    # Only notify if duration exceeds threshold
    if (( duration >= TNOTIFY_THRESHOLD )); then
        # Send notification in background to not block prompt
        (
            tnotify \
                --cmd "$__tnotify_cmd" \
                --exit "$exit_code" \
                --duration "$duration" \
                2>/dev/null
        ) &!
    fi
}

# Register hooks (avoid duplicates)
if [[ -z "${__tnotify_hooks_registered:-}" ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec __tnotify_preexec
    add-zsh-hook precmd __tnotify_precmd
    __tnotify_hooks_registered=1
fi

# Utility functions for user
tnotify-enable() {
    export TNOTIFY_ENABLED=1
    echo "Terminal notifications enabled"
}

tnotify-disable() {
    export TNOTIFY_ENABLED=0
    echo "Terminal notifications disabled"
}

tnotify-status() {
    echo "TNOTIFY_ENABLED=$TNOTIFY_ENABLED"
    echo "TNOTIFY_THRESHOLD=${TNOTIFY_THRESHOLD}s"
    echo "TNOTIFY_PORT=$TNOTIFY_PORT"

    if nc -z localhost "$TNOTIFY_PORT" 2>/dev/null; then
        echo "Server: running on port $TNOTIFY_PORT"
    else
        echo "Server: NOT running"
    fi
}

tnotify-test() {
    echo "Sending test notification..."
    tnotify --cmd "Test notification" --exit 0 --duration 99
    echo "Done. Check for notification."
}
