-- Custom palette actions. Loaded by init.lua.
-- Run them from the palette or `rex do <name> key=value`. Session calls
-- belong inside run(); at load time only rex.action{} is called.

local L = require("layouts")

local REPO = os.getenv("HOME") .. "/Config/nix-config"

local function basename(path)
  return (path:gsub("/+$", ""):match("([^/]+)$")) or path
end

local function expand(path)
  if path:sub(1, 2) == "~/" then return os.getenv("HOME") .. path:sub(2) end
  return path
end

-- Window holding the invoking block, so scratch floats over the right window.
-- nil means fall back to the session's active window.
local function window_of(ctx)
  if not ctx.block_id then return nil end
  local view = rex.session.view{}
  if not view then return nil end
  for _, w in ipairs(view.windows or {}) do
    for _, l in ipairs(w.layers or {}) do
      for _, b in ipairs(l.blocks or {}) do
        if b.block_id == ctx.block_id then return w.window_id end
      end
    end
  end
  return nil
end

local function new_window(opts)
  local w, err = rex.session.new_window(opts)
  if w == nil then error(err or "new_window failed", 0) end
  return { window_id = w.window_id, label = opts.window_label, block_ids = w.block_ids }
end

rex.action{
  name        = "scratch",
  title       = "Scratch Shell",
  description = "Floating shell in the current block's directory, over its window.",
  category    = "Layouts",
  keywords    = "float popup shell scratch overlay",
  run         = function(ctx)
    local cwd = L.cwd_of(ctx)
    local layer, err = rex.session.new_layer{
      window_id = window_of(ctx),
      bounds    = { 0.1, 0.1, 0.8, 0.8 },
      focus     = true,
      layout    = L.shell{ cwd = cwd },
    }
    if layer == nil then error(err or "new_layer failed", 0) end
    return { layer_id = layer.layer_id, cwd = cwd }
  end,
}

rex.action{
  name        = "focus_mode",
  title       = "Focus Mode",
  description = "Zoom the focused pane and hide the sidebar.",
  category    = "Layouts",
  keywords    = "zoom focus sidebar distraction",
  run         = function()
    -- Client actions need a connected client; without one this raises.
    local ok, err = pcall(function()
      rex.client.queue("pane.zoom")
      rex.client.queue("client.sidebar.toggle")
    end)
    if not ok then error(err, 0) end
    return { zoomed = true, sidebar = "toggled" }
  end,
}

rex.action{
  name        = "dev_layout",
  title       = "Dev Layout",
  description = "New window with two shells side by side in a directory.",
  category    = "Layouts",
  keywords    = "dev split shells window project",
  args        = { cwd = "string?", ratio = "number?" },
  run         = function(ctx, args)
    local cwd = args.cwd and expand(args.cwd) or L.cwd_of(ctx)
    local label = basename(cwd)
    local w = new_window{
      layout       = L.dev{ cwd = cwd, ratio = args.ratio },
      window_label = label,
    }
    w.cwd = cwd
    return w
  end,
}

rex.action{
  name        = "agent_layout",
  title       = "Agent Layout",
  description = "New window: agent on the left, shell and history log on the right.",
  category    = "Layouts",
  keywords    = "agent claude ai log jj git",
  args        = { cwd = "string?", agent = "string?" },
  run         = function(ctx, args)
    local cwd = args.cwd and expand(args.cwd) or L.cwd_of(ctx)
    local label = basename(cwd)
    local w = new_window{
      layout       = L.agent{ cwd = cwd, agent = args.agent },
      window_label = label,
    }
    w.cwd = cwd
    return w
  end,
}

rex.action{
  name        = "nix_switch",
  title       = "Nix Switch",
  description = "Run home-manager switch on the nix-config flake in a new window; the pane stays open.",
  category    = "nix-config",
  keywords    = "nix home-manager switch apply rebuild",
  run         = function()
    return new_window{
      layout       = L.cmd({ "home-manager", "switch", "--flake", REPO }, { cwd = REPO }),
      window_label = "nix switch",
    }
  end,
}

rex.action{
  name        = "nix_build",
  title       = "Nix Build",
  description = "Build the home-manager activation package (no switch) in a new window.",
  category    = "nix-config",
  keywords    = "nix build home-manager activation check",
  run         = function()
    -- argv goes straight to nix, so the attribute path needs no shell quoting.
    return new_window{
      layout = L.cmd({
        "nix", "build", "--no-link",
        '.#homeConfigurations."christopher.chalcraft".activationPackage',
      }, { cwd = REPO }),
      window_label = "nix build",
    }
  end,
}

rex.action{
  name        = "rex_reload",
  title       = "Reload Rex Config",
  description = "Reload init.lua and its modules. Uses the client action, or `rex config reload` with no client.",
  category    = "nix-config",
  keywords    = "reload config rex init",
  run         = function()
    local ok = pcall(rex.client.queue, "client.config.reload")
    if ok then return { reloaded = "client" } end
    -- No client connected: the server binary is on the server's PATH.
    local r, err = rex.exec({ "rex", "config", "reload" }, { timeout = 20 })
    if r == nil then error(err or "rex config reload did not run", 0) end
    if not r.ok then error(r.stderr ~= "" and r.stderr or "rex config reload failed", 0) end
    return { reloaded = "cli" }
  end,
}

rex.action{
  name        = "open_repo",
  title       = "Open Repo",
  description = "New window with a shell at a path, labelled with the directory name.",
  category    = "Layouts",
  keywords    = "open repo project directory window",
  args        = { path = "string" },
  run         = function(_, args)
    local path = expand(args.path)
    local label = basename(path)
    local w = new_window{
      layout       = L.shell{ cwd = path },
      window_label = label,
    }
    w.path = path
    return w
  end,
}
