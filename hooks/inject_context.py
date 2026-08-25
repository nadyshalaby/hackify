#!/usr/bin/env python3
"""Session-aware always-on context injector for hackify's UserPromptSubmit hook.

Called by hooks/inject-context.sh with three environment variables:

    HACKIFY_RULES_FILE    path to the markdown rules file to inject
    HACKIFY_HOOK_STDIN    the raw JSON the harness wrote to the hook's stdin
    HACKIFY_REFRESH_EVERY how many prompts between full re-injections

Emits one JSON envelope on stdout and always exits 0. Every error path falls
back to injecting the FULL rules text, because a repeated injection merely
costs tokens while a dropped one costs the law.
"""

import json
import os
import re
import sys
import tempfile
import time

STATE_DIR_NAME = "hackify-ctx"
STATE_MAX_AGE_SECONDS = 7 * 24 * 60 * 60
UNSAFE_NAME = re.compile(r"[^A-Za-z0-9._-]")


def envelope(text):
    """Wrap injected context in the envelope the harness parses from stdout."""
    return json.dumps(
        {
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": text,
            }
        }
    )


def rules_title(body, path):
    """The document's own H1, used to name it in the pointer line."""
    for line in body.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return os.path.basename(path)


BULLET_LEAD = re.compile(r"^\s*(?:[-*]|\d+\.)\s+\*\*(.+?)\*\*(.*)$")
DIGEST_MAX_CHARS = 900
QUALIFIER_MAX_CHARS = 34


def qualifier(remainder):
    """The clause right after a bullet's bold lead, when the lead needs it.

    "40 lines" and "500 lines" are the same phrase without their subject, so a
    digest built from bold leads alone cannot tell a function cap from a file
    cap. Carry the short qualifying clause that follows, and only that: the
    text up to the first comma, semicolon or period, dropped when it is long
    enough to be an explanation rather than a subject.
    """
    clause = re.split(r"[,;.]", remainder.strip(), 1)[0].strip()
    if not clause or len(clause) > QUALIFIER_MAX_CHARS:
        return ""
    return " " + clause


def digest_of(body):
    """The document's own bolded bullet leads, in order, as a one-line digest.

    The pointer cannot assume the full injection is still visible: this harness
    summarises long conversations, and a summary can drop the turn that carried
    the text. So the pointer carries the irreducible core with it rather than
    only a reference to it. Derived from the file, never hardcoded, so the
    digest cannot drift away from the rules it stands in for.
    """
    leads = []
    for line in body.splitlines():
        match = BULLET_LEAD.match(line)
        if not match:
            continue
        lead = match.group(1).strip()
        # A lead that already ends in terminal punctuation is a whole statement
        # ("Bound every cache."); only a bare noun phrase ("<= 40 lines") is
        # missing the subject that tells it apart from its neighbour.
        if not lead.endswith((".", "!", "?")):
            lead += qualifier(match.group(2))
        lead = lead.strip().rstrip(".,;: ")
        if lead and lead not in leads:
            leads.append(lead)
    if not leads:
        return ""
    digest = ""
    for lead in leads:
        candidate = f"{digest}; {lead}" if digest else lead
        if len(candidate) > DIGEST_MAX_CHARS:
            return f"{digest}; ..."
        digest = candidate
    return digest


def pointer_text(body, path):
    """The cheap per-prompt reminder that replaces a full re-injection.

    Every always-on file emits its own pointer, so the wording AROUND the
    digest is paid for once per file per prompt while saying the same thing
    each time. That is why this sentence is kept to the four things a pointer
    cannot do without: which file, that it binds verbatim, its core, and where
    to re-read it.

    IT IS DELIBERATELY NOT HOISTED INTO ONE SHARED PREAMBLE. Emitting it from a
    single designated entry would delete the repetition outright, and it would
    also make that one entry's failure strip the binding statement and the
    recovery path from every other file's pointer. hooks.json lists each rules
    file as its OWN UserPromptSubmit entry, in its own process, precisely so one
    failure cannot reach the others; a sentence shared across them hands that
    property back for a saving that shortening the sentence already gets most
    of. Each pointer therefore stands alone, carrying its own title, its own
    digest and its own path, and borrowing nothing from a sibling entry.
    """
    title = rules_title(body, path)
    digest = digest_of(body)
    core = f" Core, still binding in full: {digest}." if digest else ""
    return (
        f"[hackify always-on] {title} is binding verbatim.{core} Re-read "
        f"{path} for any detail not in that list."
    )


