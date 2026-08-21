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

## Load rule (this is the point of the split)

The table above is the picker. **Read it, choose, then load only the chosen direction's profile** from `directions/<slug>.md`. Reading all twelve profiles to use one is the waste this layout exists to remove.

| Situation | What to load |
|---|---|
| The user named a direction, or the project's `DESIGN.md` already sets one | that one profile, `directions/<slug>.md` |
| Choosing from scratch | this table, then the 2-3 profiles the table's "Reads as" column shortlists, then commit |
| Auditing an existing spec for conformance | the profile it claims, plus `spec-contract.md` |

Each profile carries the same seven blocks: Feels like, Palette logic, Surface & depth, Type pairing, Motion, Signature move, **Anti-tells**, and Best for.

## The profiles

| Direction | Profile |
|---|---|
| `industrial-precision` | [directions/industrial-precision.md](directions/industrial-precision.md) |
| `editorial-print` | [directions/editorial-print.md](directions/editorial-print.md) |
| `retro-terminal` | [directions/retro-terminal.md](directions/retro-terminal.md) |
| `warm-organic` | [directions/warm-organic.md](directions/warm-organic.md) |
| `brutalist-mono` | [directions/brutalist-mono.md](directions/brutalist-mono.md) |
| `neo-luxury` | [directions/neo-luxury.md](directions/neo-luxury.md) |
| `swiss-grid` | [directions/swiss-grid.md](directions/swiss-grid.md) |
| `data-dense` | [directions/data-dense.md](directions/data-dense.md) |
| `playful-pop` | [directions/playful-pop.md](directions/playful-pop.md) |
| `nordic-calm` | [directions/nordic-calm.md](directions/nordic-calm.md) |
| `cyber-neon` | [directions/cyber-neon.md](directions/cyber-neon.md) |
| `soft-depth` | [directions/soft-depth.md](directions/soft-depth.md) |

Twelve ready-to-drop full `DESIGN.md` specs (a different, deeper artifact) live in [catalog/](catalog/).
