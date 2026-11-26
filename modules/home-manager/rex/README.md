# Rex

Rex configuration and Lua automation for persistent, observable multi-agent workspaces.

Rex is a terminal multiplexer from superlogical, installed by hand from the
beta program. Nix does not install the app. It manages only its config, the
fish integration, and a few activation hints.

Implementation snapshot: **2026-11-25**, known-good with
`rex 0.1.0-preview.21` (API revision 18). The loaded configuration has 58
bindings, three modes, and 11 custom actions.

## Contents

- [Install and activate](#install-and-activate)
- [Architecture](#architecture)
- [Design decisions](#design-decisions)
- [Multi-agent workflow](#multi-agent-workflow)
- [Actions](#actions)
- [Scripts](#scripts)
- [Program status and resume](#program-status-and-resume)
- [Testing and maintenance](#testing-and-maintenance)
- [Known boundaries](#known-boundaries)
- [Roadmap](#roadmap)

## Install and activate

Rex must already be installed from the Superlogical beta program. Apply this
Home Manager configuration, then complete Rex's per-account setup:

```fish
home-manager switch --flake ~/Config/nix-config
rex terminfo setup
rex skill setup
rex config check
rex config reload
```

Codex asks before running a new hook. Approve the Rex hook with `/hooks`, then
start a new Codex session inside Rex. Check all integrations with
`rex skill status`.

`~/.config/rex` is linked directly to this repository instead of copied into
the Nix store. Lua edits are immediately visible on disk, but Rex does not
watch them: run `rex config reload` (`rxr`) after editing.

## Architecture

The configuration separates policy, layout construction, actions, bindings,
and long-running automation:

```text
init.lua
├── resume.lua          OSC 7577 trust policy
├── hosts.lua           remote Rex server declarations
├── actions.lua         palette and `rex do` actions
│   ├── agents.lua      agent catalog and team presets
│   └── layouts.lua     reusable block/layout builders
├── modes.lua           resize, move, and agent key modes
└── keys.lua            leader bindings and overrides

scripts/
├── agent-watch.lua     event-driven attention monitor
├── agent-status.lua    sanitized status/resume inventory
├── workspace.lua       idempotent named workspace
├── test-zoom.lua       run/wait/zoom workflow
└── session-export.lua  atomic session snapshots
```

`init.lua` loads each top-level module through `pcall`. A broken optional
module is logged and skipped so unrelated bindings can still load. Standalone
scripts are separate because config files cannot subscribe to events, while
`rex do` scripts can use `rex.on`, timers, waits, and server APIs.

## Design decisions

| Choice | Why |
| --- | --- |
| Out-of-store config symlink | Lua can be edited and reloaded without rebuilding Home Manager. |
| App-owned appearance remains unmanaged | Rex writes theme, font, and tab preferences itself; Nix would create a second writer. |
| One shared agent catalog | Commands and presets stay consistent across layouts and actions. |
| Idempotent team windows | Re-running `agent_team` focuses the existing project window instead of multiplying panes. |
| Stable pane labels | `operator` and `agent:<name>` make focus, monitoring, and selective broadcast deterministic. |
| Explicit broadcast selection | Prompts are never fanned out in the background; the user selects panes and confirms the message. |
| Foreground-process guard | A stale label cannot cause natural language to execute in a shell after an agent exits. |
| Narrow resume trust roots | Restoring a saved program is code execution without a new confirmation. |
| No automatic worktree lifecycle yet | Creating, merging, and deleting worktrees needs explicit ownership and cleanup. |
| Resume commands omitted from reports | Saved commands may contain prompts or secrets; routine status output exposes metadata only. |

The broader rationale and phased design live in
[docs/rex-agent-orchestration.md](../../../docs/rex-agent-orchestration.md).

## What is managed here

- **Lua config** (`config/init.lua` and its modules): resume policy, agent
  catalog, hosts, actions, modes, keys, and layouts.
- **Automation scripts** (`config/scripts/`): `rex do` scripts that run
  against a live session.
- **Fish integration** (`default.nix`): cached completions and `rx*` abbreviations.
- **Activation hints** (`default.nix`): config check and reload, plus terminfo
  and agent skill hints. They print and never install or fail the switch.

## What is app-owned (deliberately unmanaged)

Appearance and UI preferences live in the app's plist,
`com.superlogical.rex`: theme (cathode-amber), tabs, fonts. Rex writes them
itself, so they are not in this repo. Change them in the app.

## Workflow

`~/.config/rex` is linked out-of-store to `config/` in this repo, so edits are
live on disk. Rex does not watch the files:

1. Edit a file under `config/`.
2. `rxr` (`rex config reload`). A broken module is logged and skipped, and the
   last good config stays in effect.
3. `rex keymap` shows the bindings that loaded. `rex actions` lists the actions.

Run `rex config check` before reloading if you want the errors first.

## File map

| Path | Purpose |
| --- | --- |
| `default.nix` | `xdg.configFile.rex` link, activation hooks, fish completion and abbreviations |
| `config/init.lua` | Entry point. Loads `resume`, `hosts`, `actions`, `modes`, `keys` under `pcall` |
| `config/resume.lua` | Project-scoped OSC 7577 trust policy for supported agents |
| `config/agents.lua` | Agent commands and team presets shared by actions and layouts |
| `config/hosts.lua` | Hosts Rex connects to |
| `config/actions.lua` | Named actions (`rex do <name>`) |
| `config/modes.lua` | Key modes |
| `config/keys.lua` | Key bindings, loaded last |
| `config/layouts.lua` | Shared layout builders (`SHELL`, `shell`, `cmd`, `h`/`v`, `dev`, `agent`, `cwd_of`), required by actions and scripts |
| `config/scripts/*.lua` | Standalone scripts, run with `rex do` |
| `config/.gitignore` | Runtime files Rex writes into the linked dir |
| `CHECKLIST.md` | Manual regression and exploratory test matrix |

## Multi-agent workflow

Press `cmd+;`, release, then press `w` (written as `L w`). Pick a preset and
Rex creates an idempotent project window containing:

- an `operator` shell;
- one labelled pane per agent (`agent:claude`, `agent:codex`, `agent:pi`);
- an even two-, three-, or four-pane layout.

The default label is `agents:<directory-name>`. Running the action again from
that project focuses the existing window. The non-interactive equivalent is:

```fish
rex do agent_team cwd=~/Config/nix-config agents=claude,codex
```

Team panes share a checkout. Use them for research/review or assign
non-overlapping files. Give simultaneous writing agents separate worktrees.

### Key map

`L` means press `cmd+;`, release it, then press the next key.

| Keys | Function |
| --- | --- |
| `L w` | Open or focus an agent team. |
| `L c`, `L x`, `L p` | Open the single-agent layout with Claude, Codex, or Pi. |
| `L a`, then `t` | Open/focus an agent team from the one-shot agent mode. |
| `L a`, then `f` | Pick and focus a labelled operator/agent pane. |
| `L a`, then `b` | Select agents and broadcast an explicit prompt. |
| `L d`, `L s`, `L f` | Open the dev layout, scratch shell, or focus mode. |
| `L r`, `L m` | Enter resize or move mode. |
| `L n`, `L b`, `L l` | Home Manager switch, Nix build, or Rex config reload. |

Run `rex keymap` for the complete generated map and source lines.

## Actions

Actions appear in the Rex palette and can usually be invoked with
`rex do <name> key=value`.

| Action | Function and notable behaviour |
| --- | --- |
| `agent_team` | Pick or provide 1–3 agents; focus an existing team window or build a balanced operator/agent layout. |
| `agent_focus` | Pick a labelled team pane and focus its containing window. |
| `agent_broadcast` | Pick multiple agent panes, ask for a prompt, verify each still has a non-shell foreground process, then type it. |
| `agent_layout` | Open one agent beside a shell and a Git/Jujutsu history pane. |
| `scratch` | Open a floating shell in the invoking pane's reported directory. |
| `focus_mode` | Zoom the focused pane and toggle the sidebar. |
| `dev_layout` | Open two shells in the current directory. |
| `open_repo` | Open a labelled shell window at an explicit path. |
| `nix_build` | Build this Home Manager activation package without switching. |
| `nix_switch` | Run the Home Manager switch in a visible Rex window. |
| `rex_reload` | Reload through the connected client or fall back to the CLI. |

Custom team combinations work from the CLI:

```fish
rex do agent_team agents=claude,codex,pi cwd=~/Projects/example
rex do agent_team agents=codex cwd=~/Projects/example name=review
```

`agent_team` accepts at most three unique agents plus the operator pane.

## Scripts

Each script has its usage in its header comment. Run them from any Rex
terminal, which targets that terminal's session. Use `-s NAME` to target
another session.

```fish
rex do ~/.config/rex/scripts/agent-watch.lua               # flag blocks that need attention
rex do ~/.config/rex/scripts/agent-watch.lua notify=true   # also macOS notification
rex do ~/.config/rex/scripts/test-zoom.lua cmd="make test" # run in a split, zoom on failure
rex do ~/.config/rex/scripts/session-export.lua every=30   # rewrite session JSON every 30s
rex do ~/.config/rex/scripts/workspace.lua name=rex cwd=~/Config/nix-config
rex do ~/.config/rex/scripts/agent-status.lua --json        # status + sanitized resume metadata
```

- `agent-watch.lua` is long-running. It prefixes a block's label with `● ` on
  a bell, a desktop notification, or an attention program status (`blocked`,
  `error`). The flag clears when the block is focused or its status clears.
  Stop it with Ctrl-C.
- `test-zoom.lua` runs `cmd` (or `--args '{"argv":[...]}'`) in a new split,
  zooms the pane on a non-zero exit, and exits with the command's code.
- `session-export.lua` writes `session.view` and the block list as JSON. The
  default path is `~/.local/state/rex/session-<id>.json`.
- `workspace.lua` focuses the window labelled `name` if it exists. Otherwise it
  creates one with `layouts.agent{cwd}`. Running it twice does not duplicate it.
- `agent-status.lua` reports OSC 7501 agent state and OSC 7577 resume trust for
  each relevant pane. It deliberately omits saved commands because those can
  contain prompts or other secrets.

## Program status and resume

Two terminal protocols serve different purposes:

| Protocol | Purpose | Used here |
| --- | --- | --- |
| OSC 7501 Program Status | Reports whether a program is working, blocked, done, or failed. | `agent-watch.lua`, `agent-status.lua`, and Rex's native UI indicators. |
| OSC 7577 Program Resume | Reports the exact command that can restore a resumable program session. | Rex server snapshots plus `resume.lua` trust rules. |

Resume is both a program capability and a policy decision: a program must
report a real resume command, and Rex must trust it.

`config/resume.lua` keeps Rex's built-in rules but restricts Claude, Codex, and
OpenCode to common project roots. It also refuses to automatically restore a
Claude session launched with `--dangerously-skip-permissions`. Add another
trusted root there when needed.

```text
~/Config  ~/Projects  ~/Developer  ~/src  ~/code
```

As of preview.21, Claude Code reports resumable sessions through the hook from
`rex skill setup`. Rex includes Codex and OpenCode trust rules, but those
clients do not yet report resume records; Pi has no rule. Their panes still
restore as shells in the last directory.

Inspect the current pane directly with:

```fish
rex block call -b "$REX_BLOCK" program_resume_records
```

Or use `rxstatus` for a session-wide, command-free report. Raw records may
contain a saved `command` with prompts or secrets, so do not export them
casually.

Scripts load `layouts.lua` through `package.path`. The `package.path` line
derives the script's own directory from `debug.getinfo`, so it works from any
directory.

## Testing and maintenance

Before committing a change:

```fish
rex config check --autostart=false
git diff --check
nix build --no-link '.#homeConfigurations."christopher.chalcraft".activationPackage'
```

For behavioural changes, use a disposable Rex session and work through
[CHECKLIST.md](CHECKLIST.md). During the 2026-11-25 implementation pass,
`agent_team` was tested end to end: it created and labelled an operator/Codex
layout, then returned the same window with `created=false` on the second run.
The temporary session was removed. `agent-status.lua` also read a live Codex
`working` record successfully.

When Rex is upgraded:

1. Run `rex version`; update the snapshot above and the version comment in
   `default.nix` after validation.
2. Run `rex config check`, `rex skill status`, `rex actions`, and `rex keymap`.
3. Re-run the resume/status and disposable team checks in `CHECKLIST.md`.
4. Review the upstream Lua, event, resume-rule, and protocol documentation for
   changed fields or semantics.

If a reload fails, run `rex config check` and inspect `rex server logs`. The
last good server configuration remains active. Activation hooks print hints
instead of failing an entire Home Manager switch.

## Known boundaries

- Team panes share a checkout; concurrent writers need separate worktrees.
- The default team label uses the directory basename. For two same-named
  projects in one session, pass `name=...` explicitly.
- Broadcast verifies that the foreground process is not a known shell, but it
  cannot prove the agent is at a safe conversational prompt. Select targets
  deliberately.
- `focus_mode` toggles two independent client actions rather than maintaining a
  persisted state machine.
- `agent-watch.lua` is not automatically started; `rxwatch` starts it manually.
- Remote hosts fit the config architecture, but none are declared yet.
- Appearance is not reproducible from this repository by design.

## Roadmap

The next valuable layer is **worktree-aware teams**: one explicit worktree per
writing agent, a small inspectable run manifest, and separate confirmed
cleanup. Later phases cover role-specific handoff, a persistent fleet
controller, an attention inbox, native resume support in more agents, and
cross-host fleets.

See [the orchestration design note](../../../docs/rex-agent-orchestration.md)
for the rationale, phased plan, and safety boundaries.

## Troubleshooting

- **Config did not load.** Run `rex config check` to see the error. A module
  that fails is logged and skipped, and the last good config stays active until
  a clean reload.
- **A key does nothing.** Run `rex keymap` to see what each key does for this
  client. Later bindings replace earlier ones, and `keys.lua` loads last.
- **Activation says terminfo is not installed.** Run `rex terminfo setup` once
  per account. `rex terminfo status` shows what this machine would use.
- **Activation says a skill or hook is missing.** Run `rex skill setup` once per
  account. `rex skill status` shows what is installed.
- **Completions are stale after a rex upgrade.** Completions regenerate
  automatically when the rex binary is newer than `~/.cache/rex/completion.fish`.
  Delete that file to force it.
- **A script fails.** Run it with `rex do -v ...`, or check the `info`/`error`
  lines it logs.

## TODO

- Register the community Rex MCP server as `superlogical`. It is gated behind
  Discord OAuth, and the URL comes from the Rex Beta Discord. Add it with
  `claude mcp add --scope user ...`, which writes to `~/.claude.json`
  `mcpServers`. That file is the canonical location, per
  `~/.agents/AGENT-ENVIRONMENT.md`. Do not add it to this repo.
