# Picking & combining questions

Closing rules applied across every bank after composition. Phase 1 loads this alongside [wizard-contract.md](wizard-contract.md) to keep the batched questionnaire tight.

- **Single source of ambiguity** → 1 question is enough. Don't pad to look thorough.
- **Multiple ambiguities of the same shape** → group into one numbered Issue with options.
- **Question whose answer is in CLAUDE.md** → don't ask it. (E.g. if the project's CLAUDE.md pins the package manager, don't ask.)
- **Question whose answer is in your codebase-exploration tool output or recent commits** → don't ask it. Confirm in the preamble ("I see the existing `invitations` table has no `expires_at` column…") and skip the question.

The point of the batch is to make Phase 1 **one round-trip**, not zero. If you have 10 things to ask, ask them — that's still one round-trip. If you have 3, ask 3.
