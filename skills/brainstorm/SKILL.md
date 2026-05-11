---
name: brainstorm
description: Socratic pre-task refinement skill for the hackify workflow. Runs an interactive idea-shaping conversation that asks 1 or 2 forking questions per turn (NOT a batched wizard), reflects what the user said before each next question, and graduates to full hackify Phase 1 the moment the user signals build intent. Auto-discovery triggers — invoke this skill when the user prompt contains any of `/brainstorm`, `let's discuss`, `let's think`, `what if`, `brainstorm`, or `explore the idea`, or when the hackify smart router routes the prompt to the brainstorm signal group. Locked contract — brainstorm runs WITHOUT a work-doc until graduation; no scratch files, no eager creation. At graduation, write a one-paragraph distillation, create the canonical work-doc at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` with a `## Brainstorm Provenance` block, then hand off to Phase 1 of `skills/hackify/SKILL.md`. Use this skill when the user is exploring an idea, not yet asking for a build.
---

# Brainstorm — Socratic pre-task refinement

Brainstorm is the idea-shaping front door to the hackify workflow. It runs ONE Socratic conversation — 1 or 2 forking questions per turn, reflection before each next question — until the user signals intent to build. At that signal, it writes a one-paragraph distillation, creates the canonical hackify work-doc with a Brainstorm Provenance block, and hands off to Phase 1 of `skills/hackify/SKILL.md`.

This skill is fully self-contained. **Never call other skills** mid-conversation — third-party plugins may not be installed. The graduation handoff is by name to `skills/hackify/SKILL.md` Phase 1; it does not depend on any other plugin.

---

## When to invoke

Auto-discovery fires this skill when the user's most recent prompt contains any of the following (case-insensitive substring match):

- `/brainstorm`
- `let's discuss`
- `let's think`
- `what if`
- `brainstorm`
- `explore the idea`

The hackify smart router (documented in `skills/hackify/SKILL.md` "Pre-flight: smart router — pick the right flow" → "Signal group (i) — Brainstorm triggers" and mirrored in `skills/quick/SKILL.md`) is the same set of phrases. The router and this skill's auto-discovery are coupled — if either path fires, brainstorm runs.

Do NOT invoke brainstorm when the user prompt already contains build-intent verbs (`add`, `implement`, `build`, `fix`, `refactor`, `ship`, `make this happen`) — those route directly to full hackify or quick. Brainstorm is strictly pre-task; it is not a discussion stage that runs after Phase 1.

---

## Workflow shape

Brainstorm runs an interactive Socratic loop until the user signals build intent. The loop has exactly three rules. Violating any rule is a workflow failure.

**Rule 1 — 1 or 2 questions per turn. Never more.** Brainstorm is NOT the Phase 1 Clarify wizard. Clarify batches 4 questions to lock requirements; brainstorm asks 1 or 2 questions to surface a real fork in the user's thinking. Plain prose questions in chat are the format — do NOT use the `AskUserQuestion` wizard tool here. The wizard belongs to Phase 1.

**Rule 2 — Every question must surface a real fork.** A real fork is a choice where the two branches lead to different builds, different acceptance criteria, or different user experiences. Vanity questions ("what do you want to call this?", "what color theme?") are forbidden at this stage — those go to Phase 1 Clarify after graduation. If you cannot name the fork the question opens, do not ask it.

**Rule 3 — Reflect before asking the next question.** Each turn begins with one sentence (≤25 words) that mirrors back what the user just said in their own framing. Then the next 1–2 questions. The reflection proves you read what they wrote and gives them a chance to correct a misread cheaply.

**Anti-loop guard.** If you have asked 3 or more questions in a row without the user offering new substantive information (their answers shrink to one-word affirmations, or they ask you for an opinion), surface the implicit graduation offer verbatim: *"Want me to write up what we have so far as a draft plan?"* If they say yes, graduate. If they decline, change tactic — propose a concrete option instead of asking another open-ended question.

**No work-doc during brainstorm.** Brainstorm runs WITHOUT a work-doc. The conversation transcript IS the state. Do NOT create `docs/work/.brainstorm-scratch.md`, `docs/work/.brainstorm-<slug>.md`, or any scratch path. Do NOT create the canonical work-doc until graduation fires. Lazy creation is locked.

