# Rex config — test & improve checklist

A working list for exercising everything in `modules/home-manager/rex/` by hand,
recording what actually happens, and turning findings into fixes. Tick a box
when the expected result holds; otherwise write what happened under **Findings**
and add a backlog item.

Notation: `L` = the leader `cmd+;`, so `L r` = press `cmd+;`, release, press `r`.
Run the checks in Rex itself (not over SSH), in a throwaway session where
possible (`shift+cmd+n`).

## 0. Preconditions

- [ ] `realpath ~/.config/rex` → `~/Config/nix-config/modules/home-manager/rex/config`
- [x] `rex config check` → exists: yes, 58 bindings, 3 modes, 11 actions, exit 0 (2026-11-25)
- [ ] `rex keymap` → every custom row's SOURCE is `keys.lua:N` / `modes.lua:N`; MODE table lists resize, move, agent; no BLOCKED rows
- [x] `rex actions` → lists all 11 actions, including agent_team, agent_focus, and agent_broadcast (2026-11-25)
- [ ] `rex terminfo setup`; `rex skill setup` is current for all supported agents (Codex hook still needs `/hooks` approval in the client)

## 1. Leader & plain bindings (`keys.lua`)

| ✓ | Keys | Expect | Findings |
|---|------|--------|----------|
| [ ] | `L` then wait ~2s | key-sequence hint shows the `L` continuations; Esc cancels | |
| [ ] | `L =` | splits equalise (make an uneven split first) | |
| [ ] | `L e` | rename-pane prompt | |
| [ ] | `L t` | rename-tab prompt | |
| [ ] | `L g` | rename-session prompt | |
| [ ] | `L o` | light/dark switches (dark = cathode-amber, light = merino-light) | |
| [ ] | `L ]` / `L [` | next / previous session (need ≥2 sessions) | |
| [ ] | `L l` | config reloads (`rex config check` generation increments) | |
| [ ] | `cmd+;` inside nvim / fish | doesn't leak a `;` into the terminal | |
| [ ] | Rex defaults still work: `cmd+d`, `cmd+t`, `cmd+k`, `cmd+p`, `shift+cmd+enter` | unchanged | |
| [ ] | No conflicts with: AeroSpace `alt+*`, tmux/herdr `ctrl+s`, nvim `,` leader | each still reaches its tool | |

## 2. Key modes (`modes.lua`)

**resize** — `L r` (exclusive)
- [ ] mode indicator appears when entered
- [ ] arrows and `h j k l` resize the focused pane
- [ ] `shift+arrow` resizes by the large step (15)
- [ ] `shift+h/j/k/l` also resize by the large step (unverified: does `shift+h` match capital H?)
- [ ] `=` balances the splits
- [ ] `enter` exits the mode, and so does `esc`
- [ ] unbound keys (e.g. `x`) are swallowed, not typed into the shell

**move** — `L m` (exclusive)
- [ ] arrows and `h j k l` move the pane between positions
- [ ] `f` floats the pane, `t` moves it to a new tab, `z` zooms it
- [ ] `enter` and `esc` both exit

**agent** — `L a` (one shot, not exclusive)
- [ ] `c`, `x`, and `p` open the agent layout with Claude, Codex, and Pi
- [ ] `t` opens/focuses a team; `f` focuses a labelled team pane; `b` broadcasts to selected agents
- [ ] `d` opens the dev layout, `s` opens scratch
- [ ] the mode exits after a single key
- [ ] an unbound key exits the mode and reaches the shell (record the actual behaviour)

## 3. Actions — via shortcut **and** the palette (`shift+cmd+p`)

| ✓ | Action | How | Expect | Findings |
|---|--------|-----|--------|----------|
| [ ] | scratch | `L s` | floating shell over the window, in the focused pane's cwd. **Check size/position** (asked for 80% centred; testing showed ~55%×33%) | |
| [ ] | focus_mode | `L f` | pane zooms and the sidebar hides; pressing again restores? (probably not — note it) | |
| [ ] | dev_layout | `L d` | new window labelled with the cwd basename, two shells 60/40 | |
| [ ] | agent_layout claude | `L c` from a pane in a jj repo and from one in a git repo | claude on the left; right column has a shell plus `jj log` or `git log` | |
| [ ] | agent_layout codex | `L x` | same layout, running Codex | |
| [ ] | agent_layout pi | `L p` | same layout, running pi | |
| [x] | agent_team | CLI in disposable session, `agents=codex cwd=/tmp name=team-test` | operator/Codex panes labelled correctly; second run returns same window with `created=false` | passed 2026-11-25; test session removed |
| [ ] | agent_focus | `L a f` in an agent team | picker lists operator and agent panes; choice receives focus | |
| [ ] | agent_broadcast | `L a b` in an agent team | prompt reaches only selected live agents; panes whose agent exited are skipped | |
| [ ] | open_repo | palette → Open Repo, path `~/Config/nix-config` | new window at that path, labelled with its basename | |
| [ ] | nix_build | `L b` | "nix build" window; the build runs and the pane stays open afterwards | |
| [ ] | nix_switch | `L n` (only when a switch is wanted) | "nix switch" window running `home-manager switch`; activation prints its rex hints | |
| [ ] | rex_reload | palette → Reload Rex Config | reloads without Remote Control enabled | |
| [ ] | CLI parity | `rex do dev_layout cwd=/tmp ratio=0.5` | works from the CLI; `focus_mode`/`rex_reload` need Remote Control (expected) | |

