#!/usr/bin/env bash

# ssh-agent setup helper for WSL or Linux login shells
# - Starts a persistent ssh-agent
# - Auto-adds your key if not already loaded
# - Recreates the agent if the file is stale or invalid
# - Optionally expires the agent after 12 hours

SSH_ENV="$HOME/.ssh/environment"
SSH_KEY="$HOME/.ssh/id_ed25519"
MAX_AGE_MINUTES=${SSH_AGENT_MAX_AGE_MINUTES:-720}  # 12 hours default

start_agent() {
    echo ">>> Initializing new SSH agent... <<<"
    (umask 066; ssh-agent > "$SSH_ENV")
    . "$SSH_ENV" > /dev/null

    if [ -f "$SSH_KEY" ]; then
        echo ">>> Running ssh-add for $SSH_KEY <<<"
        ssh-add "$SSH_KEY"
        echo ">>> SSH identity has been added. <<<"
    else
        echo ">>> WARNING: $SSH_KEY not found. <<<"
    fi
}

echo ">>> Checking ssh-agent setup... <<<"

# Validate the environment file
if [ -f "$SSH_ENV" ]; then
    # Check if the file is older than MAX_AGE_MINUTES
    if find "$SSH_ENV" -mmin +"$MAX_AGE_MINUTES" -print -quit 2>/dev/null | grep -q .; then
        echo ">>> $SSH_ENV is older than $MAX_AGE_MINUTES minutes — recreating agent... <<<"
        rm -f "$SSH_ENV"
        start_agent
    else
        echo ">>> Found $SSH_ENV, sourcing it... <<<"
        . "$SSH_ENV" > /dev/null

        # Validate the running agent
        if [ -z "$SSH_AGENT_PID" ] || ! ps -p "$SSH_AGENT_PID" > /dev/null 2>&1; then
            echo ">>> Stale or invalid ssh-agent detected, restarting... <<<"
            rm -f "$SSH_ENV"
            start_agent
        else
            # Check if any identities are loaded
            if ! ssh-add -l >/dev/null 2>&1; then
                echo ">>> No identities loaded — adding $SSH_KEY... <<<"
                ssh-add "$SSH_KEY" >/dev/null 2>&1 && echo ">>> Identity added. <<<"
            else
                echo ">>> Agent is already running (PID: $SSH_AGENT_PID) with keys loaded. <<<"
            fi
        fi
    fi
else
    echo ">>> No $SSH_ENV file found, starting agent... <<<"
    start_agent
fi
