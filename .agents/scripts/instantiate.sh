#!/usr/bin/env bash
# Instantiate a copy of a template repository with a fresh git history.
#
# usage: instantiate.sh <template-dir> <new-dir> [remote-url]
#
#   <template-dir>  existing git repo to copy (e.g. ~/repos/template_repo)
#   <new-dir>       destination path for the copy (created if missing)
#   [remote-url]    optional; set as origin and push main (needs git push to work)
#
# What it does:
#   1. Copies the template, excluding .git, .worktrees, and OS/editor noise.
#   2. Removes any nested .git directories (worktree metadata, vendored repos).
#   3. Resets template-specific state:
#        plans/active/*, plans/done/*  -> removed (empty dirs kept)
#        plans/backlog.md              -> reset to header only
#   4. Replaces the template's repo name with the new one in *.md files.
#   5. git init, initial commit on main, optional remote + push.
set -euo pipefail

TEMPLATE="${1:?usage: instantiate.sh <template-dir> <new-dir> [remote-url]}"
NEW="${2:?usage: instantiate.sh <template-dir> <new-dir> [remote-url]}"
REMOTE="${3:-}"

TEMPLATE="$(cd "$TEMPLATE" && pwd)"
NEW="$(cd "$(dirname "$NEW")" 2>/dev/null || mkdir -p "$(dirname "$NEW")" && cd "$(dirname "$NEW")" && pwd)/$(basename "$NEW")"
NEW_NAME="$(basename "$NEW")"
TEMPLATE_NAME="$(basename "$TEMPLATE")"

# --- sanity checks -----------------------------------------------------------
if [[ ! -d "$TEMPLATE/.git" ]]; then
  echo "error: $TEMPLATE is not a git repository (no .git)" >&2
  exit 1
fi
if [[ -e "$NEW" && -n "$(ls -A "$NEW" 2>/dev/null)" ]]; then
  echo "error: $NEW already exists and is not empty" >&2
  exit 1
fi
if [[ "$TEMPLATE" == "$NEW" ]]; then
  echo "error: template and destination are the same directory" >&2
  exit 1
fi

# --- 1. copy without git state -----------------------------------------------
mkdir -p "$NEW"
rsync -a \
  --exclude '.git' \
  --exclude '.worktrees' \
  --exclude '.DS_Store' \
  --exclude '*.swp' \
  "$TEMPLATE/" "$NEW/"

# --- 2. drop nested git metadata ----------------------------------------------
find "$NEW" -name '.git' -type d -prune -exec rm -rf {} +
find "$NEW" -name '.git' -type f -delete   # worktree pointer files

# --- 3. reset template-specific state -----------------------------------------
rm -rf "$NEW"/plans/active/* "$NEW"/plans/done/* 2>/dev/null || true
mkdir -p "$NEW/plans/active" "$NEW/plans/done"

if [[ -f "$NEW/plans/backlog.md" ]]; then
  # Keep the header (everything before the first example entry), drop examples.
  awk '/^- \[ \] Example:/{exit} {print}' "$NEW/plans/backlog.md" > "$NEW/plans/backlog.md.tmp" \
    && mv "$NEW/plans/backlog.md.tmp" "$NEW/plans/backlog.md"
fi

# --- 4. rename template -> new project in markdown files ----------------------
if [[ "$TEMPLATE_NAME" != "$NEW_NAME" ]]; then
  grep -rl --include='*.md' -F "$TEMPLATE_NAME" "$NEW" 2>/dev/null | while read -r f; do
    sed -i.bak "s/$TEMPLATE_NAME/$NEW_NAME/g" "$f" && rm -f "$f.bak"
  done
fi

# --- 5. fresh git repo ---------------------------------------------------------
cd "$NEW"
git init -q -b main
git add -A
git commit -q -m "Initialize $NEW_NAME from $TEMPLATE_NAME template"

if [[ -n "$REMOTE" ]]; then
  git remote add origin "$REMOTE"
  git push -u origin main
  echo "Pushed main to $REMOTE"
else
  echo "No remote given. When ready: git remote add origin <url> && git push -u origin main"
fi

echo
echo "Done: $NEW"
echo "  - fresh git history (1 commit on main)"
echo "  - plans/active and plans/done emptied, backlog reset"
echo "  - next: .agents/scripts/new-task.sh 0001 \"<first task>\""
