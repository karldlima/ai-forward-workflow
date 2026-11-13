# Commit convention

Agents and humans write commits following [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/), and [Commitizen](https://commitizen-tools.github.io/commitizen/) helps write them. It is used in [Agent task/bug execution](../README.md). The commit types also drive [release-please](release-please.yml), which reads them to work out the next version and write the changelog.

## Structure

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

| Type | Use for |
| --- | --- |
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or correcting tests |
| `chore` | Tooling, dependencies, housekeeping |

`feat` and `fix` are defined by the spec. The others are allowed by it and are the common set; use more only when needed.

## Rules

- Type, optional scope in parentheses, optional `!`, then a colon and a space.
- The scope is a noun naming a part of the codebase, such as `feat(api)`.
- The description is a short summary after the colon and space.
- A body comes after one blank line and is free-form.
- Footers come after one blank line, as `token: value`. Tokens use hyphens instead of spaces, except `BREAKING CHANGE`.
- Mark breaking changes with `!` before the colon, a `BREAKING CHANGE:` footer (uppercase), or both.

## Commitizen

Commitizen is a command line tool that prompts for the type, scope, description, body, breaking change and issue references, and builds the message from the answers, so a commit follows the convention without anyone remembering it. It makes writing the message easier; it does not stop a non-conforming one, which the commit [hooks](../../../README.md) still check.

- **Setup.** `jira-design initialize` sets it up in Node projects: the `commitizen` and `cz-conventional-changelog` dev dependencies, `"config": { "commitizen": { "path": "cz-conventional-changelog" } }` in `package.json`, and a `"commit": "cz"` script. A project that is not a Node project is told so and keeps the convention without the tool.
- **Humans** run `npm run commit` (or `npx cz`) instead of `git commit`, and answer the prompts. At the issue references prompt, type `Refs: <ISSUE-KEY>`, so the footer the workflow expects is written.
- **Agents** cannot answer interactive prompts, so they write the message directly to this convention, with the same types and the `Refs:` footer, and run `git commit -m`. The commit hooks check it.

## Examples

```
docs: correct spelling of CHANGELOG
```

```
feat(lang): add Polish language
```

```
feat!: drop support for Node 6

BREAKING CHANGE: use JavaScript features not available in Node 6.
```

```
fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Refs: #123
```
