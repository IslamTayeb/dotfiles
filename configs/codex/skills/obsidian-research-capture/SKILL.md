---
name: obsidian-research-capture
description: Research and capture Islam's underspecified Obsidian vault ideas. Use when Codex needs to investigate a rough idea, link, post, screenshot, or project-space question; ask targeted clarifying questions when the idea is underdefined; create or update a concise projects/slug.md findings/planning note; and add a linked checkbox entry in world-breaking-ideas.md.
---

# Obsidian Research Capture

Use this skill when managing Islam's Obsidian vault from Codex. The default vault root is `/Users/islamtayeb/Documents/Obsidian Vault`.

## Global Rules

- Preserve the vault's Markdown-first style.
- Prefer small append-only edits for capture workflows.
- Do not over-polish rough ideas into formal prose unless asked.
- Keep Islam's direct, bullet-heavy, informal style.
- Default to the shortest useful note. Prefer compact bullets, sharp claims, and one concrete next step over broad explanatory prose.
- Treat underspecified research ideas as the default case, not an exception. First identify what is missing, then ask the smallest useful set of questions before writing.
- Interview more often when the core claim, desired depth, target audience, project direction, or existing-note destination is unclear. Ask 1-3 short questions; proceed once the answer is enough.
- Run an anti-slop pass before writing or finalizing notes: cut filler, generic motivation, balanced section padding, fake-depth transitions, and words no one would naturally use here.
- Use Obsidian links like `[[projects/batch-agent-sdk-research]]` when there is a clearly relevant existing note.
- Do not create new top-level directories unless explicitly asked.
- Do not write inside `.obsidian/plugins/vault-publisher/mirrors/`; those are generated mirrors.
- Do not use `research/` as the default destination for new research docs. New research docs go in `projects/`.
- If not already working from the vault root, use absolute paths under `/Users/islamtayeb/Documents/Obsidian Vault`.

## Anti-Slop Pass

- Kill these words unless they are truly the exact term needed: `delve`, `utilize`, `leverage`, `facilitate`, `elucidate`, `embark`, `endeavor`, `encompass`, `multifaceted`, `tapestry`, `testament`, `paradigm`, `synergy`, `holistic`, `catalyze`, `juxtapose`, filler `nuanced`, metaphorical `realm`, metaphorical `landscape`, `myriad`, `plethora`.
- Be suspicious of clustered words like `robust`, `comprehensive`, `seamless`, `cutting-edge`, `innovative`, `streamline`, `empower`, `enhance`, `elevate`, `optimize`, `scalable`, `pivotal`, `profound`, `underscore`, `harness`, `navigate`, `cornerstone`, and `game-changer`. Replace with plainer words or be specific.
- Delete filler openers and transitions: `It's worth noting`, `Importantly`, `Notably`, `Interestingly`, `Let's dive`, `Let's explore`, `In conclusion`, `To summarize`, `Furthermore`, `Moreover`, `Additionally`, `At the end of the day`, `When it comes to`, and `In the realm of`.
- Avoid the `not just X, but Y` construction. Say the actual claim.
- Avoid symmetrical section padding. Real notes can be lumpy: one section can be five bullets and another can be one sentence.
- Avoid list abuse. Use bullets for scannable claims, not to create the appearance of depth.
- State what is known. If uncertain, say why; do not hedge with `may potentially`, `could possibly`, or generic `it depends`.
- Start with the useful claim. End with the actual next step, not a generic call to action.

## Request Mapping

- For "research", links/posts/screenshots to investigate, vague project-space questions, side-project ideas, or "capture this but think it through" requests, use the Project Research Docs workflow.
- For "idea:", "capture this idea", or a short rough idea, still create both a `projects/<slug>.md` note and a linked `world-breaking-ideas.md` entry unless the user explicitly asks for a lighter capture.
- For mixed or ambiguous Obsidian capture requests, treat the work as research/planning by default. Ask targeted questions if ambiguity affects the claim, scope, destination, or next action.
- Todo handling is not the purpose of this skill. Only add a task to `tasks/W*.md` when the user explicitly asks for a todo/task item rather than an idea or research note.

