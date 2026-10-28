# Practices

Four practices keep agent output reliable. Each trades extra overhead for fewer regressions.

An agent (Claude Code) is a model (Opus) plus a harness.

## Prompt engineering

Curate, refine and save inputs (prompts) so the LLM produces reliable outputs without regression.

**Format**

- Role/persona (for example, senior SWE)
- Task
- Context and constraints (limits, edge cases, background info)
- Output format (JSON, table and so on)

**Shot-examples:** give the agent input/output examples.

| Pros | Cons |
| --- | --- |
| Reliable outputs, less regression | More tokens, higher latency, more maintenance overhead |

## Context engineering

Curate and optimise the dynamic data the agent uses, without brute-force or full-history searches, to get reliable outputs while maximising information density per token.

**Done through**

- Indexing: repository map plus AST (a "code graph")
- Grep and `read_lines`
- Memory management: tracking multi-turn history, compacting, user preferences over time

| Pros | Cons |
| --- | --- |
| Reliable outputs, fewer tokens (better TTFT) | Regression through context compaction |

## Harness configuration

The setup of the execution environment, tools and guardrails for the workflow. It provides reliable outputs and maintains security.

**Consists of**

- **Execution environment:** localhost, Docker container or cloud workspace
- **Multi-step agent system:** breaks a task into independent actions with sub-goals via the Orchestrator-Subagent pattern. The primary agent spins up several stateless Claude instances in parallel, each with its own context window.
- **Tools:** shell access, filesystem tools (grep, find), package managers, MCP servers, skills
- **Agent verification loop:** see below
- **Agent escalation:** see [Human sanity check](development-environment/README.md#human-sanity-check--agent-escalation)

| Pros | Cons |
| --- | --- |
| Security, reliable outputs, scalable workflow | Large initial overhead, more tokens |

## Verification loops

Before submitting a PR for a ticket or bug, the agent checks its work against the global company engineering standards, the existing CI automated tests, and manually set guardrails:

- Only touch files relevant to the ticket/bug
- Human permission gates (ask before running `rm -rf`, for example)
- Maximum iteration loops, to prevent runaway token spend
- Don't leak sensitive data (env vars)
- Check for regression, both behavioural and visual
- CI tests pass

| Pros | Cons |
| --- | --- |
| Reduces HIFT, maintains code quality | More tokens, higher latency |
