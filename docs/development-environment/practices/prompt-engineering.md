# Prompt engineering

Curate, refine and save inputs (prompts) so the LLM produces reliable outputs without regression.

**Format**

- Role/persona (for example, senior SWE)
- Task
- Context and constraints (limits, edge cases, background info)
- Output format (JSON, table and so on)

**Shot-examples:** give the agent input/output examples.

| Pros                              | Cons                                                   |
| --------------------------------- | ------------------------------------------------------ |
| Reliable outputs, less regression | More tokens, higher latency, more maintenance overhead |

## Prompt suggestions in a project

When a user is prompting in their own project that follows this workflow, the agent reads this file and applies it to the user's prompt:

1. **Suggest a format.** If the prompt is missing parts of the format above (role, task, context and constraints, output format), the agent suggests a reformatted version of the user's prompt and asks which one to use. It does not rewrite the prompt silently.
2. **Suggest shot-examples.** If the task has a specific input/output shape, the agent suggests one or more shot-examples for the user to confirm or edit.
3. **Say it can be turned off.** The first time the agent makes a suggestion in a session, it also tells the user they can tell it to turn these suggestions off, for example "stop suggesting prompt formats" or "no shot-example suggestions".

If the user turns the suggestions off, the agent stops, for the format suggestions, the shot-example suggestions, or both, depending on what they asked to turn off. It keeps them off for the rest of the session, and does not suggest again unless the user asks for them back.

To keep the suggestions off in future sessions, or to turn them back on, use `/workflow-configure`. The agent reads `artefacts/harness-preferences.md` before it suggests anything.

Prompts that are already clear and complete, and short follow-ups in an ongoing task, need no suggestions.
