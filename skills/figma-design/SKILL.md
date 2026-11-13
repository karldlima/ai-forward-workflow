---
name: figma-design
description: Create a project's Figma design through the Figma MCP server, from either a reference website or the user's own brief (page descriptions, brand colours, any existing design material), built in layers (design tokens as variables, then base, shared and domain components, then pages made only from those components), using the Jira epics, stories and sub-tasks as the inventory of what to design. Then links each Figma token set, component and page to its Jira ticket, so an agent starting the ticket has a design reference to turn into code. Runs during initialize after the task breakdown, and again on demand. Use when the user is starting a project with the workflow and wants a Figma design, asks to design the site, tokens, components or pages in Figma, wants Figma designs linked to Jira tickets, or runs /figma-design; also called when an agent starts a ticket that has a Figma design reference.
---

# Figma design

Turns a reference website or a design brief into a layered Figma file, links it to the Jira tickets that will build it, and gives the agent that executes a ticket the design to work from. It uses the Figma MCP server for Figma and the Atlassian MCP server for Jira (see [Using the Atlassian MCP server](../jira-design/SKILL.md)).

The layers follow the order the code is built in, so a ticket's design maps straight onto its code:

| Layer | In Figma | In code and Jira |
| --- | --- | --- |
| 1. Design tokens | Variable collections, text and effect styles | The design system epic's design foundations story |
| 2. Components | Base, then shared, then domain components | `components/base`, `components/shared` and `components/domain` sub-tasks, as the [component tiers](../design-system/references/stack-guide.md) define them |
| 3. Pages | Frames at mobile, tablet and desktop, made only of component instances and variables | The page stories |

## When it runs

| Caller | What happens |
| --- | --- |
| `jira-design initialize` | Runs `design` once, after the task breakdown so the tickets exist to be used and linked. The user can skip it |
| `/figma-design` | The user asks directly: `design` again, to add or change designs, or `link` to re-link after tickets change |
| `jira-design start` | An agent starts a ticket that has a Figma design reference and runs `reference` |

## Using the Figma MCP server

Load the tools with `ToolSearch`, searching `figma`. The names that matter:

| Job | Tool |
| --- | --- |
| Account, plan and seat | `whoami` |
| New blank Design file | `create_new_file` |
| Create or change pages, variables, styles, components, variants and frames | `use_figma` |
| Read the file's structure | `get_metadata` |
| See a node | `get_screenshot` |
| Read variables and styles in use | `get_variable_defs` |
| Read a node as design context and code | `get_design_context` |
| Find existing components, variables and styles | `search_design_system` |
| Add images or SVGs | `upload_assets` |
| Capture a live web page as layers | `generate_figma_design` (select clients only), or `html_to_figma` |
| Map components to code | `get_code_connect_map`, `add_code_connect_map` |

