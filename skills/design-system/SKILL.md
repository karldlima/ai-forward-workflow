---
name: design-system
description: Recommend the methodology and the component library or approach (component stack and styling tools) a project should build its UI on, from what the user values (flexibility, performance, accessibility, maintainability, scalability) and whether the project must be multi-tenant, using the workflow's design system guide. Offers to create the Jira epic and stories for the choice, with the SemVer version worked out by the agent as part of branching, and records the decision, and whether accessibility is flagged as a priority (which turns on automated axe testing in the Playwright end-to-end tests), in the committed artefacts/practice-changes.md so the team sees it. Runs during initialize and configure, and is locked once the stack has been implemented. Use when the user is starting a project with the workflow, asks which component library, design system or styling approach to use, or runs /design-system.
---

# Design system

Helps a project choose how its UI is built: the methodology (how components and styles are organised) and the component library or approach (the component stack and styling tools). The choice depends on what the project demands, so the skill asks, recommends, and records the decision where the whole team sees it.

The options, their trade-offs and the multi-tenant guidance are in [references/stack-guide.md](references/stack-guide.md). Read it before recommending anything. If the file is missing or empty, tell the user the design system guide has not been added to the skill, make no recommendation, record nothing, and stop. Never recommend a stack from memory that the guide does not cover.

## When it runs

