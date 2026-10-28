---
name: jira-design
description: Turn user requirements and project context into Jira epics, user stories and sub-tasks, and file bugs, through the Atlassian MCP server. Every story carries acceptance criteria (functional, accessibility, mobile/tablet/desktop) and Playwright and unit QA tests; every ticket carries a Definition of Ready and Done, a SemVer impact, and the naming that links it to its PR. Also tracks human estimate, agent time and HIFT on tickets during execution, logs failure branches to evals.jsonl, and evaluates agent ROI for a sprint. Use when asked to break requirements or user journeys into Jira tickets, plan a feature or epic in Jira, write user stories, raise or triage a bug in Jira, link a Jira ticket to its PR, or when an agent starts a ticket, escalates for human intervention, a human has reviewed or fixed agent work and the HIFT must be logged, or a sprint's PRs are merged and agent ROI must be evaluated.
---

# Jira design

Breaks natural-language requirements into a Jira hierarchy that an agent can execute ticket by ticket, files bugs in the same shape, and keeps the time-tracking fields honest while tickets are executed. Ticket bodies follow [references/templates.md](references/templates.md). Read it before drafting or editing any ticket.

```
Epic            a theme or user journey
└── Story       one user-visible capability, delivered by 2-6 sub-tasks
    └── Sub-task  one PR-sized unit of work
Bug             a defect, linked to what it broke
```

## Modes

| Mode | Trigger | Output |
| --- | --- | --- |
| `breakdown` | Requirements file, text or user journey | Epics, stories and sub-tasks |
| `bug` | A defect report, stack trace or log | One Bug |
| `start` | An agent is about to work a ticket | DoR checked, start recorded |
| `link-pr` | A PR now exists for a ticket | PR linked, agent time logged |
| `escalate` | The verification loop cannot pass, or the agent needs a human | Failing state snapshotted, ticket commented |
| `log-hift` | A human has fixed what the agent escalated, or has reviewed and fixed the agent's PR | HIFT asked for and logged, failure branch logged if high |
| `roi` | A sprint's PRs are reviewed and merged | Agent ROI computed, written to Confluence and memory |

