-- Reusable layout builders, shared by actions.lua and scripts/. require("layouts").
-- Builders only make tables (rex.layout), so this is safe to require at load
-- time; the functions that look at blocks or windows run only when called.
local M = {}

M.SHELL = "com.superlogical.terminal.shell"

local function shell(opts)
  opts = opts or {}
  local o = {}
  if opts.cwd then o.cwd = opts.cwd end
  -- initial_input goes through the user's fish, so PATH (nix, claude) is right.
  if opts.input then o.initial_input = opts.input end
  return rex.layout.block{ flavor = M.SHELL, options = next(o) and o or nil }
end
M.shell = shell

-- Single-quote one argument for fish (only \ and ' are special inside '...').
local function fish_quote(s)
  return "'" .. s:gsub("\\", "\\\\"):gsub("'", "\\'") .. "'"
end

-- Single-quote one argument for sh ('...' has no escapes; close, \', reopen).
local function sh_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Block creation looks argv[0] up on a narrow PATH (no nix), so a bare
-- `command = argv` cannot find home-manager. Two routes around it:
-- keep (default): type argv into the user's fish, which stays open after the
--   command so output stays readable and the pane is still a usable shell.
-- keep=false: run under /bin/sh -c, which inherits the full user PATH; the
--   pane exits with the command and terminal.child_exited carries its code
--   (typed `; exit` into fish never fires child_exited).
function M.cmd(argv, opts)
  opts = opts or {}
  if opts.keep == false then
    local parts = {}
    for i, a in ipairs(argv) do parts[i] = sh_quote(a) end
    local o = { command = { "/bin/sh", "-c", table.concat(parts, " ") } }
    if opts.cwd then o.cwd = opts.cwd end
    return rex.layout.block{ flavor = M.SHELL, options = o }
  end
  local parts = {}
  for i, a in ipairs(argv) do parts[i] = fish_quote(a) end
  return shell{ cwd = opts.cwd, input = table.concat(parts, " ") .. "\n" }
end

function M.h(ratio, a, b) return rex.layout.horizontal(ratio, a, b) end
function M.v(ratio, a, b) return rex.layout.vertical(ratio, a, b) end

-- Two shells side by side in the same directory.
function M.dev(opts)
  opts = opts or {}
  return M.h(opts.ratio or 0.6, shell{ cwd = opts.cwd }, shell{ cwd = opts.cwd })
end

-- Agent on the left; right column has a shell over a short history view.
function M.agent(opts)
  opts = opts or {}
  local cwd = opts.cwd
  local agent = opts.agent or "claude"
  local has_jj = false
  if cwd then
    local f = io.open(cwd .. "/.jj", "r")
    if f then f:close(); has_jj = true end
  end
  local log = has_jj and "jj --no-pager log\n" or "git --no-pager log --oneline --graph -20\n"
  return M.h(0.6,
    shell{ cwd = cwd, input = agent .. "\n" },
    M.v(0.5, shell{ cwd = cwd }, shell{ cwd = cwd, input = log }))
end

-- Directory of the block that invoked the action, from its reported pwd
-- (OSC 7 file:// URL). Falls back to $HOME when the block reports nothing.
function M.cwd_of(ctx)
  local home = os.getenv("HOME")
  if not (ctx and ctx.block_id) then return home end
  local r = rex.call("com.superlogical.terminal.pwd", {
    session_id = ctx.session_id,
    block_id   = ctx.block_id,
    args       = {},
  })
  local pwd = r and r.pwd
  if not pwd then return home end
  -- file://HOST/path: drop the scheme and host, then decode %xx.
  local path = pwd:match("^file://[^/]*(/.*)$") or pwd
  path = path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  return path
end

return M
