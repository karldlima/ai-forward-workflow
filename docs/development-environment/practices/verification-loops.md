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

The CI check needs a CI to run against. During task or bug execution, the first time the agent reaches the verification loop in a project, it asks the user whether the project has CI.

- **If it has CI,** the agent notes which workflow or command to run or watch, records it in `artefacts/harness-preferences.md`, and does not ask again.
- **If it does not,** the agent asks the user to add CI now, before the PR. Until there is CI the agent has nothing to test against, so it says in the PR and on the ticket that the CI check was skipped. If the user declines, it records that too and does not ask again.

## Code review

During the loop the agent uses the `code-reviewer` subagent. It is a read-only agent that starts with a fresh context and reviews the changes for logic bugs and edge cases, security risks such as leaked secrets and injection points, performance, and formatting. It reports each issue with the lines affected and a suggested fix.

The agent runs it once the other checks pass. It treats the findings as a second opinion: it checks each one, fixes the ones that are right, and says why when it disagrees. Each round of fixes counts as one of the loop's iterations, so the review cannot loop forever either.

| Pros                                 | Cons                        |
| ------------------------------------ | --------------------------- |
| Reduces HIFT, maintains code quality | More tokens, higher latency |
