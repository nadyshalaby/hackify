# Direction Library

Twelve visual directions, each specified deeply enough to build from. This is the **single canonical direction list** for the plugin, [frontend-design.md](../frontend-design.md) defers here, and every `DESIGN.md` sets its `direction:` key to one of these slugs (or `custom` with a written rationale).

Pick ONE. Commit. The core law is unchanged: *a strong, coherent aesthetic with a few bold choices beats safe-average UI.* A direction is not decoration, it is the argument the interface makes about what matters.

**How to choose.** Read the product's job first, then the audience's state of mind. A tool people live inside all day wants a direction that gets quieter over time (`industrial-precision`, `nordic-calm`, `data-dense`). A surface people meet once wants one that lands immediately (`editorial-print`, `brutalist-mono`, `playful-pop`). When the user names a mood, map it here rather than inventing a thirteenth direction.

**Anti-tells** are the specific ways each direction gets built wrong. They matter more than the positive rules: every direction has a lazy version that reads as generic AI output, and the anti-tells name it so you can refuse it.

Every font named below is freely licensed and installable today. Follow the substitute rule in [spec-contract.md](spec-contract.md): pair the named face with a stack ending in a generic family, and never cite a webfont URL.

| Slug | Canonical mode | Reads as |
|---|---|---|
| `industrial-precision` | dark | engineered, exact, unsentimental |
| `editorial-print` | light | authored, considered, worth reading |
| `retro-terminal` | dark | direct, expert, no hand-holding |
| `warm-organic` | light | human, unhurried, safe |
| `brutalist-mono` | light | honest, loud, uninterested in charming you |
| `neo-luxury` | dark | scarce, slow, expensive |
| `swiss-grid` | light | rational, ordered, neutral |
| `data-dense` | dark | professional, information-first, earned |
| `playful-pop` | light | energetic, tactile, low-stakes |
| `nordic-calm` | light | quiet, focused, unbothered |
| `cyber-neon` | dark | charged, kinetic, after-hours |
| `soft-depth` | light | modern, layered, approachable |

---

## 1. Industrial Precision (`industrial-precision`)

> Instrumentation, not decoration. The interface behaves like a well-made tool.

**Feels like.** A machine you trust because nothing about it is trying to please you. Everything is aligned, measured, and legible under pressure. Calm at rest, unmissable when something needs attention.

**Palette logic.** A narrow band of cool near-blacks and greys carries every surface, separated by 1px hairlines rather than shadows. Exactly one saturated signal color (amber, signal orange, or sodium yellow) appears at most twice per screen and always means *act here* or *look here*. Semantic colors stay desaturated so the accent keeps its monopoly on attention.

**Surface & depth.** Borders do the work. Elevation is a change of surface value plus a hairline, not a blur. Level 3 exists only for modals.

**Type pairing.** Display `Archivo` (tight, engineered grotesque) · body `Public Sans` · mono `JetBrains Mono`. Numerics always run mono with `tnum` so columns align and digits never shift width.

**Motion.** Punctuation, never decoration. 150ms state changes, one 240ms orchestrated entry per view. Nothing bounces. Nothing parallaxes.

**Signature move.** Tabular discipline: every number in the product is monospaced, right-aligned, and vertically aligned with the number above it. It reads as competence before anyone can say why.

**Anti-tells.** Grey-on-grey with no accent at all (that is not restraint, that is nothing to look at). More than one signal color. Rounded corners above 8px. Drop shadows standing in for hierarchy. Decorative icons beside every label.

**Best for.** Developer tools, infrastructure dashboards, trading and ops consoles, B2B admin.

---

## 2. Editorial Print (`editorial-print`)

> The page came first. The interface is what a magazine would do if it could respond.

**Feels like.** Being handed something someone edited. Generous margins, a strong entry point, and type that carries the hierarchy without help from boxes.

**Palette logic.** Warm paper white as the field, near-black ink for text, and a single ink-adjacent accent (oxblood, deep teal, or bottle green) for links and rules. Color is scarce on purpose; the image and the headline carry the visual weight.

**Surface & depth.** Almost none. Rules and whitespace separate content. Cards are rare and, when used, are outlined rather than shadowed.

**Type pairing.** Display `Playfair Display` (high-contrast didone) · body `Source Serif 4` · mono `IBM Plex Mono`. Large size jumps between display and body: 4x or more, never a timid 1.5x.

**Motion.** Almost still. Content fades in on scroll at 420ms with no movement. Hover underlines draw from left. Nothing slides.

**Signature move.** The asymmetric opening: a headline set flush against a wide left margin, an image breaking the grid on one side, and a drop-cap or standfirst paragraph that establishes reading rhythm before the body begins.

**Anti-tells.** Centering everything (editorial is flush-left with a ragged right). Equal-weight three-column card grids. Sans-serif body text. A hero that is a gradient instead of an image. Justified text with rivers.

