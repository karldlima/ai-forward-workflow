# Development environment

Supporting conventions: [commit convention](conventional-commits.md), [branch convention](conventional-branch.md), [PR description template](pr-template.md).

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
3. An agent uses the Epic/User Story/Task breakdown skill plus the Monday MCP server to split the journeys into appropriately sized epics, user stories and tasks. Each gets a description, artefacts, acceptance criteria, DoR/DoD and testing criteria (where applicable).
4. Humans give t-shirt size estimates for the tasks.

## Bugs

1. When a bug is reported, humans estimate the fix.
2. An agent analyses the stack trace and logs to identify the problem, then submits a PR for the minor or major fix.

## Agent task/bug execution

The agent plans from the ticket or bug, backed by [prompt/context engineering and harness configuration](../practices.md). It then:

1. Writes code in a new branch, following the [branch convention](conventional-branch.md) and [commit convention](conventional-commits.md).
2. Runs its own [verification loop](../practices.md#verification-loops), including existing CI automated tests.
3. Writes the PR for the ticket/bug using the [PR description template](pr-template.md).
4. Writes human-readable and agent-readable documentation.
5. Writes progress into stored memory.

## Memory conservation

Save token usage with `/compact` reminders, model checks, the Context7 MCP server and stored memory.

## Human sanity check / agent escalation

Humans review agent-written PRs and fix what needs fixing. Agents also escalate when they need a human fix. Together this is **HIFT** (human intervention fix time).

Typical causes: missing domain context, obvious UX/CX issues, regression.

- HIFT is recorded on the relevant ticket/bug.
- High-HIFT scenarios are logged as a benchmarked **failure branch** in Git, preserving the code state for agents to learn from.
- Each project maintains a single version-controlled `evals.jsonl` that indexes them. Each line holds:

| Field | Meaning |
| --- | --- |
| `failure_branch` | Branch holding the code state where the agent failed |
| `fixed_branch` | Branch holding the human-intervention fix for that code state |
| `error_log` | The error log, so agents can reference it easily |

## Evaluation of agent ROI

Once the sprint's PRs are manually reviewed and merged:

1. An agent updates each task/bug with the actual time the agent spent.
2. That is added to the HIFT already on the ticket.
3. The total is compared with the original t-shirt estimate. The delta is the time saved.
4. Results are documented as a Monday Page, and written into Claude's memory, split into task ROI and bug ROI.

```
Agent ROI = benchmarked human time estimated - (agent time taken + HIFT + human review time)
```
