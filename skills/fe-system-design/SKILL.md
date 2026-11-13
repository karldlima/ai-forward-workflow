---
name: fe-system-design
description: Plan and design a project's frontend system in phases (requirements, architecture, data model, interfaces, optimizations), with the design system skill running inside the architecture phase. Currently switched OFF in the workflow: while off, only the design-system skill runs, and nothing here is asked of the user. Do not use this skill until its status is set to on.
---

# Frontend system design

The process of planning and engineering the client-side architecture of a web application to promote performance, reliability, maintainability and scalability.

## Status

**Off.** The workflow does not run this skill yet, because how it should work is still to be designed. While it is off:

- `jira-design initialize` and `/workflow-configure` ignore it and run only the [`design-system`](../design-system/SKILL.md) skill, exactly as before.
- The user is asked nothing about frontend system design, only about the design system.
- Nothing in this file is read, followed or recorded.

To turn it on, change the status above to **On**. `jira-design initialize` step 5 then runs this skill's `design` in place of `design-system` on its own, and the design system is chosen inside the architecture phase below.

## Phases

Go through the phases in order.

### 1. Requirements

Ask:

- What is the purpose of this application? Banking, ticketing, retail, automation editor, membership journey?
- What are the user scenarios?
- What are the functional and non-functional needs: performance, accessibility, scale, offline support?

### 2. Architecture

Map out the high-level system components:

- the app shell and routing;
- the client-side layers: view layer, store, data transformation layer and data access layer;
- a rough idea of the middleware and database.

This is also the time to map out the design system. Run the [`design-system`](../design-system/SKILL.md) skill's `choose` here, with the answers from the requirements phase as context. It keeps its own rules: it records the decision in `artefacts/practice-changes.md`, offers the Jira epic, and is locked once the stack has been implemented.

### 3. Data model

Define the DTO and entity model that the frontend ingests, and the data normalization process.

### 4. Interfaces

Specify the API contracts, WebSockets and UI states: loading, error and empty.

### 5. Optimizations

Find performance bottlenecks, and look at bundle size, client-side caching, lazy loading, edge cases and security.

## Not yet decided

When this skill is turned on, still to be designed: how each phase is asked and recorded, which artefact holds the outcome, how it feeds the Jira breakdown, and how it is changed later through `/workflow-configure`.
