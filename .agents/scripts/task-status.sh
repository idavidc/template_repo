#!/usr/bin/env bash
# List all tasks (active + done) with status and title.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
printf "%-24s %-10s %s\n" "TASK" "STATUS" "TITLE"
for f in "$ROOT"/plans/active/*/plan.md "$ROOT"/plans/done/*/plan.md; do
  [[ -e "$f" ]] || continue
  id="$(basename "$(dirname "$f")")"
  status="$(grep -m1 '^status:' "$f" | sed 's/^status: *//' || echo '?')"
  title="$(grep -m1 '^title:' "$f" | sed 's/^title: *//' || echo '')"
  printf "%-24s %-10s %s\n" "$id" "$status" "$title"
done
