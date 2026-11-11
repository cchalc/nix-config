-- session-export.lua: write the session's view and block list as JSON.
--
-- Usage:
--   rex do ~/.config/rex/scripts/session-export.lua                  # once, default path
--   rex do ~/.config/rex/scripts/session-export.lua out=/tmp/rex.json
--   rex do ~/.config/rex/scripts/session-export.lua every=30         # rewrite every 30s, Ctrl-C to stop
--
-- Default out: ~/.local/state/rex/session-<id>.json. The file is written via a
-- temp file and rename, so readers never see a partial export.

local HOME = os.getenv("HOME") or "."

local function expand(p)
  return (tostring(p):gsub("^~", HOME))
end

local id = tostring(rex.session_id or "unknown"):gsub("^session:", "")
id = (id:gsub("[^%w%-]", "_"))

local path = expand(rex.args.out or (HOME .. "/.local/state/rex/session-" .. id .. ".json"))
local dir = path:match("^(.*)/[^/]*$") or "."
rex.exec({ "mkdir", "-p", dir })

local every = tonumber(rex.args.every)

local function export()
  local view, verr = rex.session.view{}
  if verr ~= nil then
    rex.log("error", "session-export: view: " .. tostring(verr))
    return
  end
  local listed, lerr = rex.session.list_blocks{}
  if lerr ~= nil then
    rex.log("error", "session-export: list_blocks: " .. tostring(lerr))
    return
  end

  local doc = {
    exported_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    session_id = rex.session_id,
    view = view,
    blocks = listed and listed.blocks or {},
  }
  local text = rex.json.encode(doc, { indent = true })

  local tmp = path .. ".tmp"
  local f, ferr = io.open(tmp, "w")
  if f == nil then
    rex.log("error", "session-export: " .. tostring(ferr))
    return
  end
  f:write(text, "\n")
  f:close()
  local ok, rerr = os.rename(tmp, path)
  if not ok then
    rex.log("error", "session-export: rename: " .. tostring(rerr))
    return
  end
  rex.log("info", "session-export: wrote " .. path)
end

export()

if every ~= nil and every > 0 then
  rex.every(every, function(ctx) export() end)
else
  return { path = path }
end
