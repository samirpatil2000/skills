# Reddit Post Builder: Format Templates

Choose the layout format that best matches your underlying experience. Do not fit a post into a format if you don't have the details for it.

---

## 1. Postmortem (Debugging Journey)
**When to use:** You spent hours debugging an issue with an AI-coding tool, library, or setup, and finally resolved it.
**Core Rule:** Don't just list the solution. The journey (what you tried, how it failed) is where the value is.

### Template:
```markdown
[Clear title stating what broke and what fixed it]

I spent [Time] tracking down a bug where [Tool/setup] failed with [Error/Behavior]. 

### The Setup
*   **OS:** [e.g., macOS Sonoma]
*   **Tool/IDE:** [e.g., Claude Code v0.2.9]
*   **Stack:** [e.g., Next.js 15, Turbopack]

### What I Tried
1.  **[Attempt 1]:** I thought it was [Hypothesis]. I tried [Action], but it resulted in [New error/Same error].
2.  **[Attempt 2]:** Next, I looked at [File/Setting] and changed [Value]. That didn't work because [Reason].

### The Diagnosis
I finally ran [Tool/Command, e.g., standard debug logs/tracing] and noticed:
[Paste exact line of log or config that was wrong]

It turns out [Root cause explanation].

### The Fix
To fix this, you need to:
[Show code/configuration diff or commands]

### Lessons Learned
*   [Insight 1 about how the AI tool handled it]
*   [Insight 2 about configuration gotchas]
```

---

## 2. Honest Comparison / Benchmarking
**When to use:** You ran a specific, identical task across multiple models or tools (e.g., Claude Code vs. Cursor vs. Copilot Workspace).
**Core Rule:** Use a realistic, complex coding task, not a simple fizzbuzz. Show the prompt, code, and outcome.

### Template:
```markdown
[Title highlighting the unexpected winner or key metric]

I ran a head-to-head comparison between [Tool A], [Tool B], and [Tool C] on a real-world coding task: [Describe task, e.g., migrating a complex Express router to TypeScript with full test coverage].

### The Task & Prompts
*   **The Task:** [Details]
*   **The Prompt:**
    ```text
    [Paste exact prompt used]
    ```

### Results Summary
| Metric | [Tool A] | [Tool B] | [Tool C] |
| :--- | :--- | :--- | :--- |
| **Time to Complete** | [Time] | [Time] | [Time] |
| **API Cost** | [$ Amount] | [$ Amount] | [$ Amount] |
| **Code Correctness** | [e.g., 8/10 tests passed] | [e.g., 10/10] | [e.g., 4/10] |
| **Manual Interventions**| [Number of times you had to prompt again] | [Number] | [Number] |

### The Breakdown

#### [Tool A]
*   **Strengths:** [Specific examples of what it got right]
*   **Weaknesses:** [Where it struggled, code errors it missed]
*   **Sample Output:** [Link to file or short snippet]

#### [Tool B]
*   **Strengths:** [Specific examples]
*   **Weaknesses:** [Specific examples]

### Key Takeaway
[1-2 sentences on which tool you would actually use for this type of task based on the data]
```

---

## 3. Degradation / Regression Report
**When to use:** You have noticed a sudden, reproducible drop in quality, speed, or cost efficiency of an AI model/tool.
**Core Rule:** You must provide historical data or exact comparison runs. "It feels slower" gets ignored; "latency went from 1.2s to 4.5s" gets upvoted.

### Template:
```markdown
[Title stating the regression and the numbers]

Over the last [days/weeks], I noticed [regression behavior, e.g., Claude 3.5 Sonnet failing on standard react components]. I ran a test suite of [number] prompts to verify, and here is the data.

### The Numbers
*   **Success Rate Before:** [% or fraction, e.g., 92% on July 1]
*   **Success Rate Now:** [% or fraction, e.g., 45% on July 10]
*   **Average Token Usage:** [Did it double/triple due to loops?]

### Reproducible Example
Here is the exact prompt that now fails consistently:
```text
[Prompt]
```

#### Expected Output (What it used to generate):
[Description or short code]

#### Actual Output (What it generates now):
[Description or paste buggy code/infinite loop logs]

### My Hypothesis
I think this is due to [e.g., context window stuffing, system prompt changes, model update]. Has anyone else noticed this behavior in the last 48 hours?
```

---

## 4. Novel Tool / Custom Skill Share
**When to use:** You built a script, tool, or custom skill that makes your AI coding workflow significantly better.
**Core Rule:** Do not post the day you write the code. Post after using it for at least 1-2 weeks. Explain where it fails.

### Template:
```markdown
[Title describing the utility and what it changed in your workflow]

I spent the last two weeks dogfooding a custom [script/tool/skill] I wrote to solve [specific annoyance, e.g., Claude Code running useless file reads in large directories].

Here is what it does, the code, and what I learned from using it daily.

### The Problem it Solves
[Describe the friction point in detail]

### The Code / Implementation
[Provide the code block or GitHub link]

### What Changed in My Workflow
*   **Speed/Cost:** [e.g., reduced my token usage by 30%]
*   **Friction:** [e.g., I no longer have to manually type 'ignore folder X']

### Where It Fails (The Gotchas)
It's not perfect. Here are the issues I encountered:
1.  [Gotcha 1, e.g., it occasionally misses nested folders]
2.  [Gotcha 2, e.g., it slow downs if the project has over 10k files]
```
