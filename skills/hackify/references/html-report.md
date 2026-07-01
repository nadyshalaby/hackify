# HTML summary report

Phase 6 Step F emits a **visually styled, self-contained HTML report** so the developer can grasp what shipped at a glance — stats, charts, findings, and action items in one page. The report **augments** the Area/Change chat table (which still prints); it does not replace it.

Load this file from Phase 6 Step F. The template is [../assets/report-template.html](../assets/report-template.html).

## When

At Phase 6 Step F, after the Area/Change table is generated and the work is verified. One report per shipped task (finish options 1 and 2). Skipped for option 3 (pause) and option 4 (discard).

## Where

- **Full hackify** — write beside the archived work-doc: `<project>/docs/work/done/<slug>.report.html`.
- **quick / yolo** (no archived work-doc) — write `<project>/docs/work/reports/<YYYY-MM-DD>-<slug>.report.html` (create the `reports/` dir if absent).

After writing, tell the user the path and offer to open it.

## The stat set

Compute each from git + the work-doc. Show `0` / "none" honestly when a value is empty — never fabricate.

| Stat | Source |
|---|---|
| Tasks done (n / total) | Count ticked vs total Sprint Backlog checkboxes. |
| Files changed | `git diff --stat <base>..HEAD` file count (or `--staged` / working tree for quick/yolo pre-commit). |
| LOC added / removed | `git diff --numstat <base>..HEAD` summed. |
| Commits | `git rev-list --count <base>..HEAD`. |
| Findings by severity | Phase 5 decision table: Critical / Important / Minor counts + how many fixed. |
| Phase timeline | Which phases ran (1 → 6) and each one's outcome. |
| Action items / follow-ups | The work-doc Retrospective follow-up bullets + any deferred-with-sign-off items. |
| Next steps / instructions | Anything the developer must know or do after this (env vars, migrations to run, manual steps). |

## Charts — inline SVG only

Charts are hand-emitted **inline SVG** so the file stays self-contained. No charting library, no JS required:

- **Severity chart** — a small donut or horizontal bar of Critical / Important / Minor (fixed vs open).
- **Files + LOC bar** — added (green) vs removed (red) magnitude.
- **Phase timeline strip** — six pills (Clarify → Finish), each marked done / skipped.

## Filling the template

1. Copy [../assets/report-template.html](../assets/report-template.html).
2. Replace every `{{TOKEN}}` with computed content. Token map:
   - `{{TITLE}}`, `{{SLUG}}`, `{{GENERATED_AT}}` (ISO date-time), `{{SPRINT_GOAL}}`
   - `{{STAT_TASKS}}`, `{{STAT_FILES}}`, `{{STAT_LOC_ADD}}`, `{{STAT_LOC_DEL}}`, `{{STAT_COMMITS}}`
   - `{{SEVERITY_CHART_SVG}}` — the inline `<svg>…</svg>` markup
   - `{{PHASE_TIMELINE}}` — the six phase pills
   - `{{FINDINGS_TABLE}}` — `<tr>` rows: finding / severity / decision / evidence
   - `{{ACTION_ITEMS}}` — `<li>` items (or an empty-state line)
   - `{{AREA_CHANGE_TABLE}}` — the same rows as the chat Area/Change table
   - `{{NEXT_STEPS}}` — instructions the developer must act on (or an empty-state line)
3. Write the filled file to the path above.

## Hard rules

- **Self-contained.** Inline CSS + inline SVG only. No external `<script src>`, no `<link href>` to a CDN, no web-font fetch, no remote image. The file must render fully offline.
- **No leaked paths / tokens.** Never embed absolute home-directory filesystem paths or personal handles in the report — use project-relative paths.
- **Honest empties.** Zero findings, zero follow-ups → render a clear "none" state, not a fabricated row.

## See also

- [finish.md](finish.md) — Phase 6 Step F, where this runs, and the Area/Change table it augments.
- [../assets/report-template.html](../assets/report-template.html) — the template.
