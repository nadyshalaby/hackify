# Frontend Design — Visual Law

Load this file at Phase 1 (Clarify) for any task that touches **UI / styling / theming / layout / components / typography / colors / spacing / icons / forms / buttons / cards / modals / motion / brand / RTL / responsive / accessibility / visual polish**.

These rules are binding. They preserve the soul of a strict frontend-design discipline so visual work doesn't drift into generic AI aesthetics.

---

## The core directive

> **Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work — the key is intentionality, not intensity.**

Pick ONE direction. Commit. Don't mix.

> **Pick a direction and commit to it. Safe-average UI is usually worse than a strong, coherent aesthetic with a few bold choices.**

The point is not to be flashy. The point is to have a point of view.

---

## Hard bans (the AI-slop signals)

> **NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), clichéd color schemes (particularly purple gradients on white backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character.**

Concretely, NEVER ship:

- Inter, Roboto, Arial, or "system-ui" as the primary display font
- Purple → pink gradients on white backgrounds (the canonical AI-design cliché)
- Card piles with no hierarchy
- Flat, empty backgrounds
- Random accent colors with no system
- Motion scattered as decoration (hover effects on every element)
- Space Grotesk (it has converged into a cliché — was strong, now overused)
- Interchangeable SaaS hero sections

> **Interpret creatively and make unexpected choices that feel genuinely designed for the context. No design should be the same. Vary between light and dark themes, different fonts, different aesthetics. NEVER converge on common choices (Space Grotesk, for example) across generations.**

---

## Hard musts

> **Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter; opt instead for distinctive choices that elevate the frontend's aesthetics; unexpected, characterful font choices. Pair a distinctive display font with a refined body font.**

> **Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.**

> **Focus on high-impact moments: one well-orchestrated page load with staggered reveals (animation-delay) creates more delight than scattered micro-interactions. Use scroll-triggering and hover states that surprise.**

> **Create atmosphere and depth rather than defaulting to solid colors. Add contextual effects and textures that match the overall aesthetic.**

> **Match implementation complexity to the aesthetic vision. Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful attention to spacing, typography, and subtle details. Elegance comes from executing the vision well.**

> **Preserve the established design system when working inside an existing product.**

> **Keep accessibility and responsiveness intact; frontends should feel deliberate on desktop and mobile.**

---

## The design process — 4 phases (apply within hackify Phase 2 + 3)

### Frame the interface

Before writing CSS, settle:

- **Purpose** — what is this screen for, in one sentence?
- **Audience** — who will see it, in what context (mood, urgency, environment)?
- **Emotional tone** — calm / energetic / serious / playful / formal / industrial / luxurious?
- **Visual direction** — pick ONE from the tonal directions below; do not mix casually.
- **One thing the user remembers** — if they look away after 3 seconds, what stays?

### Tonal directions (pick one)

- **Brutally minimal** — pure forms, generous whitespace, monospace where used
- **Editorial** — magazine-grade typography, asymmetric grids, image as hero
- **Industrial** — engineered, technical, tabular numerics, signal colors
- **Luxury** — restrained, slow motion, refined kerning, subtle textures
- **Playful** — bold colors, irregular shapes, generous motion, expressive typography
- **Geometric** — modular, grid-honoring, mathematical proportions
- **Retro-futurist** — CRT glows, scanlines, monochrome amber, terminal aesthetics
- **Soft / organic** — rounded everything, gradients as atmosphere, breathing motion
- **Maximalist** — layered, dense, every surface earns its space, heavy motion

> **Do not mix directions casually. Choose one and execute it cleanly.**

### Build the visual system

Lock these as **CSS variables / Tailwind tokens** before painting any component:

- **Type hierarchy** — display, h1-h4, body, caption, mono. Specify font family, weight, size, line-height, letter-spacing for each. Pair a distinctive display with a refined body.
- **Color** — one dominant field (background + neutrals), one accent (signal), 1-2 supporting tones. Use logical names (`bg`, `surface`, `border`, `text-primary`, `text-muted`, `accent`, `accent-hover`) not hex names.
- **Spacing rhythm** — geometric or modular scale. 4px base or 8px base.
- **Layout logic** — grid? Asymmetric? Container queries? Logical properties (block-start / inline-start) for RTL?
- **Motion rules** — duration scale (75/150/300/500ms), ease curves (one curve for entry, one for exit), what gets animated (reveal? hover? scroll-triggered?).
- **Surface treatment** — borders, shadows, blur, noise, grain, mesh gradients. Pick a treatment vocabulary; apply consistently.

If working inside an existing product, inherit from the project's tokens. **Don't invent a new token system** — extend the one in `index.css` / `tailwind.config`.

### Compose with intention

- **Asymmetry** when it sharpens hierarchy
- **Overlap** for depth
- **Generous whitespace** for focus, dense composition for power
- **Break the grid** when composition demands it (sparingly, deliberately)

Symmetry is fine. But asymmetry, when chosen, says "this composition was thought about."

### Polish & deliver

The quality gate before saying "done":

- Does it have a clear visual point of view?
- Do typography and spacing feel intentional, not arbitrary?
- Do color and motion *support* the product (not decorate it)?
- Does it avoid reading like generic AI UI?
- Is the implementation production-grade (responsive, accessible, RTL-correct, performant)?

If any answer is "no", iterate.

---

## Stack-specific binding (example pattern)

If the project has a committed brand spec under `docs/`, treat it as the **committed direction** for the product. Design WITHIN it, never over it. The skill's role is to enforce visual quality *within* that direction.

A concrete example of what such a binding looks like in practice:

- **Direction:** Industrial precision (dark-mode canonical; muted neutrals + a single saturated signal accent like amber)
- **Typography:** A super-family that covers Latin, the project's primary non-Latin script (e.g. Arabic, CJK), and a matching monospace for tabular/code/numerics
  - **Forbidden alternatives** even when they "would be fine": Inter, Roboto, system fonts, Space Grotesk
- **Color system:** OKLCH-based palette, signal accent for the single high-attention moment per screen (CTA, alert, status indicator). Backgrounds are muted and engineered.
- **Numerics:** Tabular features on (`font-feature-settings: 'tnum'`) wherever numbers are compared or aligned
- **Direction-awareness:** RTL-first when the product is bilingual. Use **logical properties** (`margin-inline-start`, `padding-block-end`, `inset-inline-start`) — never `margin-left` / `right`. Test in the non-default direction first.
- **Tone:** Direct, technical, not decorative. No generic SaaS gradients, no purple, no playful flourishes.

If a task asks for "softer", "more colorful", or "more friendly", **flag it back to the user** before complying — this is a brand direction shift, not a styling tweak.

Adapt the pattern: read your project's brand spec (if any), extract its committed direction + typography + color system + accessibility constraints, and enforce them as binding for the work you're doing.

---

## When the user says "polish" or "redesign"

These words trigger the full design-process phases. Do not start touching CSS. In Phase 1 (Clarify), ask:

- What's wrong with the current state? (specific pain points)
- What's the *one thing* the redesign should make different?
- Does this stay within the existing brand direction? Or is this a brand direction shift? *(Default: stays within.)*
- Reference moods / screenshots / sites the user wants to evoke
- What CANNOT change? (existing components used by other features, brand tokens, typography)

In Phase 2 (Plan), the Approach section explicitly names:

- **The committed direction** (e.g., "Tighten the Industrial Precision direction; trim ornament; emphasize tabular hierarchy")
- **What stays** (token system, type family, accent color, RTL-first behavior)
- **What changes** (specific component-level shifts)
- **The quality gate** (the 5 questions above) — ticked at the end

For a UI redesign, the work-doc's DoD includes:

- Visual point of view sharpened (vs. before/after screenshot or description)
- No new generic-AI signals introduced (purple, gradients-on-white, Inter, Space Grotesk)
- Token system honored (no inline colors, no inline font families)
- Mobile + RTL (if bilingual) + dark mode tested manually (since visual-only changes default to manual smoke)
- Existing components in the path don't visually regress

---

## Reusable visual moments (pattern library, opinionated)

When the task needs one of these, here's a canonical treatment for an "industrial precision" direction (adapt to your direction):

- **Page-load reveal** — staggered `animation-delay` on hero elements (50ms increments, 6-12 elements max), fade + 4px slide. ONE such moment per page.
- **Empty state** — illustrative SVG (geometric, monochrome accent on neutral), one-sentence message, single primary CTA. Do not show 3 options.
- **Error state** — signal-accent bar (reserve red for destructive only). Inline, not modal.
- **Loading state** — skeleton with the actual layout structure, not a spinner. Spinners only for in-place buttons.
- **Modal** — overlay is solid neutral with 80% opacity, NOT blurred (blur is a generic-AI signal). Modal itself is bordered, not shadowed.
- **Form** — labels above inputs, ample spacing, error inline below the field. Submit at the bottom-right (LTR) / bottom-left (RTL — logical properties handle this).
- **Data table** — monospace for numerics, sans for text, sticky header, zebra OFF (signal-accent column borders or none), row hover with neutral surface shift not color.

---

## The "extraordinary work" reminder

> **Remember: Claude is capable of extraordinary creative work. Don't hold back, show what can truly be created when thinking outside the box and committing fully to a distinctive vision.**

For a committed Industrial Precision direction, "extraordinary" means: tabular discipline, surgical typography, signal-only color, motion as punctuation not decoration, RTL parity that *feels* native not translated. Not flashy — *committed*. The same principle applies to whichever tonal direction your project has chosen — execute it with conviction.

---

## What's safe to drop (covered by hackify core rules)

These design-skill items are already enforced elsewhere — don't repeat:

- File-size caps (covered by `code-rules.md`)
- Function/method caps (covered by `code-rules.md`)
- TypeScript strict mode (covered by `code-rules.md`)
- Accessibility *as a hygiene rule* (covered everywhere; the principle is preserved above as part of the quality gate)
- Performance basics (covered by `review-and-verify.md`)
