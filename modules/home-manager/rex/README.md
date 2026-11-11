# Rex

Rex is a terminal multiplexer from superlogical, installed by hand from the
beta program. Nix does not install the app. It manages only its config, the
fish integration, and a few activation hints.

Known-good with `rex 0.1.0-preview.14` (`rex version`).

## What is managed here

- **Lua config** (`config/init.lua` and its modules): hosts, actions, modes,
  keys, layouts.
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
| `config/init.lua` | Entry point. Loads `hosts`, `actions`, `modes`, `keys` under `pcall` |
| `config/hosts.lua` | Hosts Rex connects to |
| `config/actions.lua` | Named actions (`rex do <name>`) |
| `config/modes.lua` | Key modes |
| `config/keys.lua` | Key bindings, loaded last |
| `config/layouts.lua` | Shared layout builders (`SHELL`, `shell`, `cmd`, `h`/`v`, `dev`, `agent`, `cwd_of`), required by actions and scripts |
| `config/scripts/*.lua` | Standalone scripts, run with `rex do` |
| `config/.gitignore` | Runtime files Rex writes into the linked dir |

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

Scripts load `layouts.lua` through `package.path`. The `package.path` line
derives the script's own directory from `debug.getinfo`, so it works from any
directory.

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