**Best for.** Publications, long-form documentation, research and essay sites, marketing for products that sell on ideas.

---

## 3. Retro Terminal (`retro-terminal`)

> The machine talks back in its own voice, and expects you to keep up.

**Feels like.** A console session in a dark room. Everything is text, everything is fast, and the interface assumes competence rather than explaining itself.

**Palette logic.** A near-black field with a slight color cast (blue-black or warm brown-black, never pure `#000`), one phosphor color as the near-universal foreground (amber, P1 green, or bone white), and a second phosphor used only for errors. Color is a signal, never a surface.

**Surface & depth.** Flat. Depth is implied by dimming: inactive regions drop to 40% foreground opacity. Optional very low-amplitude scanline or noise texture, never strong enough to hurt reading.

**Type pairing.** Everything monospaced. Display and body both `IBM Plex Mono`, size and weight carrying the entire hierarchy. Optionally `VT323` for a single large display moment.

**Motion.** Typewriter reveals on first paint only, a blinking block cursor, and instant state changes everywhere else. 75ms or nothing.

**Signature move.** A live status line pinned to one edge, always showing state (connection, mode, counts) in `KEY: value` pairs. The interface is never silent about what it is doing.

**Anti-tells.** CRT curvature and heavy glow (kitsch, not craft). Neon rainbow palettes. Proportional body text sneaking in. Rounded corners of any radius. Emoji.

**Best for.** Developer CLIs and their companion web UIs, self-hosted tooling, security and network products, hacker-audience side projects.

---

## 4. Warm Organic (`warm-organic`)

> Nothing here has a sharp edge, including the tone of voice.

**Feels like.** Something made by hand. Soft geometry, warm light, and pacing that never rushes the reader. It lowers the stakes of whatever the user is about to do.

**Palette logic.** Sand, clay, oat, and bone build the field; a muted terracotta or moss accent carries action. Nothing is fully saturated, nothing is pure white, and no color reads as cold. Semantic colors are shifted warm so even errors feel survivable.

**Surface & depth.** Soft and low: large radii, wide diffuse shadows at low opacity, surfaces that sit just barely above the canvas. Optional paper or linen grain at very low strength.

**Type pairing.** Display `Fraunces` (its soft and wonk axes are the point) · body `Karla` · mono `Martian Mono`. Line-height runs generous, 1.6 or more on body.

**Motion.** Breathing. 420ms entries with gentle overshoot, easing that decelerates slowly. Elements settle rather than snap.

**Signature move.** Radius that scales with the element: small controls at 8px, cards at 20px, and section containers at 32px or more, so the whole page reads as pebbles rather than boxes.

**Anti-tells.** Pastel purple and pink (the canonical AI-design cliché). Uniform radius everywhere. Cold greys mixed into a warm palette. Bouncy spring motion, which belongs to `playful-pop`. Illustration styles that fight the palette.

**Best for.** Health and wellness, community and education products, personal finance for non-experts, consumer mobile.

---

## 5. Brutalist Mono (`brutalist-mono`)

> The structure is the design. Nothing is hidden and nothing is softened.

**Feels like.** A poster. Raw material, visible construction, and a refusal to be charming. Confidence expressed as bluntness.

**Palette logic.** Paper white and true black do almost everything. One violent accent (electric blue, hazard red, acid green) appears in large flat areas rather than small details. No gradient, no tint ramp, no midtones.

**Surface & depth.** Zero radius, zero shadow. Depth comes from heavy 2px or 3px black borders and hard offset blocks. Elements overlap and clip deliberately.

**Type pairing.** Display `Syne` at its heaviest weight · body `Chivo` · mono `DM Mono`. Extreme scale contrast: display type at 5x body or more, often set to fill its container edge to edge.

**Motion.** Abrupt. Instant hovers, hard cuts, no easing curves that soften the change. When something moves it snaps.

**Signature move.** Type set so large it becomes the layout: a headline that spans the full viewport width, letter-spacing tightened until words nearly touch, with content flowing around it.

**Anti-tells.** Brutalism as an excuse for illegible contrast or broken accessibility. Random rotation applied to everything. Comic Sans irony. Any shadow at all. Cluttered "chaos" with no underlying grid, since real brutalism is rigorously gridded.

**Best for.** Portfolios, agencies, event and launch sites, music and culture products, anything whose job is to be remembered.

---

## 6. Neo-Luxury (`neo-luxury`)

> Restraint as the message. What is left out signals the value.

**Feels like.** A quiet room with one lit object. Slow, spacious, and confident that you will wait for it.

**Palette logic.** Near-black or deep charcoal field, a metallic-adjacent accent (champagne, brass, warm bronze) used at small scale only, and text in warm off-white. No pure white, no pure black, no saturated color anywhere.

