---
name: writing-skills
description: Authors NEW skills that conform to hackify's binding contracts — NOT a generic Claude Code skill creator. Produces SKILL.md files under skills/<slug>/ that pass every check the v0.2.0 validate-dod.sh harness runs against hackify-conformant skills. Enforces the 7-section sub-agent contract (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY / OUTPUT), the 4-section Wizard contract (SCENARIO / COMPOSITION / QUESTIONS / EXIT CRITERIA), the SKILL.md frontmatter schema, the name regex `^[a-z0-9-]{1,64}$`, the mandatory OUTPUT word-cap on every embedded sub-agent prompt, and Haiku-portability via zero soft-language tolerance in the body. Auto-discovery triggers — invoke when the user says `/writing-skills`, `author a hackify skill`, `create a new skill for hackify`, `make a hackify-style skill`, or `new hackify skill`. Self-validates every authored skill against the same 9-check checklist before declaring done; the meta-skill eats its own dog food. Explicit non-goal — does NOT author arbitrary Claude Code skills and does NOT replace the skill-creator plugin.
---

# Writing-Skills — author hackify-conformant skills

This is a META-SKILL — a skill that authors skills. Scope is narrow on purpose: every output is a NEW skill that lives under `skills/<slug>/SKILL.md` inside the hackify plugin tree and passes every structural check the v0.2.0 enforcement layer (`scripts/validate-dod.sh`) runs against hackify-conformant skills.

This skill is self-contained. It never calls other skills. The 9-check self-validation checklist below is the core deliverable behind every skill it produces — the checklist is what makes a freshly-authored skill safe to ship without a human structural pass.

## When to invoke

- **Slash command:** `/writing-skills`.
- **Phrase triggers** (case-insensitive substring match on the user prompt):
  - `author a hackify skill`
  - `create a new skill for hackify`
  - `make a hackify-style skill`
  - `new hackify skill`
- **Routed by full hackify** when the user prompt parses as "let's add a new skill to hackify that does X" — full hackify hands off to this meta-skill at Phase 2 (Plan), instead of drafting the skill inline.
- **Out of scope for this skill** — generic Claude Code skill authoring (use the `skill-creator` plugin), edits to skills that already exist (use full hackify directly on the existing file), and skill DELETION (manual `rm` + commit).

## Workflow shape

Iterative question-then-draft-then-validate loop. The skill runs exactly four steps, in order, and never writes the output file before step 4.

```
Step 1: Clarify (1-3 wizard questions)
Step 2: Draft (in working memory, never written)
Step 3: Self-validate (9-check list, blocking)
Step 4: Write (single Write call, only after Step 3 passes)
```

**Step 1 — Clarify.** Ask 1-3 questions via `AskUserQuestion`, drawn from this fixed bank:

- **Purpose.** What does the new skill DO? (one sentence; required.)
- **Trigger phrases.** Which user prompts auto-discover it? (3-6 substring triggers; required.)
- **Kept / skipped phases.** Workflow-variant skills (like `quick`) declare which hackify phases they keep and which they skip; non-workflow skills (like a single-purpose helper) answer "N/A". (optional; ask only when the skill is clearly a workflow variant.)
- **Artifact produced.** What does the skill write / print / dispatch? (one short noun phrase; required.)

Drop questions whose answers are already evident from the user's prompt. Never ask all four if the prompt already pins one.

**Step 2 — Draft.** Compose the SKILL.md in working memory ONLY. Required body sections, in this exact order:

1. `# <Slug> — <one-line title>`
2. `## When to invoke`
3. `## Workflow shape`
4. `## The 9-check self-validation checklist` (only when the authored skill itself authors other skills; otherwise omit — most skills do not need this section)
5. `## What this skill does NOT do`
6. `## Anti-rationalizations` (table with at least 4 rows)
7. `## File map`
8. `## One-line summary`

Additional H2 sections are allowed and encouraged when the skill needs them.

**Step 3 — Self-validate.** Run the 9-check list (next section) against the in-memory draft. If ANY check fails, loop back to Step 2 and revise. The output of Step 3 is a 9-row table of yes/no answers with one-line evidence each.

**Step 4 — Write.** Single `Write` call to `skills/<slug>/SKILL.md`. No incremental writes. No partial drafts on disk. After the write, run `grep -n '^## ' <path>` and `wc -l <path>` to confirm structure and size.

## The 9-check self-validation checklist

This is the core deliverable behind every produced skill. Run every check against the in-memory draft BEFORE the `Write` call. Every check is a binary yes/no — no fudge, no judgment calls.

