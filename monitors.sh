#!/bin/env bash
# @ftbento
# remote monitor
#
#   ./monitors.sh      # build session and attach
#   ./monitors.sh -k   # close the local session

set -u

SESSION="hpcc-mon"

if [[ "${1:-}" == "-k" ]]; then
  tmux kill-session -t "$SESSION" 2>/dev/null && echo "closed $SESSION" || echo "no session $SESSION"
  exit 0
fi

command -v tmux >/dev/null || { echo "tmux is required" >&2; exit 1; }

# recreate the session so a re-run is clean
tmux kill-session -t "$SESSION" 2>/dev/null

# fedora tab
tmux new-session -d -s "$SESSION" -n fedora
tmux set-option -t "$SESSION" mouse on 2>/dev/null
tmux set-window-option -t "$SESSION:fedora" remain-on-exit on 2>/dev/null
tmux send-keys -t "$SESSION:fedora" "ssh -t fedora@172.16.21.20 'sudo bash \$HOME/nextjstesting-main/monitoring/linux.sh'" C-m

# ubuntu tab
tmux new-window -t "$SESSION" -n ubuntu
tmux set-window-option -t "$SESSION:ubuntu" remain-on-exit on 2>/dev/null
tmux send-keys -t "$SESSION:ubuntu" "ssh -t ubuntu@172.16.21.10 'sudo bash \$HOME/nextjstesting-main/monitoring/linux.sh'" C-m

tmux select-window -t "$SESSION:fedora"

# Auto-attach when we're in a real terminal and not already inside tmux
if [[ -t 1 && -z "${TMUX:-}" ]]; then
  tmux attach-session -t "$SESSION"
fi
