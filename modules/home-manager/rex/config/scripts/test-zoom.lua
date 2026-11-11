-- test-zoom.lua: run a command in a new split beside the current block, zoom
-- that split if the command fails, and exit with the command's exit code.
--
-- Usage:
--   rex do ~/.config/rex/scripts/test-zoom.lua cmd="make test"
--   rex do ~/.config/rex/scripts/test-zoom.lua cmd="npm test" cwd=~/Projects/app timeout=900
--   rex do ~/.config/rex/scripts/test-zoom.lua cmd="make test" close=true   # close pane on success
--   rex do ~/.config/rex/scripts/test-zoom.lua --args '{"argv":["make","test"]}'
--
-- cmd is typed into fish as written; argv is quoted per word. The pane stays
-- open after the command exits so its output can be read. timeout (seconds,
-- default 600) bounds the wait for exit.

local HOME = os.getenv("HOME") or "."
local SHELL = "com.superlogical.terminal.shell"

local function expand(p)
  return (tostring(p):gsub("^~", HOME))
end

local function unwrap(ev)
  return ev.payload or ev
end

-- The command runs as `sh -c LINE` in the block's own process. The block's
-- login shell reads its startup files first, so PATH is the user's (nix, claude
-- and friends resolve). Typing the command into an interactive shell instead
-- never produced terminal.child_exited, so that path is not used here.
-- Note: layouts.cmd types into fish and is not suitable for exit codes.
local function sh_quote(s)
  return "'" .. (s:gsub("'", "'\\''")) .. "'"
end

local line, label
if rex.args.argv ~= nil then
  local parts = {}
  for i, a in ipairs(rex.args.argv) do parts[i] = sh_quote(tostring(a)) end
  label = table.concat(parts, " ")
  line = label
elseif rex.args.cmd ~= nil and tostring(rex.args.cmd) ~= "" then
  label = tostring(rex.args.cmd)
  line = label
else
  error('usage: cmd="..." (or --args \'{"argv":[...]}\')', 0)
end

local timeout = tonumber(rex.args.timeout) or 600
local close = rex.args.close == true or rex.args.close == "true"

local options = {
  command = { "sh", "-c", line },
  exit = { on_completion = false },  -- keep the pane so its output stays visible
}
if rex.args.cwd ~= nil then options.cwd = expand(rex.args.cwd) end

local split, err = rex.session.new_split{
  anchor_id = rex.block_id,  -- nil splits the focused block of the active window
  direction = "vertical",
  side = "after",
  focus = false,
  layout = rex.layout.block{ flavor = SHELL, options = options },
}
if err ~= nil then error("new_split: " .. tostring(err), 0) end

local block_id = split.block_ids[1]
rex.log("info", "test-zoom: running in " .. block_id .. ": " .. label)

local ev = rex.wait("terminal.child_exited", { block_id = block_id }, timeout)
if ev == nil then
  rex.log("error", "test-zoom: timed out after " .. timeout .. "s: " .. label)
  rex.stop(124)
end

local code = tonumber(unwrap(ev).exit_code) or 1

if code ~= 0 then
  local _, zerr = rex.session.zoom_block{ block_id = block_id, zoom = true }
  if zerr ~= nil then rex.log("error", "test-zoom: zoom: " .. tostring(zerr)) end
  rex.log("error", "test-zoom: failed with exit " .. code .. ": " .. label)
else
  rex.log("info", "test-zoom: passed: " .. label)
  if close then
    local _, cerr = rex.call("block.close", {
      session_id = rex.session_id,
      block_id = block_id,
    })
    if cerr ~= nil then rex.log("error", "test-zoom: close: " .. tostring(cerr)) end
  end
end

rex.stop(code)
