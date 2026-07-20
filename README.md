# Agent Skills (Codex / Claude Code / Antigravity / Pi / Hermes)

A curated collection of custom agent skills for sharper engineering, product thinking, planning, execution, documentation, and interface design.

This repository is built for people who want their AI coding assistant to behave less like a generic chatbot and more like a reliable collaborator with clear modes, strong taste, and task-specific judgment.

## Why This Repo Exists

Most AI assistants are capable, but their behavior is often too broad. A good skill gives the assistant a sharper operating mode:

- when to trigger
- how to think
- what to avoid
- what output format to use
- where to push back
- when to act and when to stay read-only

These skills turn repeated working styles into reusable instructions.

## Skill Catalog

| Skill | Purpose | File |
| --- | --- | --- |
| `senior-engineer-brainstorm` | Turns rough feature ideas into production-minded technical approaches, architecture options, risks, and implementation prompts. | [`senior-engineer-brainstorm/SKILL.md`](senior-engineer-brainstorm/SKILL.md) |
| `skill-ceo-review` | Reviews skill ideas through a founder/product lens before testing, with emphasis on scope, trigger quality, and ambition. | [`skill-ceo-review/SKILL.md`](skill-ceo-review/SKILL.md) |
| `jamming` | Collaborative thinking mode that reflects, maps knowns vs unknowns, asks one sharp question, and avoids premature answers. | [`jamming/SKILL.md`](jamming/SKILL.md) |
| `caveman` | Ultra-compressed communication mode for reducing token usage while preserving technical accuracy. | [`caveman/SKILL.md`](caveman/SKILL.md) |
| `plan` | Strict read-only planning mode for observing, scoping, and proposing next steps without modifying files. | [`plan/SKILL.md`](plan/SKILL.md) |
| `supermemory-search` | Searches a personal Supermemory knowledge base when the user asks to recall saved knowledge. | [`supermemory-fetch.md`](supermemory-fetch.md) |
| `clean-code` | Reviews and refactors code for readability, maintainability, naming, structure, and reduced complexity. | [`clean-code/SKILL.md`](clean-code/SKILL.md) |
| `execute` | Action mode for moving from planning into implementation, verification, and delivery. | [`execute/SKILL.md`](execute/SKILL.md) |
| `ask` | Answer-only mode for direct questions, with no edits or state-changing commands. | [`ask/SKILL.md`](ask/SKILL.md) |
| `interface-design` | Product interface design skill for dashboards, tools, settings pages, SaaS apps, and data-heavy workflows. | [`interface-design/SKILL.md`](interface-design/SKILL.md) |
| `steve-jobs-thinking` | Product taste mode focused on ruthless simplicity, user experience, and opinionated design decisions. | [`steve-jobs-thinking/SKILL.md`](steve-jobs-thinking/SKILL.md) |
| `the-razor` | Critical thinking engine that stress-tests arguments using Occam's, Sagan, Hitchens's, and Alder's razors. | [`the-razor/SKILL.md`](the-razor/SKILL.md) |
| `opencode-fusion` | Multi-model parallel execution, judge analysis, and synthesis — OpenRouter Fusion-style workflows via OpenCode CLI. | [`opencode-fusion/SKILL.md`](opencode-fusion/SKILL.md) |
| `debug-issue` | Systematic debugger for finding root causes. Generates hypotheses, suggests fixes, and provides verification paths for any broken code or unexpected behavior. | [`debug-issue/SKILL.md`](debug-issue/SKILL.md) |
| `terminal` | Executes user-provided shell commands as-is and returns raw output without commentary. | [`terminal/SKILL.md`](terminal/SKILL.md) |
| `align` | Interactive interview mode to resolve design decisions, clarify requirements, and eliminate ambiguity. | [`align/SKILL.md`](align/SKILL.md) |
| `seedance-prompt-en` | Write effective prompts for Jimeng Seedance 2.0 multimodal AI video generation. | [`seedance-prompt-en/SKILL.md`](seedance-prompt-en/SKILL.md) |
| `reddit-post-builder` | Turn real work the user has actually done into a Reddit post for r/ClaudeCode, r/ClaudeAI, r/codex, r/ChatGPTCoding, or r/cursor. | [`reddit-post-builder/SKILL.md`](reddit-post-builder/SKILL.md) |
| `log-papercuts` | Proactively log small friction points, flaky commands, failed tool calls, or setup gotchas to `PAPERCUTS.md` using `yarn papercut`. | [`log-papercuts/SKILL.md`](log-papercuts/SKILL.md) |
| `blueprint` | Full project scoping — combines codebase survey, architecture design, UI simplicity, and requirement interrogation before any code is written. | [`blueprint/SKILL.md`](blueprint/SKILL.md) |