`start`, `escalate`, `link-pr` and `log-hift` are called by whatever agent is [executing the ticket](../../docs/development-environment/README.md#agent-taskbug-execution), not only when the user types the skill name.

## Using the Atlassian MCP server

Load the tools with `ToolSearch`: `select:` the `mcp__claude_ai_Atlassian_MCP__*` tools you need, or search `atlassian jira`. If only `authenticate` and `complete_authentication` exist, the server is not signed in: tell the user to authenticate, still produce the draft in the reply, and create nothing.

The v2 server lists a few primary tools directly. Everything else is reached with `discover` (describe the job in plain language) and then run through `executeRead` or `executeWrite`. Prefer these tools:

| Job | Tool | Reached |
| --- | --- | --- |
| Cloud id | `getAccessibleAtlassianResources` | direct |
| Projects | `listJiraProjects` | `executeRead` |
| Issue types, required fields | `listJiraProjectIssueTypesMetadata`, `getJiraIssueTypeMetaWithFields` | `executeRead` |
| Link types | `listJiraIssueLinkTypes` | `executeRead` |
| Find duplicates, find children | `searchJiraIssuesUsingJql` | direct |
| Create ticket | `createJiraIssue` | direct |
| Read ticket | `getJiraIssue` | direct |
| Edit ticket | `editJiraIssue` | direct |
| Comment | `addOrEditJiraIssueComment` | direct |
| Link two tickets | `createJiraIssueLink` | `executeWrite` |
| Link a PR | `createJiraIssueRemoteIssueLink` | `executeWrite` |
| Check a PR link | `listJiraIssueRemoteIssueLinks` | `executeRead` |
| Task created at the wrong level | `convertJiraIssueHierarchy` | `executeWrite` |
| Rich-content rules | `getContentFormatGuide` | `executeRead` |

Rules for using it:

- Call `getAccessibleAtlassianResources` first; every other call needs the `cloudId`.
- Call `getContentFormatGuide` once before the first write and write descriptions in the format it says the create and edit tools accept. Read the tool schema for parameter names; parent, labels and custom fields go through whatever the schema offers.
- Older server versions name the tools differently. Match by purpose from the schemas `ToolSearch` returns.
- Time is recorded in the description's Time tracking section, not in Jira worklogs. A worklog only feeds one "time spent" total, which cannot separate agent time from human fix time.
- Do not use the delete or manage tool groups.

## Breakdown

1. **Preflight.** Resolve the `cloudId` and project key. If one project is visible use it; if several, match on the repo or requirements name; if still unclear, draft only and report it. Read the issue type metadata and confirm the real names and required fields for Epic, Story, Sub-task and Bug. Fetch the link types.
2. **Gather context.** Read the requirements, the repo `README.md` and `CLAUDE.md`, and enough of the codebase to know the stack, the existing components and the test setup. Tickets must reference real components and routes, not invented ones.
3. **Draft the outline** in the reply: epics, their stories, each story's sub-tasks. Check each against the checklists below.
4. **Check for duplicates.** Search by JQL for existing issues with a matching summary under the same epic. Update an existing issue instead of creating a second.
5. **Create in order:** epics, then stories with the epic as parent, then sub-tasks with the story as parent. Keep a key map.
6. **Link dependencies** between stories with the project's blocking link type.
7. **Report** a table of key, type, summary, SemVer impact and parent, plus assumptions and skipped items.

### Sizing

- An epic is a theme. A user journey usually maps to one epic.
- A story is one thing a user can do. If its acceptance criteria need more than about eight functional bullets or span unrelated screens, split it.
- A sub-task is completable in one PR and one agent run. Put shared or base components in their own earlier sub-task so later ones depend on it.
- Never set story points, assignees or Jira's own estimate fields. The human estimate is a line in the description, set by a human.

### Story checklist

- Description states what the user should be able to do, or what the application should do.
- Acceptance criteria cover function, accessibility and responsive behaviour at mobile, tablet and desktop. Backend-only stories replace the last two with contract and error behaviour.
- QA tests map one-to-one to acceptance criteria, each marked Playwright or unit.
- SemVer impact, delivery naming, DoR and DoD are present.

### Sub-task checklist

- Description says what is required and where it lives in the codebase.
- QA lists the unit tests. Add Playwright tests only when the sub-task renders UI, such as a base component or a page. Logic, hooks, utilities and API clients get unit tests only.
- SemVer impact is inherited from the story. Time tracking, DoR and DoD are present.

## Bugs

1. Gather evidence: stack trace, logs, steps, environment. Read the code the trace points to and state a suspected cause only if you found one.
2. Search by JQL for an existing open bug with the same symptom. If one exists, comment on it instead.
3. Create a Bug with the bug template. Set priority from user impact, separately from SemVer impact.
4. Link it to the story or epic it broke with a "relates to" or "caused by" link type, and set the epic as parent if the project allows it.
5. Leave the human estimate as `TBD`. A human estimates the fix.

## Definition of Ready and Done

Every story, sub-task and bug carries a DoR and a DoD checklist, copied from [references/templates.md](references/templates.md#definition-of-ready-and-done) into the ticket so it stands alone.

Tickets are created **not ready** if the human estimate is `TBD`. That is expected: the estimate is a human's job.

## Executing a ticket

### `start`

Run before any code is written for a ticket.

1. Read the ticket and check every DoR item.
2. If the only unmet item is the human estimate, look for a t-shirt size to hours table in the repo docs or `CLAUDE.md`. If there is none, ask the user for the size and its benchmarked hours in one line, for example `M, 4h`, and write it to the `Human estimate` line as `M (4h)`. Any other unmet item: do not start. Say which, and move to the next ticket.
3. Add a comment `Agent started <ISO timestamp>`. This comment is the clock; it survives context compaction and new sessions.

### `link-pr`

Run after `gh pr create`.

1. Confirm the PR title and branch carry the issue key.
2. Add the PR URL and title as a remote link on the issue. If the tool is unavailable or fails, comment the URL and title instead. Include the PR head commit SHA in a comment `PR opened <url> at <sha>`: it marks the agent's state before any human review.
3. Read the remote links back and confirm the PR is there. If the project's GitHub integration is installed, the key in the branch and title also links the PR in the Development panel on its own.
4. Log agent time (below).
5. Tick the DoD items you can evidence. Leave the human-owned ones (review, merge) unticked.

Do not transition the ticket unless asked.

### Agent time

Agent time is active working time, not wall-clock: it excludes time spent waiting on a human.

- Read the ticket comments. The active intervals are `start` to the first escalation, then each resume (the `log-hift` comment) to the next escalation, and the last resume to now.
- Sum them, round to the nearest 5 minutes, add to the `Agent time` line, and note the total in a comment.
- Write durations as `1h 30m`.

## Human sanity check and agent escalation

Humans review the agent-written PRs and fix anything that needs fixing, and agents escalate when they need a human fix. Both are measured as **HIFT**, human intervention fix time: the time a human spends reviewing and fixing. Typical causes:

- missing domain context
- obvious UX/CX issues
- regression

HIFT is marked on the relevant ticket or bug. This is part of the verification loop, so the agent escalates rather than loops forever: when its checks cannot pass within the iteration limit, or the cause is domain context or a UX/CX call it cannot make.

**High-HIFT scenarios are logged as benchmark cases.** A ticket is high-HIFT when its cumulative HIFT is more than 25% of its human estimate. Its code state is preserved as a **failure branch** in Git, with the human's fix on a **fixed branch**, so agents can learn from them. The project keeps a single version-controlled `evals.jsonl` that indexes them.

### `escalate`

1. Snapshot the failing state: commit all work as `chore: snapshot failing state for <ISSUE-KEY>` with a `Refs: <ISSUE-KEY>` footer, and create a branch at that commit, `chore/failure-<issue-key>-<slug>`. Branches and commits follow the [branch](../../docs/development-environment/conventional-branch.md) and [commit](../../docs/development-environment/conventional-commits.md) conventions; benchmark branches use `chore/` because they are not deliverable work.
2. Trim the error output to the lines that matter: the failing test, stack trace or log, at most about 40 lines, with secrets and environment values removed.
3. Comment `Escalated to human <ISO timestamp>: <cause>`, then the trimmed log in a code block and the failure branch name. Cause is one of: missing domain context, UX/CX issue, regression, other (say what). This stops the agent-time clock.
4. Tell the human what is needed, then stop work on the ticket until they report the fix is done.

### `log-hift`

Run when:

- the human reports they have fixed what the agent escalated, or
- the human reports they have reviewed the agent's PR, with or without fixes. Review time counts as HIFT.

Never log before the human says they are done.

1. **Mark the fixed state.** If the human committed on the ticket branch, create `chore/fixed-<issue-key>-<slug>` at its current tip before the agent resumes. If they used another branch, use that branch as the fixed branch.
2. **Find the failure state.** After an escalation it is the failure branch from `escalate`. After a review it is the commit in the `PR opened <url> at <sha>` comment, so create `chore/failure-<issue-key>-<slug>` at that SHA. A review with no changes needs neither branch.
3. **Ask the user one question, naming the ticket and what was reviewed or fixed:** how much time they spent, for example `45m` or `1h 30m`. If the time has no unit, confirm the unit in one line.
4. **Never invent a figure.** If they only have a rough figure, record their best estimate. If they decline, change nothing and say so in the report.
5. **Update the ticket.** Re-read it so edits made meanwhile are kept. Add the new time to the `HIFT` line and write the description back with only that line changed.
6. **Comment** `HIFT +<duration> (<cause>)`. After an escalation, add `Agent resumed <ISO timestamp>`: that restarts the agent-time clock. A review-only entry does not touch the clock.
7. **Decide if it is high-HIFT.** It is when the `HIFT` line, with this entry added, is more than 25% of the ticket's human estimate in hours, for example more than 1h in total on a `M (4h)` ticket. The entry that crosses the threshold is logged, and so is every later entry on that ticket. An entry with no code change to preserve is never logged. If the ticket has no usable estimate, skip logging and say so. If it is high-HIFT, log the benchmark case:
   - Push the two branches with the ticket branch.
   - Append one line to `evals.jsonl` at the repo root, creating the file if absent, and commit it on the ticket branch as `chore(evals): log failure branch for <ISSUE-KEY>` with a `Refs: <ISSUE-KEY>` footer.
8. **If it is not high-HIFT**, delete the local failure branch you created with `git branch -d`, so snapshots do not pile up.

```json
{"failure_branch":"chore/failure-proj-123-source-filters","fixed_branch":"chore/fixed-proj-123-source-filters","error_log":"FAIL src/filters.test.ts\n  expected 3 rows, received 0"}
```

Each line is one JSON object with exactly these fields:

| Field | Meaning |
| --- | --- |
| `failure_branch` | Branch holding the code state where the agent failed |
| `fixed_branch` | Branch holding the human-intervention fix for that state |
| `error_log` | The trimmed error log, as a single JSON string, so agents can reference it easily |

The diff between the two branches is the human's fix. Keep the lines valid JSON and one per line so the file stays easy to read and diff.

## Evaluating agent ROI

### `roi`

Run once the sprint's PRs have been manually reviewed and merged. The agent updates each task and bug with the actual agent time, adds it to the HIFT already on the ticket, compares the total with the original human estimate, and records the time saved.

```
Agent ROI = benchmarked human time estimated - (agent time taken + HIFT)
```

HIFT already includes the human's review time, so there is no separate review term. The delta is the time saved. It is negative when the agent cost more than a human would have.

1. **Scope the sprint.** Use the sprint or JQL the user names. Otherwise take the most recently closed sprint on the project's board (boards and sprints are reached through `discover`). Search for its Sub-tasks and Bugs with `searchJiraIssuesUsingJql`.
2. **Keep only merged work.** For each ticket, read its remote links and check the PR is merged, for example with `gh pr view <url> --json state`. Leave out tickets whose PR is open or closed unmerged, and list them.
3. **Bring the actual agent time up to date.** For each ticket whose `Agent time` is still `0m`, or whose comments show more active time than the line records, recompute it from the comments under [Agent time](#agent-time) and update the line.
4. **Collect any missing HIFT.** If tickets still show `HIFT: 0m`, ask the user once, as a single list, how long they spent reviewing and fixing each. `0` or `none` is a valid answer. Update the lines through `log-hift` step 5.
5. **Compute per ticket**: human estimate hours minus (agent time plus HIFT). Tickets with no human estimate are excluded and listed.
6. **Split the results** into task ROI (Sub-tasks) and bug ROI (Bugs), each with a table of key, summary, estimate, agent time, HIFT and time saved, and a total row.
7. **Document as a Confluence page** with `createConfluenceContent`, titled `Agent ROI - <sprint name>`. Put it in the Confluence space whose key matches the Jira project, else the user's personal space, and say which. Read `getContentFormatGuide` first. The page holds a short summary, the two tables, the excluded tickets, and the formula.
8. **Write it into Claude's memory** as a project memory with the task ROI and bug ROI as separate sections, following the session's memory instructions, and add its line to the memory index.
9. Report the totals, the page link, the tickets excluded, and the tickets that have a logged failure branch.

## SemVer impact

Every ticket gets exactly one label, `semver-patch`, `semver-minor` or `semver-major`, and a matching line in its Delivery section.

| Impact | Meaning | Default for | Commit | Branch prefix |
| --- | --- | --- | --- | --- |
| `semver-patch` | Backwards-compatible bug fix that adds and changes no public surface | Bugs | `fix:` | `bugfix/` |
| `semver-minor` | New backwards-compatible capability, or a bug fix that must add or deprecate something compatible | Stories | `feat:` | `feature/` for stories, `bugfix/` for bugs |
| `semver-major` | Breaking change to a public API, route, data format or behaviour that consumers rely on, including a fix that must break one | Never the default | `feat!:` or `fix!:` plus a `BREAKING CHANGE:` footer | same as above |

- A story is never patch.
- A minor bug fix is committed as `feat:` so release tooling bumps the minor version; the branch stays `bugfix/`.
- Choose major only when you can name what breaks, and write that into the ticket.
- An epic takes the highest impact of its stories.
- Use the `hotfix/` prefix instead of `bugfix/` only when the report says urgent.

## Linking the ticket to its PR

The PR does not exist when the ticket is written, so the ticket carries the names that make Jira link it on its own, following the repo's [branch](../../docs/development-environment/conventional-branch.md) and [commit](../../docs/development-environment/conventional-commits.md) conventions:

- Branch: `<prefix>/<issue-key>-<slug>`, lowercase as the branch convention requires, for example `feature/proj-123-source-filters`.
- Commit footer: `Refs: PROJ-123`, with the key in uppercase.
- PR title: `PROJ-123 <conventional commit subject>`.
- PR body: the ticket key and URL under "Ticket" in the [PR template](../../docs/development-environment/pr-template.md).

Tickets hold `<ISSUE-KEY>` as a placeholder, which avoids a second edit after creation. The agent that executes the ticket substitutes the key. `link-pr` then adds the explicit remote link.

## Final report

Close with:

- The created or updated issues as a table.
- Assumptions made, such as the project chosen, the Sub-task type used for tasks, or an impact judged major.
- Items skipped and why: ambiguous requirements, missing Jira fields or permissions, an MCP that is not signed in, an estimate or HIFT figure the human did not give.
