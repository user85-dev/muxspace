#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source "$HOME/connect-coder/modules/select_coder_env.sh"

SELECTED_CODER=""

while getopts "a" opt; do
	case ${opt} in
	a)
		SELECTED_CODER=$(tmux display-message -p '#S')
		;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;
	esac
done

if [ -z "$SELECTED_CODER" ]; then
	select_environment
fi

echo "Workspace selected: $SELECTED_CODER"

if ! tmux has-session -t "$SELECTED_CODER" 2>/dev/null; then
	echo "Session '$SELECTED_CODER' not found. Trying to restore with tmux-resurrect..."

	if ! tmux ls &>/dev/null; then
		echo "No tmux server running, starting dummy session"
		tmux new-session -d -s __dummy_session
	fi

	tmux send-keys -t __dummy_session "bash $HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh" C-m
	sleep 3

	if tmux has-session -t "$SELECTED_CODER" 2>/dev/null; then
		echo "Session '$SELECTED_CODER' restored successfully!"
		tmux kill-session -t __dummy_session
	fi
fi

if ! tmux has-session -t "$SELECTED_CODER" 2>/dev/null; then
	echo "Session still not found. Creating new session '$SELECTED_CODER'..."

	WORKDIR="$HOME/workenv"

	tmux new-session -d -s "$SELECTED_CODER" -c "$WORKDIR" -n editor
	tmux new-window -t "$SELECTED_CODER:" -n general -c "$WORKDIR"
	tmux new-window -t "$SELECTED_CODER:" -n git -c "$WORKDIR"
	tmux select-window -t "$SELECTED_CODER:1"
fi

echo "Attaching to session '$SELECTED_CODER'..."
tmux attach -t "$SELECTED_CODER"