If the server is not connected, tell the user how: `claude plugin install figma@claude-plugins-official` (the plugin includes Figma's own skills, such as `figma-use`, which help `use_figma` work reliably, and is the recommended route) or `claude mcp add --transport http figma https://mcp.figma.com/mcp`, then `/mcp`, then Authenticate, then restart the agent. Then skip Figma, make nothing, and say so in the report.

Things to know, and tell the user once before building:

- Writing to the canvas needs a Professional, Education, Organization or Enterprise plan and a Full seat to write outside drafts. Run `whoami`; if the account cannot write, stop and say what is missing.
- Writing to the canvas is free during Figma's beta and is expected to become a usage-based paid feature. It is beta quality, so the output may need manual cleanup. Never use `generate_image` or the Weave tools, which use AI credits.
- Each `use_figma` call returns at most 20 KB, so build in small steps. Fonts must be uploaded to the user's Figma account, since locally installed fonts are not available, and `use_figma` cannot add images, so use `upload_assets`.
- Components must be published in Figma before Code Connect mappings can be completed.

Work in a new draft file made with `create_new_file`, named after the project, unless the user gives an existing file URL to build in. Never edit a file the user has not pointed you to.

## Steps

### `design`

1. **Check what exists.** Read the committed `artefacts/practice-changes.md`. If it has a `Figma design` entry, a teammate already made the design: show the file link, say what was built, and stop unless the user asks to extend or change it (then add to the same file). Otherwise continue.
2. **Ask the choice, in one prompt**, and say each is optional and can be skipped:
   - **A. A reference website.** One or more URLs whose structure and look the design should follow. Say it is used as a reference for layout, structure and style direction: logos, copy and imagery are not copied, and the user's own brand colours override it if they give some.
   - **B. Your own brief.** A description of the site's pages, the brand colours (hex values), and optionally fonts, tone and any existing design material: a Figma link, screenshots or sketches. An existing Figma file is read as a reference, and a new layered file is made; it is not edited.
   - **C. Skip.** No Figma design now. Say they can run `/figma-design` later.
   If the user gives A and B, treat the brief's colours and pages as the rule and the website as the reference. If the requirements or the Jira stories already name the pages, list them and ask the user to confirm or correct them instead of asking for them again. If no brand colours are given, propose a palette from the project's tone, say it is a proposal, and mark it so in the file. Unanswered means skip.
3. **Build the inventory from Jira.** Read the epics, stories and sub-tasks for this project with `searchJiraIssuesUsingJql`, and the design system entry in `artefacts/practice-changes.md`. List, each with the key of the ticket that owns it:
   - **Token groups:** from the design system epic's design foundations and theming stories: colour, typography, spacing, radius, elevation, and a mode per tenant when the project is multi-tenant.
   - **Components by tier:** every sub-task that builds a component, with its tier (base, shared or domain) and name.
   - **Pages:** each story that is a screen or route, with its states (loading, error, empty).
   Where a ticket does not name a tier, apply the tier definitions from the guide. If there are no tickets (the breakdown was skipped or created none), build the inventory from the requirements and approach A or B, and mark the ticket column as none. Show the inventory and carry on; the user can correct it afterwards.
4. **Read the references.**
   - **A:** open each URL with the browser tools (Claude in Chrome, or Playwright). Take screenshots of the pages and read the computed styles for colours, fonts, type sizes, spacing, radii and shadows, and note the recurring components and page layouts. Prefer the extracted values to guesses.
   - **B:** take the brand colours and build the rest from them: for each colour a scale of about ten steps, neutrals, and the semantic colours for success, warning, error and info. Choose a type scale and a spacing scale. When the design system entry has `Accessibility priority: yes`, check text and control colour pairs for WCAG 2.2 AA contrast (4.5:1 for body text, 3:1 for large text and controls) and adjust the shade used, not the brand colour, until they pass.
5. **Build the layers in Figma, in order, and review each before starting the next.** Use `use_figma` in small steps. Look for an existing item by name first and update it, so a re-run adds no duplicates.
   1. **Design tokens.** Create the variable collections: `Primitives` (raw colour scales, spacing, radii, font sizes) and `Tokens` (semantic aliases such as `color/background/default`, `color/text/primary`, `color/action/primary`) pointing at the primitives. Add a mode per theme the project needs (light and dark if the requirements say so, one per tenant if multi-tenant). Name them with slashes so they map to the project's CSS variables or Tailwind theme, for example `color/primary/500` becomes `--color-primary-500`. Add text and effect styles. Put them on a `Tokens` page with a visible sheet of swatches and type samples.
   2. **Components, in tier order**, each on its own page (`Base`, `Shared`, `Domain`) named after the tier folder. Build a base component from variables only. Build a shared component from base instances. Build a domain component from base and shared instances, with bespoke parts only where needed. Dependencies point one way, as in the guide. Name every component exactly as its Jira sub-task does, in PascalCase, so Figma and code agree. Give each its variants and properties: size, state (default, hover, focus, disabled, error, loading), and an empty state where it applies.
   3. **Pages.** One Figma page per site page, with one frame per breakpoint at the workflow's viewports: mobile 375x812, tablet 768x1024 and desktop 1280x800 (the project's own breakpoints if it has them). Build them from component instances and variables only: no detached components and no hard-coded colours or sizes. Show each state the story names.
   After each layer, check with `get_metadata`, `get_screenshot` and `get_variable_defs`. List anything hard-coded or detached and fix it before moving on. Upload images with `upload_assets`, and use a placeholder where none is given.
