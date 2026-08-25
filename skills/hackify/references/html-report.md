# HTML summary report

Phase 6 Step F emits a **visually styled, self-contained HTML report** so the developer can grasp what shipped at a glance, stats, charts, findings, and action items in one page. The report **augments** the chat update log (which still prints); it does not replace it.

Load this file from Phase 6 Step F. The template is [../assets/report-template.html](../assets/report-template.html).

## When

At Phase 6 Step F, after the update log is generated and the work is verified. One report per shipped task (finish options 1 and 2). Skipped for option 3 (pause) and option 4 (discard).

## Where

- **Full hackify**, write it to the archive path the work-doc is about to take: `<project>/docs/work/done/<slug>.report.html`. Step F renders it before the doc itself is moved there, so the path exists first and the doc follows.
- **quick / yolo** (no archived work-doc), write `<project>/docs/work/reports/<YYYY-MM-DD>-<slug>.report.html` (create the `reports/` dir if absent).

After writing, tell the user the path and offer to open it. Where the runtime can publish a page, also publish it and give them the link, see **Publishing it as a link** below.

## The stat set

Compute each from git + the work-doc. Show `0` / "none" honestly when a value is empty, never fabricate.

| Stat | Source |
|---|---|
| Tasks done (n / total) | Count ticked vs total Sprint Backlog checkboxes. |
| Files changed | `git diff --stat <base>..HEAD -- . ':(exclude)docs/work/*'` file count (or `--staged` / working tree for quick/yolo pre-commit). |
| LOC added / removed | `git diff --numstat <base>..HEAD -- . ':(exclude)docs/work/*'` summed. |
| Commits | `git rev-list --count <base>..HEAD`. |
| Findings by severity | Phase 5 decision table: Critical / Important / Minor counts + how many fixed. |
| Phase timeline | Which phases ran (1 → 6) and each one's outcome. |
| Action items / follow-ups | The work-doc Retrospective follow-up bullets + any deferred-with-sign-off items. |
| Next steps / instructions | Anything the developer must know or do after this (env vars, migrations to run, manual steps). |

## Charts (inline SVG only)

Charts are emitted as **inline SVG** by the renderer so the file stays self-contained. No charting library, no JS required. The template carries exactly two chart tokens, and this list matches them:

- **Severity chart** (`{{SEVERITY_CHART_SVG}}`), horizontal found-vs-fixed bars for Critical / Important / Minor.
- **Phase timeline strip** (`{{PHASE_TIMELINE}}`), one pill per phase, each marked done / skipped.

Files changed and LOC added / removed are **stat cards, not a chart**. There is no token for a LOC bar and the renderer draws none; this page used to promise one.

## Plain-language summary + evidence appendix

Two blocks make the report readable by a non-technical person and cumulative, every claim has visible proof in one place. Both follow the B2 voice ([communication-voice.md](communication-voice.md)).

- **Top: "What changed & why it matters" (`{{PLAIN_SUMMARY}}`).** 3-6 short sentences, no jargon (define any term you must keep). State what the work delivers and why a reader should care, not how it was built. This sits directly under the header, above the stat cards, so it is the first thing anyone reads.
- **Bottom: Evidence appendix (`{{EVIDENCE_APPENDIX}}`).** The full Phase 4 Evidence Ledger rendered as table rows, every task and acceptance bullet with its claim, what was run, a trimmed proof sample, and the result. This is the cumulative proof: one place where a reader confirms each item truly landed.

Keep all existing technical blocks (stats, charts, findings, update log) between the two. Plain summary leads; technical detail follows; evidence appendix closes.

## Filling the template

**Do not hand-write the HTML.** Emit a JSON payload and let the renderer build the page:

```bash
python3 <skill-dir>/scripts/render-report.py \
  --data /tmp/report.json \
  --out <project>/docs/work/done/<slug>.report.html \
  --repo <project> --base <base-sha>
```

The script does the mechanical half: it derives files changed, LOC added and removed and commit count from `--base`, draws the severity chart as inline SVG, renders the phase pills and every table row, HTML-escapes all prose, strips the template's authoring comments, and refuses to write a page that still holds an unfilled token. You supply only what you alone know. Writing this markup by hand cost roughly 5.5k output tokens a report, which bills several times what input does; the payload is about a quarter of that.

Payload. Every key is optional, and a missing key renders an honest empty state rather than a fabricated row:

