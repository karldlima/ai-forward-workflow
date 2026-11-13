# Verification loops

Before submitting a PR for a ticket or bug, the agent checks its work against the global company engineering standards (`guidelines.md`), the existing CI automated tests, and manually set guardrails:

- **Only touch files relevant to the ticket/bug.**
- **Human permission gates.** Ask for permission before running destructive commands, for example `rm -rf`.
- **Maximum iteration loops, to prevent runaway token spend.** The default is 5 check-and-fix cycles. If the checks still fail after the fifth, the agent stops looping and escalates to a human (see [Human sanity check and agent escalation](harness-configuration.md)).
- **Don't leak sensitive data**, such as environment variables, in code, commits, logs or the PR. See [Secret management](#secret-management) below.
- **Check for regression**, both behavioural and visual. When the ticket has a Figma design reference, the visual check compares the built UI with the Figma frames at the mobile, tablet and desktop viewports.
- **CI tests pass.** See [CI](#ci) below.
- **Automated accessibility check with axe, only when the user flagged accessibility as a priority.** See [Accessibility testing](#accessibility-testing) below.
- **Code review by the `code-reviewer` subagent.** See [Code review](#code-review) below.

## Secret management

Secrets are API keys, tokens, passwords, private keys and `.env` files. The user's own mechanism always wins: if the project already has a secret scanner (`.gitleaks.toml`, `.secrets.baseline`, `.trufflehog.yml`, `.talismanrc`, or gitleaks, detect-secrets, trufflehog, git-secrets or talisman in `.pre-commit-config.yaml`, `.husky` or a workflow), the workflow adds no scan of its own. If it has a secret store (Doppler, Vault, AWS Secrets Manager, 1Password, SOPS and the like), the agent gets values from it and never copies them into the code.

If the project has no scanner, the workflow supplies three safeguards:

- **Ignored files.** `initialize` makes sure `.gitignore` covers `.env`, `.env.*` (except `.env.example`), `*.pem` and `*.key`.
- **A secret-scan hook.** The `secret-hook` [hook](harness-configuration.md) scans what a `git commit` is about to commit, and the commit just made, for secret files and for added lines that look like secrets: private keys, AWS, GitHub, Slack, Google and Stripe keys, `sk-` API keys and hardcoded `password`, `secret`, `token` or `api_key` assignments. It blocks the commit and names the file and the rule, never the value. Placeholders and environment lookups (`process.env.X`, `${X}`) do not count. A commit chained with `git add` in one command cannot be checked before it runs, so the check after the commit catches it and tells the agent not to push. It is a pattern check, not a full scanner, and it only sees commits the agent makes: for stronger coverage, add a scanner such as gitleaks to CI, and the hook steps aside.
- **Agent rules.** The agent reads secrets from environment variables or the secret store, never hardcodes them, lists only the variable names in `.env.example`, does not open `.env` files unless the task needs it, and never prints a value in a reply, commit, log, PR, Jira ticket or memory. If a secret has reached a commit, the agent stops, tells the user and says it must be rotated if it was ever pushed or shared, because removing it from the code does not make it safe again. Rewriting history is the user's call.

If the hook flags something that is not a secret, the agent tells the user and lets them decide. It never turns the hook off itself.

## CI

The CI check needs a CI to run against. The user's own CI always wins: if the project has its own (a `.github/workflows` file other than the two the workflow installs, a `.gitlab-ci.yml`, `.circleci/config.yml`, `Jenkinsfile`, `azure-pipelines.yml`, `.travis.yml` or `bitbucket-pipelines.yml`), the agent uses that and adds nothing. During task or bug execution, the first time the agent reaches the verification loop in a project, it asks the user whether the project has CI.

- **If it has CI,** the agent notes which workflow or command to run or watch, records it in `artefacts/harness-preferences.md`, and does not ask again.
- **If it does not,** the workflow supplies two safeguards, so there is always something to test against:
  - **A GitHub Actions workflow.** The agent adds the default [`ci.yml`](../artefacts/ci.yml) to the project as `.github/workflows/ai-forward-workflow-ci.yml` (a `ci.yml` in the project's own `artefacts/` folder overrides the default). It runs the project's tests on every push and pull request, for Node, Python, Go and Rust projects, and, in a Node project with a Playwright config (`playwright.config.*`), the Playwright end-to-end tests too, where the [axe accessibility scan](#accessibility-testing) runs if it was set up. It takes effect once the file is committed and pushed to GitHub.
  - **A stop hook in auto mode.** When the user is in auto mode and the agent has made a commit, the `stop-ci` [hook](harness-configuration.md) runs the project's tests locally when the agent is about to stop. If they fail, the agent is sent back to fix them and commit again, which enforces the verification loop. After 5 failed attempts it stops and escalates to a human. Outside auto mode the user is already in the loop, so it does nothing.

Both go away as soon as the user sets up their own CI: the CI workflow file is the only CI the agent manages (the [release workflow](../README.md) is not CI and stays), and the stop hook checks for any other CI before it runs. The stop hook can be turned off with the `ci-hook` setting.

## Accessibility testing

Automated accessibility testing with [axe](https://github.com/dequelabs/axe-core) is **only implemented when the user flagged accessibility as a priority** in the `design-system` [skill's](../../../skills/design-system/SKILL.md) questions during `initialize`. The skill records the answer as `Accessibility priority: yes` or `no` in the design system entry of the committed `artefacts/practice-changes.md`, and the agent reads it from there. If it is `no`, or there is no entry, no axe scan is added and none is expected.

When it is `yes`, axe runs as part of the Playwright end-to-end tests, so it runs in the CI step of this loop on every push and pull request:

- The project adds the `@axe-core/playwright` dev dependency and one shared helper, so every Playwright test scans the same way:

```ts
import AxeBuilder from "@axe-core/playwright";
import { expect, type Page } from "@playwright/test";

export async function expectNoAxeViolations(page: Page) {
  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"])
    .analyze();
  expect(results.violations).toEqual([]);
}
```

- Each Playwright test that renders a page or a component calls the helper once the page has reached the state under test, and the tests run at the mobile, tablet and desktop viewports like the rest of the suite. A violation fails the test, so CI fails and the loop sends the agent back to fix it.
- The set-up is a story in the design system epic. If the user declined the epic, or the set-up has not been built yet, the agent skips the axe check, says so in the PR and does not install it unprompted.

**axe catches only a limited portion of accessibility bugs.** It checks the rules a machine can decide: missing alt attributes and labels, invalid ARIA, low colour contrast, duplicate ids and the like. It cannot judge whether alt text or a label is meaningful, whether the keyboard order and focus handling make sense, whether a screen reader announces a flow sensibly, or whether content is understandable. A passing scan therefore does not mean the page is accessible. It is a safety net, not a replacement for keyboard and screen reader testing and, for a project that must comply with a standard, an accessibility audit. The acceptance criteria for accessibility on each ticket still need checking by a person during review.

## Code review

During the loop the agent uses the `code-reviewer` subagent. It is a read-only agent that starts with a fresh context and reviews the changes for logic bugs and edge cases, security risks such as leaked secrets and injection points, performance, and formatting. It reports each issue with the lines affected and a suggested fix.

The agent runs it once the other checks pass. It treats the findings as a second opinion: it checks each one, fixes the ones that are right, and says why when it disagrees. Each round of fixes counts as one of the loop's iterations, so the review cannot loop forever either.

When the agent opens the PR, the `pr-review` [hook](harness-configuration.md) fires after `gh pr create` and has the agent review the PR once more: it reads the PR's diff, runs the `code-reviewer` subagent over it, and writes the user a quick summary of what changed, the findings that hold up and a verdict. The agent does not comment on the PR, push fixes or merge from that review without the user's agreement.

## Modifying the loop

Verification loops are their own practice, and the list above is the default. The user can modify the loop through the [harness configuration](harness-configuration.md) during `initialize`: the agent shows the defaults and asks whether to keep them or change them, for example to set the maximum number of iterations, add a human permission gate, or add a check. The answer is recorded in `artefacts/harness-preferences.md`, and the agent runs the loop as recorded from then on. It can be changed again at any time with `/workflow-configure`, and the change is logged in `artefacts/practice-changes.md`.

Whatever the user changes, the loop still checks the work against `guidelines.md` before the PR is submitted. If the project has no `guidelines.md`, the agent says so and checks against the other items.

| Pros                                 | Cons                        |
| ------------------------------------ | --------------------------- |
| Reduces HIFT, maintains code quality | More tokens, higher latency |
