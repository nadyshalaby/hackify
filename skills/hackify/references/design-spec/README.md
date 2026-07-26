# Design Spec (package index)

The producing half of hackify's design discipline. [frontend-design.md](../frontend-design.md) is the **law** (what good looks like, what never ships); this package is the **artifact** (a committed spec the code is written against and reviewed against).

Without a spec, design intent lives in a chat message and evaporates. Every later session re-derives taste from scratch, no reviewer can check compliance, and the product drifts. The spec makes the decision durable.

---

## The pipeline

```
Phase 1  Clarify      direction chosen or inherited          direction-library.md
   ↓
Phase 2  Plan         DESIGN.md named as a deliverable       spec-contract.md
   ↓                  (existing design? → extract-protocol.md)
Phase 3  Implement    code written against {token.ref}s      spec-contract.md
   ↓                  preview.html generated                 ../../assets/design-preview-template.html
   ↓
Phase 5  Review       Reviewer E audits diff vs spec         ../parallel-agents/phase-5-multi-review-e-design.md
   ↓
Phase 6  Finish       preview linked from the HTML report    ../html-report.md
```

Standalone entry point: `/hackify:designify` authors, refreshes, or extracts a spec without running a full task.

---

## Files

| File | What | Load when |
|---|---|---|
| [spec-contract.md](spec-contract.md) | The binding `DESIGN.md` anatomy: frontmatter token schema, `{token.ref}` syntax, the eleven prose sections, the web/native mapping table, authoring rules, validation checklist. | Authoring, refreshing, or auditing any spec. |
| [direction-library.md](direction-library.md) | Twelve visual directions with palette logic, type pairing, motion character, signature move, and anti-tells. The single canonical direction list. | Phase 1, when the direction is chosen or inherited. |
| [extract-protocol.md](extract-protocol.md) | Deriving a spec from existing code, a reference site, or screenshots. Plus REFRESH mode and the merge rules. | The design already exists somewhere. |
| [catalog/](catalog/README.md) | Twelve complete, original, ready-to-drop specs, one per direction. | Starting fresh, or needing a worked example of the contract. |

Related, outside this package:

| Path | What |
|---|---|
| `../frontend-design.md` | The visual law. Bans, musts, the quality gate. Loads this package. |
| `../../assets/design-preview-template.html` | Self-contained visual catalog. Fill with the spec's tokens. |
| `../parallel-agents/phase-5-multi-review-e-design.md` | Reviewer E, design conformance, standing lens on UI-bearing diffs. |
| `../../../../commands/designify.md` | `/hackify:designify`, author, refresh, or extract standalone. |

---

## Output contract

The spec lands in the **user's** project, not in the plugin:

```
<project>/docs/design/
  DESIGN.md        the spec
  preview.html     visual catalog, light + dark toggle
```

This mirrors the existing `<project>/docs/work/` convention: committed to git, visible to humans and to other tools, not hidden in agent-only storage.

One spec per product. Never author a second spec beside an existing one, refresh it (`extract-protocol.md`, REFRESH mode).

---

## When this package applies

Any task touching UI, styling, theming, layout, components, typography, color, spacing, icons, forms, motion, brand, RTL, responsive behavior, or visual polish, on web **or** native.

| Situation | What happens |
|---|---|
| Project has `docs/design/DESIGN.md` | Load it. Design within it. Its tokens are binding. |
| Project has tokens but no spec | Run `extract-protocol.md` Mode A, propose the recovered spec. |
| Project has neither, task is UI-bearing | Choose a direction in Phase 1, author the spec in Phase 2, before any component is written. |
| Task is a one-line copy or spacing fix | No spec needed. Honor the existing one if present. |

**The spec comes before the components.** Writing components first and extracting tokens afterwards produces a spec that documents accidents. Author the token layer, then build against it.

---

## The three rules that survive everything else

1. **One direction, committed.** Mixing directions produces a product with no point of view.
2. **Every value is a token.** A raw hex or bare pixel value in a component is the beginning of drift.
3. **The spec is the contract.** When code and spec disagree, one of them is a bug, decide which, in writing, and fix that one.
