#!/usr/bin/env python3
"""Fill the Phase 6 HTML report template from a small JSON payload.

The report used to be typed out by hand, every token, including the inline
SVG charts and every table row. Output tokens bill several times input, so
hand-writing ~5.5k tokens of markup was the most expensive single artifact in
a sprint. Everything in it is either derivable from git or a short piece of
prose, so the model now emits ~1.4k tokens of JSON and this script renders the
page.

    python3 <skill-dir>/scripts/render-report.py --data r.json --out <slug>.report.html

Two output modes, one render. --out writes the deliverable: a complete,
self-contained document that opens in a browser with no network. --artifact-out
is optional and writes the SAME page with no document shell of its own, no
<!doctype>, no <html>, <head> or <body>, because a page publisher supplies that
shell itself and expects page content only. The <title> and every <style> block
move into the content, which is valid HTML and renders identically; the title
stays first so a publisher that reads the head of the file for one still finds
it. Nothing about --out changes when --artifact-out is passed, and the file on
disk stays the deliverable on any runtime that cannot publish a page. Neither
output path is written through a symlink, whichever one is planted there.

Git-derived stats (files changed, LOC added/removed, commits) are computed
here when --base is given; anything the payload supplies explicitly wins, so a
quick run with no base SHA can pass them directly.

Payload shape (every key optional, missing values render as an honest zero or
an empty-state row, never as fabricated content):

    {
      "title": str, "slug": str, "generated_at": str, "sprint_goal": str,
      "plain_summary": str,
      "stats": {"tasks_done": int, "tasks_total": int, "files": int,
                "loc_add": int, "loc_del": int, "commits": int},
      "severity": {"critical": {"found": int, "fixed": int}, ...},
      "phases": [{"name": str, "state": "done"|"skipped"}],
      "findings": [{"finding": str, "severity": str, "decision": str,
                    "evidence": str}],
      "action_items": [str], "next_steps": [str],
      "update_log": [{"title": str, "problem": str, "root_cause": str,
                      "solution": str, "verification": str,
                      "deployment": str}],
      "evidence": [{"item": str, "claim": str, "ran": str,
                    "sample": str, "result": str}]
    }
"""

import argparse
import html
import json
import os
import re
import subprocess
import sys
from pathlib import Path

TEMPLATE = Path(__file__).resolve().parent.parent / "assets" / "report-template.html"
SEV_ORDER = ("critical", "important", "minor")
SEV_COLOR = {"critical": "#e5484d", "important": "#f5a524", "minor": "#8b8d98"}
# The five update-log field headings are fixed wording, they mirror the chat
# update log exactly and are never paraphrased.
LOG_FIELDS = (("problem", "Problem"), ("root_cause", "Root cause"),
              ("solution", "Solution"), ("verification", "Verification evidence"),
              ("deployment", "Deployment status"))


def esc(value):
    """HTML-escape any scalar. Payload text is untrusted prose, never markup."""
    if value is None:
        return ""
    return html.escape(str(value), quote=True)