**Surface & depth.** Depth by light rather than shadow: subtle vertical value gradients across large surfaces, hairlines at 10% opacity, and generous negative space carrying separation.

**Type pairing.** Display `Cormorant Garamond` at light weight and large size · body `Jost` · mono `Courier Prime`. Overlines are all-caps at small size with wide positive letter-spacing (0.15em or more).

**Motion.** Slow and few. 700ms fades, long easing curves, staggered reveals at 120ms intervals. Nothing ever moves quickly.

**Signature move.** The wide-tracked overline: a small all-caps label floating well above a large light-weight serif headline, with more vertical space between them than feels comfortable. That gap is the luxury.

**Anti-tells.** Gold gradients and metallic texture fills. Bold serif weights (weight reads as cheap here). Tight spacing. Fast transitions. More than one accent. Stock imagery of watches, marble, or skylines.

**Best for.** Premium commerce, hospitality and travel, private banking and wealth, high-end real estate, exclusive membership products.

---

## 7. Swiss Grid (`swiss-grid`)

> The International Typographic Style, applied honestly rather than quoted.

**Feels like.** Order. Every element sits where the grid says, hierarchy comes from size and weight alone, and nothing is placed by feel.

**Palette logic.** White field, black text, one primary accent (traditionally red, but any single saturated hue works if applied with the same discipline). Greys exist only as a value ramp for secondary text. Total palette: five roles or fewer.

**Surface & depth.** None. No shadows, no radii beyond 2px, no elevation. Structure is expressed by the grid, hairline rules, and alignment.

**Type pairing.** One family across the whole system: `Instrument Sans` at three weights. Mono `Anonymous Pro` for code and data. Flush left, ragged right, always.

**Motion.** Functional only. 150ms linear-ish transitions on state. No entrance animation. Motion that draws attention to itself is a failure.

**Signature move.** A visible, honored modular grid: 12 columns with a consistent gutter where content genuinely spans named column ranges, and asymmetric spans (5+7, 4+8) rather than lazy halves.

**Anti-tells.** Centered layouts. Mixed type families. Decorative accent color used as background wash. Rounded cards. Faux-Swiss that keeps the red square but ignores the grid underneath.

**Best for.** Institutional and government sites, universities, design systems documentation, professional services, anything that must read as neutral and authoritative.

---

## 8. Data Dense (`data-dense`)

> Maximum information per square inch, without becoming unreadable.

**Feels like.** A professional instrument. Small type, tight rows, and no wasted space, because the user's job is to compare many things at once.

**Palette logic.** Deep neutral field with two or three surface values for row banding and panel separation. Color is reserved almost entirely for **data encoding**: positive, negative, and a small categorical set. Chrome stays achromatic so the data is the only colored thing on screen.

**Surface & depth.** Hairlines and value shifts only. Panels are separated by 1px borders, never gaps. Sticky headers and frozen columns replace visual elevation.

**Type pairing.** `IBM Plex Sans` for labels and chrome, `IBM Plex Mono` with `tnum` for every figure. Body sizes run small (12-14px) with tight line-height (1.35) and the type must stay crisp at that size.

**Motion.** Nearly none. Sorting and filtering apply instantly. The only animation permitted is a 75ms row-highlight on hover and a brief flash on a value that just changed.

**Signature move.** The comparison-ready table: monospaced right-aligned figures, a subtle in-cell bar or sparkline encoding magnitude, sticky header, no zebra striping, and hover that shifts surface value rather than color.

**Anti-tells.** Generous padding (it destroys the density that justifies this direction). Card grids where a table belongs. Decorative color on chrome. Pagination that hides the comparison. Charts with more color than data series.

**Best for.** Analytics platforms, trading and risk tools, observability, logistics and inventory, admin consoles for power users.

---

## 9. Playful Pop (`playful-pop`)

> Tactile, saturated, and unafraid to be fun. Every interaction rewards the tap.

**Feels like.** Something you want to poke. Chunky shapes, confident color, and motion with real physics behind it.

**Palette logic.** Two or three saturated hues used at full strength across large areas, plus a near-black for text. Color blocks rather than tints. The palette is loud but finite: three hues maximum, applied consistently to the same meanings.

**Surface & depth.** Chunky and physical: large radii, thick borders or hard offset shadows in a contrasting hue, and elements that look like they have mass.

**Type pairing.** Display `Bricolage Grotesque` (its variable width and optical axes carry the personality) · body `Outfit` · mono `Azeret Mono`. Heavy weights, tight tracking on display.

**Motion.** Springy and physical. Spring curves with visible overshoot, press states that scale down to 0.96, and elements that settle after arriving. Haptics on native.

**Signature move.** The press response: every interactive element visibly compresses and rebounds on touch, with a hard offset shadow that shortens as the element is pushed down. The UI feels physically clickable.

