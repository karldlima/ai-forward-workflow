# Context engineering

Curate and optimise the dynamic data the agent uses, without brute-force or full-history searches, to get reliable outputs while maximising information density per token.

**Done through**

- Indexing: repository map plus AST (a "code graph")
- Grep and `read_lines`
- Memory management: tracking multi-turn history, compacting, user preferences over time, CodeGraph

| Pros                                         | Cons                                  |
| -------------------------------------------- | ------------------------------------- |
| Reliable outputs, fewer tokens (better TTFT) | Regression through context compaction |

## CodeGraph

[CodeGraph](https://github.com/colbymchenry/codegraph) is the code graph the indexing practice above refers to. It parses the project's source with tree-sitter into a graph of symbols (functions, classes, methods) and the edges between them (calls, imports, inheritance), and stores it in a local SQLite database at `.codegraph/codegraph.db`. The agent queries it through an MCP server, so it gets the code it needs in one query instead of grepping and reading files one at a time.

**Benefits**

- Fewer tool calls and fewer tokens spent finding code, and so faster answers and lower cost. The project reports 88% fewer tool calls, 53% faster and 62% fewer tokens in its own benchmark across seven open-source repos. These are the vendor's figures on one question per repo, so treat them as indicative.
- Works across more than 20 languages, including TypeScript and Python.
- Stays current: a file watcher syncs the graph as files change.
- Local: the index stays on the machine, with no API keys or external services. It sends anonymous usage telemetry, with no code, paths or names, which can be turned off with `codegraph telemetry off`.

**Trade-off:** retrieved context stays in the session longer, so long sessions in small context windows need more budget. This is another reason to [compact](#remind-the-user-to-compact) when the topic switches.

**Install**

1. Install the CLI. macOS and Linux: `curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh`. Windows PowerShell: `irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex`.
2. Connect the agents on the machine: `codegraph install`.
3. In the project folder, build the index: `codegraph init`.
4. Restart the agent so the MCP server loads.

`/jira-design initialize` asks the user whether to install CodeGraph for the new project and explains these benefits briefly. On a yes, the agent runs all of the steps above itself, so the user does not run anything by hand. The one exception is when the installer leaves `codegraph` off the current shell's PATH and the agent cannot find it: the user then opens a new terminal and runs steps 2 and 3. The agent skips the offer if CodeGraph is already set up in the project, and does not ask again if the user declines.

## Context habits in a project

When a user is working in their own project that follows this workflow, the agent reads this file and does three things as the conversation goes on.

### Remind the user to compact

When the topic switches, for example from one ticket to another or from a feature to an unrelated question, the agent reminds the user they can run `/compact` to shrink the context and save tokens. It reminds on topic switches only, and at most once per switch, so it does not nag during a continuous task. Only the user can run `/compact`; the reminder is the action.

Before the user compacts, the agent saves anything the summary could lose: the decisions made and what is left to do, on the ticket's `Context summary` comment when the work is on a ticket, otherwise in project memory.

### Track multi-turn history

The agent keeps a short history of each multi-turn conversation:

- the decisions made and why
- what was done, and what is still open

**Ticket work is stored on the ticket.** Project memory is per user and per machine, so a teammate on the same ticket would not see it. Instead the agent keeps a single `Context summary` comment on the Jira ticket (`jira-design` `save-context` mode). Anyone on the team, and their agent, reads it when they start the ticket (`start` mode) and carries on with the same context. The agent updates the comment when the topic is done, when the topic switches, and before the user compacts.

The summary lives in Jira, not in a file committed to the repo, because the ticket is where the team already looks, the workflow already keeps the agent clock and escalations in ticket comments, and it adds no files to git. It stays useful when several people on the same Claude team plan work on one repo.

**Everything else is stored in project memory**: conversations that are not about a ticket, one entry per topic. Project memory is personal, so these entries are not shared.

Either way the agent stores summaries, not transcripts, so recalling history costs few tokens, and it never stores secrets, credentials or customer data. It reads the summary back when the user returns to a topic instead of searching the full history.

### Save user preferences over time

When the user states a preference or corrects the agent, for example "use named exports" or "don't add comments", the agent saves it to project memory as a user preference, with the reason if the user gave one. Before saving it checks whether a preference on the same thing already exists, and updates that one instead of adding a duplicate or contradicting it. It applies saved preferences at the start of later sessions without asking again.

Preferences saved this way are personal: they stay on that user's machine and are not shared with teammates. A preference the whole team should follow belongs in a committed artefact such as `guidelines.md`, and where a preference is already covered by an artefact, the agent follows the artefact and does not save a copy.
