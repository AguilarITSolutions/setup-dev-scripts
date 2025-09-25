#!/usr/bin/env bash

SSH_ENV="$HOME/.ssh/environment"

function start_agent {
    echo ">>> Initializing new SSH agent... <<<"
    (umask 066; ssh-agent > "$SSH_ENV")
    . "$SSH_ENV"

    echo ">>> Running ssh-add for ~/.ssh/id_ed25519 <<<"
    ssh-add ~/.ssh/id_ed25519
    echo ">>> SSH identity has been added. <<<"
}

echo ">>> Checking ssh-agent setup... <<<"

if [ -f "$SSH_ENV" ]; then
    echo ">>> Found $SSH_ENV, sourcing it... <<<"
    . "$SSH_ENV"
    if ! kill -0 $SSH_AGENT_PID 2>/dev/null; then
        echo ">>> No agent process found, starting a new one... <<<"
        start_agent
    else
        echo ">>> Agent is already running (PID: $SSH_AGENT_PID). <<<"
    fi
else
    echo ">>> No $SSH_ENV file found, starting agent... <<<"
    start_agent
fi
