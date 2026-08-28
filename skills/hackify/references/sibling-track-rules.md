# Sibling-track rules

`hackify:implementer` loads this file ONLY when its `{{sibling_tracks}}` input names one or more
tracks, and it then applies every rule here ON TOP of the always-on contract in
[parallel-agents/phase-3-implementation.md](parallel-agents/phase-3-implementation.md). A SOLO
dispatch, a foundation wave, an assembly wave, a single-track round or a quick-mode change never
reads it, because every rule below exists for one situation: other agents are writing this same
working tree at this same moment. Applied to a solo dispatch these rules are wrong, and skipped on
a side-by-side one they cost a sibling its work.

Read it in full. It is not a summary of the contract and the contract is not a summary of it.

## The blind-sibling framing

`{{sibling_tracks}}` names the tracks being built RIGHT NOW in this same working tree. **You
cannot see them and they cannot see you.** There is no message you can send them, no lock you can
take, and no error either of you will get when one of you overwrites the other. The partition
comes from the Phase 2.5 contention analysis, which already extracted every shared file, every
generated sequence and every genuinely exclusive resource into the solo foundation wave that ran
first. **You are only safe because that extraction happened.** The moment one track writes outside
its allowlist the partition every sibling was dispatched under stops being true, retroactively,
for work that already happened.

The assembly wave that follows mounts what these tracks built and reconciles the seams they
described differently. Your report is its input.

## The shared surfaces are named, and they are not yours

`{{owned_elsewhere}}` lists the shared surfaces you may NOT write and who owns each: the schema,
the migrations, the error registry, route mounting, the job index. The foundation wave already
landed them. They are outside your allowlist for the same reason your siblings' folders are, and
`none` there means the dispatcher decided nothing is owned elsewhere, never that nothing is.

## Your own database, never the shared one

Create `{{database_name}}` for yourself. **Never touch the shared one**, and never run a
migration, a truncate or a reset against it: siblings hold it, and a concurrent truncate destroys
their run and yours. Your integration tests belong to you and run here.

This is the input whose absence is SILENT rather than loud. A track with no database of its own
runs its integration suite against the shared one, where a concurrent truncate destroys a
sibling's run and yours with no error at either end. So `{{database_name}}` is never inferred, and
a side-by-side dispatch that carried `none` there is a dispatch to refuse.

## Cross-module type errors are expected, and they are not yours

**BUILD AGAINST THE PLAN, NOT AGAINST LANDED CODE.** Your dependencies are being built right now
by agents you cannot talk to. Build against the interface your PLAN states. Type errors on imports
of things siblings are building are EXPECTED and are not yours. Any other type error IS yours.

The corollary is the one that costs the most when it is ignored: **NEVER INVENT A SYMBOL.** Every
name you use from outside your allowlist comes from exactly one of two places, the contract your
plan states, quoted, or a file you actually opened, cited `file:line`. Guessing a signature is the
most expensive single thing a blind agent does, because a guess that happens to compile is worse
than one that does not.

## A defect in shared code is REPORTED, not fixed

Outside your allowlist you write NOTHING: not a one-line import, not an obvious bug fix, not a
file that plainly should exist. If you need something outside it, WRITE YOUR CODE AS THOUGH IT
EXISTS and report exactly what you need, spelled as you imported it. A wrong import that is
reported is cheap. A file edited outside your allowlist may have silently destroyed a sibling's
work, and nothing will tell either of you.

**Report it, not fix it** is what keeps the partition true. One write outside the allowlist
falsifies, retroactively, the partition every sibling was dispatched under, including the part of
their run that already finished. A defect you find in shared code goes in item 8 of your handoff
report with its `file:line`, and it goes nowhere near your diff.

## Do NOT write the work-doc

Siblings append to it too, and an append has no lock, no merge and no error when a write is lost.
**Write `docs/work/<slug>.tracks/<track_id>.md` instead**, yours alone, and update it as each unit
goes green rather than once at the end, so a session that dies mid-track still says what you
finished. The parent merges it and owns every other line of that doc.

This replaces the always-on contract's instruction to append your own `## 6. Daily Updates` entry.
On a side-by-side dispatch you do not touch that section at all.

## Do NOT mount your own registrar

