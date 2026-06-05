# Design Principles — Reference

Detailed guidance on values, code patterns, and dark mode implementation.
This file is loaded on demand — read it when you need specifics beyond the SKILL.md overview.

---

## Surface Elevation in Practice

### Light Mode Elevation Scale

Surfaces read as stacked through lightness. Build from a base neutral:

```css
/* Base canvas */
--surface-base: hsl(220 14% 96%);

/* Card / panel — slightly lighter */
--surface-1: hsl(220 14% 98%);

/* Popover / dropdown — one more step lighter */
--surface-2: hsl(220 14% 100%);

/* Modal — same as popover, distinguished by overlay */
--surface-modal: hsl(220 14% 100%);
```

The hue and saturation stay constant. Only lightness shifts — and only by 2–3 points per level.

### Dark Mode Elevation Scale

In dark mode, elevation goes lighter, not darker:

```css
/* Base canvas — dark but not black */
--surface-base: hsl(220 14% 9%);

/* Card / panel */
--surface-1: hsl(220 14% 11%);

/* Popover / dropdown */
--surface-2: hsl(220 14% 13%);

/* Modal */
--surface-modal: hsl(220 14% 13%);
```

Each level is 2 points lighter in `L`. The shift is subtle by design — barely visible in isolation, clear when surfaces stack.

