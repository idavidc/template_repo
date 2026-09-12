#!/usr/bin/env bash
# Instantiate a new project from a template repository, with a fresh git
# history and its own GitHub remote.
#
# usage: instantiate.sh [template-dir] <name-or-path>
#
#   [template-dir]  source template repo. Default: ~/repos/template_repo
#   <name-or-path>  new project, given as either:
#                     - a bare name (e.g. "my-project")  -> created at ~/repos/my-project
#                     - a path   (e.g. "/tmp/x" or "~/x") -> created there
#
# What it does:
#   1. Copies the template, excluding .git, .worktrees, and OS/editor noise.
#   2. Removes any nested .git directories (worktree metadata, vendored repos).
#   3. Resets template-specific state:
#        plans/active/*, plans/done/*  -> removed (empty dirs kept)
#        plans/backlog.md              -> reset to header only
#   4. Replaces the template's repo name with the new one in *.md files.
#   5. git init, initial commit on main.
#   6. Creates a GitHub repo named after the folder (private, no template
#      files) via `gh`, sets it as origin, and pushes main.
#      Skipped with --no-push.
set -euo pipefail

NO_PUSH=0
if [[ "${1:-}" == "--no-push" ]]; then
  NO_PUSH=1
  shift
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: instantiate.sh [--no-push] [template-dir] <name-or-path>" >&2
  exit 1
fi

# The name/path is always the last argument; template-dir is optional.
if [[ $# -eq 1 ]]; then
  TEMPLATE="$HOME/repos/template_repo"
  TARGET="${1}"
else
  TEMPLATE="${1}"
  TARGET="${2}"
fi

TEMPLATE="$(cd "$TEMPLATE" && pwd)"
TEMPLATE_NAME="$(basename "$TEMPLATE")"

# Bare name -> ~/repos/<name>; anything else is a path.
if [[ "$TARGET" == */* ]]; then
  NEW="${TARGET/#\~/$HOME}"
else
  NEW="$HOME/repos/$TARGET"
fi
NEW="$(cd "$(dirname "$NEW")" 2>/dev/null || mkdir -p "$(dirname "$NEW")" && cd "$(dirname "$NEW")" && pwd)/$(basename "$NEW")"
NEW_NAME="$(basename "$NEW")"

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

# --- 6. GitHub remote + push ---------------------------------------------------
if [[ "$NO_PUSH" -eq 1 ]]; then
  echo "Skipped GitHub push (--no-push). When ready:"
  echo "  gh repo create $NEW_NAME --private --source . --remote origin --push"
else
  if ! command -v gh >/dev/null 2>&1; then
    echo "error: gh CLI not found; install it or re-run with --no-push" >&2
    exit 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    echo "error: gh is not authenticated. Run: gh auth login" >&2
    exit 1
  fi
  echo "Creating GitHub repo '$NEW_NAME'..."
  gh repo create "$NEW_NAME" --private --source . --remote origin --push
fi

echo
echo "Done: $NEW"
echo "  - fresh git history (1 commit on main)"
echo "  - plans/active and plans/done emptied, backlog reset"
echo "  - next: cd $NEW && .agents/scripts/new-task.sh 0001 \"<first task>\""