| Caller | What happens |
| --- | --- |
| `jira-design initialize` | Runs `choose` once, after the harness preferences and before the task breakdown, so the epic can join the breakdown |
| `/workflow-configure` | Runs `choose` again, only while the stack has not been implemented. See [Locked after implementation](#locked-after-implementation) |
| `/design-system` | The user asks directly. Behaves as configure does |

## Steps

### `choose`

1. **Check the lock.** Read the committed `artefacts/practice-changes.md` in the project. If it has a `Design system implemented` entry, stop and follow [Locked after implementation](#locked-after-implementation). If it has an earlier design system entry that is not implemented, show it, and treat this run as a change from that value.
2. **Read the requirements** in `artefacts/requirements.md` when it exists, and the repo's stack, so the questions are asked with the project in mind. Do not ask what they already answer, such as a framework the project is already built on; say what you took from them.
3. **Ask both questions in one prompt**, and explain each briefly:
   - **What do you value?** Flexibility, performance, accessibility, maintainability, scalability. Ask the user to rank them, or to pick their top two or three. Tell them the guide treats maintainability and scalability as applying to any design system (shared HOC wrappers with governance, and SemVer with a documented rollout), so the ranking steers the choice between flexibility, performance and accessibility, while the other two are applied whatever they pick and are written into the epic. Say in a line what each means for a UI stack: flexibility is how freely the look and the components can be reshaped; performance is bundle size and runtime cost; accessibility is how much is correct by default; maintainability is how easy it is to keep consistent over time; scalability is how well it holds up as the team, the screens and the components grow.
   - **Accessibility as a priority.** Accessibility counts as flagged when the user ranks it among their top two or three, or says it is a priority. When it is flagged, tell them what follows: automated axe accessibility tests are added to the Playwright end-to-end tests that run in CI as part of the verification loop. Say plainly that axe catches only a limited portion of accessibility bugs (it cannot judge whether labels and alt text are meaningful, keyboard flow, or screen reader behaviour), so the manual accessibility checks in each ticket's acceptance criteria still matter. When it is not flagged, nothing is added.
   - **Is the project multi-tenant?** Yes or no: will several customers or organisations use the same application, each with their own branding, themes or configuration? If the requirements already say so, state it and ask the user to confirm.
4. **Recommend**, using the guide. Match the ranked values and the multi-tenant answer against its options. Give:
   - the recommended **methodology** and **component library or approach**, with the styling tools that go with them;
   - one line per value the user ranked, saying how the recommendation does on it, in their rank order;
   - what it costs: the values it is weaker on, so the trade-off is visible;
   - the multi-tenant consequences when the answer was yes, from the guide;
   - whether accessibility is flagged, and so whether axe testing will be added;
   - a runner-up, and when the user should prefer it instead.
5. **Let the user decide.** They can accept, pick the runner-up, or say what to change and have it re-run. If they do not answer, make no decision and record nothing: ask again at the next initialize or configure.
6. **Record the decision.** Follow [Recording the decision](#recording-the-decision).
7. **Offer the Jira epic.** Follow [Offering the epic](#offering-the-epic).

## Recording the decision

The decision is a global change, saved the same way as every other: it goes in the committed `artefacts/practice-changes.md`, not in the git-ignored `harness-preferences.md`, so a teammate gets it with the repo.

Append one entry, creating the file with a `# Practice changes` heading if it is missing, with the same fields as other entries: the date, the practice and setting, the old value and the new value, and the reason.

```markdown
## 2026-11-05 Design system

- Setting: design system
- Old: not chosen
- New: <methodology>, <component library or approach>, <styling tools>
- Values (ranked): <value 1>, <value 2>, <value 3>
- Accessibility priority: yes | no
- Multi-tenant: yes | no
- Status: chosen
- Reason: <the user's reason, if given>
```

- `Accessibility priority` is `yes` when accessibility was flagged, as defined in step 3, and `no` otherwise. The verification loop and `jira-design` read it from here to decide whether axe testing is implemented. See [Accessibility testing](../../docs/development-environment/practices/verification-loops.md).
- Write only the fields above. Never write secrets or machine paths into it.
- On a change before implementation, the Old line holds the previous choice and the Status stays `chosen`.
- Do not commit it. It goes in the user's next commit, or commit it when they ask, as with other practice changes.
- Tell the user the entry is tracked in git, so the team can see what was chosen and why.

## Offering the epic

Ask once, after recording: "Do you want me to create the Jira epic and stories to set this up?" Create nothing without a yes. On a no, say the epic can be created later by running `/design-system`, and move on.

On a yes, run the `jira-design` skill's `breakdown` for this one theme, with the decision as its requirements, so it follows that skill's sizing, story checklist, acceptance criteria, QA tests, DoR and DoD, and templates:

- **Epic:** `Design system: <component library or approach>`. Its description states the methodology, the styling tools, the ranked values and whether the project is multi-tenant.
- **Stories**, each one capability, following the guide's layers in order, so only the layers the choice needs: design foundations (tokens); the styling methodology; the shared component library with its base components and HOC wrappers, in its own early sub-tasks so later ones depend on them, and including the three tier folders `components/base`, `components/shared` and `components/domain` (see the guide's component tiers); the styling layer, including per-tenant theming when multi-tenant; and documentation and CI (Storybook, and regression tests on the Storybook components). Add a story for the governance and rollout rules that maintainability and scalability call for (shared HOC wrappers, governance meetings, SemVer and a documented rollout). Document the conventions in `guidelines.md`.
- When `Accessibility priority` is `yes`, add a story for automated accessibility testing, under the documentation and CI layer: add the `@axe-core/playwright` dev dependency and the shared `expectNoAxeViolations` helper from the [verification loop](../../docs/development-environment/practices/verification-loops.md), call it in the Playwright tests for the shared components and pages, and confirm it fails the CI run on a violation. Its description says that axe catches only a limited portion of accessibility bugs. Add no such story when it is `no`.
- Every story and sub-task keeps the acceptance criteria for function, accessibility and mobile, tablet and desktop that `jira-design` requires, so the accessibility of the chosen stack is tested from the first story.
- Check for duplicates first, as `jira-design` does. If the epic already exists, update it instead of creating a second one.

During `initialize` the epic joins the normal task breakdown, so create it there and do not run `breakdown` twice.

## Versioning in branching

The agent works out the version. The user is not asked for it.

When it starts a ticket under the design system epic, before creating the branch:

1. **Find the current version.** Run `git describe --tags --abbrev=0 --match 'v*'`. If there is no tag, the current version is `0.0.0`.
2. **Take the impact** from the ticket's `SemVer impact` line, as set by `jira-design`: the stack set-up and component stories are `semver-minor` and committed as `feat:`; a breaking change to a public surface the project's consumers rely on is `semver-major`, with `feat!:` and a `BREAKING CHANGE:` footer; stories are never patch.
3. **Compute the next version** from the epic's highest impact: patch bumps the third number, minor the second and resets the third, major the first and resets the rest. While the project is on `0.x`, a breaking change bumps the minor, and `1.0.0` is a decision for the user, so ask only then.
4. **Name the branch** with the ticket key, following the [branch convention](../../docs/development-environment/artefacts/conventional-branch.md) and the [Linking the ticket to its PR](../jira-design/SKILL.md) rules, for example `feature/proj-123-design-system-setup`. Name the version in the ticket, not in the branch, so branches stay one per ticket.
5. **Record it** in a comment on the ticket: `Target version v<next> (<impact>) from v<current>`.

The agent does not create tags, releases or `release/` branches: those are release tooling's job, which reads the `feat:` and `fix:` commits and the `BREAKING CHANGE:` footers, so the commits must carry the right type. The workflow installs [release-please](../../docs/development-environment/artefacts/release-please.yml) for this on GitHub, which opens and maintains a release PR from those commits, so the version the agent worked out should match the one it proposes. If the project has no release tooling, say the next version in the PR description and leave tagging to the user.

## Locked after implementation

The design system can be chosen or changed only until it has been implemented. After that, `/workflow-configure` and `/design-system` do not change it: switching a component stack once code is built on it is a migration, not a setting.

**Implemented** means the first PR for a ticket under the design system epic has been opened. When `jira-design` `link-pr` links such a PR, it runs `implemented`:

### `implemented`

1. Append an entry to `artefacts/practice-changes.md` in the shape above, with `Old` and `New` both holding the current choice, and `Status: implemented`, headed `Design system implemented`. Do not commit it.
2. Do nothing if an implemented entry already exists.

When the user asks to change a design system that is implemented:

- Say it is locked, name what was chosen and when, and that settings are not the place to change it.
- Offer the supported route: describe the change as a new requirement and run `jira-design` `breakdown` for a migration epic. Its stories carry the SemVer impact of what the migration changes for the project's consumers, which is major when it breaks them.
- Make no change to `practice-changes.md` and create no tickets until the user says to.
- If the user wants automated accessibility testing after the lock, treat it as a normal requirement: run `jira-design` `breakdown` for a story that adds it as described above.

## Final report

Close with the values and multi-tenant answer taken, whether accessibility was flagged (and so whether axe testing will be added, with the reminder that it catches only a limited portion of accessibility bugs), what was recommended and chosen, where it was recorded and that the file is tracked and uncommitted, whether the epic was created (with its key and stories) or declined, and anything skipped, such as a missing guide, an MCP that is not signed in or an unanswered question.
