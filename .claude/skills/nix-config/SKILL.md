```markdown
# nix-config Development Patterns

> Auto-generated skill from repository analysis

## Overview

This skill teaches you how to contribute to the `nix-config` repository, which manages user environments and tool configurations using Nix and Home Manager. The repository is primarily written in TypeScript, but its main focus is on declarative configuration via Nix modules, shell scripts, and related config files. You'll learn the coding conventions, common workflows (like adding packages or updating shell configs), and how to keep your changes consistent with the project's standards.

## Coding Conventions

- **File Naming:**  
  Use `camelCase` for file names.  
  _Example:_  
  ```
  myConfigFile.ts
  ```

- **Import Style:**  
  Use relative imports for TypeScript files.  
  _Example:_  
  ```typescript
  import { myFunction } from './utils';
  ```

- **Export Style:**  
  Use named exports only.  
  _Example:_  
  ```typescript
  export function myFunction() { ... }
  ```

- **Commit Messages:**  
  - Freeform, short messages (average ~13 characters).
  - Prefixes are not enforced.
  - _Examples:_  
    ```
    add starship
    update fish config
    remove postgresql
    ```

## Workflows

### Add New Package to Home Manager
**Trigger:** When you want to install or enable a new package (e.g., `python`, `node`, `elixir`, `awscli`, `ghostty`, etc.) via Home Manager.  
**Command:** `/add-package`

1. Edit `modules/home-manager/default.nix` to add the desired package.
   ```nix
   home.packages = with pkgs; [
     python
     nodejs
     # ...other packages
   ];
   ```
2. Commit the change with a message indicating the package added.
   ```
   git commit -m "add python"
   ```

---

### Add or Update Fish Shell Configuration
**Trigger:** When you want to change Fish shell behavior, add functions, or update environment variables.  
**Command:** `/update-fish-config`

1. Edit `modules/home-manager/fish/config.fish` or `config/config.fish` to update Fish shell settings.
   ```fish
   set -gx EDITOR nvim
   function ll
     ls -lah $argv
   end
   ```
2. Optionally, update `modules/home-manager/fish/default.nix` to manage Fish configuration via Nix.
   ```nix
   programs.fish = {
     enable = true;
     shellInit = ''
       set -gx EDITOR nvim
     '';
   };
   ```
3. Commit the changes.
   ```
   git commit -m "update fish config"
   ```

---

### Add New Home Manager Module
**Trigger:** When you want to manage a new tool or configuration via a dedicated Home Manager module (e.g., `tmux`, `jujutsu`).  
**Command:** `/add-module`

1. Create a new directory under `modules/home-manager/` for the tool, e.g., `tmux`.
2. Add `default.nix` and any relevant config files (e.g., `tmux.conf`).
   ```nix
   # modules/home-manager/tmux/default.nix
   { config, pkgs, ... }:
   {
     programs.tmux = {
       enable = true;
       extraConfig = builtins.readFile ./tmux.conf;
     };
   }
   ```
3. Edit `modules/home-manager/default.nix` to include the new module.
   ```nix
   imports = [
     ./tmux
     # ...other modules
   ];
   ```
4. Commit the changes.
   ```
   git commit -m "add tmux module"
   ```

---

### Remove or Undo Package from Home Manager
**Trigger:** When you want to uninstall or disable a package (e.g., `databricks`, `postgresql`) from the Home Manager setup.  
**Command:** `/remove-package`

1. Edit `modules/home-manager/default.nix` to remove the package.
2. Commit the change with a message indicating the package removal.
   ```
   git commit -m "remove postgresql"
   ```

---

### Sync Shell and Nix Config for Env Vars
**Trigger:** When you want to ensure environment variables are set both in shell config and Nix-managed files.  
**Command:** `/sync-env-vars`

1. Edit `config/config.fish` and/or `modules/home-manager/fish/config.fish` to set environment variables.
   ```fish
   set -gx JAVA_HOME /path/to/java
   ```
2. Edit `modules/home-manager/fish/default.nix` if needed to manage via Nix.
   ```nix
   programs.fish.shellInit = ''
     set -gx JAVA_HOME /path/to/java
   '';
   ```
3. Commit the changes.
   ```
   git commit -m "sync JAVA_HOME"
   ```

---

### Fix or Update Tool Configuration
**Trigger:** When you want to fix, tweak, or update the configuration of a tool managed by both Nix and a config file (e.g., `starship`, `tmux`, `python`).  
**Command:** `/fix-tool-config`

1. Edit the tool's config file (e.g., `config/starship.toml`, `modules/home-manager/tmux/tmux.conf`).
2. Edit the related Nix module (e.g., `modules/home-manager/default.nix`, `modules/home-manager/tmux/default.nix`).
3. Commit the changes.
   ```
   git commit -m "update starship config"
   ```

---

## Testing Patterns

- **Test File Pattern:**  
  Test files are named with the pattern `*.test.*` (e.g., `example.test.ts`).
- **Testing Framework:**  
  Not explicitly detected; check individual test files for framework usage.
- **Example Test File Name:**  
  ```
  utils.test.ts
  ```

## Commands

| Command           | Purpose                                                      |
|-------------------|--------------------------------------------------------------|
| /add-package      | Add a new package to Home Manager                            |
| /update-fish-config | Add or update Fish shell configuration                     |
| /add-module       | Add a new Home Manager module for a tool/configuration       |
| /remove-package   | Remove a package from Home Manager                           |
| /sync-env-vars    | Synchronize environment variable settings                    |
| /fix-tool-config  | Fix or update configuration for a specific tool              |
```