**Anti-tells.** Rainbow gradients. Emoji doing the work color and shape should do. Bounce applied to page transitions rather than interactions. More than three hues. Cutesy illustration masking an unclear layout.

**Best for.** Consumer mobile apps, kids and education, games and community, habit and fitness tracking, social products.

---

## 10. Nordic Calm (`nordic-calm`)

> The interface gets out of the way and stays out of the way.

**Feels like.** A clean desk in good light. Cool, quiet, and almost colorless, so the user's own content becomes the only thing with presence.

**Palette logic.** Cool off-whites and desaturated grey-blues, text in a soft near-black that never reaches pure black, and an accent so muted it barely registers as color (dusty blue, sage, slate). The accent appears once per view at most.

**Surface & depth.** Barely there. Hairlines at low opacity, shadows so soft they read as light rather than depth, and large amounts of whitespace doing the separating.

**Type pairing.** `Hanken Grotesk` for both display and body at contrasting weights and sizes; mono `Geist Mono`. Line-height 1.6 or more, measure capped near 68 characters.

**Motion.** Slow and soft. 300ms fades, no transforms beyond a 2-4px settle, and a strong preference for cross-fades over movement.

**Signature move.** Whitespace as the primary structural device: sections separated by 96px or more of nothing, with no rule, no card, and no background change marking the boundary. Silence does the work.

**Anti-tells.** Adding a second accent "for variety" (it breaks the whole premise). Cards with visible borders and shadows. Dense information layouts. Warm colors. Any element competing with the user's content.

**Best for.** Writing and note tools, focus and productivity apps, meditation, reading applications, portfolio sites for photographers.

---

## 11. Cyber Neon (`cyber-neon`)

> Charged, technical, and lit from within. Night-shift energy.

**Feels like.** A control surface running in the dark. High-contrast, slightly aggressive geometry, and light that appears to come from the elements themselves.

**Palette logic.** Deep indigo-black or blue-black field, one electric primary (cyan, ultraviolet, or acid magenta) and at most one secondary, both used as **light sources**: thin glowing borders, small filled indicators, and text highlights. Never as large flat fills, and never blended into a gradient wash.

**Surface & depth.** Glow as elevation: raised surfaces carry a faint colored outer glow and a brighter 1px border. Angled corner cuts rather than radii on key containers. Optional fine grid overlay at very low opacity.

**Type pairing.** Display `Chakra Petch` (its angular cuts match the geometry) · body `Sora` · mono `Fira Code`. Wide tracking on all-caps labels, tight on display.

**Motion.** Kinetic and precise. 150ms transitions, scanning or sweeping highlights on load, pulse animations on live indicators. Motion suggests a system that is running.

**Signature move.** The lit edge: a 1px border in the primary hue with a soft matching glow behind it, applied to whichever element is currently active. Focus is expressed as illumination.

**Anti-tells.** Purple-to-pink gradient backgrounds (the exact AI-design cliché this direction is closest to and must avoid). Glow on every element at once, which flattens the hierarchy it exists to create. Illegible low-contrast body text. Glitch effects applied decoratively.

**Best for.** Gaming and esports, streaming and creator tools, crypto and trading, cybersecurity, developer products with attitude.

---

## 12. Soft Depth (`soft-depth`)

> Layered, light, and modern, achieved with restraint rather than effects.

**Feels like.** Panes of frosted glass stacked in daylight. Clear hierarchy through layering, with a friendly rather than technical tone.

**Palette logic.** A very light neutral field with a barely-perceptible cool or warm tint, surfaces slightly lighter than the canvas, and one confident accent used for primary action and active state. Tints of the accent at 8-12% opacity carry selected and hover states.

**Surface & depth.** The whole point: three clear layers (canvas, surface, raised) distinguished by value, a soft large-radius shadow, and a 1px light border on top edges to suggest a lit surface. Translucency only where something meaningful sits behind it.

**Type pairing.** `General Sans` across display and body at contrasting weights; mono `Spline Sans Mono`. Comfortable sizes, moderate line-height, nothing extreme.

**Motion.** Smooth and unhurried. 240ms transitions on a decelerating curve, layered elements entering with a 4px rise and a fade, and staggered list reveals at 40ms intervals.

**Signature move.** The lit top edge: every raised surface carries a 1px highlight border on its upper edge and a soft wide shadow below, so layers read as physically stacked without any blur effect doing the work.

**Anti-tells.** Heavy backdrop blur everywhere (a generic-AI signal and a performance problem). Purple gradients. Shadow so strong the layers detach. Four or more layers, at which point the hierarchy stops being readable. Glassmorphism applied to elements with nothing behind them.

**Best for.** Consumer SaaS, onboarding and settings surfaces, cross-platform apps that must feel native on both, general-purpose product UI.
