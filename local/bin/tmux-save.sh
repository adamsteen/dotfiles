#!/usr/bin/env bash
# tmux-save.sh — Snapshot current tmux layout and generate a restore script
# that recreates all sessions/windows, resuming claude by session UUID.
set -euo pipefail

RESTORE_DIR="$HOME/.config/tmux-restore"
SYMLINK="$HOME/.local/bin/tmux-restore.sh"
MAX_NAME_LEN=20

# Check tmux is running
if ! tmux info &>/dev/null; then
  echo "Error: tmux is not running." >&2
  exit 1
fi

# Collect pane data (tab-delimited so paths/names with spaces survive)
mapfile -t panes < <(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}	#{pane_current_command}	#{pane_current_path}	#{window_id}	#{window_name}')

if [[ ${#panes[@]} -eq 0 ]]; then
  echo "Error: no tmux panes found." >&2
  exit 1
fi

is_claude() {
  local cmd="$1"
  [[ "$cmd" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] || [[ "$cmd" == "claude" ]]
}

# Parse panes into per-window data
# Keys use session:window as identifier
declare -A win_dir          # window -> directory (from first pane)
declare -A win_id           # window -> tmux window id
declare -A win_name         # window -> tmux window name
declare -A win_has_claude   # window -> 1 if any pane runs claude
declare -A win_has_shell    # window -> 1 if any pane is a shell
declare -a win_order        # ordered list of session:window keys
declare -A seen_sessions    # track session order
declare -a session_order    # ordered list of session names

for line in "${panes[@]}"; do
  IFS=$'\t' read -r pane_id cmd path win_id_field win_name_field <<< "$line"
  win="${pane_id%.*}"       # session:window
  session="${win%%:*}"      # session name

  # Track session order
  if [[ -z "${seen_sessions[$session]+x}" ]]; then
    session_order+=("$session")
    seen_sessions["$session"]=1
  fi

  # Track window order
  if [[ -z "${win_dir[$win]+x}" && -z "${win_has_shell[$win]+x}" ]]; then
    win_order+=("$win")
  fi

  # First pane sets directory, window id and name for the window
  if [[ -z "${win_dir[$win]+x}" ]]; then
    win_dir["$win"]="$path"
    win_id["$win"]="$win_id_field"
    win_name["$win"]="$win_name_field"
  fi

  if is_claude "$cmd"; then
    win_has_claude["$win"]=1
  else
    win_has_shell["$win"]=1
  fi
done

# Load window-id -> session-id map produced by the claude tmux-sync hook
declare -A wid_to_sid
map_file="$HOME/.config/tmux-restore/session-map"
if [[ -f "$map_file" ]]; then
  while IFS=$'\t' read -r wid sid; do
    [[ -n "$wid" ]] && wid_to_sid["$wid"]="$sid"
  done < "$map_file"
fi

# Generate window name from directory path
gen_name() {
  local dir="$1"
  local name
  name=$(basename "$dir")
  if [[ "$name" == "worktrees" || "$name" == ".worktrees" ]]; then
    name=$(basename "$(dirname "$dir")")-wt
  fi
  echo "${name:0:$MAX_NAME_LEN}"
}

# Prefer the live tmux window name; fall back to directory-derived name
label_for() {
  local win="$1" dir="$2" wn="${win_name[$win]:-}"
  # Strip shell metacharacters; the label is interpolated into the restore script.
  wn="${wn//[^A-Za-z0-9._-]/}"
  if [[ -n "$wn" && ! "$wn" =~ ^[0-9]+$ && "$wn" != "$(basename "$dir")" && "$wn" != "zsh" && "$wn" != "bash" ]]; then
    echo "${wn:0:$MAX_NAME_LEN}"
  else
    gen_name "$dir"
  fi
}

# Build per-session window lists
declare -A session_wins  # session -> space-separated window keys
for win in "${win_order[@]}"; do
  session="${win%%:*}"
  if [[ -n "${session_wins[$session]+x}" ]]; then
    session_wins["$session"]="${session_wins[$session]} $win"
  else
    session_wins["$session"]="$win"
  fi
done

# Generate restore script
mkdir -p "$RESTORE_DIR"
timestamp=$(date +%Y-%m-%d-%H%M%S)
restore_file="$RESTORE_DIR/tmux-restore-$timestamp.sh"

{
  cat <<'HEADER'
#!/usr/bin/env bash
# Auto-generated tmux restore script
# Re-creates tmux sessions, resuming claude by session UUID where mapped
set -euo pipefail

HEADER

  for session in "${session_order[@]}"; do
    echo "# === Session: $session ==="
    echo "tmux has-session -t \"$session\" 2>/dev/null && tmux kill-session -t \"$session\""
    echo ""

    read -ra wins <<< "${session_wins[$session]}"
    first=1
    win_num=1

    for win in "${wins[@]}"; do
      dir="${win_dir[$win]}"
      name=$(label_for "$win" "$dir")
      has_claude="${win_has_claude[$win]:-0}"
      has_shell="${win_has_shell[$win]:-0}"
      sid="${wid_to_sid[${win_id[$win]}]:-}"

      if [[ $first -eq 1 ]]; then
        echo "# Window $win_num: $name"
        echo "tmux new-session -d -s \"$session\" -n \"$name\" -c \"\$HOME\""
        # Renumber to start at 1
        echo "tmux move-window -s \"$session:0\" -t \"$session:1\" 2>/dev/null || true"

        if [[ "$has_claude" == "1" ]]; then
          if [[ -n "$sid" ]]; then
            echo "tmux send-keys -t \"$session:1\" \"cd '$dir' && claude --resume $sid\" Enter"
          else
            echo "tmux send-keys -t \"$session:1\" \"cd '$dir' && claude --continue\" Enter"
          fi
        else
          echo "tmux send-keys -t \"$session:1\" \"cd '$dir'\" Enter"
        fi
        if [[ "$has_shell" == "1" ]]; then
          echo "tmux split-window -h -t \"$session:1\" -c \"$dir\""
          echo "tmux select-pane -t \"$session:1.1\""
        fi
        first=0
      else
        echo ""
        echo "# Window $win_num: $name"
        echo "tmux new-window -t \"$session:$win_num\" -n \"$name\" -c \"$dir\""

        if [[ "$has_claude" == "1" ]]; then
          if [[ -n "$sid" ]]; then
            echo "tmux send-keys -t \"$session:$win_num\" \"cd '$dir' && claude --resume $sid\" Enter"
          else
            echo "tmux send-keys -t \"$session:$win_num\" \"cd '$dir' && claude --continue\" Enter"
          fi
        fi
        if [[ "$has_shell" == "1" ]]; then
          echo "tmux split-window -h -t \"$session:$win_num\" -c \"$dir\""
          echo "tmux select-pane -t \"$session:$win_num.1\""
        fi
      fi

      ((win_num++))
    done

    echo ""
    echo "tmux select-window -t \"$session:1\""
    echo ""
  done

  # Attach to first session
  echo "# Attach to first session"
  echo "tmux attach-session -t \"${session_order[0]}\""
} > "$restore_file"

chmod +x "$restore_file"

# Update symlink
ln -sf "$restore_file" "$SYMLINK"

echo "Saved: $restore_file"
echo "Symlinked: $SYMLINK"
echo ""

# Summary grouped by session
for session in "${session_order[@]}"; do
  echo "Session $session:"
  read -ra wins <<< "${session_wins[$session]}"
  win_num=1
  for win in "${wins[@]}"; do
    dir="${win_dir[$win]}"
    name=$(label_for "$win" "$dir")
    indicators=""
    [[ "${win_has_claude[$win]:-0}" == "1" ]] && indicators+=" [claude]"
    [[ "${win_has_shell[$win]:-0}" == "1" ]] && indicators+=" [split]"
    [[ -z "$indicators" ]] && indicators=" [shell]"
    printf "  %d. %-20s %s%s\n" "$win_num" "$name" "$dir" "$indicators"
    ((win_num++))
  done
  echo ""
done
