---
name: add-new-package-to-home-manager
description: Workflow command scaffold for add-new-package-to-home-manager in nix-config.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-new-package-to-home-manager

Use this workflow when working on **add-new-package-to-home-manager** in `nix-config`.

## Goal

Adds a new software package or tool to the user's environment by updating the Home Manager configuration.

## Common Files

- `modules/home-manager/default.nix`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Edit modules/home-manager/default.nix to add the new package.
- Commit the change with a message indicating the package added.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.