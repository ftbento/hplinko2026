#!/usr/bin/env bash
set -u

SESSION="hpcc-ops"
WINDOW="monitoring"
HOST_LABEL="ignition (Fedora Server 38)"
LOG_UNIT="sshd"
LOG_FALLBACK="/var/log/secure"

if ! command -v tmux >/dev/null 2>&1; then
  echo "ERROR: tmux is not installed. Install with: sudo dnf install -y tmux" >&2
  exit 1
fi

for bin in htop whowatch; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "WARNING: '$bin' is not installed; its pane will show a notice." >&2
  fi
done
if [[ ! -x /usr/local/bin/pspy64 ]]; then
  echo "WARNING: /usr/local/bin/pspy64 is missing/not executable." >&2
fi

pane_cmd() {
  local tool="$1"
  local cmd="$2"
  case "$tool" in
    htop|whowatch)
      if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'echo "WARNING: %s not installed"; exec bash' "$tool"
        return
      fi ;;
    pspy64)
      if [[ ! -x /usr/local/bin/pspy64 ]]; then
        printf 'echo "WARNING: pspy64 not installed at /usr/local/bin/pspy64"; exec bash'
        return
      fi ;;
  esac
  printf '%s' "$cmd"
}

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n "$WINDOW"
P0=$(tmux display-message -p -t "$SESSION:$WINDOW" '#{pane_id}')
P1=$(tmux split-window -h -P -F '#{pane_id}' -t "$P0")
P2=$(tmux split-window -v -P -F '#{pane_id}' -t "$P0")
P3=$(tmux split-window -v -P -F '#{pane_id}' -t "$P1")
tmux set-option -t "$SESSION:$WINDOW" -w remain-on-exit on >/dev/null 2>&1 || true
tmux select-layout -t "$SESSION:$WINDOW" tiled

HTOP_CMD="$(pane_cmd htop htop)"
WHOWATCH_CMD="$(pane_cmd whowatch whowatch)"
PSPY_CMD="$(pane_cmd pspy64 /usr/local/bin/pspy64)"

if command -v journalctl >/dev/null 2>&1; then
  LOG_CMD="sudo journalctl -u ${LOG_UNIT} -f"
elif [[ -r "$LOG_FALLBACK" ]]; then
  LOG_CMD="sudo tail -F ${LOG_FALLBACK}"
elif [[ -r /var/log/auth.log ]]; then
  LOG_CMD="sudo tail -F /var/log/auth.log"
else
  LOG_CMD='echo "WARNING: no supported log source available"; exec bash'
fi

tmux send-keys -t "$P0" "$HTOP_CMD" C-m
tmux send-keys -t "$P1" "$WHOWATCH_CMD" C-m
tmux send-keys -t "$P2" "$PSPY_CMD" C-m
tmux send-keys -t "$P3" "$LOG_CMD" C-m
tmux select-pane -t "$P0"

echo "hpcc-ops session ready on $HOST_LABEL."
if [[ -t 1 && -z "${TMUX:-}" ]]; then
  tmux attach-session -t "$SESSION"
fi
