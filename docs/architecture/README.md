# Architecture

Living architecture documentation, owned by the **architect** role.

- One file per major subsystem or cross-cutting concern (e.g.
  `api.md`, `data-model.md`, `deployment.md`).
- Keep each file small and current; prefer updating over adding.
- Task-specific design decisions do **not** go here — they go in
  `plans/active/<id>/adr-NN-*.md`. Promote a decision to this directory only
  when it changes the system's shape.