## Project Idea Capture

General ideas are indexed in `world-breaking-ideas.md` and get a matching findings/planning note in `projects/`.

Use this workflow for short or rough capture requests that are not todos. Create or update both:

- a `projects/<slug>.md` note
- a matching unchecked entry in `world-breaking-ideas.md` that links to the note with `[[projects/<slug>]]`

Do not create a project note only when the user explicitly asks to edit a specific non-project file or says not to create a project note.

Format:

```md
- [ ] Concise idea title
	- Context, motivation, examples, or next steps
	- [[projects/example]] - short reason this might matter
```

Rules:

- Add new ideas as unchecked checkbox bullets and include the project note link.
- Keep the top-level idea title concise.
- Use tab-indented child bullets for details.
- Preserve blank lines between top-level ideas.
- If the idea clearly expands an existing item, append child bullets to that item instead of creating a duplicate.
- If the matching entry lacks a project link, add one.
- Search existing `projects/*.md` notes for context, naming, and filename collisions.
- Use a concise slug based on the idea title.
- For thin ideas, interview before creating the project note unless the user explicitly asks to just save it. Ask about the missing core claim, intended use, and what would make the idea worth pursuing.
- If saving immediately, create a light `projects/<slug>.md` scaffold that preserves the supplied wording, marks unknowns as questions, and does not invent citations, claims, or details.
- Do not over-polish rough ideas into formal prose. Make the note useful as a research/planning artifact.
- Keep lightweight project notes to roughly 5-12 bullets total. Cut generic motivation and filler.

Default lightweight project note shape:

```md
---
title: "Readable Title"
slug: readable-title
date: "YYYY-MM-DDTHH:MMZ"
updated: "YYYY-MM-DDTHH:MMZ"
description: "Short summary of the rough idea."
host: apm-overflow
---

## Core idea

- ...

## Why it might matter

- ...

## Next steps

- ...
```

## Project Research Docs

Research docs, project specs, and long-form idea expansions live in `projects/`.

Use `projects/<slug>.md` for:

- research overviews
- project specs
- idea expansions
- literature-backed directions
- publishable APM Overflow drafts

For standalone research-style requests, create a new `projects/<slug>.md` note by default and also add or update a matching unchecked entry in `world-breaking-ideas.md`.

Treat research requests as "underspecified idea or post cluster -> concise project-space map" unless the user asks for a narrower output. The goal is not just to summarize the prompt; it is to research the space around it, plan possible directions, and answer:

- what the core idea/claim is
- what the current SOTA or frontier looks like
- whether the idea matters and why
- what adjacent projects, products, papers, or technical approaches already exist
- what options, build paths, experiments, or project directions are available
- what the main objections, constraints, and failure modes are
- what questions remain for Islam before committing more time
- what a concrete next step could be

This is a checklist, not a required essay structure. Answer only the parts that make the note useful.

When creating or updating a research/project note, the matching `world-breaking-ideas.md` entry must hyperlink to the research file. Add a tab-indented child bullet containing an Obsidian link to the project note, for example:

```md
- [ ] Concise research idea title
	- [[projects/concise-slug]] - short reason this might matter
```

If the entry already exists but lacks the hyperlink, add the link. If the entry already links to the same project note, update or append the surrounding child bullets instead of duplicating the link.

When creating a substantial new project research doc, use frontmatter like the existing project notes:

```md
---
title: "Readable Title"
slug: readable-title
date: "YYYY-MM-DDTHH:MMZ"
updated: "YYYY-MM-DDTHH:MMZ"
description: "Short summary of what this note is about."
host: apm-overflow
---
```

Rules:

- Default new research docs to `projects/`, not `research/`.
- Always add or update `world-breaking-ideas.md` when creating or updating a research project doc.
- Always include a direct Obsidian hyperlink from the matching `world-breaking-ideas.md` entry to the research note, using `[[projects/<slug>]]`.
- Always make the project note the detailed artifact. The `world-breaking-ideas.md` entry is only the short index, context, and link.
- If a matching idea already exists, append or update child bullets instead of creating a duplicate.
- Use `research/` only for existing legacy/context notes or when the user explicitly names that path.
- Search existing `projects/*.md` notes for context, naming, and filename collisions.
- Do not update an existing project note just because it is relevant.
- Only update an existing project note when the user explicitly names that path/note, or when it is already the working research note from the same session.
- If the prompt is only a title, thin idea, broad interest, or missing the core shape, interview the user before editing unless they explicitly ask for a rough scaffold, deep research, or "just save."
- Ask 1-3 short questions when needed, then stop as soon as the note is good enough.
- Only ask about missing essentials: core claim/idea, desired depth, desired output shape, audience, destination/existing-project match, project constraints, or next action.
- Do not save the interview transcript by default; distill answers into rough bullets in the project note.
- If the prompt is still thin after the interview, create a light scaffold with `## Working thesis`, `## What to research`, `## Possible directions`, `## Open questions`, and `## Next steps`; do not invent citations, claims, or details.
- If the prompt includes concrete bullets, preserve them and organize lightly under useful headings.
- Keep speculative language when the source idea is speculative.
- Use citations and links only when supplied by the user or found through an explicit research request.
- Default research notes should be compact: roughly 500-900 words plus sources unless the user asks for depth, asks to keep researching, or the source set truly requires more.
- Prefer 3-5 sections for ordinary notes. Add more sections only when the subject needs them.

## Research Behavior

- Start by distilling the supplied idea, link, post, or screenshot into a short working thesis. Preserve the user's rough framing, but separate sourced facts from speculation.
- For underspecified ideas, explicitly write down what is missing before asking questions or researching. Use the missing pieces to focus the interview and the note.
- Before web research or subagents, decide whether the prompt is specific enough. For vague "I'm interested in X" requests, ask what angle or output they want unless they explicitly request broad research.
- Treat research requests as web-enabled unless the user says `no web`, `rough scaffold`, `just save`, or similar.
- Use web research when useful to identify primary sources, definitions, SOTA/frontier work, adjacent projects, competing approaches, implementation constraints, use cases, and counterarguments.
- Prefer primary sources when available.
- For substantive research requests, use available subagent or parallel research tools when they are present and useful; split by direction such as primary sources/SOTA, prior art/products, implementation landscape, use cases/why it matters, and objections.
- After the first synthesis, do follow-up research only if important gaps remain.
- Stop when the note is useful enough for a next step; do not chase exhaustive completeness by default.
- For side-project ideas, keep the note practical and compressed: what the space is, why it might matter, SOTA/prior art, risks, possible builds, open questions for Islam, and sources.

Compact default headings for a research note:

- `## Core idea`
- `## Why it might matter`
- `## Possible directions`
- `## Risks / objections`
- `## Next steps`
- `## Sources`

Add headings like `## SOTA / frontier` or `## Existing approaches / prior art` only when the research depth warrants them. Use fewer headings for small notes and rename headings when the subject calls for it.

## Image And Screenshot Inputs

- If the prompt includes an attached image or a placeholder like `[Image 1]`, use the visible text/context in the image as source material.
- For social screenshots with multiple posts, default to the last/newest commentary post and its technical crux unless the user points elsewhere.
- If a screenshot implies a vague interest like "the form factor thing", infer the underlying research topic from the salient technical terms and claims rather than just summarizing the screenshot.
- Before using subagents, extract a short screenshot brief with the visible text, target claim, inferred research topic, and uncertainty. Pass that brief to subagents, not `[Image 1]`.
- Verify factual claims from screenshots with web or primary sources before presenting them as facts.

## Response Style

After making a vault edit, respond with:

- the path changed
- the section or note touched
- a one-line summary of the edit

Do not include a long explanation unless the user asks.
