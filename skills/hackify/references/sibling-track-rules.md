# Sibling-track rules

`hackify:implementer` loads this file ONLY when its `{{sibling_tracks}}` input names one or more
tracks, and it then applies every rule here ON TOP of the always-on contract in
[parallel-agents/phase-3-implementation.md](parallel-agents/phase-3-implementation.md). A SOLO
dispatch never reads it: a foundation wave, an assembly wave, a testing stage that runs as one
wave, a single-track round, or a quick-mode change that goes out as one wave. **A testing stage
that SPLITS is not on that list**: it splits under the same partition test as every other stage
([contention-dispatch.md](contention-dispatch.md)), its waves write the tree at the same moment
as each other, and each is handed the other testing waves' IDs and reads this file exactly as a
module track does.

**A concurrent quick dispatch DOES read it.** Quick fans out on the implement side as wide as its
partition asks for ([`../../quick/SKILL.md`](../../quick/SKILL.md)), and the moment it dispatches
more than one implementer at once those agents get a real `{{track_id}}` and a `{{sibling_tracks}}`
naming the others, which turns this file on exactly as full mode does. The tree does not care which
skill dispatched the agents writing it.

Every rule below exists for one situation: other agents are writing this same working tree at this
same moment. Applied to a solo dispatch these rules are wrong, and skipped on a side-by-side one
they cost a sibling its work.

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
their run and yours. Your integration tests belong to you and run here. That ban is absolute, and
nothing below softens it.

This is the input whose absence is SILENT rather than loud. A track with no database of its own
runs its integration suite against the shared one, where a concurrent truncate destroys a
sibling's run and yours with no error at either end. So `{{database_name}}` is never inferred. An
empty line, one carrying only spaces or a tab, or one still carrying its `{{database_name}}`
placeholder, means the dispatcher never decided, and that is a dispatch to refuse.

**`none` is the one value you verify instead of refusing.** It sits on the dispatch contract's list
of inputs where `none` is a decision the dispatcher made, and what it decides is that the project
has no database at all. That is a real project shape, not an omission: refusing it made every
concurrent dispatch in a database-free repo a dispatch to refuse. So you accept it and then go and
check it, because a claim nobody can falsify is worth nothing. Look for the four things a database
leaves behind, a migrations directory, a schema or ORM config, a connection string or a database
environment variable, and a test harness that truncates or resets tables. Find any of them and
`none` was an omission after all, so you STOP and report the dispatch as underfilled. Find none of
them and you proceed, recording in your report what you searched and what came back.

**Search the filesystem, not the index.** The gate below walks the working tree with `find` and a
recursive `grep`, and that is deliberate: `git grep` and `git ls-files` see only what is TRACKED,
so an untracked migration and a gitignored `.env` are both invisible to them. `.env` is the single
likeliest home of a connection string and it is gitignored in essentially every project, this
repo's own law included, so the index-based form came back clean on the one file most worth
reading. Measured before it was replaced: a repo carrying a gitignored `.env` with a
`DATABASE_URL` and an untracked `migrations/001_init.sql` verified clean and exited 0, and the
same two files force-added turned the same gate red.

**The pattern set is a net, not a census, and the clean line says so.** It names what the common
stacks leave behind, Rails, Django, SQLAlchemy, Prisma, TypeORM, Knex, Drizzle, Sequelize,
Alembic, Mongoose, Mongo, Redis and raw SQL, and a stack that spells its data layer some other way
will pass through it. No enumeration closes that gap, so the gate does not pretend to: a clean run
asserts that the NAMED shapes are absent, never that a database is, and it prints the matcher it
used and every path it skipped so the assertion can be audited rather than believed. Where a
project's data layer is spelled some other way, `{{database_name}}` owes a real answer and `none`
is the wrong one.

Read the hits before you trust them. A fixture corpus, an eval project or a vendored tree can
carry every one of these patterns with no database anywhere, so a path you rule out is a path you
OPENED, and it goes in your report with the reason you ruled it out. Ruling out a path you did not
read is how this check becomes one that cannot fail.

