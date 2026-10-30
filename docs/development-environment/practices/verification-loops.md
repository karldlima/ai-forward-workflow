# Verification loops

Before submitting a PR for a ticket or bug, the agent checks its work against the global company engineering standards (`guidelines.md`), the existing CI automated tests, and manually set guardrails:

- **Only touch files relevant to the ticket/bug.**
- **Human permission gates.** Ask for permission before running destructive commands, for example `rm -rf`.
- **Maximum iteration loops, to prevent runaway token spend.** The default is 5 check-and-fix cycles. If the checks still fail after the fifth, the agent stops looping and escalates to a human (see [Human sanity check and agent escalation](harness-configuration.md)).
- **Don't leak sensitive data**, such as environment variables, in code, commits, logs or the PR.
- **Check for regression**, both behavioural and visual.
- **CI tests pass.** See [CI](#ci) below.
- **Code review by the `code-reviewer` subagent.** See [Code review](#code-review) below.

## CI

The CI check needs a CI to run against. The user's own CI always wins: if the project has its own (a `.github/workflows` file other than the workflow's, a `.gitlab-ci.yml`, `.circleci/config.yml`, `Jenkinsfile`, `azure-pipelines.yml`, `.travis.yml` or `bitbucket-pipelines.yml`), the agent uses that and adds nothing. During task or bug execution, the first time the agent reaches the verification loop in a project, it asks the user whether the project has CI.

- **If it has CI,** the agent notes which workflow or command to run or watch, records it in `artefacts/harness-preferences.md`, and does not ask again.
- **If it does not,** the workflow supplies two safeguards, so there is always something to test against:
  - **A GitHub Actions workflow.** The agent adds the default [`ci.yml`](../artefacts/ci.yml) to the project as `.github/workflows/ai-forward-workflow-ci.yml` (a `ci.yml` in the project's own `artefacts/` folder overrides the default). It runs the project's tests on every push and pull request, for Node, Python, Go and Rust projects. It takes effect once the file is committed and pushed to GitHub.
  - **A stop hook in auto mode.** When the user is in auto mode and the agent has made a commit, the `stop-ci` [hook](harness-configuration.md) runs the project's tests locally when the agent is about to stop. If they fail, the agent is sent back to fix them and commit again, which enforces the verification loop. After 5 failed attempts it stops and escalates to a human. Outside auto mode the user is already in the loop, so it does nothing.

Both go away as soon as the user sets up their own CI: the workflow file is the only one the agent manages, and the stop hook checks for any other CI before it runs. The stop hook can be turned off with the `ci-hook` setting.

## Code review

During the loop the agent uses the `code-reviewer` subagent. It is a read-only agent that starts with a fresh context and reviews the changes for logic bugs and edge cases, security risks such as leaked secrets and injection points, performance, and formatting. It reports each issue with the lines affected and a suggested fix.

The agent runs it once the other checks pass. It treats the findings as a second opinion: it checks each one, fixes the ones that are right, and says why when it disagrees. Each round of fixes counts as one of the loop's iterations, so the review cannot loop forever either.

## Modifying the loop

Verification loops are their own practice, and the list above is the default. The user can modify the loop through the [harness configuration](harness-configuration.md) during `initialize`: the agent shows the defaults and asks whether to keep them or change them, for example to set the maximum number of iterations, add a human permission gate, or add a check. The answer is recorded in `artefacts/harness-preferences.md`, and the agent runs the loop as recorded from then on. It can be changed again at any time with `/workflow-configure`, and the change is logged in `artefacts/practice-changes.md`.

Whatever the user changes, the loop still checks the work against `guidelines.md` before the PR is submitted. If the project has no `guidelines.md`, the agent says so and checks against the other items.

| Pros                                 | Cons                        |
| ------------------------------------ | --------------------------- |
| Reduces HIFT, maintains code quality | More tokens, higher latency |
