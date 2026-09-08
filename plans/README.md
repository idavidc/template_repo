# plans/

Planning documentation. Lives in the **main checkout only** — never in
worktrees. This separation is what keeps code agents' contexts small: they
read one small plan folder, not the whole repo's history of thinking.

## Lifecycle

```
backlog.md  →  active/<id>/  →  done/<id>/
```

- `backlog.md` — raw ideas, one line each.
- `active/<id>/` — a task in flight:
  - `plan.md` — the contract (goal, scope, tasks, acceptance criteria).
    Status lives in its frontmatter.
  - `adr-NN-*.md` — design decisions for this task (architect).
  - `handoffs/N-<from>-to-<to>.md` — numbered agent-to-agent handoffs.
  - `test-report.md` — tester's verdict.
- `done/<id>/` — archived by `finish-task.sh` after merge.

## Conventions

- Task ids: zero-padded numbers (`0001`, `0002`, …).
- `plan.md` ≤ ~150 lines; handoffs ≤ ~60 lines; ADRs ≤ ~60 lines.
- Tasks that touch the same files must declare `depends_on:` in the plan
  frontmatter and be serialized.
- See `docs/workflow.md` for the full design.
