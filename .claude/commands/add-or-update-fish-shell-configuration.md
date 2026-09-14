---
name: add-or-update-fish-shell-configuration
description: Workflow command scaffold for add-or-update-fish-shell-configuration in nix-config.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-or-update-fish-shell-configuration

Use this workflow when working on **add-or-update-fish-shell-configuration** in `nix-config`.

## Goal

Adds or updates Fish shell configuration, either by editing config.fish or the related Nix module.

## Common Files

- `modules/home-manager/fish/config.fish`
- `modules/home-manager/fish/default.nix`
- `config/config.fish`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Edit modules/home-manager/fish/config.fish or config/config.fish to update Fish shell settings.
- Optionally, update modules/home-manager/fish/default.nix to manage Fish configuration via Nix.
- Commit the changes.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.