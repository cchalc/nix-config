# omerxx dotfiles integration — review notes

Integration of config from [omerxx/dotfiles](https://github.com/omerxx/dotfiles),
managed here by home-manager. This round filled the remaining gaps: **atuin** config,
**gh-dash** (new), and **launch-at-login** wiring for the status bar + window manager.

> Context: television, sketchybar, and aerospace were already adapted from omerxx in
> earlier commits (with machine-specific fixes — JetBrainsMono font, ctrl-t/ctrl-r
> split, floating-window rules). Those were **kept as-is**; this round only added
> what was missing.

## What changed

| Feature | File(s) | What |
|---------|---------|------|
| atuin | `modules/home-manager/default.nix` | Added `programs.atuin.settings`: `style = "compact"`, `enter_accept = true`, `sync.records = true`. |
| gh-dash | `modules/home-manager/default.nix` | New `programs.gh-dash` block; ported omerxx's `config.yml` (PR/issue/notification sections, layout, theme, the `C` code-review keybinding). |
| launch-at-login | `modules/home-manager/sketchybar/default.nix`, `config/aerospace/aerospace.toml`, `modules/home-manager/aerospace/default.nix` | Added a launchd agent for sketchybar; flipped aerospace `start-at-login` to `true`. |
| television | *(none)* | Already at full parity with upstream (61/61 cable channels). No change. |

Pre-existing hand-written `~/.config/atuin/config.toml` and `~/.config/gh-dash/config.yml`
(from May, before these were nix-managed) were moved aside to `*.backup` during the
switch so home-manager could take ownership. Delete the `.backup` files once you've
confirmed you didn't lose any personal tweaks.

## Per-feature: how to use

### atuin (shell history)
- **Ctrl-R** opens atuin's history search (atuin owns ctrl-r on this machine; fzf's
  history widget is disabled and television uses ctrl-t / ctrl-alt-r — unchanged).
- `style = "compact"` = condensed search UI; `enter_accept = true` = Enter runs the
  selected command immediately (rather than editing it first).
- **Sync is not active until you log in.** `sync.records = true` only sets the data
  format. To turn on sync: `atuin login` (existing account) or `atuin register` (new).
  Without that, atuin still works fully as local history.

### gh-dash (GitHub PR/issue TUI)
- Run with **`gh dash`** (it's a `gh` CLI extension, v4.25.2 — no standalone binary).
- You're already `gh auth` logged in, so it works now. (If not: `gh auth login`.)
- Sections mirror omerxx: My PRs / Needs My Review / Involved, plus issues and
  notifications. Table is compact with section counts shown.
- **`C` on a PR** = "code review": opens `tmux new-window` → `wt switch pr:<n>` →
  launches `opencode` with a code-reviewer prompt. Requires `wt`, `opencode`, `tmux`
  (all installed).
- **Intentionally dropped** from omerxx's config (tools not installed here):
  - `diffnav` pager → falls back to gh-dash's default diff view.
  - `lazygit` universal keybinding.
  - To re-enable: add `lazygit` / `diffnav` to `home.packages`, then restore the
    `pager.diff` / lazygit keybinding in the `programs.gh-dash.settings` block.

### launch-at-login (sketchybar + aerospace)
- **sketchybar** now starts at login via a home-manager launchd agent
  (`org.nix-community.home.sketchybar`), with `KeepAlive` so it stays up.
- **aerospace** `start-at-login = true`; its startup chain still runs sketchybar and
  re-applies borders on workspace change (harmless — launchd owns the single instance).
- **Borders unchanged:** the `borders … width=0` line in `aerospace.toml` was preserved
  byte-for-byte (`width=0` = borders visually off, your intentional setting).
- **One-time manual step:** AeroSpace needs Accessibility permission —
  System Settings → Privacy & Security → Accessibility. This can't be automated.
- Verify:
  - `launchctl list | grep sketchybar` → shows `org.nix-community.home.sketchybar`.
  - Force a restart of the bar: `launchctl kickstart -k gui/$UID/org.nix-community.home.sketchybar`.
  - Logs: `/tmp/sketchybar.out.log`, `/tmp/sketchybar.err.log`.

## Verification performed
- Each feature built in an isolated worktree, then cherry-picked onto an integration
  branch and built together: `nix build '.#homeConfigurations."christopher.chalcraft".activationPackage'` — clean.
- `home-manager switch --flake . -b backup` — activated successfully.
- Live checks: atuin config shows compact/enter_accept/sync; `gh dash` extension
  resolves and `gh auth` is logged in; sketchybar running under the launchd agent (PID
  confirmed); borders line intact.