Route mounting, job registration, module wiring and anything else that edits a shared index is the
assembly wave's job, and it is on the `{{owned_elsewhere}}` list for that reason. Report what needs
mounting, with the exact signature and its dependencies, as item 4 of your handoff report. Do NOT
commit either; the parent commits the round.

## Never destroy working-tree state

**Never run `git checkout`, `git restore`, `git stash`, or anything else that discards
working-tree state.** A sibling's uncommitted work is in this same tree and those commands take it
with no warning and no recovery. Copy a file if you need a backup.

## Two extra VERIFICATION gates

Add both to the VERIFICATION script the always-on contract runs, before its `echo PASS`. Every
value pasted in from the prompt goes between QUOTED heredoc markers, for the reason that contract
argues at length: paste BETWEEN the markers, never onto the assignment line, and never turn `<<'`
into `<<`.

```bash
# (e) THE TRACK HAS ITS OWN DATABASE. Fill this with the `{{database_name}}` input as you received
# it, and leave the body EMPTY, the placeholder line deleted and both markers kept, when your
# prompt carried no such input at all, which is the case this refuses. An absent line reads as "no
# database was decided", and a track that decides one for itself is a track running against the
# shared harness a sibling is truncating while reporting PASS.
#
# `none` REFUSES HERE TOO, and it is the one value that arrives looking like a decision. It means
# the project's normal database, which on a side-by-side dispatch IS the shared one, so it is the
# dispatch this file's own "Your own database, never the shared one" refuses rather than a track
# with a database of its own. Left out of the pattern the gate printed PASS on it, exit 0.
own_db=$(cat <<'HACKIFY_DB_EOF'
<the database_name input as received; delete this line entirely if the input was absent>
HACKIFY_DB_EOF
)
case "$own_db" in
  ''|none|*'{{'*|*'<the database_name'*)
    echo "FAIL: no per-track database reached this track; refuse the dispatch"
    exit 1 ;;
esac

# (f) NO WORKING-TREE DESTROYER RAN. A sibling's uncommitted work is in this tree, so this is
# checked rather than promised.
if [ -n "$(git stash list 2>/dev/null)" ]; then
  echo "FAIL: a stash exists; a track must never stash a shared working tree"
  exit 1
fi
```

## The eight-item handoff report

**Your report is the input to the assembly wave**, so it is a handoff and not a summary. These
eight numbered sections are what that wave mounts from, and a section you leave out is a seam
nobody reconciles. They are produced IN ADDITION to everything the always-on contract's OUTPUT
skeleton already mandates, and gate output is pasted verbatim, never summarised, and excluded from
the word cap.

````
## 0. Acceptance ledger
One row per acceptance signal from the acceptance list you wrote before any code: the
signal, the `file:line` that satisfies it, and the name of the test that proves it. A row
missing either column is NOT done and says so in that row rather than in a footnote below
the table. The assembly wave reads this first, and it is the only place a track's own claim
of DONE can be checked without re-reading the whole module.

## 1. What I built
- `<absolute path>`, <what it does>, covers plan task <id>.

## 2. Gate output
(pasted, not summarised, one block per gate command)

## 3. Mutations taken
- <production line broken>, red named `<test name>` at `<file>:<line>`.

## 4. Registrar to mount
- Signature: `<exact signature>`; dependencies: <list>. NOT mounted by me.

## 5. Shared names I ASSUMED exist
- <table / column / error code / queue name>, spelled exactly as used.

## 6. Ambiguities I resolved by assumption
- <the ambiguity>, <what I assumed>, <what it would break if wrong>.

## 7. What I could NOT verify
- <stated as unverified, never smoothed into prose; "None." if none>

## 8. Defects found in existing code
- <file:line>, <what is wrong>, <inside my allowlist: fixed | outside it: reported only>
````

If a section has nothing to report, write `None.` on its own line, never go silent.

## Three extra self-review rows

Add these to the self-review table the always-on contract's OUTPUT skeleton defines. They are the
three rules above that nothing else in that table asks about.

````
| Own database used, shared one never touched | ✓ / ✗ |
| Nothing mounted, nothing committed, work-doc untouched | ✓ / ✗ |
| No `git checkout` / `restore` / `stash` | ✓ / ✗ |
````