## Repository Structure

```text
.
├── README.md
├── align/
│   └── SKILL.md
├── ask/
│   └── SKILL.md
├── blueprint/
│   └── SKILL.md
├── caveman/
│   └── SKILL.md
├── clean-code/
│   └── SKILL.md
├── debug-issue/
│   └── SKILL.md
├── execute/
│   └── SKILL.md
├── interface-design/
│   ├── SKILL.md
│   └── references/
├── jamming/
│   └── SKILL.md
├── log-papercuts/
│   └── SKILL.md
├── plan/
│   └── SKILL.md
├── reddit-post-builder/
│   ├── SKILL.md
│   └── references/
│       ├── formats.md
│       ├── sub-cheatsheet.md
│       ├── titles.md
│       └── voice.md
├── seedance-prompt-en/
│   └── SKILL.md
├── senior-engineer-brainstorm/
│   └── SKILL.md
├── skill-ceo-review/
│   └── SKILL.md
├── steve-jobs-thinking/
│   └── SKILL.md
├── the-razor/
│   └── SKILL.md
├── opencode-fusion/
│   ├── SKILL.md
│   └── run_fusion.sh
├── terminal/
│   └── SKILL.md
└── supermemory-fetch.md
```

## How To Use

Each skill is self-contained. Open the relevant `SKILL.md`, review the trigger description at the top, and place the skill in your agent's skills directory or adapt it for your local setup.

## 💡 Personal Usage Guide: What to Use When

While there are many skills here, my typical workflow relies heavily on these core skills:

- **`jamming`**: Use when the idea is fuzzy and I just want to brainstorm architecture or strategy together. (Thinking Phase)
- **`align`**: Use when I think I know what I want to build, but need you to interrogate me and lock in the requirements/edge cases. (Requirement Phase)
- **`plan`**: Use when the requirements are set and I need a step-by-step roadmap of the codebase before writing code. (Scoping Phase)
- **`steve-jobs-thinking`**: Use when working on UI/UX changes to ensure ruthless simplicity, great taste, and a user-obsessed design. (Design Phase)
- **`debug-issue`**: Use whenever there's a bug, crash, or unexpected behavior. (Fixing Phase)

## Documentation Standards

Every skill should make the following obvious:

- **Name**: short, memorable, and specific
- **Description**: clear trigger conditions and intended use
- **Behavior**: what the assistant should do differently
- **Boundaries**: what the assistant must not do
- **Output format**: predictable structure when useful
- **Persistence rules**: whether the mode lasts across turns

Good skills are not long because they are verbose. They are long only where precision prevents bad behavior.

## Security Note

Do not commit private API keys, tokens, credentials, or personal secrets inside skill files. If a skill needs external service access, prefer environment variables and document the required variable names instead of hardcoding credentials.

## Contributing

Improvements are welcome when they make a skill more reliable, easier to trigger correctly, or safer to use.

Before adding a new skill:

1. Make sure it solves a repeated problem.
2. Keep the trigger description specific.
3. Define what the assistant should refuse or avoid.
4. Include examples only when they clarify behavior.
5. Prefer one sharp skill over one broad skill that tries to do everything.

## License

No license has been specified yet. Add one before distributing or reusing this repository publicly.
