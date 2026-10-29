# Branch convention

Agents and humans name branches following [Conventional Branch](https://conventionalbranch.org/). It is used in [Agent task/bug execution](../README.md).

## Format

```
<type>/<description>
```

Trunk branches (`main`, `master`, `develop`) take no prefix.

## Prefixes

| Prefix | Use for | Example |
| --- | --- | --- |
| `feature/` (or `feat/`) | New features | `feature/add-login-page` |
| `bugfix/` (or `fix/`) | Bug fixes | `bugfix/fix-header-bug` |
| `hotfix/` | Urgent fixes | `hotfix/security-patch` |
| `release/` | Preparing a release | `release/v1.2.0` |
| `chore/` | Non-code tasks such as dependency or documentation updates | `chore/update-dependencies` |

The spec also defines AI-agent source prefixes (`ai/`, `claude/`, `codex/`, `copilot/`, `cursor/`), for example `claude/security-patch`.

## Rules

- Lowercase letters, digits and hyphens only. Dots are allowed, mainly for version numbers.
- No consecutive, leading or trailing hyphens or dots, and no hyphen next to a dot.
- No underscores, spaces or other special characters.
- Descriptive but concise.
- Include the ticket number when one applies, for example `feature/issue-123-new-login`.

## Valid and invalid

| Valid | Invalid | Why |
| --- | --- | --- |
| `feature/issue-123-new-login` | `Feature/Add-Login` | Uppercase |
| `bugfix/fix-header-bug` | `feature/new--login` | Consecutive hyphens |
| `chore/upgrade-node-v20.11` | `fix/header_bug` | Underscore |
| `release/v1.2.0` | `unknown/some-task` | Unrecognised prefix |