**Why not pure black (#000)?** Pure black reads as a void. Dark neutrals with a slight hue feel like materials. They also make the elevation hierarchy work — you can't go lighter than white or darker than black, so starting at a mid-point gives you room to move.

---

## Border Values

Borders use rgba so they blend with whatever surface they sit on:

```css
/* Standard separation — barely there */
--border-subtle: rgba(0, 0, 0, 0.06);    /* light mode */
--border-subtle: rgba(255, 255, 255, 0.06); /* dark mode */

/* Default border — defines edges */
--border-default: rgba(0, 0, 0, 0.10);
--border-default: rgba(255, 255, 255, 0.10);

/* Emphasis — for active states, selected items */
--border-emphasis: rgba(0, 0, 0, 0.18);
--border-emphasis: rgba(255, 255, 255, 0.18);

/* Focus ring — maximum emphasis */
--border-focus: rgba(0, 0, 0, 0.40);
--border-focus: rgba(255, 255, 255, 0.40);
/* Or use the accent color for focus */
--border-focus: var(--accent);
```

### Border Weight

Always `1px`. Never `2px` unless it's a focus ring or a specific design decision. `0.5px` works on retina screens for extremely subtle lines.

---

## Spacing Scale

Base unit: 4px

```css
--space-1:  4px;   /* icon gap, tight inline spacing */
--space-2:  8px;   /* between label and value, icon and text */
--space-3:  12px;  /* padding inside compact controls */
--space-4:  16px;  /* standard card padding, component gap */
--space-5:  20px;  /* breathing room within sections */
--space-6:  24px;  /* between major elements */
--space-8:  32px;  /* section separation */
--space-10: 40px;  /* large section gaps */
--space-12: 48px;  /* page-level breathing room */
--space-16: 64px;  /* major visual breaks */
```

Use 8px base for more spacious layouts. The principle is the same — pick one and stick to multiples.

---

## Typography Scale

### Size Progression

```css
--text-xs:   11px;  /* labels, badges, metadata */
--text-sm:   12px;  /* secondary labels, captions */
--text-base: 13px;  /* body, default UI text */
--text-md:   14px;  /* slightly emphasized body */
--text-lg:   16px;  /* section headers, card titles */
--text-xl:   18px;  /* page titles, prominent headings */
--text-2xl:  22px;  /* hero numbers, display metrics */
--text-3xl:  28px;  /* large metric displays */
--text-4xl:  36px;  /* maximum display size */
```

### Weight Usage

- `400` — body text, descriptions, secondary content
- `450–500` — medium: labels, navigation items, table content
- `500–600` — semibold: card titles, section headings, emphasized values
- `600–700` — bold: page titles, hero numbers, strong emphasis

### Letter Spacing

Tight tracking on large headings: `-0.02em` to `-0.03em`
Neutral tracking on body: `0em`
Slightly open tracking on small caps/labels: `0.02em` to `0.04em`

### Monospace for Data

Any column of numbers that users will compare needs monospace with tabular figures:

```css
font-family: 'Jetbrains Mono', 'Fira Code', ui-monospace, monospace;
font-variant-numeric: tabular-nums;
```

---

## Control Heights

Consistent heights prevent the "random sizes" feeling:

```css
--control-xs:  24px;  /* tight inline controls, chips */
--control-sm:  28px;  /* compact buttons, small inputs */
--control-md:  32px;  /* default: most inputs, buttons */
--control-lg:  36px;  /* prominent CTAs, form inputs */
--control-xl:  40px;  /* search bars, hero inputs */
```

Padding should be horizontal only in most controls — height is controlled by the height value, not top/bottom padding.

---

## Radius Scale

```css
--radius-sm:   3px;   /* subtle rounding — badges, tags */
--radius-md:   6px;   /* buttons, inputs, small cards */
--radius-lg:   8px;   /* standard cards */
--radius-xl:   12px;  /* large panels, modals */
--radius-2xl:  16px;  /* overlays, sheets */
--radius-full: 9999px; /* pills, avatars, circular elements */
```

Don't mix `3px` and `8px` in the same interface arbitrarily. Choose a personality:

- Technical/precise: `3–4px` throughout
- Balanced: `6–8px` throughout
- Friendly/modern: `8–12px` throughout

---

## Animation Values

```css
/* Micro-interactions: hover states, toggles, button presses */
--duration-fast: 100ms;
--ease-fast: cubic-bezier(0.2, 0, 0.2, 1);

/* Standard transitions: panel slides, dropdowns */
--duration-base: 150ms;
--ease-base: cubic-bezier(0.0, 0, 0.2, 1);

/* Larger transitions: modals, page transitions */
--duration-slow: 200ms;
--ease-slow: cubic-bezier(0.0, 0, 0.2, 1);
```

Use deceleration easing (`cubic-bezier(0.0, 0, 0.2, 1)`) for elements entering the screen.
Use acceleration easing (`cubic-bezier(0.4, 0, 1, 1)`) for elements leaving.

**Avoid:** spring physics, bounce easing, elastic curves in professional tools. Save those for consumer/playful products.

---

## Text Hierarchy — Full Token Set

```css
/* Foreground / text */
--text-primary:    hsl(220 14% 10%);    /* headlines, important values */
--text-secondary:  hsl(220 10% 35%);    /* supporting labels, descriptions */
--text-tertiary:   hsl(220 8% 55%);     /* metadata, timestamps, placeholders */
--text-muted:      hsl(220 6% 70%);     /* disabled, decorative */
--text-inverse:    hsl(220 14% 98%);    /* text on dark backgrounds */

/* In dark mode */
--text-primary:    hsl(220 14% 93%);
--text-secondary:  hsl(220 10% 65%);
--text-tertiary:   hsl(220 8% 45%);
--text-muted:      hsl(220 6% 30%);
```

Four levels. Always four. If you're reaching for a fifth, reconsider your hierarchy. If you're only using two, your interface is too flat.

---

## Semantic Colors

Semantic colors must work without color alone (pair with icons, labels):

```css
/* Success */
--semantic-success-bg:     hsl(142 76% 95%);
--semantic-success-border: hsl(142 76% 75%);
--semantic-success-text:   hsl(142 76% 28%);
--semantic-success-icon:   hsl(142 76% 38%);

/* Warning */
--semantic-warning-bg:     hsl(38 92% 95%);
--semantic-warning-border: hsl(38 92% 72%);
--semantic-warning-text:   hsl(38 92% 28%);
--semantic-warning-icon:   hsl(38 92% 40%);

/* Destructive / Error */
--semantic-error-bg:     hsl(0 84% 96%);
--semantic-error-border: hsl(0 84% 75%);
--semantic-error-text:   hsl(0 84% 30%);
--semantic-error-icon:   hsl(0 84% 40%);

/* Info / Neutral */
--semantic-info-bg:     hsl(214 89% 95%);
--semantic-info-border: hsl(214 89% 72%);
--semantic-info-text:   hsl(214 89% 28%);
--semantic-info-icon:   hsl(214 89% 40%);
```

In dark mode, desaturate semantic colors slightly — fully saturated status colors vibrate against dark surfaces.

---

## Sidebar Pattern

```css
/* WRONG: Different background for sidebar */
.sidebar { background: var(--surface-1); }
.canvas  { background: var(--surface-base); }

/* RIGHT: Same background, border separation */
.sidebar { background: var(--surface-base); border-right: 1px solid var(--border-subtle); }
.canvas  { background: var(--surface-base); }
```

Different backgrounds fragment the layout into "sidebar world" and "content world." A border is enough.

Exception: If the sidebar needs strong visual distinction (a navigation rail vs content), a 1-level elevation shift is acceptable. Never more.

---

## Input Treatment

```css
/* Input sits slightly "inset" — darker than its surrounding surface */
input {
  background: var(--surface-input);    /* slightly darker than card */
  border: 1px solid var(--border-default);
  color: var(--text-primary);
}

input:focus {
  border-color: var(--accent);
  outline: none;
  box-shadow: 0 0 0 2px color-mix(in srgb, var(--accent) 20%, transparent);
}

input::placeholder {
  color: var(--text-muted);
}
```

Never use `outline` for focus — use `box-shadow` for more control.

---

## Shadow Values (When Using Shadow Strategy)

```css
/* Subtle — barely there, just lifts card off canvas */
--shadow-sm: 0 1px 2px rgba(0,0,0,0.04), 0 1px 4px rgba(0,0,0,0.04);

/* Default — standard card elevation */
--shadow-md: 0 1px 3px rgba(0,0,0,0.06), 0 2px 8px rgba(0,0,0,0.06);

/* Raised — dropdowns, popovers */
--shadow-lg: 0 2px 6px rgba(0,0,0,0.08), 0 4px 16px rgba(0,0,0,0.08);

/* Floating — modals, overlays */
--shadow-xl: 0 4px 12px rgba(0,0,0,0.10), 0 8px 32px rgba(0,0,0,0.10);
```

Two layers per shadow: a tight tight ambient, and a spread diffusion. Increase both opacity values by 0.5x in dark mode — shadows are less visible on dark surfaces.

If you're using more than `--shadow-lg` for regular cards, you're doing too much.

---

## Dark Mode Implementation Pattern

```css
:root {
  color-scheme: light;
  --surface-base: hsl(220 14% 96%);
  --text-primary: hsl(220 14% 10%);
  /* ...all tokens */
}

[data-theme="dark"],
@media (prefers-color-scheme: dark) {
  :root {
    color-scheme: dark;
    --surface-base: hsl(220 14% 9%);
    --text-primary: hsl(220 14% 93%);
    /* ...all dark tokens */
  }
}
```

Don't use `filter: invert()` or `brightness()` hacks. Every token needs a real dark value.

---

## Custom Controls: Why Native Inputs Fail

```html
<!-- This cannot be styled consistently across browsers -->
<select>...</select>
<input type="date">
<input type="time">
```

Build custom:

```jsx
// Date picker: trigger button → calendar popover
// Select: trigger button → positioned dropdown list
// Time: trigger button → time picker popover
```

The trigger button looks like an input (same height, radius, border). The dropdown floats above using `position: absolute` or a portal. Style everything.
