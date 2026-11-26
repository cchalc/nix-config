-- agent-status.lua: sanitized status and Program Resume report for one session.
--
-- Usage:
--   rex do ~/.config/rex/scripts/agent-status.lua --json
--   rex do -s SESSION ~/.config/rex/scripts/agent-status.lua all=true --json
--
-- Saved resume commands can contain secrets. This script deliberately returns
-- only trust/liveness metadata and never includes a record's command.

local TERMINAL = "com.superlogical.terminal"
local show_all = rex.args.all == true or rex.args.all == "true"

local listed, lerr = rex.session.list_blocks{}
if listed == nil then error("list_blocks: " .. tostring(lerr), 0) end

local blocks = {}
for _, block in ipairs(listed.blocks or {}) do
  local statuses = {}
  local status_result, serr = rex.block.call(TERMINAL, "program_status", {
    block_id = block.block_id,
  })
  if status_result ~= nil then
    for _, record in ipairs(status_result.records or {}) do
      statuses[#statuses + 1] = {
        app = record.app,
        state = record.state,
        kind = record.kind,
        message = record.message or record.msg,
      }
    end
  elseif serr ~= nil and show_all then
    statuses[#statuses + 1] = { error = tostring(serr) }
  end

  local resumes = {}
  local resume_result = rex.block.call(TERMINAL, "program_resume_records", {
    block_id = block.block_id,
  })
  if resume_result ~= nil then
    for _, record in ipairs(resume_result.records or {}) do
      resumes[#resumes + 1] = {
        program = record.program,
        cwd = record.cwd,
        reported_at = record.reported_at,
        chosen = record.chosen,
        trusted = record.trusted,
        rule = record.rule,
        untrusted_reason = record.untrusted_reason,
        owner = record.owner and {
          name = record.owner.name,
          pid = record.owner.pid,
        } or nil,
      }
    end
  end

  if show_all or #statuses > 0 or #resumes > 0 then
    blocks[#blocks + 1] = {
      block_id = block.block_id,
      label = block.label,
      statuses = statuses,
      resume = resumes,
    }
  end
end

return {
  session_id = rex.session_id,
  generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  blocks = blocks,
}