---

## Graduation rule

Graduation fires when the user signals intent to build. The signal phrases (case-insensitive substring match against the user's most recent message) are:

- `let's build`
- `let's do this`
- `ship it`
- `OK make this happen` (and the case variant `make this happen`)
- An explicit task-shaped ask of the form "now add `<feature>`" / "now implement `<change>`" / "now fix `<bug>`"

On graduation, execute these three steps in order. Do not reorder. Do not skip.

**Step 1 — Distill.** Write a one-paragraph distillation (≤120 words) of what the brainstorm clarified. The paragraph names: the user's underlying goal, the chosen approach (the surviving fork branch), the constraints surfaced during the conversation, and any explicit non-goals. The distillation is for the future hackify Phase 1 reader — it must be self-contained enough that someone who did not see the brainstorm transcript can read the work-doc and understand the locked decisions.

**Step 2 — Create the work-doc.** Create the canonical hackify work-doc at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md` (date is today; slug is `kebab-case`, ≤6 words, derived from the distilled goal). Use the skeleton from `skills/hackify/references/work-doc-template.md`. Fill in frontmatter `slug`, `title`, `status: clarifying`, `type` (best-fit from `feature` | `fix` | `refactor` | `revamp` | `redesign` | `debug` | `research`), `created`, `project`. Insert a new H2 section titled `## Brainstorm Provenance` placed directly under the frontmatter and above `## Original Ask`. The Brainstorm Provenance block contains the one-paragraph distillation from Step 1 and nothing else.

**Step 3 — Hand off to hackify Phase 1.** End your turn with a single explicit handoff line: *"Brainstorm done — handing off to hackify Phase 1 (Clarify). Work-doc created at `<path>`."* Then invoke `skills/hackify/SKILL.md` Phase 1 — Clarify. You do NOT run Phase 1 yourself inside this skill. The handoff is the terminal action of brainstorm.

**Never create two work-docs.** If a work-doc already exists for the same slug, append a numeric suffix (`-2`, `-3`) to the slug. Never write to two paths in one graduation.

---

## Anti-rationalizations

These thoughts mean STOP and apply the listed reality.

| Thought | Reality |
|---|---|
| "I'll just create the work-doc now since we have enough" | Lazy creation is locked. No work-doc until a graduation signal fires. Eager creation forks state between transcript and disk. |
| "The user said something vaguely build-shaped, that's a graduation signal" | Graduation signals are the explicit phrase list in the Graduation rule. Vague build-shape is not on the list. Ask one more reflecting question instead. |
| "I'll ask 8 questions in one turn to save time" | Rule 1 caps at 2 questions per turn. The wizard format is for Phase 1, not brainstorm. Batched questions kill the Socratic reflection loop. |
| "Brainstorm can run *after* hackify Phase 1 if they want more discovery" | Brainstorm is strictly pre-task. Once Phase 1 runs, the discovery channel is the Clarify wizard. Re-entering brainstorm mid-flow is forbidden. |
| "I'll write a quick scratch file at `docs/work/.brainstorm-<slug>.md` to track ideas" | No scratch files. The transcript is the state. Scratch files violate the one-work-doc rule. |
| "The user asked me 3 questions back-to-back, I'll just answer and keep brainstorming" | The anti-loop guard fired. Surface the verbatim graduation offer: *"Want me to write up what we have so far as a draft plan?"* |
| "I'll ask a vanity question to keep the conversation warm" | Every question must surface a real fork. If you cannot name the fork, do not ask the question. Propose a concrete option instead. |

---

## File map

```
SKILL.md                                ← this file (the Socratic loop + graduation rule)
```

No reference files in v0.2.0. The skill is small by design — discovery, not build. Cross-references resolve at runtime against `skills/hackify/SKILL.md` (Phase 1, work-doc template path) and `skills/quick/SKILL.md` (smart router brainstorm signal group).

---

## One-line summary

Reflect → ask 1–2 forking questions → loop until the user signals build → distill → create the work-doc with a Brainstorm Provenance block → hand off to hackify Phase 1.
