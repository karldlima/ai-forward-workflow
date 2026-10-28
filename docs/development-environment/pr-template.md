# PR description template

The agent fills this in when it writes the PR for a ticket or bug in [Agent task/bug execution](README.md#agent-taskbug-execution). Reviewers tick the same boxes during the [human sanity check](README.md#human-sanity-check--agent-escalation).

Copy the block below into the PR description. In a project repo, save it as `.github/pull_request_template.md` so GitHub pre-fills it.

```markdown
## Ticket

<!-- Link to the Monday ticket/bug -->

## Description

<!-- What this PR achieves, in a few sentences -->

## Acceptance criteria

<!-- Copy each AC from the ticket -->
- [ ] AC 1
- [ ] AC 2

## Testing

- [ ] Existing CI tests pass
- [ ] New or updated tests cover the change (if applicable)
- [ ] No behavioural or visual regression
- [ ] Only files relevant to the ticket/bug were touched
- [ ] No sensitive data (env vars, secrets) committed
- [ ] Human-readable and agent-readable documentation updated
- [ ] Branch and commits follow the branch and commit conventions
```