1. **Frontmatter conformance.** Frontmatter is present, fenced by `---` lines top and bottom. `name:` matches the regex `^[a-z0-9-]{1,64}$` (kebab-case, no leading dash, no double dashes). `description:` is between 40 and 300 words inclusive.
2. **Auto-discovery triggers in description.** The `description:` field contains AT LEAST 3 distinct trigger phrases the harness can substring-match against a user prompt — slash command, phrase patterns, or both.
3. **Required body sections present in order.** H1 title followed by H2 sections `## When to invoke`, `## Workflow shape`, `## Anti-rationalizations`, and `## One-line summary` — in that order. Additional H2 sections are allowed BETWEEN those four, but the four anchors MUST appear in order.
4. **Sub-agent prompts conform to the 7-section contract.** Every embedded sub-agent prompt inside the skill body has all 7 sections — ROLE, INPUTS, OBJECTIVE, METHOD, VERIFICATION, SEVERITY (review/audit templates only — omitted entirely from build/research templates), OUTPUT. Each section header appears on its own line in the form `**SECTION-NAME**.` — the bold marker plus a literal trailing period, matching the canonical templates in `skills/hackify/references/parallel-agents.md`.
5. **Wizard prompts conform to the 4-section Wizard contract.** Every embedded wizard inside the skill body has all 4 sections — SCENARIO, COMPOSITION, QUESTIONS, EXIT CRITERIA — matching the canonical structure documented in `skills/hackify/references/clarify-questions.md`. Each QUESTIONS entry specifies text / header (≤12 chars) / options (A-D, option A suffixed ` (Recommended)`) / why-this-matters.
6. **Every OUTPUT word-cap is explicit.** Every sub-agent prompt's OUTPUT section names a word cap in the form `≤N words`. No implicit caps. No "keep it short." Cap appears at the top of the OUTPUT section.
7. **Zero soft-language outside Anti-rationalizations.** The body MUST contain zero matches for the banned-substring list. The exception is for clearly-marked Anti-rationalizations rows or labeled bad-pattern example callouts. Haiku-class models read these prompts; soft language defeats them.

   **Bad-pattern listing — banned substrings (the substrings here ARE the bans, listed verbatim for the grep checker):**

   ```
   if reasonable
   consider
   maybe
   try to
   usually
   as appropriate
   where possible
   generally
   often
   ```
8. **File size cap.** The SKILL.md file is ≤500 lines.
9. **Path conventions.** Cross-references inside the body use repo-rooted paths (`skills/<slug>/...`, `scripts/...`) or absolute paths injected via `{{placeholder}}`. Zero `~/.claude/...` references — hackify is self-contained and ships across multiple runtimes per v0.2.0.

If any check returns NO, the skill loops back to Step 2 and revises BEFORE attempting Step 4.

## What this skill does NOT do

- **Does NOT author generic Claude Code skills.** The output is hackify-conformant only — frontmatter schema, 7-section sub-agent contract, 4-section Wizard contract, mandatory body sections, and soft-language ban. For generic skill authoring, use the `skill-creator` plugin (separate, not bundled with hackify).
- **Does NOT replace the `skill-creator` plugin.** That plugin is a generic skill builder for any Claude Code installation. This meta-skill is hackify-specific and produces skills bound to hackify's contracts. The two are complementary, not substitutable.
- **Does NOT modify existing hackify skills.** Edits to existing skills go through full hackify directly on the target SKILL.md file — that path runs the Plan+Gate and Phase 5 multi-reviewer on a diff, which a meta-skill cannot replicate.
- **Does NOT author non-skill artifacts.** Reference files (`references/*.md`), command files (`commands/*.md`), eval harnesses (`evals/*.json`), and project-level CLAUDE.md files are NOT in scope. Author the SKILL.md first; add supporting files via full hackify in a separate task.

## Anti-rationalizations

These thoughts mean STOP and apply the listed reality. Every row below contains soft-language phrasing INSIDE the "Thought" column on purpose — it is the bad pattern being rejected.

| Thought | Reality |
|---|---|
| "It's faster to skip the self-validation just this once" | The 9-check list IS the deliverable. Skipping it ships a skill that fails the validate-dod.sh harness — that is a guaranteed re-roll, not a shortcut. |
| "The user said 'quick skill', so the checklist is optional" | The checklist is NEVER optional. `/hackify:quick` keeps Phase 4 verify for the same reason: cheap insurance the user did not ask for and would regret losing. |
| "9 checks is a lot, 4 is enough" | Each of the 9 checks catches a distinct failure mode documented in the v0.1.0 / v0.1.3 / v0.2.0 post-mortems. Removing checks reopens documented bugs. |
| "Self-validation isn't a real test, I can vibe it" | Self-validation is exactly the test the structural harness runs. Vibing it means shipping a skill that fails the harness — the harness does not vibe back. |
| "I'll write the file first and validate after, save a step" | The no-partial-write rule exists because a half-written SKILL.md on disk gets committed, indexed, and routed to. Validate in memory, write once. |
| "The skill is small, the 7-section contract is overkill" | The 7-section contract applies to every embedded sub-agent prompt regardless of skill size. A small skill with one sub-agent dispatch still needs all 7 sections in that dispatch. |

## File map

```
skills/writing-skills/
  SKILL.md                              <- this file (the meta-skill)
```

The meta-skill is single-file by design. Reference material it depends on lives in the canonical hackify tree and is read at dispatch time:

```
skills/hackify/SKILL.md                                  <- the full workflow this meta-skill produces variants of
skills/hackify/references/parallel-agents.md             <- 7-section sub-agent contract (binding)
skills/hackify/references/clarify-questions.md           <- 4-section Wizard contract (binding)
skills/quick/SKILL.md                                    <- structural exemplar for a workflow-variant skill
scripts/validate-dod.sh                                  <- v0.2.0 enforcement harness the 9 checks mirror
```

Read these at dispatch time. Do not inline-copy them into the produced skill — produced skills reference them by path, the same way `skills/quick/SKILL.md` does.

## One-line summary

Clarify 1-3 questions -> draft in memory -> run the 9-check self-validation -> single Write call. The meta-skill eats its own dog food; this very SKILL.md was authored against the same 9-check list it enforces.
