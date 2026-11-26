-- Custom palette actions. Loaded by init.lua.
-- Run them from the palette or `rex do <name> key=value`. Session calls
-- belong inside run(); at load time only rex.action{} is called.

local L = require("layouts")
local Agents = require("agents")

local REPO = os.getenv("HOME") .. "/Config/nix-config"
local TERMINAL = "com.superlogical.terminal"

local shells = {
  bash = true,
  dash = true,
  fish = true,
  ksh = true,
  mksh = true,
  nu = true,
  nushell = true,
  sh = true,
  yash = true,
  zsh = true,
}

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

local function find_window(label)
  local view = rex.session.view{}
  if view == nil then return nil end
  for _, window in ipairs(view.windows or {}) do
    if window.label == label then return window end
  end
  return nil
end

local function agent_blocks()
  local listed = rex.session.list_blocks{}
  local items = {}
  for _, block in ipairs((listed and listed.blocks) or {}) do
    local label = (block.label or ""):gsub("^● ", "")
    if label == "operator" or label:match("^agent:") then
      items[#items + 1] = {
        id = block.block_id,
        title = label,
        subtitle = block.block_id,
        icon = label == "operator" and "terminal" or "person",
      }
    end
  end
  return items
end

-- A team label outlives the agent process. Refuse to type a prompt when the
-- pane has fallen back to a shell, where natural language could be executed as
-- a command. A non-shell foreground process is still only a point-in-time
-- check, so the action performs it immediately before every write.
local function agent_is_running(block_id)
  local process, err = rex.block.call(TERMINAL, "process", { block_id = block_id })
  if process == nil then return false, tostring(err or "process unavailable") end
  local foreground = process.foreground
  if foreground == nil or foreground.name == nil then
    return false, "no foreground program"
  end
  if shells[foreground.name] then
    return false, "foreground program is " .. foreground.name
  end
  return true
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
  name        = "agent_team",
  title       = "Agent Team…",
  description = "Focus or create an operator window with one to three agent panes.",
  category    = "Agents",
  keywords    = "agent team fleet pair orchestrate claude codex pi",
  args        = { cwd = "string?", agents = "string?", name = "string?" },
  run         = function(ctx, args)
    local cwd = args.cwd and expand(args.cwd) or L.cwd_of(ctx)
    local spec = args.agents
    if spec == nil then
      local why
      spec, why = rex.ui.pick{
        title = "Open agent team",
        placeholder = "Choose a team",
        items = Agents.preset_items(),
      }
      if spec == nil then
        if why ~= "cancelled" then rex.log("warn", "agent_team: " .. tostring(why)) end
        return
      end
    end

    local names, perr = Agents.parse(spec)
    if names == nil then error(perr, 0) end
    local label = args.name or ("agents:" .. basename(cwd))
    local existing = find_window(label)
    if existing ~= nil then
      local _, ferr = rex.session.focus_window{ window_id = existing.window_id }
      if ferr ~= nil then error(ferr, 0) end
      return { window_id = existing.window_id, created = false, cwd = cwd }
    end

    local layout, labels = L.team{ cwd = cwd, agents = names }
    local window = new_window{
      layout = layout,
      window_label = label,
      focus = true,
    }
    for i, block_id in ipairs(window.block_ids or {}) do
      if labels[i] ~= nil then
        local _, lerr = rex.session.set_block_label{
          block_id = block_id,
          label = labels[i],
        }
        if lerr ~= nil then rex.log("warn", "agent_team: label: " .. tostring(lerr)) end
      end
    end
    window.created = true
    window.cwd = cwd
    window.agents = names
    return window
  end,
}

rex.action{
  name        = "agent_focus",
  title       = "Focus Agent Pane…",
  description = "Choose an operator or agent pane by its stable label.",
  category    = "Agents",
  keywords    = "agent focus switch pane attention",
  run         = function()
    local items = agent_blocks()
    if #items == 0 then error("no labelled agent panes in this session", 0) end
    local block_id, why = rex.ui.pick{
      title = "Focus agent pane",
      placeholder = "Filter panes",
      items = items,
    }
    if block_id == nil then
      if why ~= "cancelled" then rex.log("warn", "agent_focus: " .. tostring(why)) end
      return
    end
    local _, err = rex.session.focus_block{ block_id = block_id }
    if err ~= nil then error(err, 0) end
    return { block_id = block_id }
  end,
}

rex.action{
  name        = "agent_broadcast",
  title       = "Broadcast to Agents…",
  description = "Type one explicit prompt into selected labelled agent panes.",
  category    = "Agents",
  keywords    = "agent prompt broadcast send team",
  run         = function()
    local items = agent_blocks()
    local only_agents = {}
    for _, item in ipairs(items) do
      if item.title:match("^agent:") then only_agents[#only_agents + 1] = item end
    end
    if #only_agents == 0 then error("no labelled agent panes in this session", 0) end

    local targets, why = rex.ui.pick{
      title = "Choose agents",
      placeholder = "Filter agents",
      confirm = "Choose",
      multiple = true,
      items = only_agents,
    }
    if targets == nil then
      if why ~= "cancelled" then rex.log("warn", "agent_broadcast: " .. tostring(why)) end
      return
    end
    if #targets == 0 then return { sent = 0 } end

    local prompt, pwhy = rex.ui.input{
      title = "Prompt selected agents",
      placeholder = "Be explicit about scope and expected output",
      confirm = "Send",
    }
    if prompt == nil then
      if pwhy ~= "cancelled" then rex.log("warn", "agent_broadcast: " .. tostring(pwhy)) end
      return
    end

    local sent = 0
    for _, block_id in ipairs(targets) do
      local running, reason = agent_is_running(block_id)
      if not running then
        rex.log("warn", "agent_broadcast: skipped " .. block_id .. ": " .. reason)
      else
        local _, err = rex.block.call(TERMINAL, "write", {
          block_id = block_id,
          data = prompt .. "\r",
        })
        if err ~= nil then
          rex.log("warn", "agent_broadcast: " .. block_id .. ": " .. tostring(err))
        else
          sent = sent + 1
        end
      end
    end
    return { sent = sent, selected = #targets }
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
