-- agent-watch.lua: flag blocks that want attention (long-running).
--
-- Usage:
--   rex do ~/.config/rex/scripts/agent-watch.lua                  # this session
--   rex do ~/.config/rex/scripts/agent-watch.lua notify=true      # also macOS notification
--   rex do ~/.config/rex/scripts/agent-watch.lua --all            # every session
--   rex do ~/.config/rex/scripts/agent-watch.lua attention=blocked,error,done poll=2
--
-- Sources: terminal.bell, terminal.desktop_notification, and
-- terminal.program_status_changed / _removed when a record's state is in
-- `attention` (default "blocked,error"). A flagged block's label gets a "● "
-- prefix. The flag clears when the block is the focused block of the active
-- window (checked every `poll` seconds, default 2), or when no record for it
-- is in an attention state any more. Stop with Ctrl-C.

local MARK = "● "
local notify = rex.args.notify == true or rex.args.notify == "true"
local poll = tonumber(rex.args.poll) or 2

local attention = {}
for s in string.gmatch(tostring(rex.args.attention or "blocked,error"), "[^,%s]+") do
  attention[s] = true
end

-- block_id -> label before flagging
local flagged = {}

local function unwrap(ev)
  return ev.payload or ev
end

local function block_label(block_id)
  local res = rex.session.list_blocks{}
  if res == nil then return nil end
  for _, b in ipairs(res.blocks or {}) do
    if b.block_id == block_id then return b.label or "" end
  end
  return nil
end

local function set_label(block_id, label)
  local _, err = rex.session.set_block_label{ block_id = block_id, label = label }
  if err ~= nil then
    rex.log("error", "agent-watch: set_block_label: " .. tostring(err))
  end
end

local function flag(block_id, why)
  if block_id == nil then return end
  if flagged[block_id] ~= nil then
    rex.log("info", "agent-watch: " .. block_id .. " still flagged (" .. why .. ")")
    return
  end
  local base = block_label(block_id)
  if base == nil then return end
  if base:sub(1, #MARK) == MARK then base = base:sub(#MARK + 1) end
  flagged[block_id] = base
  set_label(block_id, MARK .. base)
  rex.log("info", "agent-watch: flagged " .. block_id .. " (" .. why .. ")")
end

local function clear(block_id, why)
  local base = flagged[block_id]
  if base == nil then return end
  flagged[block_id] = nil
  set_label(block_id, base)
  rex.log("info", "agent-watch: cleared " .. block_id .. " (" .. why .. ")")
end

-- AppleScript string literal: escape backslash and double quote.
local function asq(s)
  return '"' .. (tostring(s):gsub('[\\"]', "\\%0")) .. '"'
end

local function os_notify(title, body)
  local script = "display notification " .. asq(body) .. " with title " .. asq(title)
  local r, err = rex.exec({ "osascript", "-e", script }, { timeout = 5 })
  if r == nil or not r.ok then
    rex.log("error", "agent-watch: osascript failed: " .. tostring(err or (r and r.stderr)))
  end
end

-- Re-read a block's statuses; clear the flag if none is in an attention state.
local function recheck_status(ctx)
  if ctx.block_id == nil or flagged[ctx.block_id] == nil then return end
  local res, err = rex.call("com.superlogical.terminal.program_status", {
    session_id = ctx.session_id,
    block_id = ctx.block_id,
  })
  if res == nil then
    rex.log("error", "agent-watch: program_status: " .. tostring(err))
    return
  end
  for _, rec in ipairs(res.records or {}) do
    if attention[rec.state] then return end
  end
  clear(ctx.block_id, "status cleared")
end

rex.on("terminal.bell", function(ctx, ev)
  flag(ctx.block_id, "bell")
end)

rex.on("terminal.desktop_notification", function(ctx, ev)
  local p = unwrap(ev)
  flag(ctx.block_id, "notification: " .. tostring(p.title or ""))
  if notify then
    os_notify(p.title or "rex", p.body or "")
  end
end)

rex.on("terminal.program_status_changed", function(ctx, ev)
  local rec = unwrap(ev).record
  if rec ~= nil and attention[rec.state] then
    flag(ctx.block_id, "status " .. tostring(rec.state))
  else
    recheck_status(ctx)
  end
end)

rex.on("terminal.program_status_removed", function(ctx, ev)
  recheck_status(ctx)
end)

-- Clear flags for blocks the user has focused. There is no focus event, so poll.
rex.every(poll, function(ctx)
  if next(flagged) == nil then return end
  local view, err = rex.session.view{}
  if err ~= nil or view == nil then return end
  for _, w in ipairs(view.windows or {}) do
    if w.window_id == view.active_window_id and w.focused_block_id ~= nil then
      if flagged[w.focused_block_id] ~= nil then
        clear(w.focused_block_id, "focused")
      end
    end
  end
end)

rex.log("info", "agent-watch: watching session " .. tostring(rex.session_id)
  .. " (notify=" .. tostring(notify) .. ", poll=" .. poll .. "s)")
