#!/usr/bin/env bash
# Finish a task: merge its branch into the current branch, remove the
# worktree, and archive the plan folder to plans/done/.
# Run from the main checkout.
# usage: finish-task.sh <id>
set -euo pipefail

ID="${1:?usage: finish-task.sh <id>}"
ROOT="$(git rev-parse --show-toplevel)"
WT="$ROOT/.worktrees/$ID"
BRANCH="task/$ID"
ACTIVE="$ROOT/plans/active/$ID"
DONE="$ROOT/plans/done/$ID"

if [[ ! -d "$ACTIVE" ]]; then
  echo "error: no active plan at $ACTIVE" >&2
  exit 1
fi

TITLE="$(grep -m1 '^title:' "$ACTIVE/plan.md" | sed 's/^title: *//' || true)"

# 1. Merge the task branch (worktree is removed only after a clean merge)
git merge --no-ff "$BRANCH" -m "task/$ID: ${TITLE:-merged}"

# 2. Remove worktree + branch
if [[ -d "$WT" ]]; then
  git worktree remove "$WT" --force
fi
git branch -d "$BRANCH" 2>/dev/null || true

# 3. Archive the plan
mkdir -p "$ROOT/plans/done"
mv "$ACTIVE" "$DONE"
sed -i.bak -e 's/^status: .*/status: done/' "$DONE/plan.md"
rm -f "$DONE/plan.md.bak"

echo "Task $ID finished: merged $BRANCH, removed worktree, archived plan to $DONE"