```json
{
  "title": "...", "slug": "...", "generated_at": "2026-08-22T10:00:00Z",
  "sprint_goal": "...",
  "plain_summary": "3-6 B2 sentences, what changed and why it matters",
  "stats": {"tasks_done": 5, "tasks_total": 5},
  "severity": {"critical":  {"found": 2, "fixed": 2},
               "important": {"found": 5, "fixed": 4},
               "minor":     {"found": 3, "fixed": 1}},
  "phases": [{"name": "Clarify", "state": "done"}],
  "findings": [{"finding": "...", "severity": "Critical",
                "decision": "fixed", "evidence": "path:line"}],
  "action_items": ["..."], "next_steps": ["..."],
  "update_log": [{"title": "...", "problem": "...", "root_cause": "...",
                  "solution": "...", "verification": "...",
                  "deployment": "..."}],
  "evidence": [{"item": "D1", "claim": "...", "ran": "...",
                "sample": "...", "result": "pass"}]
}
```

- **Anything in `stats` beats the git-derived value**, so quick and yolo can report a working-tree diff with no base SHA to diff against.
- **The five update-log headings are fixed wording** and the renderer emits them for you: Problem, Root cause, Solution, Verification evidence, Deployment status. They mirror the chat update log and are never paraphrased.
- **Escaping is the script's job.** Pass raw text. A commit subject carrying `&`, a type like `Promise<User>`, a proof sample with a stray `<`, all safe.

## Publishing it as a link (optional, never load-bearing)

A file path is something the user has to open by hand, and it is not something they can send to anyone. Where the runtime has a way to publish a page, Step F publishes the report as well and hands them a link. Where it does not, the file on disk is the whole deliverable and Step F behaves exactly as it did before. This is a native-tier enhancement in the sense [runtime-adapters.md](runtime-adapters.md) defines, so per-runtime support and the degrade path live in that file's "Native-tier enhancements" tables, and **no phase may hard-require it**. Publishing is never a precondition for closing ledger item `6d`: its exit artifact is the printed update log plus the rendered file, and a runtime that cannot publish still finishes the sprint.

**The renderer has a second output mode for it,** because a page publisher supplies its own `<!doctype>`, `<head>` and `<body>` and expects page content only, so the standalone document cannot be published as authored. Pass `--artifact-out` alongside the usual `--out`:

```bash
python3 <skill-dir>/scripts/render-report.py \
  --data /tmp/report.json \
  --out <project>/docs/work/done/<slug>.report.html \
  --artifact-out "$(mktemp -d)/<slug>.report.body.html" \
  --repo <project> --base <base-sha>
```

- **`--out` is unchanged.** It still writes the complete, self-contained document that opens in a browser with no network. That file is the deliverable and the thing every non-publishing runtime gets.
- **`--artifact-out` is scratch, not a second deliverable.** One render, two writes, so the two files cannot drift. Keep it out of `docs/work/done/`, which holds exactly one HTML file per sprint; a second one there is clutter in the shipped tree. (Step C.5 has nothing to say about it either way: that sweep runs before Step F and already excludes `docs/work/*`.)
- **Give it a fresh directory per run, never a fixed name in the shared temp directory.** `$(mktemp -d)` makes a private directory nobody can guess. A predictable path in a world-writable directory is one another user can pre-fill with a symlink, and a writer that followed it would overwrite whatever it points at (CWE-59, CWE-377). The renderer refuses to write through a symlink at either output path, so the worst case is a refusal rather than a clobber, and an unguessable directory means it never comes up.
- **The content-only copy keeps its `<title>`.** A publisher reads the head of the file for one and uses it to name the page, so the title stays first, ahead of the stylesheet and the page content.
- **The page must stay self-contained either way.** Publishers block requests to other hosts, so the no-CDN, no-web-font, no-remote-image rule below is load-bearing twice over now: once for the offline file, once for the published page.
- **Publish, then say the link out loud.** The user asked for something they can send someone, so the link belongs in the chat message, not only in a tool result.

## Hard rules

- **Self-contained.** Inline CSS + inline SVG only. No external `<script src>`, no `<link href>` to a CDN, no web-font fetch, no remote image. The file must render fully offline, and a published copy must render with every request to another host blocked.
- **Readable in both themes.** The template defines its light palette on bare `:root` and repeats the dark one under a guarded `@media (prefers-color-scheme: dark)` block and under `:root[data-theme="dark"]`, because a viewer's theme has three states and the published page inherits whichever one they are in. Add a color as a token in all three places or not at all.
- **No leaked paths / tokens.** Never embed absolute home-directory filesystem paths or personal handles in the report, use project-relative paths.
- **Honest empties.** Zero findings, zero follow-ups → render a clear "none" state, not a fabricated row.

## See also

- [finish.md](finish.md). Phase 6 Step F, where this runs, and the update log it augments.
- [../assets/report-template.html](../assets/report-template.html), the template.
