# Development environment

Supporting conventions: [commit convention](conventional-commits.md), [branch convention](conventional-branch.md), [PR description template](pr-template.md).

## Jira and the Atlassian MCP server

Tickets live in Jira. Agents reach Jira and Confluence through the Atlassian MCP server, which offers tools to create and edit work items, comment, link work items and PRs, search with JQL, and create Confluence pages. The [`jira-design` skill](../../skills/jira-design/SKILL.md) holds the ticket templates and the rules for using those tools. Install it globally by symlinking `skills/jira-design` into `~/.claude/skills/`.

### Time tracking on tickets

Each sub-task and bug carries three lines in its description:

| Line | Meaning | Set by |
| --- | --- | --- |
| `Human estimate` | T-shirt size and its benchmarked human hours, for example `M (4h)` | A human, before work starts |
| `HIFT` | Human intervention fix time, cumulative, covering review and fixes | The agent, after asking the human |
| `Agent time` | Active agent working time, cumulative, excluding waits on a human | The agent, when it opens the PR |

Epics and stories carry none of these; time is tracked on the units that are executed.

## Artefacts

Inputs the agent and the team build from.

**Skeleton templates / boilerplate repos** for bootstrapping:

- User journeys
- Growth landing pages (CTA, lead funnel, booking integrations)
- Informative pages (meet the team, services)

**Global company engineering standards and guidelines:**

- Frontend development patterns (folder structure, compound components, HOC wrappers, providers, global state and so on)
- Code smells
- Linting rules (JS, TypeScript checks)
- Prettier preferences

**Conventions and templates:**

- [Conventional commits](conventional-commits.md)
- [Conventional branches](conventional-branch.md)
- [PR description template](pr-template.md)

**User journey / user requirements** in natural language. This is the input to [task breakdown](#task-breakdown): for a new project it is the first file in the repo (for example a requirements `.txt`).

## Task breakdown

1. Identify pain points and a theorised solution, then gather requirements.
2. Write user journeys in detailed but clear natural language.
3. An agent uses the [`jira-design` skill](../../skills/jira-design/SKILL.md) plus the [Atlassian MCP server](#jira-and-the-atlassian-mcp-server) to split the journeys into appropriately sized epics, user stories and sub-tasks in Jira. Each gets a description, artefacts, acceptance criteria, [DoR and DoD](../../skills/jira-design/references/templates.md#definition-of-ready-and-done) and testing criteria (where applicable).
4. Humans give t-shirt size estimates for the sub-tasks, each with its benchmarked hours, written to the `Human estimate` line of its [time tracking](#time-tracking-on-tickets).

## Bugs

1. When a bug is reported, the agent files it in Jira with the `jira-design` skill, and humans estimate the fix.
2. An agent analyses the stack trace and logs to identify the problem, then submits a PR for the patch, minor or major fix.

## Agent task/bug execution

The agent plans from the ticket or bug, backed by [prompt/context engineering and harness configuration](../practices.md). It then:

1. Checks the ticket's Definition of Ready and records its start (`jira-design` `start` mode).
2. Writes code in a new branch, following the [branch convention](conventional-branch.md) and [commit convention](conventional-commits.md). The branch, commits and PR title carry the Jira issue key.
3. Runs its own [verification loop](../practices.md#verification-loops), including existing CI automated tests. If it cannot pass, it escalates (`escalate` mode).
4. Writes the PR for the ticket/bug using the [PR description template](pr-template.md).
5. Links the PR to the ticket and logs its own time (`link-pr` mode).
6. Writes human-readable and agent-readable documentation.
7. Writes progress into stored memory.

## Memory conservation

Save token usage with `/compact` reminders, model checks, the Context7 MCP server and stored memory.

## Human sanity check / agent escalation

Humans review agent-written PRs and fix anything that needs fixing, and agents escalate when they need a human fix. Both are measured as **HIFT** (human intervention fix time). Typical causes: missing domain context, obvious UX/CX issues, regression.

- HIFT is marked on the relevant ticket/bug. The agent runs the `jira-design` skill's `escalate` mode when it needs a human, and `log-hift` once the human has fixed the problem or reviewed the PR: it asks how long that took and adds it to the ticket's `HIFT` line.
- High-HIFT scenarios, where a ticket's cumulative HIFT is more than 25% of its human estimate, are logged as a benchmarked **failure branch** in Git, preserving the code state for agents to learn from, alongside a **fixed branch** holding the human's fix.
- Each project maintains a single version-controlled `evals.jsonl` that indexes them. Each line holds:

| Field | Meaning |
| --- | --- |
| `failure_branch` | Branch holding the code state where the agent failed |
| `fixed_branch` | Branch holding the human-intervention fix for that code state |
| `error_log` | The error log, so agents can reference it easily |

## Evaluation of agent ROI

Once the sprint's PRs are manually reviewed and merged, an agent runs the `jira-design` skill's `roi` mode:

1. It updates each task/bug with the actual time the agent spent.
2. That is added to the HIFT documented on the ticket.
3. The total is compared with the original human estimate. The delta is the time saved.
4. Results are documented as a Confluence page, and written into Claude's memory, split into task ROI and bug ROI.

```
Agent ROI = benchmarked human time estimated - (agent time taken + HIFT)
```
