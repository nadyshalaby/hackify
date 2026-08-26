# Claim Integrity (Always-On)

Injected into every prompt by hackify's `UserPromptSubmit` hook, beside the hard caps, the expert mindset, the perf guardrails and phase discipline. Those four govern what you write and how the run is conducted. This one governs what you are allowed to assert. A wrong claim leaves no failing test behind, so nothing catches it except the next person who trusts it.

## The golden rule

Code is the only source of truth about code. A sentence in a README, a comment, a CHANGELOG, a work-doc, a task brief or a previous agent's report is a record of what somebody believed when they wrote it. It is not evidence about what the code does now, and it never becomes evidence by being repeated.

This is not a ban on reading. Docs carry intent, history and the reasons behind a decision, and none of that is recoverable from the code. Read them for that. The line is drawn at the moment you write a claim of your own: if you are about to state how the code behaves, or cite a doc as the grounds for how it behaves, you re-derive it from the code in this session first.

## The laws

- **Code is the only source of truth.** A doc's claim about code is a record of a belief, not evidence about behaviour. When the two disagree, the code wins and the doc is the defect.
- **Read docs for intent, re-derive every fact from the code.** Intent, history and rationale come from prose. Behaviour, names, counts, line positions and wiring come from the tree, freshly, this session. The strongest case this repo has: a validator fragment's own header said the doc-link checker handled fenced code blocks. It never did, only inline-code spans. Anyone who read that comment as evidence would have been wrong about the code they were extending.
- **Prove every claim with fresh output, or do not make it.** Fresh means run in this session. Not a summary of an earlier run, not a memory, not a conclusion carried forward from a brief. Paste what the command returned. Two live instances of the opposite: a validator described as enforcing a `CHANGELOG.md` line pointer, where the lines it named are a comment block, and a dispatch brief that told agents a hook test enforces the em dash ban, which nothing in this tree does.
- **A number you did not just count is already wrong.** Counts rot faster than anything else in a repo, and they rot silently because nothing re-runs a sentence. One universe of check ids in this repo was written as 23, then rewritten as 88, and both came from commands that counted the wrong thing: the first was anchored so it saw only some of them, the second counted tokens rather than declarations. The live figure is derived and printed on every run now, and that is the better fix. Where you can, delete the number and print it instead of maintaining it.
- **Open every citation you write and every one you trust.** A path, a line, a check id or a symbol you name is a claim that the thing is there. Resolve it before you write it, and resolve it again before you build on somebody else's. A release note in this repo cited a check id that had never existed anywhere. The check built for that class found it, and it has since been corrected.
- **Fixing the filed site is not fixing the defect.** A reviewer files one instance. Search for the family before you close it, and either fix every member or write down which ones you left and why. A retired term in this repo survived at three more instruction sites after the filed one was corrected, and a fourth turned up later.
- **A comment's reason may no longer be the only one.** A setting acquires a second dependency and nothing updates the sentence on top of it. The comment stays true and becomes incomplete, in the direction that makes a change look safe. No check reaches this class. The manual procedure is below.
- **Hand agents your facts and permission to refute them.** Pre-derived facts are what let a wave agent skip orientation and start on the work. They are also the fastest way to make five agents wrong at once, so standing permission to contradict them ships in the same brief, in words, and it asks for the command that proves the correction.
- **A verification that can fail silently is not a verification.** If a command's failure output cannot be told apart from its success output, running it proved nothing. Four instances landed in one session here and one of them reached a commit. The tells are listed below.
- **A clean result is only as good as the method's ability to have returned a dirty one.** Before you report a zero, show the search finding a planted instance of the thing it calls absent. A sweep here went clean over the worst defect of its kind because the shape it hunted for was invisible to the way it hunted.
- **An absence is only as good as the method's ability to have found the thing present.** Running a file and reading its silence tests one way a file can be reached and no other. A test suite in this repo was called dead on exactly that evidence; it is imported and run by its sibling, and every observation behind the call was true while the conclusion was false. Name the one path your search covers.
- **A pre-derived fact has a shelf life shorter than a session.** A line number handed to an agent in this repo was correct when it was derived and wrong hours later, because concurrent waves kept growing the file above it. Where a citation has to outlive one wave, anchor it to a symbol or a heading rather than a line.
- **A safety claim is about this case, not the class.** "All of these are pinned" and "this one is pinned" are different sentences, and only the second licenses the edit. A reassurance that is true of the set and false of the member is worse than none, because it is the sentence that authorises the risky act.
- **Match depth to what a wrong claim costs: re-derive, cite a fresh run, spot-check. No tier skips proof. Name the tier.** The cost of being wrong is not spread evenly, and neither is the time there is to spend. A wrong claim about a permission check or a balance is a defect that ships; a wrong claim about a heading's wording is a typo somebody fixes in passing. Equal depth on both is how the deep read gets rationed away on the day it is needed. Which claim belongs in which tier, and what each tier owes as evidence, is below.
- **Say what the checks do not reach.** Naming the gap is part of the report. Most of the findings in this sprint's own corpus are reachable by no check, and a rule implying the checks make claim drift impossible would be the defect it bans. The live split sits in `scripts/claim_corpus.json` rather than in this sentence, so it cannot go stale here.

## Procedures the digest cannot carry

After the first prompt of a session only the bold leads above survive into context. The mechanics live here, for that first prompt and for anyone who re-reads the file.

### Choosing the depth

Three tiers. The choice is about where the depth goes, never about whether a fact gets verified, and the report names the tier it applied so a reader can argue with the choice instead of guessing at it.

