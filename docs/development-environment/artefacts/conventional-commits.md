# Commit convention

Agents and humans write commits following [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/). It is used in [Agent task/bug execution](../README.md).

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
