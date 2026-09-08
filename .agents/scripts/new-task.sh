#!/usr/bin/env bash
# Create a new task: plan folder + plan.md from template. No worktree yet.
# usage: new-task.sh <id> <title>
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: new-task.sh <id> <title>" >&2
  exit 1
fi

ID="$1"
TITLE="$2"
ROOT="$(git rev-parse --show-toplevel)"
TASK_DIR="$ROOT/plans/active/$ID"

if [[ -e "$TASK_DIR" ]]; then
  echo "error: $TASK_DIR already exists" >&2
  exit 1
fi

mkdir -p "$TASK_DIR/handoffs"
sed -e "s/^id:.*/id: $ID/" \
    -e "s/^title:.*/title: $TITLE/" \
    -e "s/^branch:.*/branch: task\/$ID/" \
    -e "s/^worktree:.*/worktree: .worktrees\/$ID/" \
    -e "s/^created:.*/created: $(date +%Y-%m-%d)/" \
    "$ROOT/.agents/templates/plan.md" > "$TASK_DIR/plan.md"

echo "Created task $ID: $TASK_DIR"
echo "Next: planner fills in plan.md (status -> ready), then run: start-task.sh $ID"
