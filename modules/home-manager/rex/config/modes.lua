-- Key modes (resize, move, agent). Loaded by init.lua.
-- Entry keys live in keys.lua. Declare modes before binding into them.
--
-- resize and move are exclusive so a stray key doesn't type into the pane;
-- Escape or enter leaves them. agent is not exclusive: it leaves after one key
-- (once, set on entry in keys.lua).

rex.mode("resize", { exclusive = true })
rex.mode("move", { exclusive = true })
rex.mode("agent", { exclusive = false })

-- Arrows and hjkl. Shift takes a 15-cell step in resize; move has no amount.
local dirs = {
  left = { "left", "h" },
  down = { "down", "j" },
  up = { "up", "k" },
  right = { "right", "l" },
}
for dir, keys in pairs(dirs) do
  for _, k in ipairs(keys) do
    rex.bind("resize/" .. k, "pane.resize", { direction = dir })
    rex.bind("resize/shift+" .. k, "pane.resize", { direction = dir, amount = 15 })
    rex.bind("move/" .. k, "pane.move." .. dir)
  end
end

-- resize: equalize splits, then leave.
rex.bind("resize/=", "pane.balance")
rex.bind("resize/enter", "client.mode.exit")

-- move: float toggle, send to new tab, zoom, then leave.
rex.bind("move/f", "pane.float")
rex.bind("move/t", "pane.move_to_new_tab")
rex.bind("move/z", "pane.zoom")
rex.bind("move/enter", "client.mode.exit")

-- agent: one key then out (mode is entered with once = true).
rex.bind("agent/c", "agent_layout", { agent = "claude" })
rex.bind("agent/p", "agent_layout", { agent = "pi" })
rex.bind("agent/d", "dev_layout")
rex.bind("agent/s", "scratch")
