---
name: clean-code
description: >
  Review, refactor, or rewrite code for readability and maintainability. Trigger on: "clean up",
  "refactor", "improve code", "code smells", "simplify", "make readable", "too long", "bad naming",
  "technical debt", or any request to improve existing code quality. Also trigger when code has
  obvious smells even if the user doesn't name them.
---

# Clean Code Skill

## Diagnose First
Scan for: vague names · functions doing too much · deep nesting · magic values · duplicated logic · silent error handling · comments explaining *what* not *why*

## Core Techniques

**Rename for intent**
```python
# ❌ d, arr, flag, doStuff
# ✅ today, activeUsers, isVisible, calculateDiscount
```

**Extract functions** — if a block needs a comment, make it a named function.

**Early returns** — flatten nesting by returning/guarding at the top.
```js
if (!order) return;
if (!order.isPaid) return;
// main logic here
```

**Named constants** — no magic values.
```python
HTTP_NOT_FOUND = 404  # not just 404 inline
```

**DRY** — 2+ copies of logic → extract once.

**Reduce params** — >3 args → use an options object/struct.

## Output Format
- **Review**: summary → issues (critical / moderate / minor) → refactored code → what changed & why
- **Refactor**: show cleaned code first, then brief explanation + assumptions made
- **From scratch**: just write it clean, no before/after needed

## Quick Checklist
- [ ] Each function does one thing
- [ ] Names reveal intent without comments
- [ ] No magic numbers/strings
- [ ] No duplicated logic
- [ ] Nesting ≤ 2-3 levels
- [ ] Errors handled explicitly

## Tone
Specific not vague · constructive not critical · explain *why* not just *what* · flag style vs. real problems