**This is stricter than the old refusal, not looser.** Refusing on `none` handed a dispatcher who
had answered correctly the same FAIL as one who had left the line blank, so the two were
indistinguishable and the informative signal was thrown away. And the hazard was never the word
`none`, it was a track running its suite against a database a sibling is holding. The old form
took the dispatcher's word that a database existed. This one goes and looks at the tree, so a repo
that really has a shared database cannot come back clean, and the dangerous `none`, the one where
a database was there all along, still stops the track. The safe `none` is the only one that now
proceeds, and it proceeds having been checked rather than believed.

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
finished.

**You write it because that path IS in your file allowlist.** The dispatcher puts it there when it
builds a concurrent track's list, exactly so this instruction and the allowlist law stop
contradicting each other. If it is NOT there, the dispatch is underfilled, and you say so in your
wave report rather than settling it yourself. Neither way out is open to you. Writing the file
anyway is a write outside the allowlist, which retroactively falsifies the partition every sibling
is running under, and skipping it in silence loses the progress record this whole section exists
to keep. Report it, and let the parent widen the list.

**A concurrent quick track has no work-doc, so it has no track file either.** Quick writes nothing
to disk by contract, which means there is no slug, no `docs/work/<slug>.tracks/` directory to write
into, and no parent doc for the merge below to merge anything into. A concurrent quick track writes
its report into its wave report only, and the track-file rule applies only when a work-doc exists.
Nothing about that weakens the paragraph above for a full-mode track: there the work-doc exists,
the path is real, and its absence from your allowlist is still an underfilled dispatch.

Only the parent ever writes the work-doc, and it merges your track file into
`## 6. Daily Updates` **as you return**, not once the whole round has landed, so the doc stops
running a round behind the tree. The parent owns every other line of it.

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
# (e) THE TRACK HAS A DATABASE OF ITS OWN, OR THE PROJECT HAS NONE AND THAT WAS CHECKED. Fill the
# first heredoc with the `{{database_name}}` input as you received it, and leave the body EMPTY,
# the placeholder line deleted and both markers kept, when your prompt carried no such input at
# all, which is the case this refuses. An absent line reads as "no database was decided", and a
# track that decides one for itself is a track running against the shared harness a sibling is
# truncating while reporting PASS.
#
# `none` REACHES THE SEARCH BELOW INSTEAD OF REFUSING, and that is the half that changed. `none`
# is on the dispatch contract's list of values where `none` is a decision the dispatcher made, and
# it decides that the project has no database at all. Refusing it made every concurrent dispatch in
# a database-free repo a dispatch to refuse, and worse, it returned the same FAIL to a dispatcher
# who had answered correctly as to one who had left the line blank, so the two were
# indistinguishable and the informative signal was thrown away.
#
# IT STILL CATCHES WHAT THE OLD FORM CAUGHT, and it catches it closer to the hazard. The hazard was
# never the word `none`, it was a track running its suite against a database a sibling holds. The
# old form took the dispatcher's word that a database existed; this one goes and looks in the tree
# for the things a database leaves behind. A repo that really has a shared database cannot come
# back clean, so the dangerous `none`, the one where a database was there all along, still exits 1.
# The safe `none` is the only one that proceeds, and it proceeds checked rather than believed.
#
# THE SKIP LIST IS A CLAIM YOU MAKE, NOT A FREE PASS. A fixture corpus, an eval project or a
# vendored tree can carry these patterns with no database anywhere, so every line you put in it is
# one path you OPENED and judged, and it goes in your report with the reason. Skipping a path you
# did not read is how this gate is turned into one that cannot fail. Every entry, and every row it
# suppresses, is echoed below for the same reason: a clean verdict nobody can audit is a clean
# verdict nobody should trust.
own_db=$(cat <<'HACKIFY_DB_EOF'
<the database_name input as received; delete this line entirely if the input was absent>
HACKIFY_DB_EOF
)
# TRIMMED FIRST, FOLDED SECOND, AND BOTH BEFORE ANYTHING JUDGES IT. A value arriving as a single
# space, a tab, `None`, `NONE` or `none ` used to clear the refusal below AND miss the `none`
# comparison further down, so the gate took the "a database was declared" branch and skipped the
# search entirely. That is the one combination where a dispatch carrying no decision at all
# verifies nothing and still reports PASS. Trimming collapses whitespace-only to the empty string
# the refusal already catches; folding case sends every spelling of the word to the search.
own_db=${own_db#"${own_db%%[![:space:]]*}"}
own_db=${own_db%"${own_db##*[![:space:]]}"}
own_db_lc=$(printf '%s' "$own_db" | tr '[:upper:]' '[:lower:]')
case "$own_db" in
  ''|*'{{'*|*'<the database_name'*)
    echo "FAIL: no database decision reached this track; refuse the dispatch"
    exit 1 ;;
