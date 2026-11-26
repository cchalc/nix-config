-- Agent catalog and team presets. This module is data-only so layouts and
-- actions share one definition of what can be launched.

local M = {}

M.catalog = {
  claude = { title = "Claude", command = { "claude" }, icon = "person" },
  codex  = { title = "Codex",  command = { "codex" },  icon = "code" },
  pi     = { title = "Pi",     command = { "pi" },     icon = "star" },
}

M.presets = {
  {
    id = "claude,codex",
    title = "Pair: Claude + Codex",
    subtitle = "Operator shell and two complementary agents",
  },
  {
    id = "claude,codex,pi",
    title = "Fleet: Claude + Codex + Pi",
    subtitle = "Operator shell and three agents in a 2x2 grid",
  },
  {
    id = "claude",
    title = "Claude workspace",
    subtitle = "Operator shell and Claude",
  },
  {
    id = "codex",
    title = "Codex workspace",
    subtitle = "Operator shell and Codex",
  },
}

local function copy(xs)
  local out = {}
  for i, value in ipairs(xs) do out[i] = value end
  return out
end

function M.get(name)
  return M.catalog[name]
end

function M.command(name)
  local agent = M.get(name)
  return agent and copy(agent.command) or nil
end

function M.parse(spec)
  local names, seen = {}, {}
  for name in tostring(spec or ""):gmatch("[^,%s]+") do
    if M.catalog[name] == nil then
      return nil, "unknown agent " .. name .. " (want claude, codex, or pi)"
    end
    if not seen[name] then
      names[#names + 1] = name
      seen[name] = true
    end
  end
  if #names == 0 then return nil, "choose at least one agent" end
  if #names > 3 then return nil, "a team supports at most three agents" end
  return names
end

function M.preset_items()
  local items = {}
  for i, preset in ipairs(M.presets) do
    items[i] = {
      id = preset.id,
      title = preset.title,
      subtitle = preset.subtitle,
      icon = "person",
    }
  end
  return items
end

return M