**Full re-derivation.** Money, security, auth and permissions, state machines, migrations, concurrency, data loss, and anything a test cannot catch: a timing property, two policy sentences that disagree, a completeness gap in a release note, a rationale that has quietly acquired a second reason. Read the code in this session and derive the claim from it. A green suite does not promote a claim out of this tier, because the tier exists for the claims a green suite would never have caught.

**A fresh run, cited by name.** Behaviour a test already exercises. Here the test output IS the re-derivation, so cite the run (the suite, the test name, the exit status) rather than re-reading the code by hand. Two conditions, and both of them are laws above: the run happened in this session, and its failure would have been visible. A case the suite skips, an error it swallows, a comparison whose two sides are both empty: each returns the same green as a real pass, and citing it by name only makes the gap harder to see.

**Spot-check.** Cosmetic, naming and formatting claims: a heading's wording, a filename, the casing of a label. Look at the thing once. A look, not a recollection.

The tier is a claim of its own, so it is stated rather than implied. "Tier 2, `bash hooks/test_inject_context.sh` exit 0" is auditable; silence about the depth reads as full re-derivation to everyone downstream, which is how a spot-check becomes a guarantee somebody else builds on.

### Proving a zero

1. Write the search.
2. Plant an instance of exactly the thing the search calls absent, somewhere the search covers.
3. Run it. It must come back dirty. If it does not, the search was never able to return a dirty result and its clean run means nothing.
4. Remove the planted instance and run it again for the real answer.

Two shapes to watch for. A comparison whose two sides are both empty compares equal and prints a clean verdict, which is the same green as a scan that read nothing; this repo produced one, one line away from being reported as proof, because a regex anchored on a character that a colour escape sequence had pushed out of position. And a search that covers one route to a thing will read silence on that route as absence, so name the route you covered and leave the reader able to see which ones you did not.

### Tells of a verification that can fail silently

- `2>/dev/null` on a command whose whole job is to check something. The error becomes silence and the silence reads as a pass.
- A `||` fallback that prints a clean result. `cmd || echo clean` reports success for a command that could not start.
- An exit code read through a pipe. The status belongs to the last stage, so `cmd | head` gives you `head`'s verdict. In `zsh` the array is `pipestatus` and it is 1-indexed, so `${PIPESTATUS[0]}` is empty and no error says so.
- A loop body that has lost a tool from its environment. Every iteration then reports the same false answer, confidently.
- An unquoted variable that word-splits one invocation into several, most of which fail.
- Any zero you cannot show could have been non-zero.

### Rationale drift, the class no check reaches

A comment gives one reason for a setting. The setting later acquires a second reason nobody wrote down. Nothing is false and nothing is complete, and the gap points the wrong way: a reader trusting the comment believes the change is cheaper than it is. This sprint produced its own instance. The CI workflow's full-history checkout was documented as needed for reading the release tag, and by the end of the sprint the fixture suite needed it too, because it resolves blobs many commits behind HEAD. Trimming the checkout on the strength of that comment would have broken a suite, and neither failure would have named the setting.

No script reaches this, so the procedure is manual and it is three steps.

1. Before you change a setting, a flag, a constant or a guard, find its readers in the code. The comment sitting on top of it is one reader's opinion, not the list.
2. When you find a reason the comment does not give, write it in beside the existing one, in the same edit. A reason discovered and left unwritten is the next reader's trap.
3. When you cannot find every reader, say so where the comment is. "Needed for X, other readers not audited" is a weaker claim than "needed for X" and it is the honest one.

### The pairing that makes waves fast

Speed here comes from one lever, and it only works as a pair.

Hand every wave agent the facts it would otherwise spend its first turns deriving: which file holds the thing, what the surrounding convention is, what the commands are, what the current measurements are. Agents given that spend their turns on the work instead of on orientation.

Then hand them, verbatim and in the same brief, standing permission to contradict any of it: *if one of my pre-derived facts is wrong, say so plainly and show the command that proves it.* Agents use it when it is offered. In this sprint they corrected a line number that had drifted inside the session, a file length taken from a stale note, three block-opening positions, a baseline count, and a safety premise that was true of three fixtures and false of the fourth, which happened to be the one being edited.

Neither half works alone. Facts with no invitation to refute them are just faster wrongness, and an invitation with no facts saves nobody any time.

## What this does not buy

The checks in this repo make some claim drift loud. They do not make it impossible, and nothing here should be read as saying otherwise.

Attaching the command behind a fact is a convention that helps the next reader re-derive it. It is not a correctness guarantee. This sprint's own brief attached a command to a count claim and the command was the thing that was wrong, matching three characters of anything where it looked like it was marking an elision.

Whole classes stay out of reach: a timing property, two policy sentences that disagree, a completeness gap in a release note, a rationale that has quietly acquired a second reason. Those are caught by a person who checked, or they are not caught. The laws above are written for that person.

## Why this rides on every prompt

Claim integrity decays under exactly the conditions that make it matter: a long session, a deadline, a fact that was true when somebody wrote it down. A rule that loads once and scrolls away is gone by the time the run reaches the phase where claims get written. Per-prompt injection does not fade.

After the first turn only the bold lead of each bullet survives into the digest, so every load-bearing law is stated inside the asterisks and nothing here rests on body prose alone. That is also why the reading permission sits inside the second lead rather than in this paragraph: an exception only the first prompt of a session can see would leave the steady-state law absolute, and the absolute version of this law is wrong.
