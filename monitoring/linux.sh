#!/bin/bash
# @ftbento
# Tmux monitoring

# needs tmux, htop, whowatch and pspy64
# detatch  :  Ctrl-b d
# reattach :  tmux attach -t hpcc-mon
# kill     :  tmux kill-session -t hpcc-mon

SESSION="hpcc-mon"

cmd_logs() {
  if command -v journalctl >/dev/null 2>&1; then
    # Follow SSH + sudo + audit events in one stream
    echo "sudo journalctl -f -n 50 SYSLOG_IDENTIFIER=sshd SYSLOG_IDENTIFIER=sudo SYSLOG_IDENTIFIER=su _TRANSPORT=audit 2>/dev/null || sudo journalctl -f -n 50"
  elif [ -r /var/log/secure ]; then
    echo "sudo tail -F /var/log/secure"
  elif [ -r /var/log/auth.log ]; then
    echo "sudo tail -F /var/log/auth.log"
  else
    echo 'echo "No log source found"; exec bash'
  fi
}

# delete old session
tmux has-session -t "$SESSION" 2>/dev/null && tmux kill-session -t "$SESSION"

# make session
tmux new-session  -d -s "$SESSION" -x 220 -y 50
tmux rename-window -t "$SESSION:0" $(hostname -s)

# Create panes
P0=$(tmux display-message -p -t "$SESSION:0" '#{pane_id}')
P1=$(tmux split-window -h -P -F '#{pane_id}' -t "$P0")
P2=$(tmux split-window -v -P -F '#{pane_id}' -t "$P0")
P3=$(tmux split-window -v -P -F '#{pane_id}' -t "$P1")
P4=$(tmux split-window -v -P -F '#{pane_id}' -t "$P2")   # bottom spanning pane

tmux select-layout -t "$SESSION:0" tiled
tmux set-option -t "$SESSION:0" -w remain-on-exit on 2>/dev/null || true

# Mouse on so the scroll wheel enters copy-mode (scrollback) in each pane
tmux set-option -g mouse on 2>/dev/null || true

# pspy reports every process the monitor spawns; filter its own noise out
PSPY='sudo /usr/local/bin/pspy64 | grep --line-buffered -vE "htop|whowatch|pspy64|watch|ss -tulpna|--line-buffered"'

tmux send-keys -t "$P0" "htop" C-m
tmux send-keys -t "$P1" "whowatch" C-m
tmux send-keys -t "$P2" "$PSPY" C-m
tmux send-keys -t "$P3" "$(cmd_logs)" C-m
tmux send-keys -t "$P4" "watch -n3 ss -tulpna" C-m

tmux select-pane -t "$P0" -T "htop"
tmux select-pane -t "$P1" -T "users"
tmux select-pane -t "$P2" -T "pspy"
tmux select-pane -t "$P3" -T "auth-log"
tmux select-pane -t "$P4" -T "ports"

tmux select-pane -t "$P0"

# Auto-attach if we're in a real terminal and not already inside tmux
if [[ -t 1 && -z "${TMUX:-}" ]]; then
  tmux attach-session -t "$SESSION"
fi
