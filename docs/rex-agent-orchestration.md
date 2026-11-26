# Rex agent orchestration

This is the working design note for using Rex as the control plane around
multiple coding agents. The first slice is implemented under
`modules/home-manager/rex`; later slices should stay incremental and keep
agent/process lifecycle visible to the operator.

## What Rex can coordinate

Rex exposes four useful layers:

1. **Topology:** sessions, windows, splits, floating layers, stable labels,
   focus, and layout construction.
2. **Control:** create panes, type input, capture output, wait for exits, call
   terminal methods, and present interactive Lua pickers.
3. **State:** OSC 7501 program status (`working`, `blocked`, `error`, etc.),
   terminal events, foreground processes, and session view events.
4. **Continuity:** saved layouts/directories plus OSC 7577 resume records,
   filtered through explicit trust rules.

Those layers make Rex a good operator surface, but not a replacement for an
agent's own task graph. Rex should launch, isolate, observe, route attention,
and restore. Agents should still own reasoning and task execution.

## Implemented slice

- `resume.lua` scopes built-in agent resume rules to project roots and rejects
  automatic restoration of permission-bypassing Claude sessions.
- `agents.lua` is the single catalog for Claude, Codex, Pi, and team presets.
- `layouts.team` builds an operator pane plus up to three agent panes.
- `agent_team` is idempotent per default window label.
- `agent_focus` provides a palette switcher for labelled team panes.
- `agent_broadcast` sends an explicit prompt only to selected panes and refuses
  to write after an agent pane has fallen back to a shell.
- `agent-watch.lua` surfaces blocked/error states and optional notifications.
- `agent-status.lua` combines OSC 7501 state with sanitized OSC 7577 trust
  metadata. It never returns saved resume commands.

Program resume is deliberately treated as a capability, not an assumption.
With Rex preview.21, Claude reports resumable sessions through the Rex hook.
Codex and OpenCode have trust rules but do not report yet; Pi has no rule.

## Next experiments

### 1. Worktree-aware teams

Add a separate, explicitly named action that creates one Git/Jujutsu worktree
per writing agent, then opens each pane in its own directory. Store a small
manifest under the repository (or Rex state) with:

- team/window ID;
- agent and role;
- worktree path and branch/bookmark;
- creation time and cleanup state.

Cleanup must be a distinct confirmation step. Never infer that a worktree is
safe to delete just because its agent exited.

### 2. Role/task handoff

Extend the catalog with role templates such as implementer, reviewer, and
researcher. Render the task plus constraints per target agent, rather than
broadcasting identical prose. Keep prompts out of window labels and logs.

A useful first protocol is file-based and inspectable:

```text
.agents/runs/<team-id>/
  task.md
  implementer.md
  reviewer.md
  state.json
```

Rex can open/focus the panes and notify on state; agents can update the run
files without needing a new Rex-specific RPC layer.

### 3. Persistent fleet controller

Turn `agent-watch.lua` into one `rex do ... --all` controller started by a
Home Manager launch agent. It should react to:

- `terminal.program_status_changed` and `_removed`;
- `terminal.program_resume_changed`;
- `block_created`, `block_closed`, and `session_destroyed`;
- `session_view_changed` with debounce.

The controller can maintain a compact JSON index for external status bars and
notifications. It should preserve human labels separately rather than stacking
status glyphs into them.

### 4. Agent inbox

Build an action using `rex.ui.pick` that lists only panes needing attention,
with state, app, task message, session, and window. Selecting one focuses it.
This removes polling and makes many concurrent agents manageable.

### 5. Resume coverage

Track native OSC 7577 support in Codex, OpenCode, and Pi. Prefer native reports
because they contain the real conversation/session ID. A generic wrapper can
restart a command, but Rex intentionally does not trust wrapper reports when
the resulting process differs, and restarting an agent without its session ID
is not continuity.

### 6. Cross-host fleets

When a second Rex server exists, add it with `rex.host{}` and make status/focus
scripts iterate `rex.servers()`. Keep OSC 7577 tokens local: the protocol
explicitly forbids forwarding them over SSH or into containers.

## Safety boundaries

- Multiple writers do not share one checkout unless their file ownership is
  explicitly non-overlapping.
- Broadcast is opt-in per message and per pane; it is not a background fan-out.
- A pane label is not proof that an agent is still running. Check foreground
  process/status immediately before sending input.
- Saved resume commands may contain prompts or secrets. Status tooling omits
  the `command` field by default.
- Resume trust roots stay narrow. Add roots intentionally instead of trusting
  the whole home directory.
- Destructive cleanup, merge, push, deployment, and external messaging remain
  separate authorized actions.

## Primary references

- <https://www.superlogical.com/rex/docs/build/program-resume>
- <https://www.superlogical.com/rex/docs/customize/resume-rules>
- <https://www.superlogical.com/rex/docs/build/program-status>
- <https://www.superlogical.com/rex/docs/automate/lua-scripts>
- <https://www.superlogical.com/rex/docs/automate/lua-events>
- <https://www.superlogical.com/rex/docs/reference/lua>
