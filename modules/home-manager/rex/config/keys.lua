-- Key bindings, sequences and overrides of Rex defaults. Loaded last by init.lua.
--
-- Custom chords all sit under one leader, cmd+; (semicolon). Why cmd:
--   * no Rex default, aerospace, tmux, herdr, nvim or fish binding uses cmd;
--   * aerospace owns alt+* globally and tmux/herdr own ctrl+s, so alt/ctrl
--     chords here would fight them.
-- A key is either an action or a sequence start, so cmd+; has no single-key
-- binding of its own.
--
-- Leader map (cmd+; then):
--   r resize mode     m move mode       a agent mode (once)
--   s scratch         f focus_mode      d dev_layout
--   c agent claude    p agent pi        n nix_switch     b nix_build
--   l rex_reload      e pane.rename     t client.tab.rename
--   g session.rename  o appearance      = pane.balance
--   ] session.next    [ session.previous

-- Mode entry. Declarations live in modes.lua.
rex.bind("cmd+;>r", "client.mode.enter", { name = "resize" }) -- resize arrows/hjkl
rex.bind("cmd+;>m", "client.mode.enter", { name = "move" }) -- move panes
-- once: the agent mode leaves itself after one key (c/p/d/s).
rex.bind("cmd+;>a", "client.mode.enter", { name = "agent", once = true })

-- Custom actions (defined in actions.lua / scripts/).
rex.bind("cmd+;>s", "scratch") -- scratch terminal
rex.bind("cmd+;>f", "focus_mode") -- hide chrome, focus the pane
rex.bind("cmd+;>d", "dev_layout") -- editor + shell + server layout
rex.bind("cmd+;>c", "agent_layout", { agent = "claude" }) -- agent layout, claude
rex.bind("cmd+;>p", "agent_layout", { agent = "pi" }) -- agent layout, pi
rex.bind("cmd+;>n", "nix_switch") -- home-manager switch
rex.bind("cmd+;>b", "nix_build") -- nix build (no activation)
rex.bind("cmd+;>l", "rex_reload") -- reload this config (l = load)

-- Built-in actions with no default shortcut.
rex.bind("cmd+;>=", "pane.balance") -- equalize splits
rex.bind("cmd+;>e", "pane.rename") -- rename pane (e = edit)
rex.bind("cmd+;>t", "client.tab.rename") -- rename tab
rex.bind("cmd+;>g", "session.rename") -- rename session (g = group)
rex.bind("cmd+;>o", "client.appearance.switch_mode") -- light/dark (o = look)
-- Physical bracket codes: the bare "[" / "]" would be read as a code delimiter.
rex.bind("cmd+;>[BracketRight]", "session.next") -- next session
rex.bind("cmd+;>[BracketLeft]", "session.previous") -- previous session
