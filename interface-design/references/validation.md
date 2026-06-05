# Validation — Reference

Memory management, system.md hygiene, and consistency enforcement.
Read this when maintaining an existing system or deciding what to save.

---

## What system.md Is For

system.md is a living record of decisions already made. It answers the question: "What has this project committed to?"

It is not:
- A style guide (too abstract)
- A component library (too detailed)
- A CSS file (too implementation-specific)

It is: the minimum set of decisions that prevent drift.

---

## When to Read system.md

**Every session start, automatically.** If `.interface-design/system.md` exists, read it before doing anything else. Don't wait to be asked.

When you load it:
1. Extract the depth strategy
2. Extract the spacing base
3. Extract the color palette
4. Extract any documented patterns

These are not suggestions — they are constraints. Work within them.

---

## When to Update system.md

Update when:
- A component is used 2+ times in the project
- You've made a new foundational decision (new accent color, new radius strategy)
- A pattern has been refined and the old version is outdated
- A new section type is introduced (e.g., first data table, first modal)

Do NOT update for:
- One-off components unlikely to repeat
- Temporary experiments
- Variations better handled with component props
- Minor adjustments that don't change the system

---

## system.md Structure

Maintain this exact structure:

```markdown
# Design System

## Direction
Personality: [one phrase that captures the feel]
Foundation: [color family, e.g., "Cool slate", "Warm amber", "Neutral zinc"]
Depth: [borders-only / subtle-shadows / layered-shadows / surface-shifts]
Mode: [light / dark / both]

## Tokens

### Spacing
Base: [4px or 8px]
Scale: [comma-separated values, e.g., "4, 8, 12, 16, 24, 32, 48, 64"]

### Colors
[Use role names, not hex values]
--canvas: [description]
--surface: [description]
--surface-raised: [description]
--text-primary: [description]
--text-secondary: [description]
--text-tertiary: [description]
--text-muted: [description]
--border-subtle: [description]
--border-default: [description]
--border-emphasis: [description]
--accent: [description]
--accent-muted: [description]
--destructive: [description]

### Typography
Body: [font name — why it fits]
Display: [font name — why it fits, or "same as body with weight variation"]
Data: [monospace font for numbers/code, or "system monospace"]
Scale: [base size — e.g., "13px base, 4-level hierarchy"]

## Patterns

### [Component Name]
- Height: [value]
- Padding: [value]
- Radius: [value]
- Border: [value]
- Background: [token reference]
- Notes: [any specific decisions]

### [Component Name]
...
```

---

## Consistency Checks

Before delivering any component, verify:

**Spacing:**
- [ ] All gaps are multiples of the base unit
- [ ] No magic numbers (values not in the scale)

**Depth:**
- [ ] Only one depth strategy used throughout
- [ ] No mixing of borders and shadows unless the system explicitly allows it

**Color:**
- [ ] All colors trace back to defined tokens
- [ ] No raw hex values in component code (exception: semantic one-offs documented in system.md)

**Typography:**
- [ ] Font families match the documented choices
- [ ] Sizes are from the defined scale
- [ ] Four text hierarchy levels used, not more, not fewer

**Patterns:**
- [ ] Previously documented components match their spec
- [ ] If deviation was needed, document the new version

---

## Drift Detection

Signs that a system is drifting:

- Two components with the same purpose but different heights
- Spacing values that aren't in the scale (e.g., 10px when base is 4px)
- Cards with different border radiuses for no clear reason
- Some borders using hex, some using rgba
- New accent colors appearing without documentation

When you notice drift, flag it before building more. Ask: "I notice the existing cards use `6px` radius but the documented pattern says `8px`. Should I match the existing code or the documented system?"

---

## Pattern Evolution

Systems evolve. When a documented pattern needs to change:

1. Note why the existing pattern isn't working
2. Propose the refined version
3. Update system.md
4. Note the change with a brief reason

```markdown
### Card Default
- Border: 1px solid var(--border-default)
- Padding: 16px
- Radius: 8px  ← updated from 6px (felt too sharp at larger card sizes)
- Background: var(--surface-1)
```

Don't silently diverge — document it.

---

## Saving After a Session

When offering to save patterns, include:

```
"Want me to save these patterns to .interface-design/system.md?

I'd add:
- [Component A]: [key measurements]
- [Component B]: [key measurements]
- [Decision X]: [what was decided and why]"
```

Give the user a preview of what will be saved. Don't dump everything — be selective.

---

## When system.md Conflicts With the Codebase

Sometimes the code diverges from system.md. When this happens:

1. Identify which is "right" — the system (intentional) or the code (accidental drift)
2. Ask the user which to trust
3. Update system.md or fix the code accordingly

Never silently use one and ignore the other.

---

## First-Time System Creation

When writing system.md for the first time after a build:

1. Extract the actual values used — don't document what you intended, document what's there
2. Look for patterns: what height did most buttons end up at? What padding did most cards use?
3. Name the direction based on what it actually feels like, not what you planned
4. Be honest about what was consistent and what wasn't — note areas that need cleanup

```markdown
# Design System

## Direction
Personality: Precise and dense — engineering tool aesthetic
Foundation: Cool gray with blue accent
Depth: Borders-only

[continues...]

## Notes
- Icon sizes were inconsistent between sidebar (16px) and cards (20px). Standardize to 16px.
- Two card variants emerged. Documented both — consider consolidating.
```

Honesty in system.md is more valuable than a perfect-looking system. You're leaving notes for your future self.
