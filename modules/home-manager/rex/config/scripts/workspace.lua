-- workspace.lua: ensure a window labelled NAME exists in this session, with an
-- agent layout running in CWD. Idempotent: if the window exists it is focused
-- instead of created again. Window labels match exactly.
--
-- Usage:
--   rex do ~/.config/rex/scripts/workspace.lua name=rex cwd=~/Config/nix-config
--   rex do ~/.config/rex/scripts/workspace.lua name=omni cwd=~/Projects/Databricks/ai-kitchen-dbx
--
-- The layout comes from layouts.agent{cwd=...} (config/layouts.lua). If that is
-- not there yet, a plain shell in CWD is used instead.

local HOME = os.getenv("HOME") or "."

local function expand(p)
  return (tostring(p):gsub("^~", HOME))
end

-- Find layouts.lua next to this scripts/ dir; this must run before require.
local src = debug.getinfo(1, "S").source:gsub("^@", "")
local dir = src:match("^(.*)/[^/]*$") or "."
package.path = dir .. "/../?.lua;" .. package.path

local function agent_layout(cwd)
  local ok, layouts = pcall(require, "layouts")
  if ok and type(layouts) == "table" and type(layouts.agent) == "function" then
    return layouts.agent{ cwd = cwd }
  end
  rex.log("warn", "workspace: layouts.agent unavailable; using a plain shell in " .. cwd)
  return rex.layout.block{
    flavor = "com.superlogical.terminal.shell",
    options = { cwd = cwd },
  }
end

local name = rex.args.name ~= nil and tostring(rex.args.name) or ""
if name == "" then
  error("usage: rex do workspace.lua name=NAME cwd=DIR", 0)
end
local cwd = expand(rex.args.cwd or HOME)

local view, err = rex.session.view{}
if err ~= nil then error("view: " .. tostring(err), 0) end

for _, w in ipairs(view.windows or {}) do
  if w.label == name then
    local _, ferr = rex.session.focus_window{ window_id = w.window_id }
    if ferr ~= nil then error("focus_window: " .. tostring(ferr), 0) end
    rex.log("info", "workspace: focused existing window " .. name)
    return { window_id = w.window_id, created = false }
  end
end

local res, nerr = rex.session.new_window{
  window_label = name,
  layout = agent_layout(cwd),
  focus = true,
}
if nerr ~= nil then error("new_window: " .. tostring(nerr), 0) end
rex.log("info", "workspace: created window " .. name .. " in " .. cwd)
return { window_id = res.window_id, created = true }
