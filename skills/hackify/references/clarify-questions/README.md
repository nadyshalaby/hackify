# Clarify — Per-Task-Type Question Banks (File Map)

Phase 1 builds **one batched questionnaire** drawn from the bank for the matched task type. This directory holds the canonical wizard contract plus one bank per task type. See [wizard-contract.md](wizard-contract.md) for the 4-section specification every bank conforms to.

| File | When Phase 1 loads it |
|---|---|
| [wizard-contract.md](wizard-contract.md) | Always — defines delivery format, composition rules, and the 4-section bank specification |
| [universal-preamble.md](universal-preamble.md) | Always — runs before any task-type bank to settle scope, worktree, tests, done-state |
| [feature.md](feature.md) | When the user is adding new behavior the system doesn't currently have |
| [fix.md](fix.md) | When the user is reporting broken behavior with a clear reproduction |
| [refactor.md](refactor.md) | When behavior should NOT change but structure should |
| [revamp-redesign.md](revamp-redesign.md) | When old behavior is being replaced — UI redesign, API redesign, subsystem replacement |
| [debug.md](debug.md) | When the user has a mystery with no reliable reproduction |
| [research.md](research.md) | When the user wants to explore an idea before committing to build it |
| [picking-and-combining.md](picking-and-combining.md) | Always — closing rules for picking and combining questions across banks |
