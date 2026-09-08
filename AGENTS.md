# Agent instructions

You are working in a multi-agent repository. Read this file first, then load
your role prompt from `.agents/prompts/<role>.md`.

## Layout

- `plans/` — planning docs. Main checkout only. Never in worktrees.
- `docs/architecture/` — architecture docs + ADRs.
- `.agents/` — role prompts, templates, lifecycle scripts.
- `.worktrees/<id>/` — per-task git worktrees. **All code changes happen here.**
- `src/` (and other code dirs) — in the main checkout these are read-only
  context; the main checkout stays on `main`.

## Rules

1. **Identify your role** and load `.agents/prompts/<role>.md`. Your role
   prompt defines exactly what you may read and write.
2. **Read only what your role allows.** Do not explore the repo broadly.
   Grep before reading; read only files your plan's Scope section lists.
3. **Communicate via handoff files** (`plans/active/<id>/handoffs/`), never by
   assuming shared context with another agent.
4. **Never edit files owned by another role** (see `.agents/agents.yaml`).
5. **Code changes only in `.worktrees/<id>/`**, never in the main checkout.
6. **Keep docs small:** plan ≤ ~150 lines, handoff ≤ ~60 lines, ADR ≤ ~60
   lines. If you need more context than your budget allows, write an open
   question in the plan and stop.
7. **One task per session.** Work the task id you were given; ignore other
   tasks' plans, worktrees, and branches.

## Task lifecycle (for reference)

`PLANNING → READY → CODING → TESTING → REVIEW → DONE`

Scripts: `new-task.sh` (create plan) · `start-task.sh` (create worktree) ·
`finish-task.sh` (merge + archive) · `task-status.sh` (list tasks).
Full design: `docs/workflow.md`.
