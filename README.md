# AI Forward Workflow

An agentic-assisted development methodology.

**Purpose:** leverage AI to accelerate delivery across the development lifecycle, while maintaining high standards of code quality, architecture, collaboration and security.

We do this through practices like governance, prompt/context engineering, harness configuration and verification loops.

We measure accellerated delivery through agent ROI.

This repo is the frame of reference for future software projects that follow this workflow.

![AI Forward Workflow](AI%20Forward%20Workflow.png)

## Getting started

You can use this workflow to start a new project, with an agent doing the work. Before you begin, install the `jira-design` [skill](skills/jira-design/SKILL.md) globally by symlinking `skills/jira-design` from this repo into `~/.claude/skills/`, and sign the Atlassian MCP server in.

1. Start a new repo for your project.
2. Create `artefacts/requirements.md` and write the goal of the project and its requirements in natural language.
3. Activate initialize mode by running `/jira-design initialize` in the new repo.

Initialize mode is for starting a new project that uses the workflow. It:

1. Looks for `artefacts/requirements.md`. If the file is missing, the agent tells you to create it first, and stops.
2. Asks for your harness preferences, all in one go, and explains each briefly, unless `artefacts/harness-preferences.md` already exists. It writes your answers to that file and adds it to `.gitignore`, so it is not committed: pass it to teammates yourselves. See [harness configuration](docs/development-environment/practices/harness-configuration.md) for the full explanations.
   - **Execution environment:** localhost (the default), Docker container or cloud workspace.
   - **Permissions:** whether the agent may use filesystem tools (grep, find), package managers, MCP servers, skills and shell access. You can allow some and not others.
   - **Default tools:** the agent tells you the defaults and asks if you want to add anything. Plugins (MCPs): CodeGraph, Playwright, Frontend Design by Anthropic. Connectors: Atlassian MCP, Claude in Chrome, Context7, GitHub integration. Skills: CodeGraph, Deep Research, Import Memory, Frontend Design.
   - **Verification loop:** a practice of its own, and the way the workflow keeps code quality high. Before the agent submits a PR for a ticket or bug it checks the work against the global company engineering standards and guidelines (`guidelines.md`), the existing CI tests and a set of guardrails. You can keep the defaults or modify them here, and the checks against `guidelines.md` always stay. See [verification loops](docs/development-environment/practices/verification-loops.md).
   - **Human sanity check and agent escalation:** on by default. Before the agent opens a PR it shows you what changed and prompts you to review and confirm, and when it cannot fix an issue it escalates to you instead of looping. The time you spend is tracked as human intervention fix time (HIFT) on the ticket, and the hardest cases are logged as failure branches for agents to learn from. You choose to leave it on or turn it off.
   - **Multi-step agent system:** on by default. The primary agent splits the work into independent sub-goals and runs several stateless Claude instances on them in parallel, each with its own context window (the Orchestrator-Subagent pattern), mainly while executing tickets. It is faster on independent work and keeps the primary context small, but costs more tokens and the instances share no context. You choose to leave it on or turn it off.
3. Runs [task breakdown](docs/development-environment/README.md) on the requirements, creating the epics, user stories and sub-tasks in Jira through the Atlassian MCP server.
4. Writes the project scope and domain knowledge into project memory.
5. Asks whether you want to install CodeGraph, and briefly explains its benefits: it indexes your code into a local graph, so the agent finds code with fewer tool calls and tokens. It installs only if you say yes. See [context engineering](docs/development-environment/practices/context-engineering.md) for the full explanation.

From there, humans estimate the sub-tasks and agents execute them as described in [Using this repo on a project](#using-this-repo-on-a-project).

## How the workflow is organised


| Area                    | What it covers                                                                                       | Doc                                                                                         |
| ----------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Practices               | Prompt engineering, context engineering, harness configuration, verification loops                   | [docs/development-environment/practices/](docs/development-environment/practices/README.md) |
| Development Environment | Artefacts, task breakdown, bugs, agent execution, memory conservation, human sanity check, agent ROI | [docs/development-environment/](docs/development-environment/README.md)                     |
| Governance              | Fortnightly review of agent ROI and the practices                                                    | [docs/governance.md](docs/governance.md)                                                    |




## Using this repo on a project

This repo is the source of truth. A project repo starts with a single file of user requirements in natural language (`artefacts/requirements.md`), and an agent follows the flow below against that project repo, reading the linked docs as it goes.

1. Read the [artefacts](docs/development-environment/README.md), including the commit, branch and PR conventions.
2. Break down the requirements into Jira epics, user stories and sub-tasks with the `jira-design` [skill](skills/jira-design/SKILL.md), following [Task breakdown](docs/development-environment/README.md).
3. Execute each task or bug ([Agent task/bug execution](docs/development-environment/README.md)) under the [practices](docs/development-environment/practices/README.md): new branch, conventional commits, verification loop, PR from the template, documentation, stored memory.
4. Escalate to a human where needed and track HIFT ([Human sanity check and agent escalation](docs/development-environment/practices/harness-configuration.md)).
5. After merge, evaluate agent ROI ([Evaluation of agent ROI](docs/development-environment/README.md)).
6. Feed the results into [governance](docs/governance.md) every 2 weeks.

We maintain high standards of:


| Standard      | Maintained through                                                                |
| ------------- | --------------------------------------------------------------------------------- |
| Code quality  | Governance, prompt/context engineering, verification loops, harness configuration |
| Collaboration | Governance                                                                        |
| Security      | Harness configuration                                                             |




## Pitfalls of AI


| Pitfall                                         | Cause                                                                      |
| ----------------------------------------------- | -------------------------------------------------------------------------- |
| Developers lack understanding of what was built | Thin documentation and no real grasp of implemented features               |
| Regression                                      | Harness not configured properly, or human intervention not thorough        |
| Architectural drift                             | Governance and harness not given enough care                               |
| Excessive code generation                       | Unnecessary abstractions, documentation and complexity for simple features |




## Repo layout

```
.
├── README.md
├── AI Forward Workflow.png
├── skills/
│   └── jira-design/
│       ├── SKILL.md
│       └── references/templates.md
├── docs/
│   ├── governance.md
│   └── development-environment/
│       ├── README.md
│       ├── practices/
│       │   ├── README.md
│       │   ├── prompt-engineering.md
│       │   ├── context-engineering.md
│       │   ├── harness-configuration.md
│       │   └── verification-loops.md
│       └── artefacts/
│           ├── conventional-commits.md
│           ├── conventional-branch.md
│           └── pr-template.md
```