## 4. Scripts (`config/scripts/`)

- [ ] `rxd ~/.config/rex/scripts/workspace.lua name=nixcfg cwd=~/Config/nix-config` → window created; run it again → existing window focused, not duplicated
- [ ] `rxd ~/.config/rex/scripts/test-zoom.lua cmd="false"` → split opens, gets zoomed, CLI exits 1
- [ ] `rxd ~/.config/rex/scripts/test-zoom.lua cmd="true" close=true` → split closes, exit 0
- [ ] `rxd ~/.config/rex/scripts/session-export.lua` → JSON at `~/.local/state/rex/session-<id>.json`; `jq . <file>` is readable
- [x] `rxd ~/.config/rex/scripts/agent-status.lua all=true --json` → returns every block and a live Codex `working` record without resume commands (2026-11-25)
- [ ] `rxd ~/.config/rex/scripts/agent-watch.lua notify=true`:
  - [ ] `printf '\a'` in another pane → label gets `● `; focusing the pane clears it
  - [ ] a **real agent** (claude) waiting for permission → is it flagged? (program_status path, untested so far)
  - [ ] the macOS notification shows a sensible title (the OSC 9 test gave an empty one)

## 5. Shell integration

- [ ] new fish: `rx`, `rxc`, `rxr`, `rxk`, `rxd`, `rxa`, `rxwatch`, `rxstatus` all expand
- [ ] `rex <TAB>` completes subcommands; `rex do <TAB>` — does it complete action names?
- [ ] fish startup cost: `fish -i -c exit` timing is unchanged (completions come from the cache)

## 6. Lifecycle & resilience

- [ ] **Broken module:** add a syntax error to `hosts.lua` and run `rxr`. Expect the other modules to still load and the error to be logged. Then revert. Record where the log shows up (`rex server logs`?).
- [ ] **Error in init.lua itself:** the last good config is kept (documented). Confirm, then revert.
- [ ] Rex app restart (`client.server.restart` or quit/reopen) → config loads again without an `rxr`
- [ ] A Rex beta update → the `rexBin` path still resolves (`Versions/Current`) and the activation hints still run
- [ ] `home-manager switch` with Rex **not** running → no errors, no hangs (`--autostart=false`)

## 7. Known issues / improvement backlog

Fix:
- [x] Correct the stale `dev_layout` key comment (2026-11-25).
- [x] Correct the stale `test-zoom.lua` execution comment (2026-11-25).
- [ ] Find out why the scratch layer comes out at the wrong size/position (new_layer bounds), and why its returned layer id differs from the one in `session.view`.
- [ ] Rename `L g` / `L o` if the mnemonics don't stick.

Ideas to evaluate:
- [ ] Make `focus_mode` a toggle (remember the zoom/sidebar state).
- [x] Add a Codex single-agent layout and multi-agent team layout (2026-11-25).
- [ ] Re-evaluate explicit prompt/resume args after more agents report native OSC 7577 session IDs.
- [ ] Add a `workspace` action wrapper so the palette can open named workspaces (list in Lua, e.g. nix-config, ai-kitchen-dbx, omnigent-talk).
- [ ] Run `agent-watch` automatically (launchd agent from the module, or a startup hook) instead of by hand.
- [ ] Add an `L ?` cheat-sheet action that prints the `rex keymap` rows for the custom bindings.
- [ ] Try `rex.host{}` for a second machine (Tailscale) once there is one.
- [ ] Community MCP `superlogical`: register once the URL is known (see README TODO).
- [ ] Revisit app-owned prefs: worth snapshotting `defaults read com.superlogical.rex` (Workspace.* keys only) into the repo for diffing?
