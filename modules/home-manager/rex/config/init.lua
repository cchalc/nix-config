-- Rex config — managed by nix-config: modules/home-manager/rex/config/init.lua,
-- linked writable (out-of-store) as ~/.config/rex. Rex does not watch this
-- file: after editing, run `rex config reload` (fish abbr `rxr`), and
-- `rex config check` / `rex keymap` to see what loaded.
--
-- A Lua error anywhere fails the whole load, so each module is loaded under
-- pcall: a broken module is logged and skipped while the rest still apply.
-- Order matters: later bindings for the same key replace earlier ones.

for _, name in ipairs({ "hosts", "actions", "modes", "keys" }) do
  local ok, err = pcall(require, name)
  if not ok then
    rex.log("error", "rex config: " .. name .. ".lua failed: " .. tostring(err))
  end
end
