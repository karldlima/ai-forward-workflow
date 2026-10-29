# Development environment

## Jira and the Atlassian MCP server

Tickets live in Jira. Agents reach Jira and Confluence through the Atlassian MCP server, which offers tools to create and edit work items, comment, link work items and PRs, search with JQL, and create Confluence pages. The `jira-design` [skill](../../skills/jira-design/SKILL.md) holds the ticket templates and the rules for using those tools. Install it globally by symlinking `skills/jira-design` into `~/.claude/skills/`.

### Time tracking on tickets

Each sub-task and bug carries three lines in its description:


| Line             | Meaning                                                            | Set by                            |
| ---------------- | ------------------------------------------------------------------ | --------------------------------- |
| `Human estimate` | T-shirt size and its benchmarked human hours, for example `M (4h)` | A human, before work starts       |
| `HIFT`           | Human intervention fix time, cumulative, covering review and fixes | The agent, after asking the human |
| `Agent time`     | Active agent working time, cumulative, excluding waits on a human  | The agent, when it opens the PR   |


Epics and stories carry none of these; time is tracked on the units that are executed.

## Artefacts

Inputs the agent and the team build from. They are files in an [`artefacts/`](artefacts/) folder.


| Name                     | File name                                                                        | Used in                                                                                                     |
| ------------------------ | -------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Requirements             | `requirements.md`                                                                | [Task breakdown](#task-breakdown)                                                                           |
| Boilerplate              | `boilerplate.md`                                                                 | [Task breakdown](#task-breakdown), [Agent task/bug execution](#agent-taskbug-execution)                     |
| DoR                      | [`dor.md`](../../skills/jira-design/references/templates.md) | [Task breakdown](#task-breakdown)                                                                           |
| DoD                      | [`dod.md`](../../skills/jira-design/references/templates.md)  | [Task breakdown](#task-breakdown)                                                                           |
| Conventional commits     | [`conventional-commits.md`](artefacts/conventional-commits.md)                   | [Agent task/bug execution](#agent-taskbug-execution)                                                        |
| Conventional branches    | [`conventional-branch.md`](artefacts/conventional-branch.md)                     | [Agent task/bug execution](#agent-taskbug-execution)                                                        |
| PR template              | [`pr-template.md`](artefacts/pr-template.md)                                     | [Agent task/bug execution](#agent-taskbug-execution)                                                        |
| Standards and guidelines | `guidelines.md`                                                                  | [Agent task/bug execution](#agent-taskbug-execution), [Verification loops](practices/verification-loops.md) |
| Harness preferences      | `harness-preferences.md`                                                         | [Agent task/bug execution](#agent-taskbug-execution)                                                        |


What they hold:

- `requirements.md`**:** user journeys and user requirements in natural language. This is the input to [task breakdown](#task-breakdown).
- `boilerplate.md`**:** skeleton templates and boilerplate repos for bootstrapping: user journeys, growth landing pages (CTA, lead funnel, booking integrations), and informative pages (meet the team, services).
- `dor.md` **and** `dod.md`**:** the Definition of Ready and Definition of Done each ticket carries.
- `guidelines.md`**:** all global company engineering standards and guidelines: frontend development patterns (folder structure, compound components, HOC wrappers, providers, global state and so on), code smells, linting rules (JS, TypeScript checks) and Prettier preferences.
- `harness-preferences.md`**:** the user's answers from `initialize` on execution environment, permissions and the multi-step agent system. It is git-ignored and passed between team members directly. See [harness configuration](practices/harness-configuration.md).

**Defaults and project overrides.** When a project repo uses this workflow, it defaults to the artefacts in this repo's `artefacts/` folder. If the project has its own `artefacts/` folder at its repo root, the agent uses those instead: a file in the project's folder overrides the default of the same name, and any file the project does not have falls back to the default.

## Task breakdown

1. Identify pain points and a theorised solution, then gather requirements.
2. Write user journeys/requirements in detailed but clear natural language.
3. An agent reads `requirements.md` and `boilerplate.md`, then uses the `jira-design` [skill](../../skills/jira-design/SKILL.md) plus the [Atlassian MCP server](#jira-and-the-atlassian-mcp-server) to split the journeys into appropriately sized epics, user stories and sub-tasks in Jira. Each gets a description, artefacts, acceptance criteria, DoR and DoD (from `dor.md` and `dod.md`, or the skill's [defaults](../../skills/jira-design/references/templates.md) when a project has none) and testing criteria (where applicable).
4. Humans give t-shirt size estimates for the sub-tasks, each with its benchmarked hours, written to the `Human estimate` line of its [time tracking](#time-tracking-on-tickets).



## Bugs

1. When a bug is reported, the agent files it in Jira with the `jira-design` skill, and humans estimate the fix.
2. An agent analyses the stack trace and logs to identify the problem, then submits a PR for the patch, minor or major fix.



## Agent task/bug execution

The agent plans from the ticket or bug, backed by [prompt engineering](practices/prompt-engineering.md), [context engineering](practices/context-engineering.md) and [harness configuration](practices/harness-configuration.md). When the multi-step agent system is on (the default), the primary agent runs the independent parts of the work as parallel subagents. It then:

1. Checks the ticket's Definition of Ready and records its start (`jira-design` `start` mode).
2. Initialises the project when it takes on the task: looks in `boilerplate.md` for a skeleton template to bootstrap from, and in `guidelines.md` for the linting rules and Prettier preferences to set up.
3. Checks `guidelines.md` for the frontend development patterns (folder structure, compound components, HOC wrappers, providers, global state) while thinking of solutions.
4. Writes code in a new branch, following those patterns, the [branch convention](artefacts/conventional-branch.md) and the [commit convention](artefacts/conventional-commits.md). The branch, commits and PR title carry the Jira issue key.
5. Runs its own [verification loop](practices/verification-loops.md) against `guidelines.md`, the project's CI automated tests and a `code-reviewer` subagent review, before making the PR. The first time, it asks the user whether the project has CI, and if not, asks them to add it now; without CI it has nothing to test against and notes that the CI check was skipped. If the loop cannot pass within its maximum of 5 iterations, it escalates (`escalate` mode).
6. Runs the human sanity check (`sanity-check` mode): shows the user what changed and prompts them to review and confirm before the PR. The review time is logged as HIFT. If the agent cannot fix an issue at any point, it diverts to agent escalation (see [harness configuration](practices/harness-configuration.md)). Both can be turned off at `initialize`.
7. Writes the PR for the ticket/bug using the [PR description template](artefacts/pr-template.md).
8. Links the PR to the ticket and logs its own time (`link-pr` mode).
9. Writes human-readable and agent-readable documentation.
10. Writes progress into [stored memory](practices/context-engineering.md), and the ticket's conversation summary onto the ticket (`save-context` mode) so teammates share it.



## Memory conservation

Save token usage with `/compact` reminders, model checks, the Context7 MCP server and stored memory. This is [context engineering](practices/context-engineering.md): memory management and indexing.

## Human sanity check / agent escalation

Humans review the agent's work before the PR is opened and fix what needs fixing, and agents escalate when they need a human fix. Both are measured as HIFT. On by default, and chosen during `initialize`. See [harness configuration](practices/harness-configuration.md).

## Evaluation of agent ROI

Once the sprint's PRs are manually reviewed and merged, an agent runs the `jira-design` skill's `roi` mode:

1. It updates each task/bug with the actual time the agent spent.
2. That is added to the HIFT documented on the ticket.
3. The total is compared with the original human estimate. The delta is the time saved.
4. Results are documented as a Confluence page, and written into Claude's memory, split into task ROI and bug ROI.

```
Agent ROI = benchmarked human time estimated - (agent time taken + HIFT)
```

HIFT is human intervention fix time, which includes the human's review time.