# AI Forward Workflow

An agentic-assisted development methodology.

**Purpose:** leverage AI to accelerate delivery across the development lifecycle, while maintaining high standards of code quality, architecture, collaboration and security.

We do this through practices like governance, prompt/context engineering, harness configuration and verification loops.

We measure accellerated delivery through agent ROI.

This repo is the frame of reference for future software projects that follow this workflow.

![AI Forward Workflow](AI%20Forward%20Workflow.png)

## Getting started

You can use this workflow to start a new project, with an agent doing the work. Before you begin, install the `jira-design` [skill](skills/jira-design/SKILL.md), the `workflow-configure` [skill](skills/workflow-configure/SKILL.md) and the `design-system` [skill](skills/design-system/SKILL.md) and the `figma-design` [skill](skills/figma-design/SKILL.md) globally by symlinking `skills/jira-design`, `skills/workflow-configure`, `skills/design-system` and `skills/figma-design` from this repo into `~/.claude/skills/`, and sign the Atlassian MCP server in. To use the Figma design step, also connect the Figma MCP server (`claude plugin install figma@claude-plugins-official`, then `/mcp` to sign in); it is optional.

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
   - **Hooks:** the commit, PR, prompt and subagent-role [hooks](#hooks) are installed into your project and can be turned off, individually or all at once.
   - **Human sanity check and agent escalation:** on by default. Before the agent opens a PR it shows you what changed and prompts you to review and confirm, and when it cannot fix an issue it escalates to you instead of looping. The time you spend is tracked as human intervention fix time (HIFT) on the ticket, and the hardest cases are logged as failure branches for agents to learn from. You choose to leave it on or turn it off.
   - **Multi-step agent system:** on by default. The primary agent leads a team of Claude instances using Claude Code's [Agent Teams](https://code.claude.com/docs/en/agent-teams): it splits the work into independent sub-goals on a shared task list, and the teammates work on them in parallel, each with its own context window, messaging each other and the lead, mainly while executing tickets. It is faster on independent work and keeps the lead's context small, but costs significantly more tokens, and Agent Teams are experimental in Claude Code, so `initialize` turns them on in your project's `.claude/settings.json` only if you leave this on. Quick, focused jobs still use plain subagents or the agent alone. You choose to leave it on or turn it off.
3. Helps you choose the design system with the `design-system` [skill](skills/design-system/SKILL.md), unless a teammate has already chosen one. It asks what you value (flexibility, performance, accessibility, maintainability, scalability) and whether the project is multi-tenant, then recommends a methodology and a component library or approach (with components organised in three tiers, `components/base`, `components/shared` and `components/domain`), and offers to create the Jira epic and stories for it. If you flag accessibility as a priority (rank it among your top choices), automated [axe](docs/development-environment/practices/verification-loops.md) accessibility tests are added to the Playwright end-to-end tests that run in CI as part of the verification loop. They are only added then. axe catches only a limited portion of accessibility bugs, so it does not replace keyboard, screen reader and manual accessibility testing. The agent works out the semantic version of that work itself when it creates the branches. The decision is logged in `artefacts/practice-changes.md`, which is committed to the repo so your team sees it.
4. Runs [task breakdown](docs/development-environment/README.md) on the requirements, creating the epics, user stories and sub-tasks in Jira through the Atlassian MCP server, including the design system epic if you accepted it.
5. Offers to create a Figma design with the `figma-design` [skill](skills/figma-design/SKILL.md), once the tickets exist. You choose (A) a reference website, or (B) your own brief: the pages and your brand colours, plus any existing design material, or you skip it. It builds the file in Figma in layers through the Figma MCP server: design tokens first, then base, shared and domain components, then pages made only from those components, using your epics, stories and sub-tasks to decide what to design. It then links each token set, component and page to its Jira ticket, so when an agent executes the ticket it starts from the design and turns it into code. Writing to Figma is in beta (free for now, expected to become usage-based), needs an eligible plan and seat, and its output needs your review in Figma.
6. Writes the project scope and domain knowledge into project memory.
7. Asks whether you want to install CodeGraph, and briefly explains its benefits: it indexes your code into a local graph, so the agent finds code with fewer tool calls and tokens. It installs only if you say yes. See [context engineering](docs/development-environment/practices/context-engineering.md) for the full explanation.

You can change any of these settings later, at any time, by running `/workflow-configure` or just asking the agent. It updates your local `artefacts/harness-preferences.md` and logs the change in `artefacts/practice-changes.md`, which is committed to the repo so your team can see how the project's practices differ from the defaults and why. See [harness configuration](docs/development-environment/practices/harness-configuration.md).

The design system is the one exception: you can change it with `/workflow-configure` only until the first PR for its epic is opened. After that it is locked, because switching a component stack once code is built on it is a migration, which goes through a new epic instead.

From there, humans estimate the sub-tasks and agents execute them as described in [Using this repo on a project](#using-this-repo-on-a-project).

### Frontend system design (off)

The workflow also has a `fe-system-design` [skill](skills/fe-system-design/SKILL.md): the process of planning and engineering the client-side architecture of a web application, in five phases (requirements, architecture, data model, interfaces, optimizations). The design system is part of its architecture phase, so the `design-system` skill runs inside it.

It is switched **off** for now, until it is designed more thoughtfully. While it is off, the agent asks you only about the design system (step 3 above) and nothing about frontend system design, and you do not need to install it. To turn it on, set its status to On in [the skill](skills/fe-system-design/SKILL.md).

## Hooks

The workflow installs a set of Claude Code hooks in your project. Each one catches a moment and nudges the agent to offer help, so your commits, PRs and prompts follow the workflow's conventions. They only offer: nothing is rewritten without your say-so.

| Hook | When it runs | What it does |
| --- | --- | --- |
| Commit, before | Before a `git commit` whose message does not follow the [commit convention](docs/development-environment/artefacts/conventional-commits.md) | Pauses the commit once and offers to write the message for you, suggests using the commit conventions, or helps set some up. Run the same command again to commit it as written |
| Commit, after | After a `git commit` | Checks the message against the commit conventions and, if it does not follow them, tells you what is wrong and offers to fix it with `git commit --amend` |
| PR, before | Before a `gh pr create` whose description does not follow the [PR template](docs/development-environment/artefacts/pr-template.md) | Pauses the PR once and offers to write it for you, suggests using the PR conventions, or helps set a template up |
| PR, after | After a `gh pr create` | Checks the PR's title and description against the PR conventions and offers to fix them with `gh pr edit` |
| Secret scan, before and after | Before and after a `git commit`, unless the project has its own secret scanner | Blocks a commit whose changes look like they contain secrets (keys, tokens, passwords, `.env` and key files), names the file and the rule but never the value, and, if one slips into a commit made in a chained command, tells the agent not to push and to remove it. Also see [secret management](docs/development-environment/practices/verification-loops.md) |
| PR, review | After a `gh pr create`, the last step of the verification loop | Has the agent review the PR it just opened, with the `code-reviewer` subagent, and write you a quick summary: what changed, the findings that hold up and a verdict. It does not comment on the PR, push fixes or merge without your agreement |
| Prompt refinement | When you submit a prompt | Offers a refined prompt based on the [prompt engineering](docs/development-environment/practices/prompt-engineering.md) template |
| Team roles | When you submit a multi-part prompt, once per session | Offers to set up roles for the agent team related to your prompt, as part of the multi-agent orchestration. Accepted roles are saved locally on your machine as subagent definitions that Claude Code can also spawn as teammates. See [harness configuration](docs/development-environment/practices/harness-configuration.md) |

The hooks only see what runs inside Claude Code: a commit or PR the agent runs for you, or a prompt you submit here. A commit you make in a separate terminal does not trigger them.

**Turning them off.** Every hook tells you it can be turned off the first time it speaks. Tell the agent, for example "stop the commit hooks", or run `/workflow-configure`. It records `commit-hooks`, `pr-hooks`, `pr-review`, `secret-hook`, `prompt-refinement`, `subagent-roles` or `ci-hook` as off under Hooks in your local `artefacts/harness-preferences.md`, or `hooks: off` for all of them. `jira-design initialize` installs the hooks into your project's `.claude/` folder, and the script and `.claude/settings.json` can be committed so the team shares them. See [harness configuration](docs/development-environment/practices/harness-configuration.md).

## CI when you have none

The verification loop needs tests to run against. If your project has no CI of its own, the workflow supplies two safeguards, and both step aside as soon as you set up your own:

- **A GitHub Actions workflow.** `jira-design initialize` adds the default [`ci.yml`](docs/development-environment/artefacts/ci.yml) as `.github/workflows/ai-forward-workflow-ci.yml`, which runs your tests on every push and pull request, and your Playwright end-to-end tests too when the project has a Playwright config. If you flagged accessibility as a priority, the end-to-end tests include an axe accessibility scan. axe catches only a limited portion of accessibility bugs: it cannot tell whether labels are meaningful, whether the keyboard flow makes sense or how a screen reader reads the page, so a passing scan does not mean the page is accessible.
- **A stop hook in auto mode.** When you are in auto mode, the `stop-ci` [hook](#hooks) runs your tests after the agent commits, and sends the agent back to fix any failure (up to 5 attempts, then it escalates to you). This enforces the [verification loop](docs/development-environment/practices/verification-loops.md).

## Commits and releases

- **Commitizen.** Commits follow [Conventional Commits](docs/development-environment/artefacts/conventional-commits.md), and `jira-design initialize` sets up [Commitizen](https://commitizen-tools.github.io/commitizen/) in Node projects so `npm run commit` prompts you through a conforming message. The agent cannot answer the prompts, so it writes conforming messages itself, and the commit hooks check them.
- **release-please.** `jira-design initialize` adds [`release-please.yml`](docs/development-environment/artefacts/release-please.yml) as `.github/workflows/ai-forward-workflow-release-please.yml`. Each time a PR is merged into `main`, it reads the conventional commits since the last release and opens or updates a release PR with the next semantic version and the changelog. Merging that PR tags the release. It needs the repo setting "Allow GitHub Actions to create and approve pull requests" turned on.

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
│   ├── design-system/
│   │   ├── SKILL.md
│   │   └── references/stack-guide.md
│   ├── fe-system-design/
│   │   └── SKILL.md
│   ├── figma-design/
│   │   └── SKILL.md
│   ├── jira-design/
│   │   ├── SKILL.md
│   │   └── references/templates.md
│   └── workflow-configure/
│       └── SKILL.md
├── hooks/
│   ├── workflow-hook.sh
│   └── settings.json
├── .claude/
│   └── settings.json
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
│           ├── pr-template.md
│           ├── ci.yml
│           └── release-please.yml
```

