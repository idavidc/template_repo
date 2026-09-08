# Multi-Agent Workflow

How planner / architect / coder / tester agents collaborate on this repository
using git + git worktrees, with planning docs kept separate from code so each
agent's context stays small.

## Core principles

1. **Docs in main, code in worktrees.**
   Planning and architecture docs live in the *main checkout* (on `main`) and
   are committed to `main`. Code changes happen in per-task git worktrees
   under `.worktrees/<id>/` on branch `task/<id>`.

2. **Files are the interface.**
   Agents never share conversation history. They hand off via small structured
   files: `plan.md`, `handoffs/*.md`, `test-report.md`, `adr-*.md`. The next
   agent reads only those files — not the previous agent's session.

3. **Context budgets are enforced per role.**
   Each role prompt (`.agents/prompts/<role>.md`) lists exactly which files the
   agent may read. The plan is the contract; agents do not re-derive intent by
   reading the whole repo.

4. **One task = one plan folder = one branch = one worktree.**
   `plans/active/<id>/` ↔ `task/<id>` ↔ `.worktrees/<id>/`.

## Layout

```
repo/
├── AGENTS.md                  # First file any agent reads (rules of the road)
├── .agents/
│   ├── agents.yaml            # Role registry: cwd, read/write paths per role
│   ├── prompts/               # One system prompt per role
│   │   ├── planner.md
│   │   ├── architect.md
│   │   ├── coder.md
│   │   └── tester.md
│   ├── templates/             # plan / handoff / test-report / adr templates
│   └── scripts/
│       ├── new-task.sh        # create plan folder (no worktree yet)
│       ├── start-task.sh      # create worktree + branch (enter CODING)
│       ├── finish-task.sh     # merge, remove worktree, archive plan
│       └── task-status.sh     # list all tasks + status
├── plans/                     # PLANNING DOCS — main checkout only
│   ├── backlog.md             # raw ideas, one line each
│   ├── active/<id>/
│   │   ├── plan.md            # the contract (frontmatter holds status)
│   │   ├── adr-NN-*.md        # design decisions for this task
│   │   ├── handoffs/          # N-<from>-to-<to>.md, numbered in order
│   │   └── test-report.md
│   └── done/<id>/             # archived after finish-task.sh
├── docs/
│   ├── workflow.md            # this file
│   └── architecture/          # living architecture docs (architect-owned)
├── .worktrees/<id>/           # per-task git worktrees (gitignored)
└── src/ ...                   # code — main checkout stays on main
```

## Roles

| Role      | Works in     | Reads (only)                          | Writes (only)                              |
|-----------|--------------|---------------------------------------|--------------------------------------------|
| Planner   | main checkout| backlog, architecture docs, template  | `plans/active/<id>/plan.md`, backlog       |
| Architect | main checkout| plan + handoffs, architecture, code (grep-first) | `docs/architecture/**`, `adr-*.md`, plan Context/Risks |
| Coder     | worktree     | plan, handoffs, scoped code           | worktree code (scope only), handoffs       |
| Tester    | worktree     | plan (acceptance criteria), handoff, code under test | worktree tests, `test-report.md`, handoffs |
| Reviewer  | main checkout| diff, plan, handoff, test report      | review notes in plan.md (optional role)    |

Full read/write rules: `.agents/agents.yaml`.

## Lifecycle

```
 plans/backlog.md
      │  .agents/scripts/new-task.sh <id> <title>
      ▼
 PLANNING ──► READY ──► CODING ──► TESTING ──► REVIEW ──► DONE
  (planner)   (architect  (coder)   (tester)   (reviewer)  (finish-task.sh)
              if needed)
```

- **PLANNING** — no worktree exists yet. Planner writes `plan.md`
  (goal, scope, tasks, acceptance criteria).
- **READY** — plan complete; acceptance criteria are testable. If the plan
  contains `needs architect` markers, the architect writes ADRs first.
- **CODING** — `start-task.sh <id>` creates `.worktrees/<id>` + branch
  `task/<id>`. Coder implements, checking off plan tasks as it goes.
- **TESTING** — tester (same worktree) writes/runs tests against the
  acceptance criteria, produces `test-report.md`.
- **REVIEW** — optional. Diff reviewed against plan; notes go in plan.md.
- **DONE** — `finish-task.sh <id>` merges `task/<id>` into the current
  branch, removes the worktree, moves the plan folder to `plans/done/`.

Status is tracked in `plan.md` frontmatter (`status:` field) and by folder
location (`active/` vs `done/`). `task-status.sh` shows everything.

## Handoff protocol

When an agent finishes, it writes
`plans/active/<id>/handoffs/N-<from>-to-<to>.md` (template:
`.agents/templates/handoff.md`) and appends one line to the plan's
**Handoff log**. The next agent reads **only**:

1. `plan.md`
2. the latest handoff
3. (coder/tester) the code paths listed in the plan's Scope section

Handoffs are capped at ~60 lines. If an agent needs more context than that,
it writes an **open question** in the plan and stops — it does not go read
the whole repo.

## Context budget rules

- `plan.md` ≤ ~150 lines; handoff ≤ ~60 lines; ADR ≤ ~60 lines.
- Coder/tester never read other tasks' plans, worktrees, or branches.
- Tester never reads planner reasoning or ADRs unless a failure is ambiguous.
- Planner/architect never read full source files — grep for symbols to verify
  scope claims.
- One task per agent session. If a plan's task list exceeds the session's
  context, stop at the last completed checkbox and hand off.

## Parallelism & conflicts

- Multiple tasks can be in CODING simultaneously: separate worktrees,
  separate branches, no checkout conflicts.
- The planner serializes tasks that touch the same files via `depends_on:`
  in plan frontmatter.
- `finish-task.sh` merges into the current branch. On conflict, the task
  goes back to CODING (recreate worktree from the branch, which still exists
  until the merge succeeds).
- **Worktrees are optional.** If unavailable, run one task at a time: check
  out `task/<id>` in the main checkout, work, merge. The file-based protocol
  is unchanged.

## Launching agents

Start one agent session per role, loading the role prompt as the system
prompt (or first instruction), and give it the task id:

```
planner:   "Plan task 0001: <title>"            → .agents/prompts/planner.md
architect: "Resolve open questions in task 0001" → .agents/prompts/architect.md
coder:     "Implement task 0001 in .worktrees/0001" → .agents/prompts/coder.md
tester:    "Test task 0001 in .worktrees/0001"  → .agents/prompts/tester.md
```

A coordinator (human or orchestrator agent) runs the scripts and moves tasks
between states; it does not do the role work itself.