6. **Link to Jira** as described under [`link`](#link).
7. **Record it.** Append an entry headed `Figma design` to the committed `artefacts/practice-changes.md`, creating the file with a `# Practice changes` heading if it is missing, in the same shape as the other entries: date, approach (reference website, brief, or both) and the site URLs if any, the Figma file link, and counts of token collections, components per tier and pages. Never write secrets or machine paths into it. Do not commit it. Add the file link to the project scope memory if `initialize` is writing one.
8. **Report** as under [Final report](#final-report).

### `link`

Link every inventory item to its ticket, so the design is in front of the agent that executes it. A node URL has the form `https://www.figma.com/design/<fileKey>/<fileName>?node-id=<id>`, with `:` in the node id written as `-`; take the ids from `get_metadata` or the `use_figma` results.

| Jira ticket | Links to |
| --- | --- |
| Epic | The Figma file, and the page that holds its work |
| Story | Each page frame, per breakpoint, and the components the page uses |
| Sub-task | Its component, or its token collection |

For each ticket:

1. **Edit its description:** fill the `Design reference` section from the [templates](../jira-design/references/templates.md) with the links, each with the node name, its layer (tokens, base, shared, domain or page) and, for a component, its folder, `components/<tier>/`. Replace the `None` the template starts with. A ticket written before the section existed has none: add the section above `Delivery`. Keep every other section as it is.
2. **Add a remote link** titled `Figma: <name>` through `createJiraIssueRemoteIssueLink`, so it shows in the ticket's links, unless one with the same URL is already there (`listJiraIssueRemoteIssueLinks`).
3. **Leave a ticket with no design alone** and list it in the report: a ticket that renders no UI, or an item the design did not cover.

### `reference`

Run by an agent that has started a ticket, before it plans, when the ticket has a `Design reference` section with Figma links. A ticket with none, or a Figma server that is not connected, is not a blocker: say so in a comment on the ticket, then work from the acceptance criteria.

1. **Read the design.** For each linked node call `get_design_context` for the structure and the generated code, `get_variable_defs` for the tokens, and `get_screenshot` for the picture. `get_code_connect_map` shows which components are already mapped to code.
2. **Translate it into the project, not around it.** Treat the generated code as a sketch to adapt to the project's stack and the design system choice, its conventions in `guidelines.md` and the existing components:
   - search `components/base`, `components/shared` and `components/domain` first and reuse what exists;
   - build a new component in the folder of the tier the Figma component belongs to, named as in Figma;
   - map each Figma variable to the project's token (CSS variable or theme entry); write a raw value only when no token exists, and say so;
   - match the layout at all three breakpoints.
3. **Check it against the design.** In the verification loop, take a screenshot of the built UI at the mobile, tablet and desktop viewports and compare it with `get_screenshot` of each page frame. Differences that are not intended are failures to fix.
4. **Handle gaps honestly.** If the design lacks a state or a breakpoint the ticket's acceptance criteria need, do not invent a design: build it to the criteria in the style of the tokens, and add a comment on the ticket naming the gap so a designer can fill it in.
5. **Offer Code Connect** once the component is merged and published in Figma, if the plan supports it: map the Figma component to the code component with `add_code_connect_map`, so the next `get_design_context` returns the project's real component instead of generated code. On a Professional plan only one framework can be active at a time.

## Final report

Close with the approach taken and the references used, the Figma file link, what was built per layer (token collections, components per tier, pages with their breakpoints), the tickets linked and any left unlinked and why, anything hard-coded or detached that remains, what was skipped (Figma not connected, a seat that cannot write, a skipped choice, fonts not uploaded, images left as placeholders), and the reminders that the output is beta quality and needs a human review in Figma, and that the `Figma design` entry in `artefacts/practice-changes.md` is tracked and uncommitted.
