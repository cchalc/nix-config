-- Program Resume trust policy (OSC 7577).
--
-- A report is only a hint. Rex resumes it when both the program's report and
-- one of these rules agree. Keep the roots narrow: a resumed agent starts
-- without another confirmation after the Rex server restarts.

local project_roots = {
  "~/Config",
  "~/Projects",
  "~/Developer",
  "~/src",
  "~/code",
}

-- Rex ships the command/flag matchers for these agents. Restrict only their
-- directories here so upstream additions to the safe flag lists are retained.
-- Claude reports resumable sessions today. Codex and OpenCode are ready for
-- when their clients begin reporting OSC 7577 records.
for _, agent in ipairs({ "claude", "codex", "opencode" }) do
  rex.set("resume.trust." .. agent .. ".dir", project_roots)
end

-- Never silently bring back a Claude session that disabled permission checks.
-- Removing the flag from the rule rejects that session; Rex does not strip the
-- flag and resume a less-privileged variant.
rex.set("resume.trust.claude.flags.--dangerously-skip-permissions", false)
