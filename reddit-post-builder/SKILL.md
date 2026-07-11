---
name: reddit-post-builder
description: Turn real work the user has actually done into a Reddit post for technical, developer-centric, or AI-related subreddits. Use whenever the user says "write me a Reddit post", "help me post on Reddit", "turn this into a Reddit post", "share this on Reddit", or anything similar — and also proactively suggest this skill when the user just finished something post-worthy (a benchmark, a workflow they figured out, a bug/incident diagnosis, a tool/framework comparison, a meaningful failure). The skill REFUSES to generate posts from nothing — it requires real work, real numbers, real experience as the input. Karma-farming generic listicles are explicitly out of scope.
---

# Reddit Post Builder for Technical Subs

A skill for turning **real work the user has actually done** into a Reddit post that fits the conventions of developer, technical, or AI subreddits.

The most important rule: **this skill does not invent experience.** If the user hasn't done something post-worthy, the skill says so and helps them figure out what to do instead — or talks them out of posting. The audience in developer subs is sharp and downvotes manufactured content fast.

## Hard refusals

Refuse outright (don't try to soften or work around) if the user asks for:

- A "viral Reddit post" with no underlying experience
- A generic listicle like "10 tips for X" or "Best prompts/tools"
- A defection post ("Why I quit X for Y") when they haven't actually defected
- Anything that's clearly product marketing dressed up as a personal story
- Karma farming with no substance

The right response in these cases: explain that developer audiences filter that content out fast, and ask what they've actually been working on. If nothing comes up, suggest they revisit when they have something concrete.

## The core workflow

### Step 1 — Find the post-worthy thing

Ask the user what they did. Don't accept vague answers. The skill needs at least one of:

- **A concrete outcome with numbers** (e.g., "Script X ran 10x faster after optimizing Y")
- **A workflow they figured out the hard way** ("I tried 4 ways to configure X, only one worked")
- **A measurement they made** ("I tracked latency across 100 requests and found...")
- **A specific failure they diagnosed** ("Production crashed, I traced it to line X in Y")
- **A comparison they actually ran** ("Same task in tool A, B, C — here's what happened")
- **A novel tool/script/wrapper they built and used** (not "I made a thing", but "I made a thing, used it for a week, here's what changed")

If the user gives a vague answer ("I've been using tool X a lot and have thoughts"), push for specifics. If after one round of questions there's still nothing concrete, recommend not posting.

### Step 2 — Pick the sub

Identify the target community category and match the post to the audience:

- **Tool/Product Specific Subs** (e.g., `r/ClaudeCode`, `r/cursor`, `r/neovim`) — Highly focused on the specific tool, CLI tricks, system integrations, configs, edge-case bugs, and tool-specific workflows. Avoid generic tips or unrelated content.
- **Language/Framework Specific Subs** (e.g., `r/reactjs`, `r/rust`, `r/python`) — Loves: concrete code patterns, architectural decisions, performance optimization benchmarks, package comparisons. Hates: low-effort tutorials or unrelated AI-generated code snippets.
- **General Coding/Developer Subs** (e.g., `r/webdev`, `r/programming`, `r/softwareengineering`) — Broader audience of engineers. Loves: high-level architecture trade-offs, interesting postmortems of production outages, real-world case studies with data.
- **AI-Coding & API Communities** (e.g., `r/ChatGPTCoding`, `r/ClaudeAI`, `r/codex`) — Loves: comparison of models, workflows/pipelines, API cost optimization, custom agent frameworks.

If the post fits multiple subreddits, the skill should say so — but the wording should be tuned per community, not the same post copy-pasted. Cross-posting verbatim is detectable and looks lazy.

### Step 3 — Pick the format

See [references/formats.md](references/formats.md) for the full template library. Common ones:

- **Postmortem** — "I [did thing], here's what happened"
- **Hidden features dump** — only if features are actually obscure
- **Honest comparison** — head-to-head with real code/tasks
- **Degradation/regression report** — needs receipts
- **Defection** — only if real
- **Tool/wrapper share** — must include "I used this for X weeks and here's what it changed"

### Step 4 — Write to the voice

See [references/voice.md](references/voice.md) for detailed voice rules. The compressed version:

- Lead with the punchline. The TL;DR goes near the top, not buried at the bottom (though a short summary at the very bottom for skimmers is fine).
- Specific numbers, dated events, named tools. "Last Tuesday my build pipeline burned 80% of my monthly CPU hours" beats "I've been hitting limits a lot."
- Acknowledge what didn't work. The audience trusts posts that admit failure.
- Strip every "it's worth noting that," "in conclusion," "leverage," "robust solution." The corporate voice is the kiss of death.
- No em-dashes everywhere — a couple is fine, every sentence reads as AI.
- No emoji headers, no "🚀 The Results 🚀." Plain markdown.
- Don't tell the audience how to feel ("This is huge!"). Show them.
- Avoid the AI-tell trifecta: "Let's dive in," "It's important to note," and ending paragraphs with "...and that's a game-changer."

### Step 5 — Title

Titles do most of the work. See [references/titles.md](references/titles.md) for formulas and examples. Compressed rules:

- Specific outcome > vague claim
- Numbers in titles when they're real and surprising
- No clickbait questions ("Is Tool X Actually Worth It?")
- No "[Discussion]" or "[Question]" tags unless the sub requires them
- Lowercase casual is fine; Title Case Reads Robotic

### Step 6 — Draft, then stress-test

After writing the draft, apply the stress test before showing it to the user:

1. **The "would I downvote this" test** — read it as a skeptical regular. Does it read as content marketing? Does it have an obvious agenda?
2. **The "what does the top comment say" test** — predict the most likely critical comment. If the post can't survive it, fix the post.
3. **The "could this be by anyone" test** — if you swap the tool/framework name and the post still works, it's too generic.
4. **The hedge-phrase scan** — search for "it's worth noting," "various," "leverage," "robust," "delve." Cut all of them.
5. **The em-dash count** — more than 3 in a short post is suspicious.

If the draft fails any of these, fix before presenting.

### Step 7 — Output

Two outputs:

1. **In chat:** the post draft, formatted as it would appear on Reddit (title on top, body below, with markdown). Plus a short "before you post" note flagging anything risky.
2. **Optional file:** save to outputs or local files in the current workspace if requested.

Don't auto-post. Reddit posts are irreversible-ish; the user should always copy and review.

## Things this skill does NOT do

- Post to Reddit directly (even if a Reddit MCP is connected, hand the user the draft and let them post)
- Generate posts in bulk for "engagement"
- Write the same post for multiple subreddits without retuning
- Write replies/comments on existing threads (different skill)
- Defend or rebut things the user hasn't actually verified

## When the right answer is "don't post"

Sometimes after the interview, it'll be clear there's nothing post-worthy. Common cases:

- The user is frustrated and venting. Vent posts get downvoted unless extremely well-written; usually better to wait a day.
- The "insight" is actually well-known in the sub already.
- The user wants to promote a product/repo without having used it long enough.
- The post would be the user's first karma-farming post on a brand-new account (will get auto-flagged).

In these cases, say so directly. The skill's job is to make good posts happen, not to manufacture them.

See:
- [references/voice.md](references/voice.md) — detailed voice and style guide
- [references/formats.md](references/formats.md) — post format templates with examples
- [references/titles.md](references/titles.md) — title formulas with strong/weak examples
- [references/sub-cheatsheet.md](references/sub-cheatsheet.md) — per-sub conventions, mod rules, and culture notes
