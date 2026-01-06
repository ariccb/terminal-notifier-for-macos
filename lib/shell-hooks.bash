# shell-hooks.bash - Bash integration for terminal-notifier
# Source this file in your .bashrc:
#   source /path/to/shell-hooks.bash

# Configuration
export TNOTIFY_THRESHOLD="${TNOTIFY_THRESHOLD:-10}"  # Minimum seconds before notification
export TNOTIFY_ENABLED="${TNOTIFY_ENABLED:-1}"       # Set to 0 to disable
export TNOTIFY_PORT="${TNOTIFY_PORT:-9999}"

# Internal state
__tnotify_cmd=""
__tnotify_start=0
__tnotify_active=0

# Commands to ignore (short/interactive commands)
__tnotify_ignore_cmds="ls cd pwd echo cat less more head tail vim nvim vi nano emacs code top htop btop watch man help which type where clear reset exit logout fg bg jobs ssh ssh-notify tmux"

# Check if command should be ignored
__tnotify_should_ignore() {
    local cmd="$1"
    local base_cmd="${cmd%% *}"  # Get first word

    for ignore in $__tnotify_ignore_cmds; do
        [[ "$base_cmd" == "$ignore" ]] && return 0
    done
    return 1
}

# Called via DEBUG trap before command execution
__tnotify_debug_trap() {
    [[ "$TNOTIFY_ENABLED" != "1" ]] && return

    # Avoid triggering on PROMPT_COMMAND itself
    [[ "$BASH_COMMAND" == "$PROMPT_COMMAND" ]] && return

    # Skip subshells and pipes
    [[ "$BASH_SUBSHELL" -gt 0 ]] && return

    local cmd="$BASH_COMMAND"

    # Skip if command should be ignored
    if __tnotify_should_ignore "$cmd"; then
        __tnotify_active=0
        return
    fi

    __tnotify_cmd="$cmd"
    __tnotify_start=$SECONDS
    __tnotify_active=1
}

# Called via PROMPT_COMMAND after command execution
__tnotify_prompt_command() {
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
        ) &
        disown 2>/dev/null || true
    fi
}

# Register hooks (avoid duplicates)
if [[ -z "${__tnotify_hooks_registered:-}" ]]; then
    # Set up DEBUG trap
    trap '__tnotify_debug_trap' DEBUG

    # Add to PROMPT_COMMAND
    if [[ -z "$PROMPT_COMMAND" ]]; then
        PROMPT_COMMAND="__tnotify_prompt_command"
    elif [[ "$PROMPT_COMMAND" != *"__tnotify_prompt_command"* ]]; then
        PROMPT_COMMAND="__tnotify_prompt_command; $PROMPT_COMMAND"
    fi

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