esac

db_skip=$(cat <<'HACKIFY_DBSKIP_EOF'
<one repo-relative path per line, each a fixture or vendored path you OPENED and judged; empty is fine>
HACKIFY_DBSKIP_EOF
)
# An untouched placeholder is an EMPTY skip list, never a path. Left as text it would match
# nothing, exclude nothing and quietly widen the search instead of narrowing it, which is the
# harmless direction here but not the honest one.
case "$db_skip" in *'<one repo-relative path'*) db_skip='' ;; esac
db_ex=()
while IFS= read -r db_p; do
  db_p=${db_p#"${db_p%%[![:space:]]*}"}
  db_p=${db_p%"${db_p##*[![:space:]]}"}
  [ -n "$db_p" ] || continue
  # A ONE-CHARACTER SKIP LIST USED TO VOID THE WHOLE GATE IN SILENCE. An entry of `.` or `*`
  # excludes every path in the tree, both searches then return empty, and a repo that should FAIL
  # prints a clean line byte-identical to a genuine one. These are refused rather than narrowed,
  # because no honest skip entry is the whole tree.
  case "$db_p" in
    .|./|/|'*'|'**'|'.*')
      echo "FAIL: skip-list entry '$db_p' excludes the whole tree, which turns this gate into one that cannot fail"
      exit 1 ;;
  esac
  # A SECOND REFUSAL, FOR A DIFFERENT FAILURE. An entry climbing above the repo root used to make
  # BOTH searches error out, and the error was swallowed into a clean verdict. The exit-code check
  # further down is the backstop; this is the front door, and a skip entry is one path INSIDE the
  # repo you opened and judged.
  case "$db_p" in
    ..|../*|*/..|*/../*)
      echo "FAIL: skip-list entry '$db_p' climbs above the repo root; a skip entry is one path inside this repo that you OPENED and judged"
      exit 1 ;;
  esac
  db_p=${db_p#./}
  db_p=${db_p%/}
  db_ex+=("$db_p")
done <<EOF
$db_skip
EOF

if [ "$own_db_lc" != none ]; then
  echo "note: track database '$own_db' declared; the no-database search does not apply"
else
  if [ ${#db_ex[@]} -gt 0 ]; then
    echo "note: the no-database search excludes ${#db_ex[@]} declared path(s), each one you OPENED and judged:"
    printf 'note:   skip %s\n' "${db_ex[@]}"
  fi

  # THE MATCHER IS PINNED TO AN ABSOLUTE PATH, and the control below adjudicates where it cannot
  # be. A bare `grep` is a shell FUNCTION in at least one agent harness, wrapping a matcher that
  # honours `.gitignore`, and under that wrapper this search skips the single likeliest home of a
  # connection string and reports clean. Measured, not assumed: over a repo whose `.gitignore`
  # lists `secret.env`, `grep -rlIE DATABASE_URL .` returned exit 1 and no rows while
  # `/usr/bin/grep` with the same arguments returned the file.
  db_grep=grep
  for db_c in /usr/bin/grep /bin/grep; do
    if [ -x "$db_c" ]; then db_grep=$db_c; break; fi
  done

  # THE PRUNE LIST IS THE BOUND ON THE WALK, and it is third-party trees only. Generated output
  # stays IN: a database traced only through `dist/` is still a database, and pruning build
  # directories is how a scan gets fast by getting blind. A project with another vendor directory
  # adds it to the skip list above, having opened it.
  db_dirs=(.git .svn .hg node_modules bower_components vendor .venv venv __pycache__)
  db_dirs+=(.mypy_cache .pytest_cache .tox Pods .terraform .gradle target .cargo)
  db_gx=()
  db_fx=()
  for db_c in "${db_dirs[@]}"; do
    db_gx+=(--exclude-dir="$db_c")
    if [ ${#db_fx[@]} -eq 0 ]; then db_fx=('(' -name "$db_c"); else db_fx+=(-o -name "$db_c"); fi
  done
  db_fx+=(')')

  # PROSE IS EXCLUDED FROM THE CONTENT SEARCH, and this line is why. A database leaves its traces
  # in code and config, never in markdown, so a `.md` hit is a file TALKING about databases: a
  # README, an ADR, a changelog, and this very file, whose `db_pat` below is itself a literal run
  # of the tokens it hunts for. That is not hypothetical: the first run of this gate in the repo
  # that authored it reported `sibling-track-rules.md` as evidence of a database, having matched
  # its own source. The file half is unaffected, and it is the half that reaches a `.sql` file, a
  # Rails `db/migrate/` tree, an Alembic revision and a Prisma schema wherever they sit.
  db_pat='DATABASE_URL|DATABASE_URI|DB_HOST|DB_NAME|DB_USER|DB_PASSWORD|DB_PORT'
  db_pat=$db_pat'|POSTGRES_|MYSQL_|MONGO_URI|MONGODB_URI|SQLALCHEMY_|TYPEORM_|DJANGO_DB'
  db_pat=$db_pat'|postgres://|postgresql://|mysql://|mysql2://|mariadb://|mongodb(\+srv)?://'
  db_pat=$db_pat'|sqlite://|sqlite3://|mssql://|redis://'
  db_pat=$db_pat'|adapter: *(postgresql|postgres|mysql|mysql2|mariadb|sqlite3|sqlite)'
  db_pat=$db_pat'|image: *(postgres|mysql|mariadb|mongo)'
  db_pat=$db_pat'|create_engine\(|createConnection\(|TRUNCATE |DROP TABLE'
  db_fpat=('(' -iname '*.sql' -o -iname '*.sqlite' -o -iname '*.sqlite3' -o -iname '*.db')
  db_fpat+=(-o -iname 'schema.rb' -o -iname 'structure.sql' -o -iname '*.prisma')
  db_fpat+=(-o -iname 'database.yml' -o -iname 'database.yaml' -o -iname 'mongoid.yml')
  db_fpat+=(-o -iname 'ormconfig*' -o -iname 'knexfile*' -o -iname 'drizzle.config.*')
  db_fpat+=(-o -iname 'alembic.ini' -o -iname '.sequelizerc' -o -iname 'sequelize*')
  db_fpat+=(-o -path '*/migrations/*' -o -path '*/migrate/*' -o -path '*/alembic/versions/*')
  db_fpat+=(')')

  # ONE FUNCTION, RUN TWICE. DRY is not the point here, IDENTITY is: a positive control that runs
  # a different command from the real search proves nothing about the real search.
  #
  # EVERY EXIT CODE IS READ, and 0 / 1 / >1 are three answers, not two. The retired form ended both
  # searches in `|| true`, which collapsed "clean", "no match" and "the search never ran" into one
  # clean verdict; a skip entry pointing above the repo root made both git searches exit 128 and
  # the gate printed VERIFIED. This repo already wrote that rule for itself in
  # `scripts/validate-dod.d/00-helpers.sh`, in `check_no_token`: a count of 0 from a search that
  # errored is a count of nothing. `grep` says 0 for a hit, 1 for a clean sweep and 2 for a failure,
  # so only 2 and above is a refusal; `find` says 0 for a completed walk and anything else is one
  # it could not finish.
  db_search() {
    db_hits=$("$db_grep" -rlIE "$db_pat" --exclude='*.md' "${db_gx[@]}" -- .) && db_rc=0 || db_rc=$?
    if [ "$db_rc" -gt 1 ]; then
      echo "FAIL: the content search exited $db_rc, so it screened nothing; a clean result here would be a count of nothing"
      return 2
    fi
    db_files=$(find . "${db_fx[@]}" -prune -o -type f "${db_fpat[@]}" -print) && db_rc=0 || db_rc=$?
    if [ "$db_rc" -gt 0 ]; then
      echo "FAIL: the file-name walk exited $db_rc, so it screened nothing; a clean result here would be a count of nothing"
      return 2
    fi
    return 0
  }

  # THE POSITIVE CONTROL, AND IT IS NOT OPTIONAL. Everything this branch can print on success is a
  # zero, and a zero is worth exactly what the search's ability to have returned non-zero is worth.
  # Two ways this search goes blind with no error at either end: a matcher that honours
  # `.gitignore`, and a prune list that swallowed the tree. So a probe carrying its own `.gitignore`
  # of `*` is planted, the REAL search runs over it, and the gate refuses unless both halves found
  # it. Gitignored ON PURPOSE: a matcher that skips ignored files fails here loudly instead of
  # passing the repo silently. The probe is invisible to `git status` for the same reason, so it
  # cannot show up as a stray edit in a sibling's tree, and it is removed on the line after the
  # search that reads it.
  db_probe=.hackify-db-probe.$$
  if [ -e "$db_probe" ]; then
    echo "FAIL: $db_probe already exists; an earlier run died mid-probe, remove it by hand"
    exit 1
  fi
  mkdir -p "$db_probe/migrations"
  printf '*\n' > "$db_probe/.gitignore"
  printf 'DATABASE_URL=postgres://control@localhost/control\n' > "$db_probe/control.env"
  printf 'SELECT 1;\n' > "$db_probe/migrations/control.sql"
  db_ctl_rc=0
  db_search || db_ctl_rc=$?
  db_ctl_hits=$db_hits
  db_ctl_files=$db_files
  rm -rf "$db_probe"
  [ "$db_ctl_rc" -eq 0 ] || exit 1
  case "$db_ctl_hits" in
    *"$db_probe/control.env"*) ;;
    *) echo "FAIL: the content search did not find its own planted control at $db_probe/control.env, so it cannot return a dirty result and a clean one from it means nothing (a matcher honouring .gitignore does exactly this)"
       exit 1 ;;
  esac
  case "$db_ctl_files" in
    *"$db_probe/migrations/control.sql"*) ;;
    *) echo "FAIL: the file-name walk did not find its own planted control at $db_probe/migrations/control.sql, so a clean result from it means nothing"
       exit 1 ;;
  esac

  # THE REAL RUN, over a tree the probe has already left.
  db_search || exit 1
  db_kept=''
  db_drop=0
  while IFS= read -r db_r; do
    [ -n "$db_r" ] || continue
    db_r=${db_r#./}
    db_m=''
    for db_c in "${db_ex[@]}"; do
      case "$db_r" in "$db_c"|"$db_c"/*) db_m=$db_c; break ;; esac
    done
    if [ -n "$db_m" ]; then
      db_drop=$((db_drop + 1))
      echo "note:   skip '$db_m' suppressed $db_r"
    else
      db_kept="$db_kept$db_r
"
    fi
  done <<EOF
$db_hits
$db_files
EOF
  if [ -n "$(printf '%s' "$db_kept" | tr -d '[:space:]')" ]; then
    echo "FAIL: database_name is 'none' but this project has a database; the dispatch is underfilled"
    printf '%s' "$db_kept"
    exit 1
  fi
  echo "note: database_name 'none' VERIFIED against the tree, nothing a database leaves behind was found"
  echo "note:   matcher $db_grep, control fired before the real run, ${#db_ex[@]} declared skip path(s) suppressed $db_drop row(s)"
  echo "note:   the named shapes are absent; that is not the same claim as 'no database exists'"
fi

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
signal, the `file:line` that satisfies it, and the `## 3.` row below that hands the
testing wave its proof. The test NAME is not a column here and cannot be. A production
track authors no tests now, so a column asking every track for one would be empty on
most of the reports this file governs, and a split testing wave that does author them
names them in its own wave report rather than here. A row missing any of its three
columns is NOT done and says so in that row rather than in a footnote below the table.
The assembly wave reads this first, and it is the only place a track's own claim of
DONE can be checked without re-reading the whole module.

## 1. What I built
- `<absolute path>`, <what it does>, covers plan task <id>.

## 2. Gate output
(pasted, not summarised, one block per gate command)

## 3. Behaviour the testing wave must cover
Named mutations belong to the testing wave now, not to you, so this slot hands that
wave what it needs to take them: one row per behaviour you built, where it lives, and
the edge that flips it. The slot is retargeted rather than dropped, because the item
numbers below it are cited by number elsewhere.
- <the behaviour>, at `<file>:<line>`, flipped by <the edge case>.

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
| Own database used, or `none` verified against the tree; shared one never touched | ✓ / ✗ |
| Nothing mounted, nothing committed, work-doc untouched | ✓ / ✗ |
| No `git checkout` / `restore` / `stash` | ✓ / ✗ |
````
