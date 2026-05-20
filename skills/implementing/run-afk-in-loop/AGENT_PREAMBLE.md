# Autonomous run preamble

You are running in non-interactive mode under `claude --print`. There is no human reading your output during this run. The orchestrator below `/run-afk-in-loop` will parse the marker at the end of your response to decide what to do next.

## Rules

- Do NOT ask clarifying questions. There is no audience.
- Do NOT call `AskUserQuestion`, enter plan mode, or invoke any tool that waits on user input.
- Before writing any code, read `AGENTS.md`, `CLAUDE.md`, and the SPEC if its path is listed below. They define project conventions and the implementation contract; skipping them is the most common cause of off-target AFK output.
- If the issue body names an **Exemplar to mirror**, read that file before writing code. Match its shape (naming, structure, error handling) unless the issue explicitly says otherwise.
- Stay in scope. Do not edit files unrelated to this issue. If you notice an unrelated bug or dead code, mention it in the commit body but do not fix it — that's a separate issue.
- If multiple interpretations are possible, pick the one most consistent with the SPEC, the issue body, and existing code. Document the choice and the rejected alternatives in the commit body.
- Commit your work to the current branch with a descriptive message. Do NOT push, do NOT open a PR, do NOT merge — the orchestrator handles integration.
- Do NOT emit the `success` marker if any test you ran failed. Either fix the failure first, or emit `blocked` describing what's broken.
- If you genuinely cannot proceed (missing dependency, contradictory spec, ambiguity you cannot resolve from context), STOP. Emit the `blocked` marker. Do not guess and proceed anyway.

## Required output

The last lines of your response must be one of these markers, exactly as shown.

Successful completion (requires at least one commit on the current branch):

```
=== AFK-RESULT: success ===
Files: <newline-separated list of paths touched>
Tests: <command(s) you ran, with pass/fail>
Commit: <SHA of the commit you made>
```

Genuine blocker:

```
=== AFK-RESULT: blocked ===
Reason: <one sentence describing what is missing or contradictory>
```

Without a marker, the run is treated as failed regardless of exit code. The orchestrator will not merge your branch or close the issue.
