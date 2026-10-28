# AI Forward Workflow

An agentic-assisted development methodology.

**Purpose:** leverage AI to accelerate delivery across the development lifecycle, while maintaining high standards of code quality, architecture, collaboration and security.

We do this through practices like governance, prompt/context engineering, harness configuration and verification loops.

This repo is the frame of reference for future software projects that follow this workflow.

![AI Forward Workflow](AI%20Forward%20Workflow.png)

## How the workflow is organised

| Area | What it covers | Doc |
| --- | --- | --- |
| Practices | Prompt engineering, context engineering, harness configuration, verification loops | [docs/practices.md](docs/practices.md) |
| Development Environment | Artefacts, task breakdown, bugs, agent execution, memory conservation, human sanity check, agent ROI | [docs/development-environment/](docs/development-environment/README.md) |
| Governance | Fortnightly review of agent ROI and the practices | [docs/governance.md](docs/governance.md) |

## Using this repo on a project

This repo is the source of truth. A project repo starts with a single file of user requirements in natural language, and an agent follows the flow below against that project repo, reading the linked docs as it goes.

1. Read the [artefacts](docs/development-environment/README.md#artefacts), including the commit, branch and PR conventions.
2. [Break down](docs/development-environment/README.md#task-breakdown) the requirements into Jira epics, user stories and sub-tasks with the [`jira-design` skill](skills/jira-design/SKILL.md).
3. [Execute](docs/development-environment/README.md#agent-taskbug-execution) each task or bug under the [practices](docs/practices.md): new branch, conventional commits, verification loop, PR from the template, documentation, stored memory.
4. Escalate to a human where needed and track [HIFT](docs/development-environment/README.md#human-sanity-check--agent-escalation).
5. After merge, [evaluate agent ROI](docs/development-environment/README.md#evaluation-of-agent-roi).
6. Feed the results into [governance](docs/governance.md) every 2 weeks.

## Measure & maintain

We measure accelerated delivery through **Agent ROI**:

```
Agent ROI = benchmarked human time estimated - (agent time taken + HIFT)
```

HIFT is human intervention fix time, which includes the human's review time. See [Agent ROI](docs/development-environment/README.md#evaluation-of-agent-roi).

We maintain high standards of:

| Standard | Maintained through |
| --- | --- |
| Code quality | Governance, prompt/context engineering, verification loops, harness configuration |
| Collaboration | Governance |
| Security | Harness configuration |

## Pitfalls of AI

| Pitfall | Cause |
| --- | --- |
| Developers lack understanding of what was built | Thin documentation and no real grasp of implemented features |
| Regression | Harness not configured properly, or human intervention not thorough |
| Architectural drift | Governance and harness not given enough care |
| Excessive code generation | Unnecessary abstractions, documentation and complexity for simple features |

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
│   ├── practices.md
│   ├── governance.md
│   └── development-environment/
│       ├── README.md
│       ├── conventional-commits.md
│       ├── conventional-branch.md
│       └── pr-template.md
```