def run_git(repo, args):
    """Return stdout for a git command, or None when git cannot answer."""
    try:
        out = subprocess.run(["git", "-C", str(repo)] + args,
                             capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    return out.stdout


def numstat_totals(text):
    """Sum added/removed/file-count from `git diff --numstat` output."""
    added = removed = files = 0
    for line in text.splitlines():
        parts = line.split("\t")
        if len(parts) != 3:
            continue
        files += 1
        if parts[0].isdigit():
            added += int(parts[0])
        if parts[1].isdigit():
            removed += int(parts[1])
    return {"files": files, "loc_add": added, "loc_del": removed}


def git_stats(repo, base, head):
    """Derive the diff stats the model would otherwise have to count by hand."""
    if not base:
        return {}
    diff = run_git(repo, ["diff", "--numstat", f"{base}..{head}"])
    if diff is None:
        return {}
    stats = numstat_totals(diff)
    count = run_git(repo, ["rev-list", "--count", f"{base}..{head}"])
    if count and count.strip().isdigit():
        stats["commits"] = int(count.strip())
    return stats


def severity_svg(severity):
    """Horizontal found-vs-fixed bars, inline so the page stays self-contained."""
    rows = [(name, int(severity.get(name, {}).get("found", 0) or 0),
             int(severity.get(name, {}).get("fixed", 0) or 0)) for name in SEV_ORDER]
    peak = max([found for _, found, _ in rows] + [1])
    parts = ['<svg viewBox="0 0 320 108" width="100%" role="img" '
             'aria-label="Findings by severity, found versus fixed">']
    for index, (name, found, fixed) in enumerate(rows):
        top = index * 34 + 10
        full = round(found / peak * 190) if found else 0
        done = round(fixed / peak * 190) if fixed else 0
        parts.append(f'<text x="0" y="{top + 12}" font-size="12" fill="currentColor">'
                     f'{name.title()}</text>')
        parts.append(f'<rect x="76" y="{top}" width="{full}" height="16" rx="3" '
                     f'fill="{SEV_COLOR[name]}" opacity="0.35"/>')
        parts.append(f'<rect x="76" y="{top}" width="{done}" height="16" rx="3" '
                     f'fill="{SEV_COLOR[name]}"/>')
        parts.append(f'<text x="{76 + max(full, 0) + 8}" y="{top + 12}" font-size="12" '
                     f'fill="currentColor">{fixed}/{found} fixed</text>')
    parts.append("</svg>")
    return "\n      ".join(parts)


def phase_pills(phases):
    """One pill per phase. An empty list is a real answer, not an error."""
    if not phases:
        return '<span class="pill skipped">no phases recorded</span>'
    pills = []
    for index, phase in enumerate(phases, start=1):
        state = "done" if str(phase.get("state", "")).lower() == "done" else "skipped"
        pills.append(f'<span class="pill {state}">{index} {esc(phase.get("name", ""))}</span>')
    return "".join(pills)


def findings_rows(findings):
    if not findings:
        return '<tr class="empty"><td colspan="4">None, the panel found nothing.</td></tr>'
    rows = []
    for item in findings:
        sev = str(item.get("severity", "minor")).lower()
        css = sev if sev in SEV_ORDER else "minor"
        rows.append(
            f'<tr><td>{esc(item.get("finding"))}</td>'
            f'<td><span class="sev {css}">{esc(item.get("severity"))}</span></td>'
            f'<td>{esc(item.get("decision"))}</td>'
            f'<td>{esc(item.get("evidence"))}</td></tr>')
    return "\n        ".join(rows)


def list_items(items, empty_text):
    if not items:
        return f'<li class="empty">{esc(empty_text)}</li>'
    return "\n      ".join(f"<li>{esc(entry)}</li>" for entry in items)


def one_update_section(entry):
    parts = ['<section class="update">']
    title = entry.get("title")
    if title:
        parts.append(f"<h3 class=\"update-title\">{esc(title)}</h3>")
    for key, heading in LOG_FIELDS:
        value = entry.get(key)
        if not value:
            continue
        parts.append(f"<h3>{heading}</h3><p>{esc(value)}</p>")
    parts.append("</section>")
    return "".join(parts)


def update_sections(entries):
    if not entries:
        return '<p class="empty">No update log recorded.</p>'
    return "\n    ".join(one_update_section(entry) for entry in entries)


def evidence_rows(rows):
    if not rows:
        return '<tr class="empty"><td colspan="5">No evidence ledger recorded.</td></tr>'
    out = []
    for row in rows:
        out.append(
            f'<tr><td>{esc(row.get("item"))}</td><td>{esc(row.get("claim"))}</td>'
            f'<td><code>{esc(row.get("ran"))}</code></td>'
            f'<td><code>{esc(row.get("sample"))}</code></td>'
            f'<td>{esc(row.get("result"))}</td></tr>')
    return "\n        ".join(out)


def stat_tokens(stats):
    """The five stat cards, every one of them escaped.

    THESE ARE NOT GIT-ONLY VALUES. main() lets the payload win over anything git
    derived, which html-report.md documents for quick runs, so each of
    these five is untrusted prose exactly like the rest of the payload. They were
    built with a bare str() until a reviewer put a script tag through
    stats.files and watched it land in the page, and the page is published to a
    shareable link now, so that was stored XSS rather than a local file.
    """
    done = esc(stats.get("tasks_done", 0))
    total = esc(stats.get("tasks_total", 0))
    return {
        "STAT_TASKS": f"{done} / {total}",
        "STAT_FILES": esc(stats.get("files", 0)),
        "STAT_LOC_ADD": esc(stats.get("loc_add", 0)),
        "STAT_LOC_DEL": esc(stats.get("loc_del", 0)),
        "STAT_COMMITS": esc(stats.get("commits", 0)),
    }


def build_tokens(data, stats):
    tokens = {
        "TITLE": esc(data.get("title", "Sprint report")),
        "SLUG": esc(data.get("slug", "")),
        "GENERATED_AT": esc(data.get("generated_at", "")),
        "SPRINT_GOAL": esc(data.get("sprint_goal", "")),
        "PLAIN_SUMMARY": esc(data.get("plain_summary", "")),
        "SEVERITY_CHART_SVG": severity_svg(data.get("severity", {})),
        "PHASE_TIMELINE": phase_pills(data.get("phases", [])),
        "FINDINGS_TABLE": findings_rows(data.get("findings", [])),
        "ACTION_ITEMS": list_items(data.get("action_items", []),
                                   "None, nothing outstanding."),
        "NEXT_STEPS": list_items(data.get("next_steps", []), "None, ready as-is."),
        "UPDATE_LOG": update_sections(data.get("update_log", [])),
        "EVIDENCE_APPENDIX": evidence_rows(data.get("evidence", [])),
    }
    tokens.update(stat_tokens(stats))
    return tokens


# The template documents each token in an HTML comment beside it. Those
# comments are notes for whoever edits the template; substituting into them
# would emit every block twice, so they are stripped before substitution.
DOC_COMMENT = re.compile(r"<!--(?:(?!-->).)*?\{\{[A-Z_]+\}\}(?:(?!-->).)*?-->", re.DOTALL)


def render(template_text, tokens):
    """Substitute every token, then refuse if the template still has one left."""
    out = DOC_COMMENT.sub("", template_text)
    for name, value in tokens.items():
        out = out.replace("{{" + name + "}}", value)
    leftover = sorted(set(re.findall(r"\{\{[A-Z_]+\}\}", out)))
    if leftover:
        raise SystemExit(f"render-report: template tokens left unfilled: {', '.join(leftover)}")
    return out


# The content-only mode lifts three pieces out of the rendered document and
# drops the shell around them. Matched on the rendered page, not the template,
# so the authoring comments are already gone by the time these run.
DOC_TITLE = re.compile(r"<title>.*?</title>", re.DOTALL | re.IGNORECASE)
DOC_STYLE = re.compile(r"<style>.*?</style>", re.DOTALL | re.IGNORECASE)
DOC_BODY = re.compile(r"<body[^>]*>(.*)</body>", re.DOTALL | re.IGNORECASE)


def content_only(page):
    """Same page, no document shell, for a publisher that supplies its own.

    Title first so a publisher scanning the head of the file for one finds it,
    then EVERY stylesheet in document order, then what was inside <body>. It
    refuses on absence and only on absence: a page with no title, no style block
    at all or no body would otherwise publish as a silently broken half page.
    A page carrying two style blocks is not broken, so it is carried whole rather
    than refused. DOC_STYLE is non-greedy and one search() took only the first,
    which dropped the second without a word.
    """
    title = DOC_TITLE.search(page)
    styles = [found.group(0) for found in DOC_STYLE.finditer(page)]
    body = DOC_BODY.search(page)
    if not (title and styles and body):
        raise SystemExit("render-report: the rendered page has no <title>, no <style> "
                         "or no <body> to lift into a content-only page")
    return "\n".join([title.group(0)] + styles + [body.group(1).strip(), ""])


def write_page(path, text, note=""):
    """Write one output file, refusing to follow a symlink at the destination.

    O_NOFOLLOW IS THE ENFORCEMENT, not a stat() first. Both output paths are
    predictable by design, so a stat-then-write would be a race an attacker on a
    shared host can win. write_text() follows a pre-existing symlink, which made
    a planted link an arbitrary file overwrite as whoever ran the render, and the
    link survived to be used again (CWE-59, CWE-377). The parent directory is
    still created when missing, and only the final component is protected.
    """
    out = Path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW
    try:
        handle = os.open(str(out), flags, 0o600)
    except OSError as err:
        raise SystemExit(f"render-report: refused to write {out} ({err.strerror}); a "
                         f"symlink at the destination is never followed")
    with os.fdopen(handle, "w", encoding="utf-8") as stream:
        stream.write(text)
    print(f"  ok   wrote {out} ({len(text)} bytes){note}")


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Fill the Phase 6 HTML report template.")
    parser.add_argument("--data", required=True, help="JSON payload path, or - for stdin")
    parser.add_argument("--out", required=True, help="where to write the report")
    parser.add_argument("--artifact-out", default="",
                        help="optional scratch path for the same page with no document "
                             "shell, ready for a publisher that supplies its own")
    parser.add_argument("--template", default=str(TEMPLATE))
    parser.add_argument("--repo", default=".")
    parser.add_argument("--base", default="", help="base SHA; enables git-derived stats")
    parser.add_argument("--head", default="HEAD")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    raw = sys.stdin.read() if args.data == "-" else Path(args.data).read_text()
    data = json.loads(raw)
    stats = dict(data.get("stats", {}))
    for key, value in git_stats(args.repo, args.base, args.head).items():
        stats.setdefault(key, value)
    text = Path(args.template).read_text()
    page = render(text, build_tokens(data, stats))
    write_page(args.out, page)
    if args.artifact_out:
        write_page(args.artifact_out, content_only(page), ", content only")
    return 0


if __name__ == "__main__":
    sys.exit(main())
