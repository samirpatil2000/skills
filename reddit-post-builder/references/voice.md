# Reddit Post Builder: Voice & Style Guide

To survive in technical subreddits (especially r/ClaudeCode), your writing must sound like a real developer speaking to other developers. This guide defines the voice rules and specific anti-patterns to avoid.

## The "Corporate AI" Failure Mode
The absolute kiss of death is the polite, structured, marketing-adjacent tone of standard LLM writing. We must actively strip this out.

### 1. The AI-Tell Hit List
If any of these words or phrases appear in your draft, remove or replace them:
*   **"Let's dive in"** / **"Let's delve into"** (Use: No intro at all, start directly with the context or data)
*   **"It is important to note"** / **"It's worth noting"** (Use: Just state the fact)
*   **"Leverage"** (Use: "Use", "utilize", or "run")
*   **"Robust"** (Use: "Reliable", "solid", "production-ready", or describe the actual behavior)
*   **"Game-changer"** (Use: Describe what changed without hyping it)
*   **"In conclusion"** / **"To sum up"** (Use: Short final thought, or nothing at all)
*   **"Testament to"** / **"Beacon of"** (Delete entirely)
*   **"Seamlessly"** (Use: "Without errors", "smoothly", or delete)

### 2. Sentence Structure & Grammar
*   **Em-dashes (—):** Standard AI drafts use em-dashes to connect clauses in almost every paragraph. Limit the entire post to a maximum of 2-3 em-dashes. Use simple sentences instead.
*   **Transition Phrases:** Strip "Furthermore," "Moreover," "Additionally," "On the other hand." Real developers write in short, punchy paragraphs and connect thoughts through logical progression rather than formal transitions.
*   **Passive Voice:** Avoid "The command was run by me." Use active voice: "I ran the command."

## The "Authentic Developer" Tone
*   **Lead with the Punchline:** Do not write a three-paragraph build-up. State the main finding, cost, bug, or outcome in the very first sentence.
*   **Be Specific:** Instead of "I ran a script and it took a long time," write "I ran a custom bash wrapper that spent 42 minutes loop-retrying `npm run test`."
*   **Admit Failure:** If a tool failed or you made a mistake, highlight it. A post that says "I spent 4 hours fixing a config bug that I introduced" is far more trustworthy than "Here is my perfect system."
*   **No Unwarranted Hype:** Do not tell the reader "This will save you hours!" Show them the numbers and let them decide.

## Formatting Constraints
*   **No Emoji Headers:** Avoid `### 🚀 The Results` or `## 🛠️ The Fix`. Use plain markdown: `### Results` or `## The Fix`.
*   **Code Blocks:** Always format terminal commands, code snippets, logs, and errors in appropriate code blocks with syntax highlighting.
*   **Bullet Points:** Keep bulleted lists concise. Avoid having every bullet point start with bolded text followed by a long explanation.
