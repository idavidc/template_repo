# template_repo — multi-agent development template

A folder structure + workflow that lets different agents (planner, architect,
coder, tester) work on one code repository in parallel, using **git worktrees**
for code isolation and **file-based handoffs** to keep every agent's context
small.

**Key idea:** planning docs live in the main checkout (`plans/`, `docs/`);
code changes happen in per-task worktrees (`.worktrees/<id>/`). Agents
communicate through small structured files, never through shared conversation
history.

## Creating a new project from this template

```bash
.agents/scripts/instantiate.sh ~/repos/template_repo ~/repos/my-project [git@github.com:me/my-project.git]
```

Copies the template (without `.git` or worktrees), resets `plans/` and the
backlog, renames the project in docs, and starts a fresh git history with one
commit on `main` (plus a push if you give a remote URL).

## Quickstart

```bash
# 1. Create a task (plan folder only, no worktree yet)
.agents/scripts/new-task.sh 0001 "Add rate limiter to API"

# 2. Planner agent fills in plans/active/0001/plan.md (status → ready)

# 3. Create worktree + branch when coding starts
.agents/scripts/start-task.sh 0001

# 4. Coder agent implements in .worktrees/0001 (status → testing)
# 5. Tester agent verifies in .worktrees/0001 (status → review)

# 6. Merge, remove worktree, archive plan
.agents/scripts/finish-task.sh 0001

# Anytime: see where all tasks stand
.agents/scripts/task-status.sh
```

## Where things live

| Path | What | Owned by |
|---|---|---|
| `AGENTS.md` | Rules every agent reads first | — |
| `.agents/prompts/` | One system prompt per role | — |
| `.agents/templates/` | plan / handoff / test-report / ADR templates | — |
| `.agents/scripts/` | task lifecycle + `instantiate.sh` (new project from template) | — |
| `plans/backlog.md` | raw ideas | planner |
| `plans/active/<id>/` | plan, ADRs, handoffs, test report | planner → coder → tester |
| `plans/done/<id>/` | archived tasks | — |
| `docs/architecture/` | living architecture docs | architect |
| `docs/workflow.md` | the full workflow design | — |
| `.worktrees/<id>/` | per-task git worktrees (gitignored) | coder, tester |

## Read this next

- **`docs/workflow.md`** — the complete design: roles, lifecycle, handoff
  protocol, context budgets, parallelism rules.
- **`AGENTS.md`** — what any agent must do when it opens this repo.
