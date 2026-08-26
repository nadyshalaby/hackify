# Clarify, Per-Task-Type Question Banks (File Map)

Phase 1 builds **one batched questionnaire** drawn from the bank for the matched task type. This directory holds the canonical wizard contract, one bank per task type, and the shared domain facts the banks cite. See [wizard-contract.md](wizard-contract.md) for the 4-section specification every bank conforms to.

Every bank asks about the same four things beyond the logistics, in its own words: the shape working systems use for the domain the request touches, whether the expensive half of the request needs to exist, the business rule that has to be exactly right, and what the real numbers are. The mechanisms behind the first of those are shared data and live once, in [domain-mechanisms.md](domain-mechanisms.md).

| File | When Phase 1 loads it |
|---|---|
| [wizard-contract.md](wizard-contract.md) | Always, defines delivery format, composition rules, the honesty rule, how `(Recommended)` is chosen, and the 4-section bank specification |
| [domain-mechanisms.md](domain-mechanisms.md) | Whenever the request touches a domain it names. Reference data, not a bank: the mechanism behind each recommendation and the failure it prevents |
| [universal-preamble.md](universal-preamble.md) | Always, runs before any task-type bank to settle scope, worktree, tests, done-state |
| [feature.md](feature.md) | When the user is adding new behavior the system doesn't currently have |
| [fix.md](fix.md) | When the user is reporting broken behavior with a clear reproduction |
| [refactor.md](refactor.md) | When behavior should NOT change but structure should |
| [revamp-redesign.md](revamp-redesign.md) | When old behavior is being replaced. UI redesign, API redesign, subsystem replacement |
| [debug.md](debug.md) | When the user has a mystery with no reliable reproduction |
| [research.md](research.md) | When the user wants to explore an idea before committing to build it |
| [picking-and-combining.md](picking-and-combining.md) | Always, closing rules for picking and combining questions across banks |