def session_id_from(raw):
    """Pull session_id out of the harness payload, or '' when unavailable."""
    if not raw:
        return ""
    payload = json.loads(raw)
    if not isinstance(payload, dict):
        return ""
    value = payload.get("session_id") or ""
    return value if isinstance(value, str) else ""


def prune(state_dir, now):
    """Bound the state dir so counter files cannot accumulate forever."""
    for name in os.listdir(state_dir):
        stale_path = os.path.join(state_dir, name)
        if now - os.path.getmtime(stale_path) > STATE_MAX_AGE_SECONDS:
            os.remove(stale_path)


def bump_turn(session_id, rules_path):
    """Record and return this session's 1-based prompt count for one rules file."""
    state_dir = os.path.join(tempfile.gettempdir(), STATE_DIR_NAME)
    os.makedirs(state_dir, exist_ok=True)
    try:
        prune(state_dir, time.time())
    except OSError:
        # Pruning is opportunistic housekeeping. A racing session removing the
        # same file, or a read-only dir, must not cost us the injection.
        pass
    key = UNSAFE_NAME.sub("_", session_id)[:64]
    counter_path = os.path.join(
        state_dir, f"{key}.{UNSAFE_NAME.sub('_', os.path.basename(rules_path))}"
    )
    turn = 0
    if os.path.exists(counter_path):
        with open(counter_path, encoding="utf-8") as handle:
            turn = int(handle.read().strip() or 0)
    turn += 1
    with open(counter_path, "w", encoding="utf-8") as handle:
        handle.write(str(turn))
    return turn


def is_refresh_turn(turn, refresh_every):
    """Turn 1 always injects in full; so does every Nth turn after it."""
    if turn <= 1:
        return True
    return refresh_every > 0 and turn % refresh_every == 0


def resolve(rules_path, raw_stdin, refresh_every):
    """Decide between the full rules text and the one-line pointer."""
    with open(rules_path, encoding="utf-8") as handle:
        body = handle.read()
    try:
        session_id = session_id_from(raw_stdin)
        if not session_id:
            return body
        turn = bump_turn(session_id, rules_path)
    except (OSError, ValueError, json.JSONDecodeError):
        # No session identity or no writable state means we cannot tell a first
        # prompt from a fiftieth. Inject in full: costlier, never wrong.
        return body
    if is_refresh_turn(turn, refresh_every):
        return body
    # A pointer with nothing in it is a bare reference, and a summarised
    # conversation can leave a bare reference pointing at text that is gone.
    # A file this cannot digest gets the full body every prompt instead.
    if not digest_of(body):
        return body
    return pointer_text(body, rules_path)


def refresh_interval():
    """Read the refresh cadence, falling back to the documented default."""
    try:
        return int(os.environ.get("HACKIFY_REFRESH_EVERY", "25"))
    except ValueError:
        return 25


def main():
    rules_path = os.environ.get("HACKIFY_RULES_FILE", "")
    if not rules_path or not os.path.isfile(rules_path):
        return 0
    try:
        text = resolve(rules_path, os.environ.get("HACKIFY_HOOK_STDIN", ""), refresh_interval())
    except OSError:
        # The rules file became unreadable between the shell's check and ours.
        # Emit nothing and let the caller's degrade path try jq.
        return 1
    sys.stdout.write(envelope(text))
    return 0


if __name__ == "__main__":
    sys.exit(main())
