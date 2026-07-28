# nixconf


## Usage

```sh
nix run github:nix-community/home-manager -- switch --flake .
```

After the first run, home-manager is available directly, and so you can do:

```sh
home-manager switch --flake .
```

## Updating dependencies

Since this repository is a nix flake (basically a self-contained nix package),
upgrading software is a single command away:

```sh
nix flake update .
```

## Service bootstrap

Some packages installed by this flake need imperative one-time setup (data dirs,
DB creation, etc.) that home-manager doesn't handle on standalone darwin. Nix
manages the package + env vars; you run these once.

### Metabase + local Postgres

Postgres connection params live in `home.sessionVariables` (`MB_DB_*`, `PGDATA`)
in `home.nix`. Metabase reads them automatically.

First-time setup:

```fish
# 1. Initialize the Postgres data dir at $PGDATA (~/.local/share/postgres)
mkdir -p $PGDATA
initdb --auth=trust --username=$USER

# 2. Start Postgres in the background (logs to $PGDATA/logfile)
pg_ctl -l $PGDATA/logfile start

# 3. Create the metabase database + user
createdb metabase
psql -d postgres -c "CREATE USER metabase WITH PASSWORD 'metabase' SUPERUSER;"
psql -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE metabase TO metabase;"

# 4. Launch metabase — picks up MB_DB_* env vars from the shell
metabase
```

Open <http://localhost:3000> once Metabase finishes booting (first launch takes
~30s while it writes its own schema into Postgres).

Day-to-day:

```fish
pg_ctl start   # if not already running
metabase
```

Stop with `pg_ctl stop` (Postgres) and `Ctrl-C` (Metabase). The Postgres data
directory persists at `$PGDATA`, so your Metabase dashboards survive restarts.

If you later want either to auto-start at login, wrap them in a launchd agent
via home-manager's `launchd.agents`.

### Hunk (TUI diff viewer)

Declarative install is blocked on the corp firewall (see comment in
`modules/home-manager/git/default.nix`). Bootstrap imperatively:

```fish
BUN_CONFIG_REGISTRY=https://npm-proxy.cloud.databricks.com/ bun install -g hunkdiff
```

Binary lands at `~/.cache/.bun/bin/hunk` (already on `PATH` via `home.nix`).

### Herdr (agent workspace manager)

Nix pins the herdr binary (`modules/home-manager/herdr`) and its config
(`config/herdr/config.toml`, symlinked to `~/.config/herdr/config.toml`). The
config ports the tmux ergonomics — `ctrl-s` prefix, `hjkl` pane nav, Catppuccin —
so it's ready on switch. Launch it in any project with `herdr`.

Agent integrations write lifecycle hooks into each agent's own config, so they
can't be managed declaratively. Run these once (re-run on a new machine):

```fish
herdr integration install claude
herdr integration install cursor
herdr integration install pi
herdr integration status   # confirm all three report installed
```

Agents without an integration (e.g. omnigent, codex) still work — herdr detects
them via screen manifests, just without authoritative state. Validate config
edits with `herdr config check`; reload a running server with
`herdr server reload-config`.

Version bumps: edit `version` in `modules/home-manager/herdr/default.nix`, then
`nix-prefetch-url <url>` and `nix hash to-sri --type sha256 <hash>` for the new
`hash`.

### Window management (AeroSpace + sketchybar)

AeroSpace (`modules/home-manager/aerospace`) replaces yabai as the tiling window
manager, with its config at `config/aerospace/aerospace.toml` (adapted from
omerxx/dotfiles: `hjkl` focus, `alt-shift-hjkl` move, `alt-1..4` workspaces,
`alt-w` → Ghostty, `alt-o` → Obsidian, `alt-s` → Slack). Sketchybar (a status
bar) and JankyBorders (active-window outlines) live in
`modules/home-manager/sketchybar` with config under `config/sketchybar/`.
AeroSpace launches both (`after-startup-command` / `exec-on-workspace-change`),
so they need no separate login items.

First-run setup (re-run on a new machine):

```fish
yabai --stop-service          # if a yabai service is still loaded from before
open -a AeroSpace             # launch once, then grant Accessibility permission
                              # (System Settings → Privacy & Security → Accessibility)
                              # and enable "Start at login" from its menu-bar icon
```

Reload AeroSpace config from `service` mode: `alt-shift-;` then `esc`. The
sketchybar app-glyph font (`sketchybar-app-font`, used by the spaces item) is
installed via nix but macOS may not register it until it's also added in Font
Book — the bar still works without it (glyphs fall back to boxes). Sketchybar is
the least portable piece; expect minor per-item tweaking.

### Television (`tv` fuzzy finder)

`modules/home-manager/television` installs `tv`; config + cable channels are at
`config/television/` (from omerxx, Catppuccin theme). Fish integration
(`tv init fish | source`) binds `ctrl-t` to tv smart-autocomplete — this
supersedes fzf's `ctrl-t` file widget. atuin keeps `ctrl-r`; tv's command
history is remapped to `ctrl-alt-r` to avoid the collision (see
`config/television/config.toml`).

## references

[repo](https://github.com/synecdokey/dotfiles/tree/dev)

nix-config % nix --extra-experimental-features "nix-command flakes" run github:zmre/pwzsh
