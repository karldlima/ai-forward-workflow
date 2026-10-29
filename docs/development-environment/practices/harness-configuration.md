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


