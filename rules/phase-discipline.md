# Phase Discipline (Always-On)

Injected into every prompt by hackify's `UserPromptSubmit` hook, beside the hard caps, the expert mindset and the perf guardrails. Those three govern what you write; this one governs how the run is conducted. A dropped phase and an unasked question leave no diff behind, so no code review ever catches them. The full contracts live in `skills/hackify/references/phase-ledger.md` and `skills/hackify/references/clarify-questions/wizard-contract.md`, both loaded on demand.

## The five laws

- **Every task that edits code opens the step ledger** unless it is trivial or read-only. One trackable ordered checklist, one item per phase, opened at task start in EVERY mode, re-printed at every phase boundary and at the end of every wave round inside a phase, because a phase that runs for hours across four rounds is exactly where the ledger goes quiet. Where the runtime exposes no todo-tracker tool (Claude Code frequently does not expose `TodoWrite`), print the block in chat, say once which substrate you are on, and keep the durable copy in the work-doc's `## 0. Phase ledger` section. It never silently disappears. The carve-outs are three and only three: trivial factual Q&A, a single-line typo fix, and pure read-only inspection that will not lead to an edit.
- **Phases run in order, one open at a time.** No later phase may start while an earlier one is still open. This is the refuse-to-advance law, and it is the whole point of keeping a ledger.
- **No phase is ever silently skipped.** A phase that genuinely does not apply is marked complete with a one-line reason, never deleted and never dropped in silence. This holds in every mode, the compressed ones included.
- **Every question goes through the wizard tool.** Any question, decision, approval or request for feedback put to the user goes through the wizard tool (`AskUserQuestion` on Claude Code). A plain numbered list in chat is forbidden. It binds in EVERY phase, plan sign-off, fix approvals, the finish menu and a mid-task fork alike, not only the clarify phase.
- **A tick with no reflection is an untrusted tick.** One line saying what changed and whether it passed, then flip the item, then open the next.

## Why this rides on every prompt

Phase discipline decays quietly. These rules used to live only in files that load once and then fade as the conversation grows, so by the time a run reached its longest phase, nothing in front of the model still said to keep the ledger or to ask through the wizard. Per-prompt injection does not fade. After the first turn only the bold lead of each bullet above survives into the digest, plus the short clause that follows it, which is why every load-bearing instruction is stated there and nothing rests on this paragraph alone. The scope carve-out rides in the first lead's clause for exactly that reason: an exception only the first prompt of a session can see would leave the steady-state law absolute.
