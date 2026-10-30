---
name: workflow-configure
description: Change the practice settings of the AI Forward Workflow at any time after a project was initialized. Covers all four practices (prompt engineering, context engineering, harness configuration, verification loops), for example execution environment, permissions, default tools, multi-step agent system, human sanity check and escalation, verification loop guardrails, prompt suggestions, /compact reminders and CodeGraph. Updates the project's local git-ignored artefacts/harness-preferences.md and logs the change in the committed artefacts/practice-changes.md. Use when the user wants to change, turn on or off, or raise or lower any workflow practice or setting, or runs /workflow-configure.
---

# Workflow configure

Change the settings of the whole workflow's [practices](../../docs/development-environment/practices/README.md) at any time. `jira-design initialize` asks for the first values; this skill changes them afterwards. Run it when the user types `/workflow-configure`, or when they simply ask for a change, for example "turn the multi-step agent system off", "stop suggesting prompt formats from now on" or "raise the iteration limit".

## Settings

| Practice | Settings that can be changed |
| --- | --- |
| [Prompt engineering](../../docs/development-environment/practices/prompt-engineering.md) | Format suggestions on or off; shot-example suggestions on or off |
| [Context engineering](../../docs/development-environment/practices/context-engineering.md) | `/compact` reminders on or off; multi-turn history tracking on or off; saving user preferences on or off; CodeGraph installed or not |
| [Harness configuration](../../docs/development-environment/practices/harness-configuration.md) | Execution environment; permissions for filesystem tools, package managers, MCP servers, skills and shell access; tools beyond the defaults; multi-step agent system; human sanity check and agent escalation |
| Hooks | Each of the commit hooks (`commit-hooks`), PR hooks (`pr-hooks`), prompt refinement (`prompt-refinement`) and subagent roles (`subagent-roles`) and the auto-mode CI check (`ci-hook`) on or off, or all of them (`hooks`). Written as `- <setting>: off` lines under a `## Hooks` heading in `artefacts/harness-preferences.md`; remove the line, or set it to `on`, to turn one back on |
| [Verification loops](../../docs/development-environment/practices/verification-loops.md) | The guardrails, such as the maximum iterations (5 by default), permission gates and extra checks; the CI the loop runs against. Checking against `guidelines.md` cannot be removed |

## Steps

1. **Read the current settings** from `artefacts/harness-preferences.md` in the project, which holds one section per practice. If the file is missing, create it with the defaults and make sure the project's `.gitignore` lists it.
2. **Find out what to change.** If the user has not said, list the settings above with their current values and ask which. For each change, say in a line what it does, using the explanations in the practice docs. Several changes can be made in one go.
3. **Apply the change** to `artefacts/harness-preferences.md`. It takes effect straight away, for the work that follows. For CodeGraph, follow the install steps in the context engineering practice.
4. **Log the change** by appending to `artefacts/practice-changes.md`, creating it with a `# Practice changes` heading if it is missing: the date, the practice and setting, the old value and the new value, and the reason if the user gave one. Never write secrets or machine paths into it. This file is tracked in git, unlike `harness-preferences.md`, so the team can see what changed and why, and `jira-design initialize` reads it for a teammate who has no local preferences file.
5. **Report** the settings changed, and tell the user `artefacts/practice-changes.md` is tracked. Do not commit it on your own; it goes in the user's next commit, or commit it when they ask.

## Reading the settings

Every other practice and skill reads `artefacts/harness-preferences.md` when it needs a setting, for example before suggesting a prompt format, before reminding the user to compact, and before running the human sanity check. If a setting is not in the file, the default applies.
