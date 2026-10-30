# Harness configuration

agent (claude code) = model (opus) + harness.

The setup of the execution environment, tools and guardrails for the workflow. It provides reliable outputs and maintains security.

**Consists of**

- **Execution environment:** localhost, Docker container or cloud workspace. See [Execution environment](#execution-environment)
- **Multi-step agent system:** breaks a task into independent actions with sub-goals via the Orchestrator-Subagent pattern. The primary agent spins up several stateless Claude instances in parallel, each with its own context window. See [Multi-step agent system](#multi-step-agent-system)
- **Tools:** shell access, filesystem tools (grep, find), package managers, MCP servers, skills, with a set of [default tools](#default-tools). See [Tools and permissions](#tools-and-permissions)
- **Agent verification loop:** its own practice, adjustable during `initialize`. See [Verification loops](verification-loops.md)
- **Human sanity check and agent escalation:** on by default, and chosen during `initialize`. See [Human sanity check and agent escalation](#human-sanity-check-and-agent-escalation)


| Pros                                          | Cons                                |
| --------------------------------------------- | ----------------------------------- |
| Security, reliable outputs, scalable workflow | Large initial overhead, more tokens |




## Harness preferences file

The answers to the `initialize` questions (execution environment, permissions and multi-step agent system) are stored in `artefacts/harness-preferences.md` in the project. The file is listed in the project's `.gitignore`, so it stays out of git. It is passed between team members directly: a teammate who has the file in their `artefacts/` folder is not asked again, and the agent reads it to know the environment, what it may use and whether subagents are on. A teammate without the file is asked the same questions, and writes their own.

## Changing the practices later

The user can change the settings of any practice at any time with the `workflow-configure` [skill](../../../skills/workflow-configure/SKILL.md): run `/workflow-configure` or just ask, for example "turn the multi-step agent system off" or "raise the iteration limit". It covers all four practices, not only the harness, and the agent:

1. updates `artefacts/harness-preferences.md`, the local, git-ignored file with the user's current settings, and the change applies straight away
2. appends the change (the date, the setting, the old and new value, and the reason) to `artefacts/practice-changes.md`

`practice-changes.md` is committed to the repo. It is the record of how the project's practices differ from the defaults, so teammates can see what changed and why. When a teammate runs `initialize` without a local `harness-preferences.md`, the agent reads the log and offers to start from those changes. The agent does not commit the log on its own: it goes in the user's next commit.

## Execution environment

Where the agent runs code and commands. The default is **localhost**. When a user starts a project with `/jira-design initialize`, the agent asks which they prefer and records the answer in `artefacts/harness-preferences.md`.

| Environment | Good for | Watch out for |
| --- | --- | --- |
| Localhost (default) | The simplest setup and the fastest feedback | The agent acts on the user's real machine and files |
| Docker container | A reproducible, isolated environment that matches CI | Setup and maintenance of the image |
| Cloud workspace | Isolation from the user's machine, and a workspace others can reach | Network latency and a hosted environment to manage |

## Tools and permissions

The tools the agent can use are shell access, filesystem tools (grep, find), package managers, MCP servers and skills. During `initialize` the agent asks the user which of these it may use. The user can allow some and not others. The agent stays inside what was granted, and where a permission was not granted it asks at the moment it needs the tool. Claude Code's own permission prompts still apply on top of this.

### Default tools

The workflow starts from these defaults.

| Kind | Defaults |
| --- | --- |
| Plugins (MCPs) | CodeGraph, Playwright, Frontend Design by Anthropic |
| Connectors | Atlassian MCP, Claude in Chrome, Context7, GitHub integration |
| Skills | CodeGraph, Deep Research, Import Memory, Frontend Design |

CodeGraph is explained in [context engineering](context-engineering.md), and `initialize` installs it through its own offer. During `initialize` the agent tells the user these are the defaults, reports any that do not appear to be set up so the user can install or connect them, and asks whether there is anything else to add. Additions are recorded under a tools section of `artefacts/harness-preferences.md`.

## Multi-step agent system

The multi-step agent system is **on by default**. It breaks a task into multiple independent actions, each with a sub-goal, that together achieve the long-term goal. It uses the **Orchestrator-Subagent pattern**:

- The primary agent (the orchestrator) plans the work and splits it into independent sub-goals.
- It spins up several stateless Claude instances (subagents) in parallel, each with its own context window and only the context its sub-goal needs.
- The subagents return their results and the primary agent combines them.

It is used mainly during [agent task/bug execution](../README.md), where the independent parts of a ticket can be worked at the same time.

| Pros | Cons |
| --- | --- |
| Faster on independent work, because instances run in parallel | More tokens, because every instance has its own context window |
| The primary agent's context stays small and focused | Instances are stateless and share no context, so hand-offs must be explicit |
| Each instance works on one sub-goal | Parallel edits to the same files can conflict, and runs are harder to debug |

During `initialize` the agent explains these trade-offs and asks the user whether to leave it on or turn it off. With it off, the primary agent works through the sub-goals one at a time itself.

### Subagent roles

A role is what a subagent is for: a name, a one-line responsibility, and the tools it needs, for example a researcher that reads and summarises, an implementer that writes the code, and a reviewer that checks it. Roles keep each subagent's context window small and its job narrow.

When the multi-step agent system is on, the `subagent-roles` [hook](#hooks) fires when the user submits a multi-part prompt, at most once per session. The agent then offers to set up roles for subagents related to that prompt: it proposes two to four roles and the user accepts, edits or declines them. Accepted roles are saved locally, on the user's machine, as subagent definitions in `.claude/agents/<role>.md` in the project (frontmatter with the name, description and tools, then the role's system prompt), and `.claude/agents/` is added to the project's `.gitignore` so they are never committed. The primary agent then hands the matching sub-goals to those roles when it orchestrates the work. A role can be edited or deleted at any time by editing its file or asking the agent.

## Hooks

The workflow's Claude Code hooks are part of the harness. They are installed by `jira-design initialize`: the script `hooks/workflow-hook.sh` is copied into the project's `.claude/hooks/` and the entries in `hooks/settings.json` are merged into the project's `.claude/settings.json`, so the team can share them. The root [README](../../../README.md) describes what each one does for the user.

| Hook | Event | Setting |
| --- | --- | --- |
| Commit, before and after | `PreToolUse` and `PostToolUse` on Bash, for `git commit` | `commit-hooks` |
| PR, before and after | `PreToolUse` and `PostToolUse` on Bash, for `gh pr create` | `pr-hooks` |
| Prompt refinement | `UserPromptSubmit` | `prompt-refinement` |
| Subagent roles | `UserPromptSubmit` | `subagent-roles` |
| CI after commits, in auto mode, only if the project has no CI of its own | `Stop` | `ci-hook` |

The hooks pass the agent instructions as context. The before hooks for commits and PRs block the command once, only when the message or description does not follow the convention, so the agent can offer to write it, and let the same command through the second time. The after hooks stay silent when the commit or PR already follows the convention. The `stop-ci` hook runs the project's tests when the agent stops in auto mode after making a commit, and sends the agent back to fix failures, up to 5 attempts (see [verification loops](verification-loops.md)); a `record-head` step on each prompt tells it which commit the session started from.

Each hook can be turned off. The switch lives in `artefacts/harness-preferences.md`, the local, git-ignored file, as a line under a Hooks heading:

```markdown
## Hooks
- commit-hooks: off
```

`hooks: off` turns all of them off. A missing line means on. The user turns them off by telling the agent or running `/workflow-configure`, and each hook tells the user this the first time it speaks.

## Human sanity check and agent escalation

This is on by default. During `initialize` the agent asks the user whether they want it on, and records the answer in `artefacts/harness-preferences.md`. It has two parts:

- **Human sanity check:** during [task/bug execution](../README.md), after the verification loop passes and before the agent opens the PR, the agent shows the user what changed and prompts them to review and confirm. If they want changes, the agent makes them or the user fixes them, and the agent re-runs the verification loop before the PR.
- **Agent escalation:** if the agent cannot fix an issue, it diverts to a human instead of looping forever.

With it off, the agent opens the PR without pausing for confirmation, and when it cannot fix something it reports that and stops. No HIFT is tracked, no failure branches are logged and `evals.jsonl` gets no entries, so [agent ROI](../README.md) is then computed from agent time alone.

Humans review the agent's work, before the PR and in review after it, and fix anything that needs fixing, and agents escalate when they need a human fix. Both are measured as **HIFT** (human intervention fix time). Typical causes: missing domain context, obvious UX/CX issues, regression.

- HIFT is marked on the relevant ticket/bug. The agent runs the `jira-design` [skill](../../../skills/jira-design/SKILL.md)'s `escalate` mode when it needs a human, and `log-hift` once the human has fixed the problem or reviewed the PR: it asks how long that took and adds it to the ticket's `HIFT` line.
- High-HIFT scenarios, where a ticket's cumulative HIFT is more than 25% of its human estimate, are logged as a benchmarked **failure branch** in Git, preserving the code state for agents to learn from, alongside a **fixed branch** holding the human's fix.
- Each project maintains a single version-controlled `evals.jsonl` that indexes them. Each line holds:


| Field            | Meaning                                                       |
| ---------------- | ------------------------------------------------------------- |
| `failure_branch` | Branch holding the code state where the agent failed          |
| `fixed_branch`   | Branch holding the human-intervention fix for that code state |
| `error_log`      | The error log, so agents can reference it easily              |


