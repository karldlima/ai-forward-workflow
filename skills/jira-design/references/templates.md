# Ticket templates

Copy the block for the issue type, fill every section, and delete none. Replace `<ISSUE-KEY>` only at execution time, when the key exists. Epics are a theme and carry no estimate, DoR or DoD.

Default viewports for responsive criteria and Playwright projects: mobile 375x812, tablet 768x1024, desktop 1280x800. Use the project's own breakpoints when it defines them.

Durations are written as `1h 30m`.

## Epic

```markdown
## Description

The journey or theme in two to four sentences, written from the user's point of view.

## Outcome

What a user can do once every story in this epic ships.

## Stories

- Story summary
- Story summary

## Delivery

SemVer impact: minor
```

Label: the highest `semver-*` impact of its stories.

## Story

Summary: the capability, as a short verb phrase, for example `Filter sources by status`.

```markdown
## Description

As a <role>, I should be able to <capability> so that <outcome>.

Context the implementer needs: screens, components and routes involved.

## Acceptance criteria

Functional
- [ ] AC1: The user should be able to <action> and see <result>.
- [ ] AC2: The user should be able to <action> and see <result>.
- [ ] AC3: When <error or empty state>, the user sees <message> and can <recover>.

Accessibility
- [ ] AC4: Every interactive element is reachable and operable by keyboard alone, in a logical order, with a visible focus indicator.
- [ ] AC5: Controls have accessible names and correct roles; form fields have associated labels and errors are announced.
- [ ] AC6: Text and controls meet WCAG 2.2 AA contrast, and no information relies on colour alone.
- [ ] AC7: Dynamic updates such as loading and results are announced to assistive technology.

Responsive
- [ ] AC8: Mobile (375px): <layout and behaviour>, with no horizontal scroll and touch targets of at least 44px.
- [ ] AC9: Tablet (768px): <layout and behaviour>.
- [ ] AC10: Desktop (1280px): <layout and behaviour>.

## QA tests

Playwright
- AC1: Given <state>, when the user <action>, then <visible outcome>.
- AC3: Given <failure condition>, when the user <action>, then <message shown and recovery works>.
- AC4-AC7: Tab through the flow and assert focus order and visible focus; assert roles and names with `getByRole`; run an axe scan on the page.
- AC8-AC10: Run the flow in mobile, tablet and desktop projects and assert the layout at each.

Unit
- <function or component>: given <input>, returns or renders <output>.
- <function or component>: given <edge case>, <behaviour>.

## Delivery

SemVer impact: minor
Branch: feature/<ISSUE-KEY>-<slug>
Commit: feat(<scope>): <description>
Footer: Refs: <ISSUE-KEY>
PR title: <ISSUE-KEY> feat(<scope>): <description>

<Definition of Ready, story variant>

<Definition of Done, story variant>
```

Stories are never patch. For a major story, add a `Breaking change` line under Delivery naming what breaks, and use `feat!:` with a `BREAKING CHANGE:` footer.

For a backend-only story, replace the Accessibility and Responsive groups with contract criteria (inputs, outputs, status codes, error shapes) and keep the QA split between unit and API-level tests.

Stories have no Time tracking section: time is tracked on the sub-tasks and bugs that are executed.

## Sub-task

Summary: the work, as a short verb phrase, for example `Build SourceStatusFilter base component`.

```markdown
## Description

What is required, and where it lives (file or folder). Reference the existing components or patterns to follow.

## Done when

- <observable result>
- <observable result>

## QA tests

Unit
- <function or component>: given <input>, <expected>.
- <function or component>: given <edge case>, <expected>.

Playwright
- Only for sub-tasks that render UI, such as a base component or a page: <what is asserted, at which viewports>.
- Not applicable: this sub-task has no rendered UI.

## Delivery

SemVer impact: minor
Branch: feature/<ISSUE-KEY>-<slug>
Commit: feat(<scope>): <description>
Footer: Refs: <ISSUE-KEY>
PR title: <ISSUE-KEY> feat(<scope>): <description>

## Time tracking

Human estimate: TBD
HIFT: 0m
Agent time: 0m

<Definition of Ready, sub-task variant>

<Definition of Done, sub-task variant>
```

Keep exactly one of the two Playwright lines.

## Bug

Summary: the symptom, not the cause, for example `Source list shows duplicate rows after refresh`.

