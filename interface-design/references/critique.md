# Critique — Reference

Post-build craft critique protocol. Use this when reviewing your own output before showing it,
or when running `/interface-design:critique`.

---

## The Critique Mindset

You are not looking for bugs. You are looking for defaults.

A default is any decision that happened without thought. It feels inevitable in the moment. It looks like infrastructure. It is the output you would get if you hadn't tried.

Critique means: identify the defaults, replace them with choices.

---

## The Three Levels of Critique

### Level 1: Surface (What You Can See Immediately)

Run the squint test. Blur your eyes. What do you notice?

- Is the hierarchy clear? (Can you tell what's primary/secondary/tertiary without reading?)
- Are there harsh elements jumping out? (Borders, shadows, contrast too strong)
- Does the spacing feel consistent? (Or are there random gaps that break rhythm)
- Is the color doing work? (Or is it just there)

Flag everything that catches your eye for the wrong reason.

### Level 2: System (Does It Hold Together)

Read the code as if auditing a stranger's work:

- Pick any two similar components. Do they share values? Button heights, card padding, border radii?
- Find all spacing values. Are they multiples of the base unit, or are there magic numbers?
- Find all border values. Are they consistent? Same weight, same opacity approach?
- Find all font sizes. Do they map to a scale, or did sizes drift?

A system that doesn't hold together signals no system at all. Users feel this even when they can't name it.

### Level 3: Intent (Does It Mean What You Said)

Pull up your stated intent. Read it. Now look at the interface.

- You said "warm." Are the surfaces warm? Is the type warm? Are the borders warm? Or did you say warm and use default cool gray?
- You said "dense." Is the spacing actually tight, or is there generous padding everywhere?
- You said "precise." Is the grid exact? Are the alignments perfect? Or are there one-pixel-off details?

If any intent statement doesn't manifest in the code, you have a broken promise. Fix it.

---

## Common Defaults to Catch

**The safe font:** You reached for a familiar, "clean" typeface. It could be from any project. It adds nothing.
→ Ask: what typeface belongs in this product's world?

**The icon-left layout:** Every card has an icon on the left, a title, and a value. All cards identical.
→ Ask: what does each card's content actually need to communicate? Design the internal structure for that.

**The purple-to-blue gradient button:** Or any gradient on a primary action.
→ Ask: why a gradient? Does it serve intent, or is it just making it look "designed"?

**The 8px radius on everything:** Buttons, cards, modals, inputs — all the same radius.
→ Ask: what radius personality fits this product? Is it technical (tighter) or friendly (rounder)?

**The arbitrary accent:** The accent color was picked without grounding. It could be any product.
→ Ask: where does this color come from in the product's world?

**The floating page:** No navigation, no context. A data table in space.
→ Ask: where is this in the app? Add navigation context.

**The incomplete states:** The happy path looks good. But hover states are missing, or all look identical. No empty state, no loading, no error.
→ Add all states before delivering.

**The CSS variable naming:** `--gray-700`, `--primary-500`, `--color-1`. No product identity.
→ Rename with role and character. `--surface-parchment`, `--text-ink`, `--accent-copper`.

---

## Critique Process

1. **Run Level 1** — squint test, 30 seconds, note what catches
2. **Run Level 2** — audit 5 specific values for consistency
3. **Run Level 3** — compare output against stated intent word by word
4. **List the defaults** — write them down explicitly
5. **Rebuild the defaulted parts** — not the whole thing, just what failed

The goal is not a perfect first pass. The goal is catching defaults before the user has to.

---

## Self-Critique Template

Before showing output, fill this out mentally:

```
Swap test: If I swapped [typeface] for a generic one, would it feel different? → [yes/no + what I'd lose]
Squint test: What catches my eye for the wrong reason? → [list]
Signature test: Where do I see the signature I named? → [5 specific locations or "I don't — fix this"]
Token test: Read tokens out loud — do they sound product-specific? → [yes/no]
Intent test: Did I say [X] and actually deliver [X]? → [yes/no for each intent statement]
```

If any answer is no — fix it first.

---

## Rebuilding What Defaulted

When you identify a default:

1. Name what the default was: "Used Inter because it's readable and familiar"
2. Name what it should be instead, tied to intent: "This product manages handwritten records for museum archivists — use a humanist typeface that reads like handwriting has craft"
3. Rebuild only that element
4. Verify the fix doesn't break system consistency

Don't rebuild everything. Surgical fixes compound faster than wholesale rewrites.

---

## When the User Asks for a Critique

If running `/interface-design:critique`:

1. State what you built
2. Run all three critique levels
3. Name 3–5 specific defaults you found
4. Show the rebuilt versions
5. Offer to update system.md with the improved patterns

Be direct. "This header font could be from any project" is more useful than "the typography could be more distinctive."

The user asked for critique because they want to improve the work. Give them specific problems and specific fixes.
