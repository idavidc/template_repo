#!/usr/bin/env bash
# Create the git worktree + branch for a task (enter CODING state).
# usage: start-task.sh <id>
set -euo pipefail

ID="${1:?usage: start-task.sh <id>}"
ROOT="$(git rev-parse --show-toplevel)"
WT="$ROOT/.worktrees/$ID"
BRANCH="task/$ID"

if [[ ! -f "$ROOT/plans/active/$ID/plan.md" ]]; then
  echo "error: no plan at plans/active/$ID/plan.md — run new-task.sh first" >&2
  exit 1
fi

if [[ -d "$WT" ]]; then
  echo "worktree already exists: $WT (branch $BRANCH)"
  exit 0
fi

git worktree add "$WT" -b "$BRANCH"
sed -i.bak -e "s/^status: .*/status: coding/" "$ROOT/plans/active/$ID/plan.md"
rm -f "$ROOT/plans/active/$ID/plan.md.bak"

echo "Worktree ready: $WT (branch $BRANCH)"
echo "Coder: work in $WT, read plans/active/$ID/plan.md"