```markdown
## Description

What is wrong, who is affected, and how often.

## Environment

App version or commit, browser and viewport, OS, data involved.

## Steps to reproduce

1. <step>
2. <step>

## Expected

<what should happen>

## Actual

<what happens>

## Evidence

Stack trace, logs and screenshots, pasted or attached.

## Suspected cause

<only if the code was read and the cause found; otherwise "Not yet analysed">

## Acceptance criteria

- [ ] The steps above no longer produce the actual behaviour.
- [ ] <related behaviour that must keep working>

## QA tests

Unit
- Regression test that fails before the fix: given <input>, <expected>.

Playwright
- Include when the bug is user-visible: <flow and viewports>.

## Delivery

SemVer impact: patch
Branch: bugfix/<ISSUE-KEY>-<slug>
Commit: fix(<scope>): <description>
Footer: Refs: <ISSUE-KEY>
PR title: <ISSUE-KEY> fix(<scope>): <description>

## Time tracking

Human estimate: TBD
HIFT: 0m
Agent time: 0m

<Definition of Ready, bug variant>

<Definition of Done, bug variant>
```

Bugs default to patch. Use minor when the fix must add or deprecate something compatible, and commit it as `feat:`. Use major when the fix must break something consumers rely on: add a `Breaking change` line naming what consumers must change, and use `fix!:` with a `BREAKING CHANGE:` footer.

## Time tracking

Every sub-task and every bug carries the three-line Time tracking block shown in its template. These lines feed the agent ROI calculation, so keep their format exact.

| Line | Format | Set by | When |
| --- | --- | --- | --- |
| `Human estimate` | A t-shirt size and its benchmarked hours, for example `M (4h)`. Hours are what ROI uses. Never filled in by the skill on its own judgement | A human, or the user when `start` asks | Before work starts (a DoR item) |
| `HIFT` | A duration, cumulative. Covers the human's review and fix time | The `log-hift` mode, from what the human reports | After each escalation fix or PR review |
| `Agent time` | A duration, cumulative. Active working time, excluding time waiting on a human | The `link-pr` mode, from the start and escalation comments | When a PR is opened |

Each update to HIFT or Agent time is also posted as a comment, so the history is kept and the description holds the running total.

## Definition of Ready and Done

Append the DoR and DoD for the issue type. They are checklists inside the ticket, so a ticket stands alone.

### Definition of Ready

Story:

```markdown
## Definition of Ready

- [ ] Description names the user, the capability and the outcome
- [ ] Acceptance criteria are testable and cover function, accessibility and mobile, tablet and desktop
- [ ] QA tests map to every acceptance criterion
- [ ] Sub-tasks exist and each is PR-sized
- [ ] Artefacts are referenced: designs, API contracts, engineering standards, skeleton repo
- [ ] Blocking stories are Done or there are none
- [ ] SemVer impact is set
```

Sub-task:

```markdown
## Definition of Ready

- [ ] Description says what is required and where it lives
- [ ] "Done when" is observable
- [ ] QA tests are listed, with Playwright decided
- [ ] Artefacts are referenced: designs, API contracts, engineering standards, existing patterns to follow
- [ ] Blocking sub-tasks are Done or there are none
- [ ] SemVer impact is set
- [ ] Human estimate is set as a size and hours, for example `M (4h)`
```

Bug:

```markdown
## Definition of Ready

- [ ] Steps to reproduce, expected and actual are written
- [ ] Evidence is attached: stack trace, logs or screenshots
- [ ] Environment is stated
- [ ] The story or epic it broke is linked, if known
- [ ] SemVer impact is set
- [ ] Human estimate is set as a size and hours, for example `M (4h)`
```

### Definition of Done

Story:

```markdown
## Definition of Done

- [ ] Every sub-task is Done
- [ ] Every acceptance criterion is met and verified
- [ ] Playwright tests pass at mobile, tablet and desktop, including the axe scan
- [ ] CI passes
- [ ] No behavioural or visual regression
- [ ] Human-readable and agent-readable documentation is updated
```

Sub-task:

```markdown
## Definition of Done

- [ ] "Done when" is met
- [ ] New or updated unit tests pass, and Playwright tests too where listed
- [ ] The verification loop passed: existing CI tests, no regression, only relevant files touched, no secrets committed
- [ ] Branch and commits follow the branch and commit conventions
- [ ] PR is opened from the PR template and linked on this ticket
- [ ] Human-readable and agent-readable documentation is updated
- [ ] Progress is written to memory
- [ ] Agent time and HIFT are recorded
- [ ] A human has reviewed and merged the PR
```

Bug:

```markdown
## Definition of Done

- [ ] The steps to reproduce no longer produce the actual behaviour
- [ ] A regression test fails before the fix and passes after
- [ ] The verification loop passed: existing CI tests, no regression, only relevant files touched, no secrets committed
- [ ] Branch and commits follow the branch and commit conventions
- [ ] PR is opened from the PR template and linked on this ticket
- [ ] Human-readable and agent-readable documentation is updated
- [ ] Progress is written to memory
- [ ] Agent time and HIFT are recorded
- [ ] A human has reviewed and merged the PR
```
