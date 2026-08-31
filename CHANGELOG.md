# Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.18.0] - 2026-08-30

> **Your prompts now land in quick mode, and the full workflow is something you ask for by name.**
> It used to be the other way round. Anything that looked substantive, and anything that so much as
> mentioned auth or a migration or a schema, was pulled into the full ceremony whether the job
> needed it or not: a plan to sign off, a spec review, a five-reviewer panel, a four-option finish
> menu. That costs roughly three times the tokens and the waiting, and most of the time it bought
> nothing you could point at afterwards. Quick keeps every guarantee that actually protects the
> work, the tests, the lint and typecheck run, both scouts, the ship gate and a full review round
> that closes before finish, and drops only the ceremony. Say *"switch to full"* or type
> `/hackify:hackify` and you have the whole thing back.
>
> **Implementation got much wider.** One agent used to take one wave and that was the end of it.
> Now a wave is packed up to a stated per-agent task budget, and a round runs up to a stated
> concurrent-wave budget of those side by side, so a backlog that used to trickle out over several
> rounds can land in one. The rules that make this safe have not moved: two agents never write the
> same file, and two agents never hold the same exclusive resource such as a shared test database.
> Where a codebase cannot go wide, because its features all touch the same few files, the round
> comes out narrow and says so in a line rather than dressing the width up as a choice. Both budgets
> are written as numbers in exactly one file, so changing either is one edit instead of a sweep that
> misses a site.
>
> **Tests moved to the end of implementation, and there is a new trick that keeps them honest.**
> Implementation agents write production code only. One dedicated wave afterwards writes the tests
> for everything the round landed. The obvious objection is that a test written against code that
> already works passes on its first run and proves nothing, so that wave has to manufacture the
> failure it never got to see: break the production line each test protects, run the test, require a
> red that names that test, then put the line back. The guarantee did not weaken when the tests
> moved. The way it is earned changed.
>
> **The work-doc keeps up now.** It used to be brought current at the end of a round, so a session
> that died partway through lost the record of everything the finished agents had already done. Each
> agent's work is folded in as it reports back instead.
>
> **The tradeoff, said plainly, because you should read it here rather than discover it later.**
> Quick has no auto-escalation list at all any more. Nothing about an ask pulls it up to full mode:
> not the file count, not a cross-file refactor, not an unknown root cause, not auth, crypto, a
> migration, a secret or a token. So a schema migration now gets quick's single reviewer instead of
> the panel's five lenses, and the only road to that panel is asking for full mode. This was chosen
> deliberately, with the cost on the table, because the old escalation list would have caught
> exactly the wide multi-file work the new throughput exists for. If a change feels like it wants
> five reviewers on it, say so and promote it.

### Added

- **A testing wave at the end of implementation.** It runs after the last wave of production code
  and before verification, it is handed the same file allowlists and the same scouts every other
  wave gets, and it owes a manufactured red plus a named mutation for every test it writes. It is
  not a new kind of agent, it is the existing implementer told it is in test-authoring mode, which
  is why nothing else about a dispatch had to change. Like the other stages it scales down: a diff
  with genuinely nothing to test marks the wave complete with a written reason rather than dropping
  it in silence. It also scales the other way: when a round lands more production code than one
  agent can cover, the stage splits into concurrent testing waves under the same partition test
  every other stage answers to, asked of the test files those waves would write and the production
  files each one breaks to watch a red. A split stage's waves are siblings like any other, so each
  is handed the others' IDs, and none of them may assume it has the tree to itself.
- **A stated dispatch budget, with one home.** The per-agent task budget and the concurrent-wave
  budget are written down once, as numbers, in the file that already owns the partition test.
  Everywhere else names them instead of repeating them, so the two can be retuned in one place. Both
  are packing targets and never quotas: they decide which of the permitted splits to take, and they
  can never authorise one the partition test refuses.

### Changed

- **Routing flipped.** Quick is the default route for any substantive prompt, whatever its size and
  whatever it touches. Full hackify fires only on an explicit request, by name or by slash command.
  The old autopilot phrases are not such a request and never were a way past the gate.
- **The plan-shaping conversation hands off to quick.** Groom used to graduate into the full
  workflow with a work-doc waiting. It now graduates into whichever mode you are actually in, which
  by default is the one that keeps no work-doc, so the shaped idea arrives as the goal anchor in
  chat instead of a file on disk.
- **Quick fans out on the implement side.** It uses the same per-agent and concurrent-wave budgets
  and the same never-two-agents-on-one-file rule as full mode. The review side deliberately stays at
  one reviewer and one refuter however wide the implementation went, which is what keeps quick cheap.
- **Quick runs the root-cause hunt in place.** A debug ask used to be a reason to promote to full
  mode. Since nothing auto-promotes any more, quick carries the same four-phase hunt rather than
  pointing at a mode you may never enter.
- **The work-doc is refreshed per returning agent.** The rule that said to persist before
  dispatching the next round is gone, replaced by one that folds each agent's report in as it lands.
  Agents still write their own separate track files, because a crowd of agents appending to one
  markdown file is the collision that arrangement exists to avoid, and only the parent ever writes
  the work-doc itself.

### Fixed

- **The checker that guards every release was itself unreliable, about one run in nine.** It would
  announce that a file was missing a section the file plainly contained, name a different section each
  time, and then pass on the next run. The cause is a plumbing detail with a nasty edge: a check would
  push a whole 40KB file into `grep`, and `grep` stops reading the moment it finds what it wants. If the
  writer is still pushing when the reader walks away, the shell reports that as an error, and the check
  read the error as "not found". It only shows up under a full run's load, because an idle machine gives
  the pipe enough room to swallow the file whole, which is why it looked like a ghost for so long.
  Twenty-three places had the same shape. Most turned it into a false alarm, but one fed a check that asserts
  a marker is ABSENT, so the glitch read as "confirmed absent" and passed exactly when the marker was
  really there, which is the one input that check exists to catch. All of them now test the text directly
  instead of piping it, and a new check refuses any new occurrence, so it cannot come back quietly.
  Measured: three failures in thirty runs before, none in the seventy runs against the finished code.
- **A concurrent dispatch could not say that the project has no database.** When several agents work
  the same tree at once, each has to prove it has a database of its own, because two agents resetting
  one shared database destroy each other's test runs with no error at either end. The rule read the
  answer "none" as a dispatcher who had not answered at all, and refused the dispatch. In a project
  with no database anywhere, which is a real shape and this repo's own, that refused every legitimate
  concurrent dispatch. "none" now reaches a search instead of a refusal: the track goes looking for
  what a database leaves behind, connection strings and database environment variables in code and
  config, migration folders, plain SQL files and the config files the common data layers ship, opens
  every hit before ruling it out, and proceeds only on a clean result. The three answers that really
  do mean nobody decided, a blank line, a placeholder nobody replaced and a form left exactly as it
  shipped, still stop the track as they did before. This is the stricter reading and not the looser
  one. The old rule handed back the same refusal to a dispatcher who had answered correctly as to one
  who had answered nothing, so the two were indistinguishable, and the cheapest way past it was to
  invent a database name that named no real database, which is the thing it existed to prevent.
- **The two files that govern concurrent work disagreed about where a track writes its progress.**
  One told the agent to keep a progress file of its own rather than appending to the shared work-doc,
  since a crowd of agents appending to one file lose each other's writes. The other never put that
  file on the list of paths the agent is allowed to write, and writing outside that list is the one
  thing a blind agent must never do. The instruction and the law cancelled out and left no legal
  move. The dispatcher now puts the path on the list, and both files say so, so the pair only works
  as a pair and is finally written down that way.
- **Two of the validator's own ban lists were never tamper-tested.** A ban list is proved by planting
  the exact wording it forbids and watching the check go red. These two shipped, ran on every
  validator pass, and were planted by nothing, so either could have stopped banning anything
  overnight and the suite would have stayed green. That is the check that cannot fail, shipped by the
  same release whose new checks exist to catch it. Both lists are parsed and planted now, all eleven
  tokens, each watched reddening by name, and the suite's plant total goes from 91 to 102.
- **A comment restated a number that had moved twice.** It gave the pinned count of batched ban calls
  as three. That became four in 0.16.1 and six in this release, and nothing goes red over prose,
  which is why it sat wrong for two releases. The comment now points at the one file the number is
  allowed to live in, instead of keeping a copy of its own.

## [0.17.2] - 2026-08-28

> **The idea-shaping skill and the main workflow stopped stepping on each other.** Three of the
> phrases that route a prompt to `groom` were listed on the routing surface but missing from the
> list inside the skill that tells you it names them all, so someone who typed "considering" or
> "thinking about" landed in groom and then read a page that never mentioned the words they used.
> Saying "ship it" was worse. Groom read it as "start building" and handed straight over, and the
> very next question offered to merge the work into main with nobody reviewing it, because "ship
> it" is also the phrase that opens that option. Both are fixed. What happens when a prompt is a
> discussion and a build request at the same time is now written down rather than left to be
> guessed, and the main workflow file finally says where a fuzzy, half-formed ask should go.
>
> **The review agents got a pass in the same release, and one of them was quietly throwing away
> real problems.** There is an agent whose only job is to double-check every review comment before
> anyone spends time fixing it. It had a rule saying that when it could not restate a comment as a
> clear, testable claim, it should mark that comment wrong and drop it. But being confused by a
> comment is not evidence the comment is wrong, and that was the one route in the whole file that
> could kill a top-severity finding with no counter-evidence at all. Keeping the comment was the
> right call, but on its own it left the comment with nowhere to go next. It is now reworded inside
> the review round already running and fixed along with everything else, rather than parked waiting
> for a round that never comes. If nobody can word it clearly even after a proper try, it comes to
> you in writing instead of being dropped quietly. Four other checks that could report "all clear"
> without actually looking at anything were closed at the same time.

### Added

- **The validator now checks that a skill's two trigger lists agree with each other.** It already
  guarded the routing surface, the frontmatter line the model matches your words against, so a
  phrase could not quietly disappear from it during a round of trimming. The other direction was
  open: a phrase could sit on the routing surface and be absent from the list printed inside the
  skill, which is what had happened to groom. Both lists are now checked against one pinned set of
  phrases, and the two halves fail separately so a red line tells you which surface lost the phrase.
  The half that reads the skill body reads the bullet list itself, never the whole page. The first
  version searched the entire file, and one of the eight phrases is quoted a few lines under the
  list as a worked example, so deleting its bullet left the check printing green over the exact
  loss it exists to catch. That was re-proved afterwards on that phrase, and the check now fails on
  all eight, as well as on an emptied list and on a skill wired in without its phrases. The green
  line also reports how many bullets the list holds beside how many are pinned, because groom lists
  nine and pins eight. The odd one out is the bare word `groom`, which runs through every page of
  the file, so a pin on it could never fail and there is no point pretending otherwise.

- **A new check keeps one rule's list of file kinds identical everywhere it is repeated.** The rule
  banning loose type definitions names eight kinds of file, and six agent prompts repeat that list
  so a working reviewer does not have to stop and open the rule file mid-review. Nothing was
  watching those copies, which is how three of them had quietly drifted back to the first three
  kinds. The check reads the eight straight out of the rule file on every run rather than keeping a
  copy of its own, looks for the whole list in order in each of the six places, and names both the
  file and the exact kind that went missing when one breaks. It was watched failing four ways: a
  kind deleted from one prompt, a kind deleted from the rule itself, the rule's sentence reworded so
  the read comes back empty, and one copy deleted from a file that still held two more.

### Changed

- **The main workflow skill names `/hackify:groom` where it lists the other ways in.** It described
  `/hackify:quick` as the compressed route and said nothing about groom at all, while its own first
  line claimed everything "discussing-then-building" for itself. That line now says a conversation
  lands in the workflow the moment it names something to build, and open-ended discussion with no
  build verb belongs to groom. A new line describes groom in the same shape as the others.
- **The two places that dispatch the double-checking agent now say what to hand it.** That agent
  got a rule this release that makes it refuse a blank list of comments, which is right: a blank
  looks exactly like a quiet round, and reading it that way would drop every comment the reviewers
  actually filed. What nothing said was that the dispatcher has to pass that list at all, so a
  review round that found nothing would have hit the refusal instead of finishing. Both dispatch
  paragraphs and the dispatch table now say the whole round goes across word for word, and that a
  round with nothing in it passes the written word `none` rather than a blank.
- **Phase 1 no longer calls itself a grooming session.** Two places in the Clarify protocol used
  the word for the phase itself, which read as if Phase 1 and the groom skill were the same thing.
  They are not: groom runs before a task exists and hands over, Phase 1 runs inside the task. The
  protocol now describes itself as locking the goal anchor. The two mentions of "the groom path",
  which correctly point at the handover, are untouched.
- **A third page was still calling Phase 1 a grooming session, and now it does not.** The
  goal-anchor reference is linked straight from the Clarify protocol, so the two pages disagreed
  with each other after the fix above. It now makes the same point without borrowing groom's name.
- **A design review on a project with no design spec is no longer close to a no-op.** It used to
  skip six of its nine checks the moment no spec was found, and it kept only the ones that look
  for generic-looking fonts and gradients. Colour contrast was one of the six it dropped, so a
  screen shipping grey text nobody could read came back clean. Contrast, hardcoded colour and size
  values, and missing hover and focus states now run whether or not a spec exists, because an
  accessibility standard is a standard with or without one. Only the four checks that genuinely
  measure against the project's own spec still wait for one, and the report now states which mode
  it ran in and what that mode skipped. What counts as a user-interface file got wider in the same
  pass, and that is a real change in how much gets reviewed rather than a wording tidy-up: page
  templates of any flavour, plain HTML, SVG and other vector art, and design-token data files all
  count now, and so does a file you are unsure about. More files get looked at than before. An empty
  list after that filtering is reported as "not UI-bearing", with every touched file named so you
  can check the call, instead of coming back as a clean result.

### Fixed

- **"ship it" no longer counts as a signal to start building.** It was on groom's list of phrases
  that end the conversation and open the task, and it is also the exact phrase that makes Phase 1
  recommend merging straight into main unreviewed. Since groom hands over in the same turn, anyone
  using "ship it" to mean "let's go" would have been steered toward an unread merge. The phrase is
  off the list, and the reason is written beside it so it does not come back.
- **`what do you think`, `considering` and `thinking about` now appear inside groom, not only on
  its routing surface.** The list in the skill body says it holds every trigger, and it was three
  short. The new check above is what stops the two lists drifting apart again.
- **Groom now says which rule wins when a prompt matches both of its lists.** "let's discuss adding
  rate limiting" carries a discussion phrase and a build verb at once, and nothing said which one
  decided. The rule the tests already assumed is now stated in both the routing surface and the
  skill body: a discussion phrase wins, and the build-verb block only applies to a prompt carrying
  none of them.
- **The response table now has somewhere to put a comment nobody could restate.** The
  double-checking agent gained that outcome in this same release, and the skill that turns its
  verdicts into a table still allowed exactly three answers. The only one of the three that fitted
  an unresolved row was "defer", which is the quiet drop the new outcome existed to prevent, so the
  comment survived inside one file and died at the join to the next. The table takes a fourth
  answer now, `needs-restatement`, and it is the one answer that holds a row open instead of
  closing it: the comment keeps its severity, stays on the list, and waits for someone to write it
  more clearly. Both files call the state by the same name, and the skill says plainly where it
  differs from "defer", since that is the place the two are most likely to be confused.
- **A review comment nobody could restate now survives, and it gets judged in the same round.** The
  double-checking agent used to file it as refuted, which took it off the fix list for good, and it
  did that before either of its two lines of attack had run. It also could not obey its own rule
  that every refusal cites the line of code proving the comment wrong, because there was no such
  line to cite. Those comments now get their own outcome that keeps them alive at their original
  severity and hands them back to be written more clearly. The observation that a vague comment is
  itself a problem was right and is kept; only the punishment changed. Keeping the comment was only
  half the job, though. The new outcome told the parent to reword the claim and put it through "the
  next refuter round", while four other files state that Phase 5 runs exactly one reviewer panel and
  one refuter and then ends. Both could not be obeyed, and the comment was what lost: held out of
  the fix dispatch, then never judged, which is the silent drop this outcome was added to prevent.
  The round cap did not move to make room. The rewording now happens inside the round that is
  already open, and since the refuter kills findings rather than certifying them, a claim it
  declined to kill is a survivor like any other, so the reworded row reads `accept` and is fixed in
  the same pass as the rest. That is the call this file already makes on "I could not confirm it",
  one step earlier in the same uncertainty. The rewrite gets one attempt and no loop, because an
  unbounded reword is the unbounded round in miniature: a claim that still cannot say what breaks
  and where goes to the user in the written list the cap already sends unresolved rows to, at its
  original severity and quoting the reviewer's own words. The cap's own wording, in
  `references/review-and-verify.md` and in the main skill, now says a reworded finding is judged
  inside the same round. While all this was being traced, one more free kill turned up nearby: a
  comment aimed at a carved-out file (a test, a generated file) could be dropped outside the
  two-attack rule entirely, and that now counts as one of the two.
- **The size-cap review can no longer pass over nothing.** The reviewer is handed a table of
  measurements and told to flag every row above a cap. It knew what to do when the table was
  missing or explicitly marked unavailable, and it fell back to counting by hand. A table that
  arrived present but with no rows in it was undeclared, so the reviewer flagged every row over a
  cap across zero rows and reported a pass. An empty table now counts as a broken handoff worth
  reporting, and the file-length check in particular can never be skipped, since counting lines
  needs no tooling at all. The same hole was still open one column across. A table can arrive with a
  row per file and the word `n/a` in every function column, which is exactly what a documentation
  diff genuinely produces and also what a failed build produces on a diff full of code. The reviewer
  now tells those two apart by looking at which files the diff touched rather than by taking the
  table's word for it, and the checklist item can no longer be answered yes over an all-`n/a` table
  when the diff carries even one source file.
- **The ban on loose type definitions now covers all eight kinds of file it was written for.** The
  rule names routers, services, middleware, guards, controllers, components, pages and routes. Four
  places in the agent prompts stopped at the first three, including the only reviewer that checks
  this at all, so five kinds of file went unchecked. One prompt listed three in one place and all
  eight in another, contradicting itself. Every one of those now carries the full list. A stray
  description of the rule as a "glob list" was corrected too; it is a plain sentence, and matching
  on filenames was never what it asked for.
- **Three agents can now refuse a handoff that arrived broken.** The contract has always said an
  agent handed an unfilled blank must stop and say so, and six of the nine did. Security review,
  the double-checking agent and the plan reviewer had no such rule anywhere in them. The plan
  reviewer was the worst of the three, because its checklist sends any failed answer back to the
  start and there was no way out of that: with a missing project path it could never answer yes,
  and it would circle forever instead of saying what was missing. All three now check their inputs
  before doing anything, and each one names the inputs where a written "none" is a real answer so
  the new rule cannot fire on a legitimate one.
- **The contract itself stopped saying "should" and "must" about the same rule.** One page said an
  agent handed an unfilled blank "should refuse" and, eighty lines later, that it "MUST refuse to
  proceed". Every fix above is written against that page, and "should" is exactly the wording a
  literal reader satisfies by doing nothing. Both lines now say must. The first attempt at that fix
  also left a sentence behind describing the line as still saying "should". That page's whole
  premise is that a literal reader parses what is written and nothing else, so a sentence that
  describes its own text wrongly is a defect there rather than a footnote. It is gone, and the line
  ends where the rule ends.

- **A design review with a spec and no reference pictures can now answer its own last question.** The
  report has to list the steps it skipped, and the checklist said that list is empty whenever a
  design spec exists. But the step that compares the screen against reference pictures is skipped
  whenever there are no reference pictures, which has nothing to do with whether a spec exists, so a
  reviewer in that ordinary situation had to either lie or report a step it dropped without
  permission. The item now names both reasons a step can be skipped and spells out the four lists
  that are allowed, so a skipped step stays visible either way.

## [0.17.1] - 2026-08-28

> **Phase 3 had two implementer agents doing one job, and now it has one.** Which one a wave got
> depended on whether other tracks were running beside it, and the two prompts drifted apart with
> nothing keeping them honest, so a rule written into one was simply missing from the other. There
> is now a single implementer, and the thing that used to pick between two agents is now a single
> input telling that agent whether anybody else is writing the same tree right now. Told nobody is,
> it works as the only writer. Told who is, it loads the extra rules for staying out of their way.
> Nothing was dropped in the merge: every rule either agent carried is still enforced, and the
> side-by-side half is a file the agent opens only when it is told it needs it.

### Changed

- **`hackify:wave-implementer` and `hackify:module-implementer` are gone, replaced by one
  `hackify:implementer`.** **If you have a saved dispatch, a script, a snippet or a note that names
  either old type, update it to `hackify:implementer`.** A dispatch naming a retired type does not
  fail validation, it fails at dispatch time, when there is no such agent to run. The new agent
  takes 21 inputs, nine of which accept the literal `none` (`work_doc_path` is one of them, for
  quick mode, which writes no work-doc), and it serves every shape a Phase 3
  dispatch comes in: a solo foundation wave, concurrent module tracks, a solo assembly wave, a
  single-track round, and a quick-mode change.
- **The rules for building beside other agents moved to their own file,
  `skills/hackify/references/sibling-track-rules.md`, and load only when siblings are actually
  named.** The `sibling_tracks` input is the switch. Set to `none` it stays shut, and a solo wave
  never reads a line written for a concurrent one, which is what used to make the wrong half of the
  old module prompt apply to work that had no siblings at all. Naming the other tracks opens it, and
  the agent then applies all of it on top of its always-on contract: its own database, cross-module
  type errors that are expected and not its own, reporting a defect in shared code instead of
  fixing it, its own track file instead of the shared work-doc, no registrar mounting, no command
  that discards working-tree state, and the eight-item handoff the assembly wave mounts from.
- **Every dispatch site, the workflow prose and the plan review now name the one type.** The
  hackify skill, quick mode, the Phase 3 protocol, the dispatch catalog, the contention doctrine,
  the work-doc template and the spec reviewer's own wave-plan skeleton all say the same thing, and
  the counts they quote were re-measured against the tree rather than carried forward.

## [0.17.0] - 2026-08-27

> **The full workflow now plans around what genuinely has to happen one at a time, and runs
> everything else at once.** A round used to turn into a queue of waves, and most of that queue was
> waiting rather than working. The plan review now names every serial resource the backlog touches,
> a file two tasks both write, a counted sequence, an exclusive external resource such as one shared
> test database, and then asks of each one whether it is really exclusive or only exclusive by
> convention. Most turn out to be convention. Whatever survives the question is settled up front in
> a single solo pass, the module tracks then run side by side with every track delivering finished
> and tested work, and one last solo pass mounts the parts and boots the system for real. The shape
> scales to the change: nothing contended means no first pass, one track means nothing to assemble,
> so a small edit runs exactly as it always did. No verification was traded away to get this. The
> waiting was.

### Added

- **The no-AI-attribution rule now stops the commit, instead of asking nicely.**
  It used to live only in written rules and in a check that runs inside this
  repository, so in a real project the only thing preventing a sign-off trailer
  was the model choosing that rule over the one its own harness pushes the other
  way. It kept losing. A new blocker sits in front of the shell and refuses any
  command that would create a commit, tag, pull request or release carrying a
  co-author line naming an assistant, a link back to a chat, a generated-with
  footer or a robot emoji, including one written to a file first. It reads
  nothing else: a plain `git log | grep` audit still runs, which matters,
  because that is how you find a trailer that already landed. Claude Code only,
  since it is the only supported tool with a place to put such a thing.
- **A check that reads the shell inside the agent instructions.** Some of those
  instruction files carry a small script the worker runs on itself before it
  reports back. Nothing ever checked that script was valid, because the files
  are documents and no tool opens a document looking for code. One of them had
  been broken the whole time, so the worker's self-check quietly did nothing
  while every other check stayed green. The new check reads all eleven of those
  files and fails if any of their scripts will not run.
- **A place in the work-doc for the details a side-by-side worker needs.** A
  worker running next to others needs to be told which folders are its own,
  which are somebody else's, which database to make for itself, and what to
  hand back at the end. Nothing produced any of that, so it would have refused
  every job. The plan file now has a block for it, filled in before the workers
  go out.
- **Workers write down what they finished, while they are finishing it.**
  Progress used to live only in the message a worker sends back at the end, so
  a session that died halfway through lost the record of everything done up to
  that point. A worker running alone now writes straight into the plan file's
  daily log; workers running side by side each keep their own file, which the
  parent folds in afterwards, because several of them writing one file at once
  is the exact clash this release was built to remove.
- **The house rules now travel with the worker.** They used to be attached to
  messages from you, and a job handed to a worker is not one of those, so
  workers had never actually been receiving them. The rules a worker is most
  likely to break are now written into its instructions directly.

- **`references/contention-dispatch.md`, the technique written down in one place.** It carries the
  three classes of serial resource, the exclusivity re-test, how a foundation wave gets extracted,
  what a track finishes for itself against what it defers to assembly, what the dispatcher owes the
  round while tracks are in flight, and the honest limits. Phase 3 and the spec reviewer cite it
  instead of restating it, so there is one copy of these rules to keep current rather than three.
- **`module-implementer`, a second implementer agent for concurrent tracks.** It builds against the
  planned contract rather than waiting for a sibling's code to land, holds its own test database
  where the stack needs one, and is told in as many words never to destroy work it did not write.
  The wave implementer still takes the foundation wave, the assembly wave and any round with only
  one track, because with no siblings running the blind-sibling rules protect nothing and cost
  context.

### Changed

- **Phase 3 is three stages now, not a queue.** A solo foundation wave lands every contended write
  and no feature code, N module tracks then run at the same time, and a solo assembly wave mounts,
  reconciles and boots. A stage with nothing in it is marked complete with a written reason rather
  than silently dropped, which is what keeps the shape honest on a two-file change.
- **Phase 2.5 re-tests exclusivity instead of just recording it.** The spec reviewer already listed
  the serial resources a backlog touches. It now has to say, per resource, whether the thing is
  genuinely exclusive or merely conventionally so, because a resource nobody re-tested is how a
  round ends up serial for no reason at all.

### Removed

- **The `yolo` mode is gone, and `skills/yolo/` with it.** Two build modes ship from here, the full
  workflow and `quick`. The phrases that used to start autopilot, `yolo`, `just do it`,
  `don't ask me`, `no questions`, `fully autonomous`, `auto mode` and `go full auto`, now route to
  the full workflow rather than failing silently. Little is lost in the trade: autopilot skipped the
  plan sign-off and the finish menu to save time, and contention-first dispatch saves that time by
  deleting the waiting instead of the gates.

## [0.16.1] - 2026-08-26

> **Commits and pull requests stop carrying Claude's name.** The skill used to instruct the
> attribution and now forbids it: no `Co-Authored-By:` trailer, no `Claude-Session:` line, no
> generated-with footer, in a commit message or a PR body. A repository's history is the project's
> record rather than a tool's, and a reader of `git log` should see the change and who owned it. The
> runtime harness ships a standing instruction to append those lines, so the rule says out loud that
> it overrides that instruction; a rule that quietly disagrees with the instruction in front of you
> at the moment you write the commit is not a rule. Where a project genuinely wants the attribution,
> its own CLAUDE.md asks for it and that request wins. Silence is a no.

### Changed

- **Five sites flipped, four of which used to mandate the trailer rather than merely allow it.**
  `references/implement-and-test.md` carried it in the commit template and again in the worked
  example; `phases/phase-6-finish.md` said a commit "ends with Claude Code Co-Authored-By trailer";
  `references/finish.md` put a generated-with footer in every PR body template; and `yolo`'s own eval
  scored a run as correct FOR carrying the trailer, which would have graded the new rule as a
  failure.

### Added

- **Check `[81]`, which is why this is a rule and not a preference.** The thing it guards against is
  not a careless edit, it is a default reasserting itself, and prose alone already lost that argument
  once. It bans the trailer, the session line, the bracketed footer and the noreply address across
  `skills`, `agents`, `rules`, `commands`, `hooks`, `.claude-plugin` and `README.md`, and it separately pins the rule sentence at
  each of the four sites that state it, because a ban-only check is perfectly green over a skill that
  has quietly stopped saying anything. The banned tokens are trailer-shaped rather than
  mention-shaped, carrying the part only a real trailer has, so the rule can name what it forbids
  without reddening itself. Eleven tamper rows in `scripts/test_tamper_attribution.py` plant every
  one of those losses and show the check red, taking the battery from 148 rows to 159. Two of those
  eleven exist because the first cut of this check scanned five paths while its own header claimed
  the only exclusions were `scripts/`, `dist/` and `docs/work/`: `hooks/` was in neither list, so the
  one tree that injects rule text into every prompt was silently unscanned. It is scanned now, and a
  row pins the scan list against `CAP_SEARCH_PATHS` so the two cannot drift apart again. What the
  check cannot reach, stated plainly: it reads the shipped instructions that tell an agent how to
  write a commit, never a commit message itself, and the 289 commits already carrying trailers were
  not rewritten.

## [0.16.0] - 2026-08-26

> **Phase 3 stops being the workflow's throughput floor, and every safety property it carried
> survives the change.** One agent still takes a whole wave, because a wave whose tasks read the same
> types, the same neighbouring code and the same conventions pays for those reads once instead of
> once per task. What does not survive is the unconditional version of that rule, which was stated
> without conditions while its own justification carried one. Waves that share no file, no import
> edge and no serial resource now go out at the same time, one agent each, and the parent settles
> that with a written test rather than a hunch. The other half of the release is the checks
> concurrency turned out to need, one of which found 68 stale files sitting in the built trees before
> they could ship. Phase 5 also stops being open-ended: one reviewer panel, one refuter, and the
> panel is no longer gated, so four lenses run on every non-trivial diff instead of one plus whatever
> the evidence let through. Dev-facing: no phase moved, no gate moved, and no allowlist widened in
> either direction. User-facing: what you install out of `dist/` is compared against the source it
> was copied from, byte for byte, on every CI run, because the workflow builds `dist/` before the
> validator; locally, whenever `dist/` has been synced, and it prints a skip line naming what it
> would have compared otherwise.

### Added

- **A three-condition partition test, written once in
  `skills/hackify/references/phases/phase-3-implement.md` and pointed at from every other site that
  states the rule.** Take the union of every task's file allowlist in the wave and ask whether it
  splits into subsets where no file appears twice, no import edge runs between the modules those
  subsets live in, in either direction, and no subset holds a serial resource another subset also
  holds. All three hold and the subsets MAY be dispatched as concurrent waves, one agent each; any
  one of them fails and one agent takes the whole wave. Condition 1 is inherited from the wave plan
  rather than work the test does, since a wave's tasks are file-disjoint by construction, so the
  teeth are conditions 2 and 3. Condition 2 exists for what file-disjointness cannot see: two agents
  that both read a shared type while each writes its own module can still contradict each other, and
  that contradiction is the defect the Phase 5 coherence lens exists to catch. Where the tree has no
  imports to follow, in prose, docs and config, the edge is the same relation without the keyword,
  one subset reading text or values another subset is rewriting. **The three conditions say a split
  is PERMITTED, never which permitted split to take**, because the trivial partition holding the
  whole wave passes all three vacuously, so a passing partition always exists and a greedy reading
  shatters a wave into singletons. Choosing among the passing partitions is a written procedure that
  runs coarse to fine, proposing something finer only where the tasks share no read surface and
  taking the fewer subsets when two proposals both pass. Assembling a ROUND out of waves is its own
  step with its own pairwise allowlist intersect, because the test is scoped to one wave and never
  asked whether two waves in a round collide with each other. The stop-at-first-failure clause is
  stated explicitly as PER AGENT: every agent in a round stops on its own account, keeps its own
  landed work on disk and files its own report, so one wave stopping never stops another and never
  costs that wave what it already wrote.
- **`exclusive_resources`, a new input on the wave dispatch contract, so two concurrent agents can
  never both hold a shared test database.** Four parts, all of them the parent's job: each wave brief
  names any exclusive resource that wave holds, concurrent waves run scoped unit tests ONLY, the
  suite that needs the resource runs once and serially at the parent after the concurrent waves have
  landed, and the parent records the cost in the wave log rather than leaving it implicit, naming
  which resource was held back, which suite did not run while the concurrent waves ran, and that
  those waves' evidence is scoped-unit-only until the serial run lands. Written but not exercised
  this release: this sprint held no test database, no generated sequence and no shared fixture, and
  the wave log says so rather than going quiet.
- **A `## Serial resources` section in the Phase 2.5 spec reviewer's report, plus concurrency
  candidate marks on the wave plan.** The reviewer names every shared file, generated sequence and
  external exclusive resource the backlog touches, because parallelism keeps being blocked by a
  handful of resources nobody names up front. The parent pulls the tasks holding those into one solo
  foundation wave and runs it first, which stops that resource blocking condition 3 for every round
  after it. The parent still applies the partition test itself, so a wrong mark from the reviewer
  cannot start a bad run on its own.
- **The law and perf scouts run at two points in Phase 3 instead of one, with different owners and
  different scopes.** Each wave agent scans its OWN file allowlist before it returns and may fix a
  trivial candidate in place, which is the run the round-level move had quietly left without an
  actor. The parent then scans at round end over what that round's waves DECLARED they wrote, and
  stages or re-dispatches rather than writing the fix itself. The parent's scope is the wider one on
  purpose: a defect that crosses two waves is only visible over the union, and it is the declarations
  that define that union.
- **`[56] dist integrity` in `scripts/validate-dod.d/56-dist-integrity.sh`.** It reds on a shipped
  file that differs from its source, a planned file the sync never wrote, an exclusion count off its
  pin of 7, a comparable set below 700, a planner exiting non-zero, or a hasher that could not read
  every file. **What a green cannot prove is freshness**, and that limit is worth stating rather than
  leaving to be discovered: `dist/` is untracked and CI builds it fresh on every run, so in CI the
  check compares a tree built minutes ago against the source it was built from and always agrees. It
  proves the sync writes byte-identical copies of everything it plans and drops nothing. The stale
  reading, the one that found the 68 files below, survives only on a developer machine where `dist/`
  has been sitting since the last build. Every file the sync copies into `dist/<runtime>/` is
  hashed against the canonical file it was copied from. The two checks that existed before it both
  read the PLAN, whether the sync still targets all seven runtimes and whether every canonical file
  is named in the manifest, and neither one ever opened a shipped file. The destination set is read
  out of the sync script's own dry run rather than restated, so a future emitter with a different
  layout is covered without editing the fragment, and the seven files written from a heredoc are
  counted and printed as uncompared rather than passing silently.
- **`[75h]` compares the hand-maintained tail of each agent mirror, not just the block the sync
  rewrites.** A mirror that annexed parent-side text used to print nine `ok` lines and exit 0. The
  rule is byte-equality against the template tail above a `<!-- parent-side: not mirrored -->`
  marker, bounded at both ends so the marker cannot be forged: sliding it with the mirror untouched
  reds too, which makes blessing drift a matched two-sided edit. `scripts/sync_agent_mirrors.py`
  gained `--check-tails` to report tail drift alone, every mode exits non-zero on drift so a caller
  chaining under `&&` stops, and an unrecognised flag exits 2 instead of falling through to write
  mode, where a typo in a validator fragment would have had the validator edit the tree it audits.
  The check now reports what it compared rather than how many lines it printed, and the regression
  rows behind it live in `scripts/test_tamper_mirror_tails.py`.
- **A proportionality law in `rules/claim-integrity.md`, with a `### Choosing the depth` procedure
  naming three tiers.** Full independent re-derivation where a wrong claim costs real money or real
  safety, the fresh test output cited by name where a passing test already covers the behavior, and a
  spot-check for cosmetic, naming and formatting claims, with the agent stating which tier it
  applied. No law was deleted and none was softened: proportionality decides WHERE the depth goes and
  is never a licence to assert an unverified fact. The injected digest moved from 777 to 895
  characters against a 900 cap, and that measurement was proved able to come back dirty before it was
  trusted, twice: a deliberately over-long lead returned 903 with the file's last law dropping out of
  the digest, and the unedited file returned 777 with the new lead absent. `hooks/test_inject_context.sh`
  reports 66 passed, 0 failed. The tier paragraphs are deliberately unbulleted, because a bolded
  bullet lead would have entered the digest and spent the remaining budget.
- **Reviewer B closes every report with a completeness section, and it files findings rather than a
  note.** The last step of B's METHOD asks what the review did NOT reach, in five named shapes: a
  check that cannot fail, a claim asserted but never verified, a new gate with no regression
  coverage, a number nobody re-measured, and a file in the diff no lens opened. Each answer is a
  finding with a severity, because a note is read and forgotten while a Critical is fixed, and the
  first two shapes are at least Important on the grounds that a gate which cannot fire is worse than
  no gate, since someone is relying on it. It is a SECTION of B rather than a tenth agent, decided
  deliberately: B is never sliced and already reads every touched file, so the lens costs one more
  step instead of one more context. The evidence is a completeness critic run beside the four lenses
  in this sprint, which found nine findings none of them had, two severe, a shell variable used but
  assigned nowhere in the tree and a brand-new validator check that could never go red in CI.
  Pinned in both halves, instruction and report skeleton, by `[76h]`.
- **Phase 1 questions now ask about the product, not just the plumbing.** Every bank adds questions
  about the proven shape for the domain, whether the expensive half needs building, the business
  rule that has to be exactly right, and the real numbers. New
  `references/clarify-questions/domain-mechanisms.md` states the mechanisms and the failure each one
  prevents. Recommendations must now name a mechanism; "industry standard" and invented figures are
  banned, and `(Recommended)` goes to the option the mechanism supports rather than the smallest one.
  The new file is 305 lines covering twelve domains, and the per-bank question counts are feature +4,
  revamp-redesign +4, fix +3, refactor +3, research +2, debug +2. The same wave repaired `fix.md`'s
  COMPOSITION labels, which had been off by one since `895c9da`, with a duplicate Q6 arriving later
  at `c7e1481`.

- **Waves now declare what they DELETED, and the parent reconciles against that declaration.** The
  wave contract grew a `## Paths deleted` fence beside `## Paths written`, mandatory and empty-not-
  absent, bound by the same file allowlist. Before it, a deleted path reached the parent as a path in
  the round's diff that no wave claimed, which is indistinguishable from the stray edit the
  reconciliation exists to catch, so every deletion had to red. The parent's three checks now treat a
  declared deletion exactly like a written path: same allowlist bound, same one-wave rule, same
  claim. That is stricter than what it replaced rather than looser, because attribution now comes
  from the wave's own declaration, which is authorship, instead of from allowlist membership, which
  on a file-disjoint round names one wave whether or not that wave deleted anything. An UNdeclared
  vanished path still reds, and the red names the allowlists that held it as the lead to follow.

### Changed

- **The parent MAY merge consecutive waves, and the sentence that seemed to forbid it now says what
  it actually bans.** Merging is allowed when no file collides inside the merged set and no dependency
  edge crosses the merge, and it needs no re-review: "read the plan rather than rebuild it" bans
  RE-PLANNING, not merging. It is worth doing because every wave pays a near-constant setup cost, its
  agent re-reading the project rules and quoting the same rule sentences before it writes a line, so
  a run of narrow waves pays that toll over and over. The spec reviewer optimises the plan for
  reviewability and produces narrow waves by design, which is the right thing for it to optimise and
  the wrong thing to dispatch unchanged.
- **One commit closes the whole ROUND, and a round holding one wave is that same rule with one wave
  in it.** The commit point sat at the wave while the wave was the largest unit that existed. Now that
  a round can hold several of them, a per-wave commit would cut one round's work into commits that
  only make sense read together, and a reviewer pulling any one of them would get a tree the round
  never actually left behind. The commit body still lists every task ID that landed, and a wave that
  stopped early contributes only the IDs its agent reported, so the commit and the ticked checkboxes
  say the same thing.
- **Resuming an older work-doc migrates it to the current shape first, in one edit, before any phase
  resumes.** What "current shape" means is a six-point conformance list in
  `skills/hackify/references/work-doc-template.md`, the file that IS the shape, so the migration
  reads it from there rather than from a restatement: section 0 present, the goal anchor present, the
  repo brief present, the skeleton's own section labels in the skeleton's order, every frontmatter
  key the field-reference table declares, and a `status` that agrees with the directory the doc sits
  in. Content is preserved and reorganised, ticked tasks stay ticked, and the migration runs before
  the resume confirmation rather than after, because a re-partition moves the status and the upcoming
  task the confirmation quotes. Archived docs under `docs/work/done/` are exempt from all six: they
  are records of what somebody believed at the time. Stated plainly in the skill and worth repeating
  here, no validator check reaches any of this, because resume runs inside your project and the
  validator only ever reads this plugin's tree.
- **The demo animation's Phase 3 caption now reads `parallel waves, 1 agent`.** Measured at 146px
  against a 165px tile with the same `ImageDraw.textbbox` method the renderer uses, and the method was
  validated first by reproducing two already-recorded numbers exactly. The change was then proved to
  be in the pixels rather than only in the source: the phase 3 tile's text padding moved from 19 to 9,
  matching `(165-146)//2`, while a control tile held at 36. `docs/assets/hackify-demo.gif` went from
  135,296 to 134,070 bytes, still 1200x675 across 7 frames.
- **Phase 5 dispatches exactly ONE reviewer panel and ONE refuter, and the phase ends when the
  surviving findings are fixed.** No second panel, no second refuter, no settle round, no re-scan,
  however much the fixes changed. A defect a fix introduces is fixed in the same fix sequence and
  reported; anything still unresolved when the fixes are done goes to the user as a written list
  rather than as another round. **The rule this replaces was right about the mechanics, and the cap
  gives that up rather than solving it.** A clean panel result describes the diff as it stood when
  the panel read it, not the diff after the fixes, so the last fixes ship without the panel ever
  having seen them. That risk is real and it is priced, not denied. What it buys off is measured: one
  task in this sprint took 14 review rounds and 32 waves, and each extra round bought less than the
  one before. Ten defects did surface after the panel closed, 3 created by fixes and 7 the panel had
  missed, and all 7 were one family, a summary restating a canonical fact that had since moved.
  Narrow, real and known, against a loop with no way to stop. Retired with it: the FULL-round exit
  gate, the settle-round grammar and its `settle ` echo prefix, blob-hash-keyed verdict carry-over,
  the scope ledger's `blob` column, and Reviewer B's `Round:` marker. The `':(exclude)docs/work/*'`
  pathspec keeps its job, because it defines the reviewed diff and never depended on the round count.
- **The reviewer panel is no longer evidence-gated: A, B, D and F each run on every non-trivial diff,
  and E joins on a UI-bearing one.** E is the only conditional lens left, and it is omitted rather
  than folded, because with no UI surface it leaves no residual for anyone else to carry. The gate
  folded A, D or F into B whenever the diff showed no surface for their lens, with B running the
  folded lens's residual checklist so nothing was formally dropped. The saving was real; the cost was
  larger. On the diff that retired it the un-gated panel returned 41 findings where the gated one had
  returned 15, because a checklist run by the reviewer that already read the diff for a different
  purpose is not the same as a reviewer whose whole context is that lens. Folding moved the words and
  lost the attention. **The bill is stated rather than buried:** two more reviewer contexts on every
  non-trivial wave, paid every time, recovered nowhere. Folding had no remaining user afterwards, so
  `{{folded_lenses}}`, the residual-checklist mechanism, the `[folded:` finding tag and the gate
  table went with it rather than surviving as an always-`none` vestige.
- **The phase ledger says which substrate it is on, prints a header you can read at a glance, and
  re-prints inside a phase and not only at its edges.** It used to say to degrade to the printed
  block *without comment* when no todo tracker exists, and that was the defect: silence about a
  missing tool is indistinguishable from silence about a skipped step. One line, once, at the first
  print, naming the substrate. The block now carries phase numbers and a `(<done> of <total>, Phase
  <n>)` header, so a reader is not counting rows to find where the task is. And the re-print
  obligation gained a second trigger: **the end of every wave round inside a phase**, not only phase
  boundaries. Phase 5 stayed open for hours in this sprint across a panel, a refuter and four fix
  waves, none of which is a boundary, so the old rule permitted total silence through the longest
  phase of the run. What can honestly be checked is written down beside the rule: `[98]` catches a
  section 0 that contradicts its own frontmatter, which is consistency and not currency, and a ledger
  that stopped being updated two hours ago is perfectly self-consistent and passes. The in-phase
  re-print is enforced by the rule and by a reader noticing the silence, and by nothing else.

### Fixed

- **Sixty-eight files in the built runtime trees were shipping the pre-fix text of their source.**
  The figures below are a **historical measurement, taken on 2026-08-26 before the repair**, and they
  are not reproducible now: `dist/` was resynced in that same fix, so re-running the check today
  compares a fresh tree and reports zero drift. Dating them is the honest option, because a number
  nobody can re-measure is a claim, not a record. Twelve rounds of fixes had rewritten canonical
  files and the trees under `dist/` were never re-synced, so 68 of the 791 compared files were
  carrying 13 source files as they read earlier in the sprint, and anyone installing from a built runtime would have got that older text. The worst
  single instance makes the size of it legible: the shipped copy of `agents/wave-implementer.md` was
  3,114 bytes behind, still carrying the round-end scout scope four rounds of this sprint had spent
  their time correcting. Repaired with `scripts/sync-runtimes.sh` across 798 files and seven
  runtimes, and `[56]` above is what keeps it repaired. The task that was supposed to cover this had
  been ticked for twelve rounds, which is the real lesson: a done-claim about a generated artifact
  expires every time its source changes.
- **The wave contract's own verification step could not tell a concurrent wave's edits from an
  allowlist breach, and the first thing that replaced it could not fail at all.** Step (a) diffed the
  WHOLE tree against one wave's allowlist, which is correct under strictly serial dispatch and wrong
  the moment two waves run at once: every agent sees its neighbours' files and reports a breach that
  never happened. Two agents in this sprint's own first round hit it independently and both marked the
  step inapplicable by hand, which is the worst available outcome for a gate, a check that survives by
  being ignored. What ships is a two-sided gate instead. Each agent reports the paths it wrote under
  `## Paths written`, scoped to its own wave, and the parent reconciles the round three ways at round
  end: every declared path inside that wave's own allowlist, no path claimed by two waves, and no path
  in the round's diff left unclaimed. The third check is the one the other two cannot cover, the stray
  edit no agent admits to, and it has to union `git diff` with the untracked files, since a file that
  was created and never staged appears in neither the diff nor any declaration. The reconciliation
  block is written as a real array so it iterates identically under bash and zsh; the string form it
  replaced was silently correct in one shell and silently wrong in the other, and silent-and-wrong is
  the expensive one. Worth recording rather than fixing quietly: the original defect was created by
  this release and caught by the release's own agents, which is the only reason it did not ship.
- **Two mechanisms this release shipped were absent from this entry, which is the same defect class
  the entry documents.** Recorded now rather than left to the next reader to rediscover. **(1) The
  resume re-derivation bound.** `skills/hackify/SKILL.md` step 4 of Pause / Resume bounds a resuming
  agent to re-deriving the plan for the UNTICKED tasks and nothing beyond them. That bound is not
  arbitrary and it is not the one the work-doc's own Q&A #10 proposed: the frontmatter carries no
  plugin-version stamp, so "which rules moved since this doc was written" is a question the document
  cannot answer, and an agent told to re-derive only what a changed rule invalidated has no way to
  tell which rules changed. The unticked remainder is the only bound a resuming agent can actually
  derive from what is on disk. **(2) The wave contract refuses an incomplete dispatch, and reads its
  concurrency out of `current_task`.** `{{exclusive_resources}}` is the input whose absence is
  silent: the wave's method branches on what it NAMES, so a prompt that omits the line reads as
  "names nothing" and the wave runs an exclusive suite against a harness a concurrent wave is
  truncating, reporting PASS. An input that is missing, or that still carries literal `{{...}}`
  text, means the dispatcher did not decide, so the agent REFUSES the dispatch, names the input that
  did not arrive, and writes nothing; `none` is a decision and an absent line is the absence of one.
  On the parent's side, frontmatter `current_task` carries every task in the round across all of its
  waves (`R<n>:T<a>+T<b>+…`), which is what makes a round's concurrency legible on disk to a
  resuming agent rather than only in the dispatch message that scrolled away.

## [0.15.1] - 2026-08-25

> **The code is the only source of truth, and the workflow now says so in every prompt.** A document
> is a claim about a repository, not the repository. This release adds a fifth always-on rule built
> from fourteen laws, each one traced to a mistake this project actually made, plus the checks that
> enforce the parts a machine can enforce. Dev-facing and user-facing both: the rule reaches every
> prompt, the checks run in CI.

### Added

- **`rules/claim-integrity.md`, injected into every prompt as the fifth always-on rule.** Fourteen
  laws: re-derive facts from the code rather than reading them off a page, prove a claim with fresh
  output or do not make it, open every citation you write and every one you trust, treat a number
  you did not just count as already wrong, and never read a clean result as evidence without first
  showing the method could have come back dirty. Wired in `hooks/hooks.json`, in the sync manifest,
  and in check `[38]`, whose pass line and comment both said "four" and now say five. The digest
  that survives compression after the first prompt is 777 characters against a 900 cap, verified by
  running the injector rather than by reading the file, and `hooks/test_inject_context.sh` grew from
  29 tests to 45 with every new guard tamper-proved.
- **Three checks that catch a claim a document cannot keep**, each with its own unit suite and each
  wired into CI. `[93]` in `93-token-declarations.sh` resolves every `{{token}}` used in a prompt
  against that prompt's declared INPUTS. `[94]` in `94-section-exists.sh` catches an instruction to
  use a work-doc section the template no longer has. `[95]` in `95-literal-absent-claims.sh` catches
  a sentence claiming a phrase is unpinned when the phrase is present elsewhere in the tree.
- **`[97]` in `97-test-suites-reachable.sh`, so a test suite on disk that nothing runs is a
  failure.** A suite must be named in `ci.yml` or be reachable by import from a file that is. A
  suite nobody runs is the same defect as a check fragment nobody sources.
- **A frozen answer key and a replay runner, so the sprint's own score stops being something
  anybody types.** `scripts/claim_corpus.json` labels thirteen real findings before any check
  existed, `scripts/claim_fixtures.json` pins each one's evidence by git blob SHA, and
  `scripts/replay_claim_checks.py` runs each shipped check against its own pinned fixture. A catch
  requires a non-zero exit, a pinned path in the output and a witness literal, all three read from
  fixture data rather than from an authored expectation.
- **Check `[91]` in `scripts/validate-dod.d/91-claim-resolvers.sh`, so a release note cannot cite a
  check that is not there.** Every live `check [NN]` sentence in the tree is resolved against the
  ids the validator really declares, and one that resolves to nothing turns the run red. The defect
  it was written for is this repo's own: a sprint recorded that breaking a `CHANGELOG.md` line
  pointer would redden `[71]`, and no fragment declares `[71]` at all. Sourced from
  `scripts/validate-dod.sh`, so it runs in CI with every other check.
- **`[57]` now opens the `:N` half of a citation instead of only the path.** A pointer like
  `some/file.md:123` makes two claims, that the file is there and that the line is, and only the
  first was ever read. The second rots faster, because a file survives a refactor that moves every
  line in it. `scripts/check_doc_links.py` counts the cited file for real and fails a line number
  the file does not have, ranges judged at their last line. Where the path resolves nowhere it stays
  quiet about the line, so one broken pointer does not print as two findings.
  `scripts/test_doc_link_lines.py` is its own suite and `.github/workflows/ci.yml` runs it.
- **`[98]` and `[99]`, so an archived sprint cannot claim a phase that never ran.** Four assertions
  across two checks. `98-work-doc-ledger-sync.sh` reads the progress list: a record filed as finished
  must have closed every row of it, and a record written since the list became a section must carry
  one at all, which closes the path where deleting the list turns a failure into a pass.
  `99-work-doc-status-claims.sh` reads the status line: it must be one of the values the template
  declares, read out of that template at run time rather than copied into the check, and it must
  agree with the folder the record sits in. They were written against a real archived sprint whose ledger showed
  Phase 5 still running under a `done` stamp, and the evidence said the ledger was the honest half:
  the retrospective was never written and no report was emitted. That doc now records what actually
  happened rather than being tidied to make the check pass.

### Changed

- **Ticking a phase means writing the file, not printing a line.** Every phase-open and phase-exit
  instruction now says the `## 0. Phase ledger` block is rewritten in the work-doc, with frontmatter
  `status` advanced in that same edit, before anything is re-printed in chat. The old wording asked
  for the chat re-print at every boundary and reached the durable copy through the word
  "additionally", so a session that ended between two boundaries left the file describing a phase
  the work had already passed. Chat scrolls away; the file is what resume and archive read.
- **Phase 6 finishes in a different order, and the ledger closes before the file moves.** The update
  log and the HTML report are produced first, while the work-doc is still at its live path, with the
  report written straight to the archive path it is about to occupy. One edit then closes both of
  the last two ledger rows and writes `status: done`, and the rename runs last as the only step
  carrying no content change. The old order archived the doc first, which meant every finished
  sprint spent the length of the summary sitting in `done/` with a row still open, the exact state
  `[98]` reads as work that stopped mid-phase. What the swap gives up is the rule that the summary
  was the reward for archiving. What it buys is the better wreckage when a session dies mid-finish:
  a doc stranded at its live path claiming `done`, which `[99]` catches, instead of an archived doc
  quietly claiming a phase nobody ran, which is the defect that started this.
- **The sprint report can be published as a shareable link.** The finish step still renders the
  same self-contained page to disk, and on runtimes that can publish one it also hands you a link
  instead of a file path to open by hand. The renderer gained a second output mode for it, because
  the publisher supplies its own page wrapper and the existing output is a complete document. This
  is an optional upgrade with a written fallback, not a replacement: on the six runtimes where
  publishing is unverified the file on disk is still the deliverable, and no phase can be blocked by
  the absence of a publisher. The report template already followed the reader's browser setting for dark mode; it now also honours an explicit light or dark choice made by whatever page it is published inside.
- **`paused` is a declared status value.** The finish menu's "keep the branch as-is" option has
  always told the agent to write `status: paused`, and the template declared eight values without
  it, so a paused sprint held a status nothing recognised. Nine values now, still declared in one
  place.

- **The shared repo brief has to show its working.** The block handed verbatim to every dispatched
  helper now ends each line with the command or `file:line` that established it, and a line with no
  evidence behind it does not go in. A wrong fact in that block used to reach a whole round of work
  at once with no cheap way for anyone to notice. The cap moved from 200 to 350 words to pay for
  that and nothing else.
- **Three validator files that had run out of room were split**, each keeping its check IDs so an
  existing citation still lands on a live block.
- **The always-on pointer says the same thing in 114 characters instead of 246.** Five rules files
  means five pointers on every prompt that is not a refresh turn, so each word of wording around the
  digest is paid for five times. The pointer now names its file, says it binds verbatim, carries that
  file's own core and says to re-read the path for any detail outside it, and nothing else. Across the
  five that is 3,557 characters per prompt down to 2,897, measured by running the injector rather than
  by reading the source. The shared wording was deliberately NOT hoisted into one entry emitting it on
  behalf of all five, which would have saved more: `hooks/hooks.json` gives each rules file its own
  UserPromptSubmit entry, in its own process, so one file going unreadable costs that file and nothing
  else, and wording borrowed from a sibling entry would hand that property back. The saving is a
  shorter sentence, not a de-duplicated one, and the difference is the whole point.
  `hooks/test_inject_context.sh` gained a row that reds the day someone tries it, driving four files
  to their pointer turn beside a dead entry and requiring each to carry its own title, path, digest
  and binding sentence with nothing borrowed. It went from 45 tests to 66, and the new row was proved
  by tamper: hoisting the sentence to a single carrier turns twelve of them red.

### Fixed

- **Three release notes cited checks that have never existed.** Two said `[50]` and one said `[70]`;
  both took a file number for a check ID. They now say `[24]` and `[38g]`, each confirmed from the
  code rather than guessed.
- **A comment claimed the shared brief is required on 14 prompts when the tree holds 12.** The
  number is gone rather than corrected, and the comment carries the command to recount it, because
  a number in a comment only rots again.
- **The link checker called a runtime tree's own subsetting a dead pointer.** The built bundles
  ship skills but no `docs/`, so a sentence pointing at an archived work-doc could never resolve
  there. The checker's own notes already argued why that is not a defect, and applied the argument
  only to which files get scanned, never to which files get pointed at. It now judges that
  structurally, by whether the directory is present at all, so the source tree stays strict.
- **Two sentences said the sync script reads the runtime mapping table.** It does not reference that
  file at all. The per-runtime writers carry the mapping in code, which means drift between the two
  is silent, and the note now says that instead of promising a breakage that would never come.
- **Six sentences said the hook injects four rules files.** Adding the fifth made all of them false
  at once, which is the new rule's own sixth law landing on the change that introduced it.

## [0.15.0] - 2026-08-24

> **Phase 3 dispatched one agent per same-module task batch, capped at three tasks; it now dispatches exactly one agent per execution wave, in every mode, with no cap and no module split.** The saving is tokens and coherence, not wall-clock, and this release does not pretend otherwise: several agents running a wave in parallel finish sooner than one agent working through it in order. Decision **#9-B** took that trade with the cost stated, and decision **#11-A** is what pays for the wider blast radius, an agent that cannot finish a task stops there, keeps everything already on disk, and reports which task IDs landed. The Phase 5 refuters collapsed the same way, one agent per round carrying both lenses. Underneath all of it sat a gap worth more than the saving: nothing in this repo grepped an agent-type string, so `hackify:wave-task-implementer` could be renamed on disk while every dispatch site kept asking for a type that no longer resolved, with the validator fully green. Check `[40]` closes that from both ends. The sweep that followed the rename found four documents describing dispatch shapes that did not exist, three of them already wrong before this release began.

### Added

- **Check `[40]`, in `scripts/validate-dod.d/73-implementer-rename.sh`, pins the Phase 3 implementer's agent type from both ends.** `hackify:wave-implementer` must be present at all four dispatch sites (`skills/hackify/SKILL.md`, `skills/quick/SKILL.md`, `skills/yolo/SKILL.md`, and the type-to-INPUTS table in `parallel-agents/README.md`), and `hackify:wave-task-implementer` must be absent from every live file, by a union of two `git grep` scans, one reading the worktree and one reading the index, both scoped to the tracked tree minus `dist/`, `docs/work/`, `CHANGELOG.md` and the fragment itself. A presence pin on its own cannot see a stale dispatch site sitting beside a corrected one, which is exactly the shape a half-applied rename leaves. The site list carries its own length written beside it, so dropping a site cannot quietly take that site's check away with it, and each half of that union refuses a clean result that arrived with anything on `git grep`'s stderr, because exit status 1 covers an honestly clean tree AND a scan that could not read what it was told to read. Neither half is safe alone, which is why both run: a worktree scan reports rc 1 with nothing on stderr for a tracked file that was deleted without staging the deletion, replaced by a directory, or marked `skip-worktree`, and an index scan does the same over an unmerged path, so either one on its own greens over a blob that still holds the retired name. The block also pins the **#11-A** reporting sentence on both mirror sides; the stopping half was already pinned in `71-release-mechanism-pins.sh` and the reporting half was not, and the reporting half is the mitigation that bought one agent per wave its wider blast radius. Three retired batching phrases are banned by the same scan. The bare word `batch` is deliberately left alone, because a batched wizard questionnaire and a flat batch of parallel subagents are a different sense of the word and both still ship. Twelve tamper steps proved every pin bites, run against a backup copy and restored by file rather than `git checkout`, with HEAD identical before and after, plus two controls that plant the banned strings inside an EXCLUDED path and require the run to stay green, which is what rules out a malformed pathspec that silently scans nothing.

### Changed

- **Phase 3 dispatches exactly one agent per execution wave, and the implementer was renamed to match.** `agents/wave-task-implementer.md` is now `agents/wave-implementer.md`, mirrored byte-for-byte against `skills/hackify/references/parallel-agents/phase-3-implementation.md`, with no alias left behind. The three-task cap and the group-by-module rule are gone rather than relaxed: decision **#9-B** is pure per-wave with no width valve, in full hackify, quick and yolo alike. Each task keeps its own file allowlist and the agent is bounded by their union, so the union never widens what one task may touch. Decision **#11-A** ships as its own clause in the contract, stop at the first task you cannot finish, keep everything already on disk, name which task IDs landed and which did not. The contract's VERIFICATION clause was inverted to match: it previously suppressed the report entirely on a failure the agent could not fix inside its allowlist, which would have hidden which of N tasks were on disk, and hiding that is the opposite of what #11-A promises. The OUTPUT skeleton gained a `## Wave status` header so the parent reads the landed split instead of counting headings. One planning constraint dissolved on contact: the rule that only one task per wave may own a given validator fragment existed to stop two concurrent agents colliding on one file, and with one agent per wave there is no second writer to collide with.
- **One refuter per Phase 5 round, and the Critical bar survived the collapse.** Decision **#14-A** on its own would have weakened a real safety property: a Critical used to die only when two independent agents both refuted it, and one agent means one refutation kills it. Decision **#2-A** keeps the bar by moving it from agents to lenses, so a Critical may only be refuted when BOTH lenses fail, reproduction and authority, each with its own file:line counter-citation. Reproduction refutes while authority upholds and the Critical lives. Important and Minor still die on one refutation. `{{assigned_lens}}` is retired as an input, since the single agent always carries both, and a Critical's OUTPUT reports each lens verdict separately, because a merged verdict hides exactly the thing the rule protects.
- **Reviewer F's METHOD was inverted, because this release falsified the reason F was given for existing.** F was told to audit same-wave seams FIRST, on the grounds that same-wave files came from separate agents blind to each other. One agent per wave makes that exactly backwards: same-wave files now come from one context that saw both sides, and the risky seams run ACROSS wave numbers, or out to a consumer the diff never touched. F is not weakened and was not removed. Its justification now rests on what is still true, that a wave's implementer is blind to every wave that ran before it and to every line of pre-existing code, which is where a producer and its consumers drift apart. The METHOD and its VERIFICATION item were inverted together in the template and its agent mirror, the two files that carry them, and the `{{task_file_index}}` dispatch note was corrected in the Phase 5 protocol's routing table as well, which is the only line of F's wiring that lives outside those two. The two mode skills never carried that dispatch note at all; what they carry is F's one-line reason for existing, and only yolo's needed rewriting, because quick's already said that one implementation agent leaves seams against existing code. This is the second time in one release that changing a rule falsified the REASON another component was given for existing, and both were caught by reading the neighbours rather than by any check. Nothing in the validator can see a rationale that has quietly become untrue, which is worth stating rather than letting a green triad imply otherwise.
- **The hero animation was regenerated, because the Phase 3 caption was baked into its generator as source rather than read from anything the rename touched.** `docs/assets/hackify-demo.gif` is drawn by `scripts/gen-demo-gif.py`, which carries each phase's one-line caption as a string literal in its own frame table. Nothing links that table to the files describing the dispatch shape, so every markdown file in the repo could be corrected and the shipped animation would keep advertising the retired per-task batch dispatch, to the one audience most likely to be reading the project for the first time: the README's hero image is what a visitor sees before a single line of prose. The caption now reads one agent per wave and the GIF was re-rendered from the corrected generator. It is the only copy of the dispatch shape in the repo that is not text, which is exactly why it outlived every text fix and had to be found by looking at the picture. Re-rendering it also cut the file by 40.4%, from 226,856 bytes to 135,296, and that half was a deliberate call rather than a free ride on the caption fix. The generator had always saved with Pillow's `optimize` flag off, so every shipped copy carried frame data the encoder could have dropped, on the one asset a first-time visitor downloads before reading a word. Turning it on changes nothing anybody can see: the seven frames come back pixel-identical at 1200x675, and on identical content the flag alone measures 40.5%, the small gap to 40.4% being the 635 bytes the longer caption added. The refuter had re-routed this to Phase 6 as adjacent cleanup, and decision **#5-C** overrode that routing to pull it into the release rather than ship a known 40% of waste for another version. Eight further rows of encoder settings were measured at the same time and their numbers written into the generator, so the next person reads them instead of re-deriving them.
- **The parent's side of a wave gained two rules, because one agent per wave changed what a correct wave diff looks like.** The union of the wave's allowlists used to be checked both ways, and while several agents each finished their own slice that was a fair check. With one agent that stops at the first task it cannot finish, the union is a SUPERSET of what a correct run writes: a union path missing from the diff is decision **#11-A** working as designed, and only a diff path missing from the union is a violation. Asserting the reverse would have turned every honest early stop into a false red, which is precisely the pressure that would make an agent paper over a stop instead of reporting it. The second rule is the one the first protects: tick ONLY the task IDs the report's `## Wave status` names as landed, never the whole wave, because ticking a task the agent never finished records work that is not on disk, and that is the one thing a work-doc must never do. Both rules ship in `parallel-agents/phase-3-implementation.md`, `phases/phase-3-implement.md` and `references/implement-and-test.md`, together with the split that follows from them: a not-landed ID goes back out in the next wave dispatch when the agent stopped for an agent reason, and drops to Phase 3b when it stopped for a plan reason.

### Fixed

- **Four documents described dispatch shapes that did not exist, and three of them were already wrong before this release.** `references/orchestration.md` said one implementer per task, which was stale against the per-batch protocol that preceded this one. `parallel-agents/template-contract.md` said a wave's tasks go to one agent each, the third file found carrying that same claim after `SKILL.md` was fixed for it and this one was not. And the refuter's row in the type-to-INPUTS table listed `finding_verbatim`, `lens`, `project_root` and `head_sha`, of which `lens` was retired by this release and the other three had already drifted from the template's real `project_root` / `base_sha` / `head_sha` / `findings_batch`. That row is the sharpest of the four, because a dispatcher builds a call out of it: wrong, load-bearing, and pinned by nothing, which is the same defect class as the unpinned agent-type string. The fourth, `phases/phase-2.5-spec-review.md`, was made stale by this release itself and fixed inside it, it still described the dispatch batches the spec reviewer had just stopped emitting.
- **A reviewer panel over the finished diff found roughly fifteen more sites in the same class, and no check in this repo could have found any of them.** The four documents above were the sweep that followed the rename; this is what a full Phase 5 panel turned up afterwards, over a tree the validator was already calling green. The sites run across the README's FAQ, the two mode skills, the shipped `implement-and-test.md` reference (whose commit section still said one commit per task while its own wave loop three pages up said one per wave), two Phase 5 reviewer prompts and their agent mirrors, the type-to-INPUTS table in `parallel-agents/README.md`, and check `[40]`'s own explanatory comment. Several of them were not instructions at all but RATIONALES, sentences that were true the day they were written and were quietly falsified by a rule change made later in the same sprint. `[40]`'s comment is the clearest case: it stated that the CHANGELOG exclusion waived nothing and existed purely as future-proofing, and the release note you are reading falsified that sentence by quoting the retired type. A stale rationale is invisible to every mechanism this repo has. It breaks no test, trips no ban token, and reddens no pin, because the code beside it is correct and only the reason given for it has died. That is why a panel found these and the validator did not, and it is worth saying plainly rather than letting a green run imply the sweep was complete.
- **`v0.14.2` had never been tagged, and nothing in the repo would have said so.** It surfaced only because bumping to 0.15.0 moves 0.14.2 below the in-flight version, which is where `[27d]` starts looking; while 0.14.2 was itself in flight the missing tag sat outside that check's window by construction. The tag was backfilled at its release commit. The previous release closed the known-untagged list to empty and called that the state to defend, and it went undefended one release later.
- **The validator orchestrator's hand-written fragment map did not list `[40]`.** `scripts/validate-dod.sh` opens with one row per fragment naming the check IDs it owns, and `[76i]` compares only a row's RANGE endpoints. This row's last item is a single ID rather than a range, so its upper end is skipped by construction and the omission reddened nothing. A hand-kept record going quietly stale is this repo's most-repeated defect, and it turned up again inside the sprint that keeps finding it.

## [0.14.2] - 2026-08-23

> **Phase 5 could not close, for a structural reason no reviewer could have fixed by being more careful.** The loop may only exit on a round that leaves every byte of the diff covered by a live verdict, a verdict dies when its path's blob hash moves, and the work-doc is both a changed path in that diff and the authority Reviewer B measures the diff against. So writing a round's result into the work-doc killed the work-doc's own verdict and mandated another round, whose result had to be written into the work-doc. This sprint's doc was rewritten 25 times. The reviewed diff now excludes `docs/work/`, so the ruler stops being one of the things measured; B still reads it in full and simply stops grading it. Alongside that, three separate things were found reporting success while measuring nothing, which is the failure mode this release is really about: the law scanner threw away every file whose name begins with a dot and counted it as neither scanned nor skipped, two enforcers of the same 500-line cap disagreed by exactly one line, and three pins added a wave earlier turned out not to bite at all.

### Added

- **Two checks now guard the validator's own wiring, `[0]` and `[0b]`, and neither one lives in a fragment.** A check that guards the source list cannot be reached through the source list: delete the line that sources it and the guard leaves along with the thing it was guarding. So both are written out in `scripts/validate-dod.sh` itself, which is the one file that cannot be un-sourced because running it is the run. `[0]` walks both directions, every fragment on disk is sourced and every source line names a fragment that is really there, and it prints through `printf` rather than the colour helpers because `00-helpers.sh` is a fragment like any other and its source line can go too. `[0b]` puts a floor under the run's own ok-line total, which is the loss `[0]` cannot see: a fragment that is still sourced while its contents stop checking anything. Both were measured rather than feared. Deleting the single source line for `71-release-mechanism-pins.sh` dropped the run from 1400 ok lines to 851, with zero failures, "ALL CHECKS PASSED" printed, and exit 0.
- **Check `[76g]` pins the `docs/work/` exclusion at all four sites that carry it**, counting both the pathspec and the written reason at each, and failing loudly when a listed file is missing or empty rather than reporting zero occurrences as a pass. The count uses `grep -oF` rather than `-c`, because the exclusion appears twice on some lines and `-c` counts lines and not occurrences, and never `-E`, because the literal is almost entirely regex metacharacters.
- **Check `[80b]` holds the two 500-line counters to each other.** `[80]` counts with `wc -l`, the lawkeeper scanner counts its own lines, and the agreement between them had only ever been prose. It probes at both sides of the cap boundary, which is the only place an off-by-one is visible, asserts `files_scanned` before reading any verdict so a scan that never reached the file cannot pass as clean, and asserts newline termination first so a stripped terminator blames the file rather than the scanner. The probe is the fragment itself, resolved from `${BASH_SOURCE[0]}` and made relative to the repo root, because a pinned path dies the day that file is split and the two fragments sitting at the cap are already queued for exactly that. As shipped in 0.14.2 that reason was false: the sentence claimed a path that survives a split while the code named this exact file as a string literal, so a rename would have reddened the check rather than moved it. Corrected here rather than left standing, since the claim shipped in these release notes as well as in the comment.
- **The law scanner now publishes what it discarded.** Five counters (`paths_outside_root`, `paths_in_skipped_dir`, `paths_not_found`, `paths_unsupported`, `paths_unaccounted`) mean the handed list, the scanned list and the dropped list have to add up, and the law-scout runner reconciles them before reading a single finding. The reconciliation sums the drop buckets by name prefix, so a bucket added later is counted without anyone editing the snippet. Eight new tests cover it, six written failing first, including one that hands three paths, scans one, and requires the unaccounted count to report two.

### Changed

- **The four files that had run into the 500-line cap were split, moving roughly eleven hundred lines and changing no behaviour.** `70-invariants-and-new.sh` handed its release-mechanism pins to the new `71-release-mechanism-pins.sh`, `77-reviewer-roster.sh` handed the roster-claim half of the roster guard to the new `79-standing-member-invariant.sh`, `test_ban_tokens.sh` became a driver plus four fragments under `scripts/test_ban_tokens.d/`, and the lawkeeper scanner's own suite handed its scoped-scan half, the path-list parsing and the three counter families, to the new `skills/lawkeeper/scripts/test_scoping.py`, because growing the file that tests a 500-line cap past 500 lines would have been the joke it sounds like. Check IDs moved with their blocks instead of being renumbered, so a work-doc or a release note citing `[38g]` still lands on a live block. The split also bought a failure mode none of the three single SHELL files could have had, a source line that quietly goes missing and takes its whole section with it, which is the hole `[0]` above was written to close and the reason the ban-token suite grew a wiring gate that exits outright rather than printing a partial verdict over a truncated run.
- **Two hygiene rules stopped firing on the two kinds of file that are supposed to trip them.** The rule that flags a commented-out line of code and the rule that flags a left-behind debt marker were both hitting test fixtures, where a commented-out line IS the fixture, and rule documentation, where the marker is being quoted rather than left behind. Neither could be fixed by writing the test differently, because the thing under test is the text itself. Test paths now waive those two rules only, alongside the waivers they already carried, and markdown gets its own prose waiver list rather than borrowing the test one, so a future rule that should apply to docs but not to tests has somewhere to go. Every other rule still applies to both.
- **The two enforcers of the append-only exemption now have to name the same files or the build goes red.** The 500-line cap is enforced in two places, a shell check and the Python scanner, and each carried its own idea of which files are exempt from it. The shell side now imports the scanner's set and compares, so the lists cannot drift apart quietly. It imports the module rather than reading the literal out of the source, which means reformatting the Python cannot break the check, and an import that fails or a set that comes back empty is a failure rather than an agreement between two empty lists.

### Fixed

- **A settle round could not be declared complete by any dispatch, because two rules contradicted each other.** A round closes only when every dispatched lens echoes back the scope it was handed, marked as the final round, which is how the parent learns no lens quietly reviewed a subset of the diff. Reviewer B has no scope to echo: B is never sliced, and a release-mechanism pin fails the build the moment B's prompt gains a scope placeholder. So one rule required exactly what another forbade, and no dispatch could close the loop. B is now exempt from the SCOPE echo and writes a round marker instead, a first report line naming the round its dispatch asked for, which carries no pathspec and so leaves the pin green; a B that reports any other round, or none because its dispatch named none, still leaves the round unclosable. The pin was deliberately NOT accepted as a substitute for the echo, and the first draft of this fix, which did accept it, is retracted with it. The pin is a universal over TEMPLATES, no copy of B's prompt may carry the placeholder; an echo is an existential over RUNS, this instance read what it says it read. Neither implies the other, a dispatcher can narrow B in prose without touching the placeholder, and one already had. B's silence was never coverage, and reading it as coverage was the defect. The marker is not coverage either, it only names the round the dispatch asked for, so a B that read every path and a B narrowed in prose emit the same string; coverage rests on the scope ledger, one row per changed path.
- **The law scanner silently dropped every dotfile it was handed.** `str.lstrip('./')` strips a character set and not a prefix, so `.github/workflows/ci.yml` became `github/workflows/ci.yml`, matched nothing on disk, and was skipped by a bare `continue` with no counter behind it. A file that vanishes raises no findings, so the report was byte-identical to a clean scan. Now `removeprefix('./')`, and every exit from the path loop goes through a counter.
- **The scanner counted one line more than `wc -l` on every newline-terminated file.** Splitting the source on newlines keeps the phantom empty element a POSIX terminator produces, so a file sitting exactly at the cap read one over it and was flagged, while a file missing its terminator read one under and slipped past. `70-invariants-and-new.sh` is at exactly 500 lines, passed `[80]`, and was flagged by the scanner at the same time. Deliberately not `str.splitlines()`, which corrects the count but also breaks on form feed, vertical tab and the Unicode separators; those extra break points would renumber every other rule's findings, and the masked twin rejoins the list with a newline before the lexer reads it, so a split on any other character would quietly rewrite the source being analysed.
- **CI needed `fetch-tags: true` as well as `fetch-depth: 0`.** All four combinations were tested rather than reasoned about: depth 0 with tags off still lands zero tags on a non-shallow clone, which under the fail-closed tag check would have reddened every run. The recommendation this replaced was `fetch-depth: 0` alone, and it was wrong.
- **Three pins added in the previous fix wave did not bite, and one probe that reported them as vacuous had edited nothing.** `[27d]` now pins its never-cut version list with an expected count placed outside the block that can early-return, the plant suite counts the batched ban calls that actually ship, and `[70]`'s two lists gained size guards. Every pin in this release was proven by tamper in both directions, with the probe comparing the file against a backup and reporting whether the edit actually landed, because a `sed` pattern that matches nothing passes a validator exactly like a correct pin does.
- **All released versions now resolve to a real git tag.** `v0.3.1`, `v0.14.0` and `v0.14.1` had never been cut, each verified against the version recorded in `plugin.json` at that commit rather than against the commit subject. The known-untagged list is now empty, which is the state to defend.
- **The 500-line cap had never been applied to the repo root at all.** `[80]`'s search list is six directories, and `find` on a directory never climbs out of it, so `CHANGELOG.md` and `README.md`, the two longest markdown files this repo ships, sat outside the only mechanism enforcing the cap. The scan now reaches the root as well. `CHANGELOG.md` carries a documented append-only exemption, because a changelog grows by one entry per release and has no second responsibility to split out, and `README.md` is enforced for real. The exemption is from the cap and never from the scan, so an exempt file is still opened and still counted, and the check names `README.md` as the root file it enforces rather than counting root files, because with the changelog exempt a bare count is satisfied by the exempt file on its own.
- **Rule (c) of the marketplace pin printed green over an empty set.** With `.claude-plugin/marketplace.json` set to `{"plugins": []}` the run printed "ok every channel version equals plugin.json" while rules (a) and (b) beside it correctly reddened. The mismatch counter starts at zero, so a `.plugins` array that is empty, unparseable, or no longer carrying the queried fields left the loop body unexecuted and the clean verdict standing. `[27d]` four lines below had gained exactly this floor a wave earlier; its sibling in the same file had not.
- **`[0]` and `[0b]` shipped with no automated test, only a manual probe written into their own comments.** The ban-token suite now builds a throwaway validator under its own temp directory, out of a copy of `scripts/validate-dod.sh` with every fragment it sources replaced by an empty stub, and drives all four branches through it: a fragment on disk that nothing sources, a source line naming a fragment that is not there, a wiring scan over a set that has collapsed to three, and both sides of the ok-line floor. The stubs are what make `[0b]` testable, since against the real fragments the count is whatever the repo prints that day and neither side of the floor is reachable. Every case asserts something present as well as something absent, because a fixture that failed to build emits no output and an absence-only assertion passes over silence. All four were then proven by mutating the guard in a throwaway worktree and watching the cases fail.
- **The measured ok-line totals beside `[0b]` were stale, and the reason printed next to them was wrong.** The gap between the shell-side counter and a `grep -c` over the transcript is per INVOCATION, not per checker: `[57]` runs the doc-link checker twice, once over the source tree and once over `dist/claude-code`, and `[85]` runs the design-spec checker once. It also is not a constant, because `dist/` is gitignored and the second invocation prints `skip` on a tree that has never been synced. Both halves are now measured from the same run rather than quoted from the last person who quoted them.
- **A file the scanner could not open was reported exactly like a file with nothing wrong in it.** A plain, readable 2.3 MB file of 200,000 lines, four hundred times over the 500-line cap, produced `files_scanned 0`, `paths_unaccounted 0` and no findings at all. It landed in a `files_skipped` bucket that nothing downstream read, so the reconciliation added up and the report was byte-identical to a clean one. That bucket is gone, replaced by `unread_too_large` and `unread_unreadable`, and the summary now says "1 file(s) located but never opened. Never covered, in any mode." The two new counters are deliberately not named `paths_*`, because the reconciliation sums the drop buckets by name prefix and a new `paths_` bucket would have been silently absorbed into the total it was supposed to disturb. Three smaller holes on the same path closed with it: the root-escape guard resolved its argument twice and could disagree with itself between the two calls, `PathListing.supplied` recorded truthiness so an explicitly supplied empty list read as "never supplied", and a path-list line that carries no path once normalized (a bare `.` or `./`) now lands in `lines_malformed` instead of being admitted as a path and counted in `paths_not_found`, where it read as a file the diff had deleted.
- **The check that proves no home directory path ships in the plugin returned zero for a path that was not there.** It ran one recursive `grep` across a hardcoded list of files and directories, summed the per-file counts with `awk`, and treated zero as clean. Rename or move any entry on that list and grep exits 2, prints nothing, and the sum is zero, which is the same answer as "scanned it and found nothing". The exit status was never the problem and `pipefail` was already set, so the status was visible the whole time; nothing tested it. It now loops over the same list calling the existing single-path helper once per path, which fails loudly on a path that is missing. The batched form of that helper takes many tokens over one path, and this is one token over four, so there was never anything to batch.

## [0.14.1] - 2026-08-23

> **The dispatcher's reviewer-input table routed `{{task_file_index}}` to a reviewer retired two releases ago, and left off the one that refuses to start without it.** Reviewer C folded into B in v0.13.0, but the table still read "Reviewers C and F", and B genuinely consumes that map, so a dispatcher following the table starved B and burned a whole review round. That is the shape of most of this release: not prose that merely reads stale, but written instructions that route a live dispatch somewhere it cannot succeed. Two more files still called the evidence-gated reviewers standing members of every wave, one of them wrong for three releases under a fully green validator. A new check now guards the roster by reading what a claim's subject is rather than how the claim is worded, so it reddens on phrasings nobody has written yet, and the validator gets back most of the second it had quietly lost to spawning processes.

### Added

- **Check `[77]`, `scripts/validate-dod.d/77-reviewer-roster.sh`, bans stale reviewer-count grammar over six files, two of which no other check in the validator reaches.** It also pins the invariant sitting underneath the count: the Phase 5 panel has exactly one standing member and that member is B. The pin locates each claim's SUBJECT instead of matching known phrasings, so it reddens on wordings nobody has written yet, and it discovers its own file set rather than carrying a path list, because a hand-kept list is the next thing to go stale. The list was not what failed this sprint, though: both roster defects sat in files check `[38g]`'s ban loop already named, and both named the wrong letter rather than the wrong number, so no count ban could ever have reached them. The list is not the unit of coverage, the claim is. Ten phrase-order tokens close the gap where a wording removed from `review-and-verify.md` this sprint could have walked straight back in at any count through the other word order.
- **`scripts/test_ban_tokens.sh` plants all 89 tokens in the validator's three batched ban lists one at a time and requires each to redden and be named.** A ban loop that greps for a token it has never proven it can find is a check that measures nothing, and this repo has already shipped two of those. Each sweep asserts its own plant count rather than only a grand total, so pointing one sweep at another's list reddens even when the three still sum to 89. It runs in CI rather than inside the validator, because it costs roughly twice what the whole validator does, and the validator is the thing that runs before every commit.

### Fixed

- **`{{task_file_index}}` was routed to "Reviewers C and F", so Reviewer B never received an input it refuses to start without.** Fixed at all three sites in one change, because correcting the template without the table it points at would have traded one contradiction for another. The two files also disagreed with each other about what the consumer does with the map, one saying it is ignored and the other saying it is matched on. The true one won.
- **Two files still called the evidence-gated reviewers standing members of every wave.** C folded into B in v0.13.0 and F was gated on a seam in `17c4a24`, so B is the only standing member left. Both stale sentences sat just past the end of a mirrored block, where the mirror check is structurally blind, while a neighbouring check passed on the correct sentence a few lines above. One had been wrong for three releases with a fully green validator, which is the argument for check `[77]`: a review round reads a diff, so drift in files the diff never touches is invisible to it by construction.
- **A WCAG citation named the AAA target-size criterion while claiming Level AA.** It now reads `minimum target size 2.5.8`, which is the WCAG 2.2 Level AA criterion. 2.5.5 Target Size (Enhanced) is AAA, so the old citation promised one bar and pointed at another.
- **The validator had drifted from 4.26s to about 6.0s, and 64% of its CPU was going on spawning processes rather than on matching.** Two checks re-read every file once per banned token, so the cost scaled with the length of the token list instead of with the size of the corpus. A shared helper now screens each file once with a batched grep and falls back to the original per-token loop only on the files that screen dirty. Back to about 4.6s, a shade above where the sprint started, with `[70]` down 61% and `[77]` down 80%. The screen is stricter than the loop it replaces, and identical on every path that was already covered. Where it diverges it goes the safe way: an unreadable path now fails saying it was never screened, where the old loop printed green, and the fallback's vacuous green lines still print under it, so that hole is announced rather than closed. The slow path itself is untouched and still decides every file the screen flags, and the batched screen was checked token by token against the real corpus with no divergence.
- **Three smaller truth defects.** The check manifest described a check by a scope claim that check itself retracts; the validator's printed output named a template that had since been renamed; and the block written to refuse silent skips was itself skipping silently, because a path containing a newline made its scan fail without saying so.

## [0.14.0] - 2026-08-23

> **The step tracker vanished because one table cell named a tool and never said what to do without it.** `runtime-adapters.md` maps every workflow primitive onto every runtime, and six of the seven spelled out a fallback inside their own `todo tracker` cell. Claude Code's said `TodoWrite` and stopped there. That tool is frequently absent from a session's tool surface, so a model reading the table found a name it could not use and no written instruction for what to do instead. The phase ledger disappeared, and with it the only thing that made phase ordering visible. This release gives the ledger a second home no missing tool can take away, puts phase discipline in front of the model on every prompt instead of once at session start, and pins the whole contract in the validator, which had never checked any of it. A doc-truth sweep of 119 files rides along, and the worst thing it found was not stale prose but a dispatch that could never succeed.

### Added

- **`rules/phase-discipline.md`, a fourth always-on rules file, injected on every prompt beside the hard caps, the expert mindset and the performance guardrails.** Nothing that rides on every prompt had ever mentioned phases. Those three files govern what you write; this one governs how the run is conducted, and that gap matters because a dropped phase and an unasked question leave no diff behind, so no code review ever catches them. Five laws ride along: the ledger opens at task start in every mode and is re-printed at every phase boundary, phases run in order with one open at a time, no phase is ever silently skipped and one that does not apply is marked complete with a reason, every question, decision or approval goes through the wizard tool instead of a numbered list in chat, and a tick with no one-line reflection is an untrusted tick. **The scope carve-out rides in the qualifier attached to the first law's bold lead, never in body prose**, because after the first turn the injector keeps only bold leads plus the short clause that follows them: an exception written anywhere else would be visible on turn 1 and gone from every turn after it, leaving the steady-state law absolute. The carve-outs are three and only three, trivial factual Q&A, a single-line typo fix, and read-only inspection that will not lead to an edit.
- **`## 0. Phase ledger`, a real work-doc section, so full hackify's ledger survives a restart.** A printed block lives inside one conversation and dies with it; a section on disk does not. The ten items are written into the file at Phase 2 step 1, and resume now READS that section back instead of rebuilding the phase state from whatever it can infer. The rule is that whoever creates the work-doc writes section 0, which on the groom path means groom writes it, because groom is what creates the file, and Phase 1 then adopts the existing block instead of opening a second one beside it. All six per-phase protocol files gained a `Ledger, at phase open` and a `Ledger, at phase exit` line, deliberately byte-identical so one literal pins all six. `phase-3-implement.md` and `phase-2.5-spec-review.md` had never contained the word "ledger" at any commit.
- **`always-on injection`, a twelfth runtime primitive**, appended last in `runtime-adapters.md` so its "first 8 primitives" and "eight load-bearing" sentences both stay true. `SKILL.md` keeps its own copy of that list and had sat at eleven for two waves after the table moved to twelve, which is now pinned rather than trusted.
- **Check `[76]`, `scripts/validate-dod.d/76-phase-ledger-substrate.sh`, six blocks that pin the ledger contract nothing had ever checked.** The canonical sentence is pinned WHOLE in both files that carry it, not by the bolded clause inside it, because a substring matches by construction in each file separately and stays green while the two sentences drift apart around it. The Claude Code degrade is pinned by its fallback clause and scoped to the extracted table row, never by the tool name, since a `TodoWrite` pin would have passed on every commit throughout the original bug. The three load-bearing laws are pinned in their full bold-bullet form, leading `- ` and both pairs of asterisks included, because a law demoted to body prose still greps clean on its own words and reaches nothing after turn 1. Every pin was proven to fail when the thing it guards is removed, and the proof caught two first-draft pins that passed under tampering, one of which reproduced this sprint's own stale-count defect. `[76f]` closes the same rot inside the validator itself: three fragments were sourced and running while the orchestrator's header enumeration never named them, and the triad stayed green the whole time.

### Fixed

- **The Claude Code `todo tracker` cell now carries a written fallback, and the guarantee that was built on top of the missing tool is gone too.** The cell named `TodoWrite` and nothing else, alone among seven runtimes, so when the tool was not on the session's tool surface there was no fallback in writing, the ledger silently disappeared, and phase ordering stopped being enforced by anything. The same file's degrade table then made it worse by asserting that out-of-order phase starts were "mechanically impossible" because blocked-by edges on that same absent tool prevented them, which is a promise that evaporates in exactly the case the table exists to describe. Both are corrected: the cell tells the model to print the block in chat and keep the durable copy in the work-doc, and the degrade table now says ordering rests on written law whenever the tool is not there. Sweeping `phase-ledger.md` for the same buried assumption, that the todo tracker is the ledger's only home, turned up a seventh site nobody had listed.
- **The Phase 5 escalation prompt could not run at all, and had not been able to since v0.13.0.** It told the agent to read `{{reviewer_c_report}}`, a placeholder for a reviewer retired in that release, and the same prompt carries no INPUT slot that could ever fill it. Under the Template Contract an agent handed an unfilled placeholder must refuse and report `unfilled placeholder`, so every escalation burned a round and returned nothing. This was not documentation drift with a cosmetic cost, it was a live dispatch failure, and nothing pinned it because an unfilled placeholder looks exactly like a filled one until dispatch time. The same prompt also said "the four prior reviewers" while its own OBJECTIVE adjudicated three.
- **The Phase 6 finish menu was numbered differently in `SKILL.md` than in the two files that own it, on all four options.** All four numbers named a different git operation, so this was never cosmetic: the fully autonomous mode auto-picks option 1 by number, and an agent that had read `SKILL.md` would take a number to mean one operation while the two owning files meant another. `SKILL.md` now matches both owners operation for operation. yolo's own option 1 wording was deliberately left alone, because a validator pin already holds it and renumbering it there would have traded one contradiction for a red build.
- **`SKILL.md` said one agent per task where the protocol says one per batch.** Phase 3 groups same-module tasks and caps a batch at three, so following `SKILL.md` fanned out one implementer per task where the protocol wants roughly a third of that. Three sites carried it, not the two the first sweep listed. The fix adopts the owning file's own noun instead of patching the sentence, which also repaired a check that had been matching correct text.
- **Around twenty sites still described an unconditional lettered reviewer panel.** Reviewer C folded into B in v0.13.0 and Reviewer F was gated on a seam in `17c4a24`, but the docs went on promising a fixed panel that no longer exists. Five of those sites were agent frontmatter `description` fields, which check `[75h]` structurally cannot see because frontmatter sits outside the fenced block that gets mirrored, and which are the line an orchestrator reads when it decides who to dispatch. The stale pins guarding this area were re-founded on the gating RULE rather than on a count, because a count pin fails on correct text and passes on a reverted panel, which is backwards. WCAG citations moved to 2.2 to match the binding allowlist in the Template Contract, checked against the published Recommendation rather than from memory: no 2.1 criterion was renumbered in 2.2, and the only removal, 4.1.1 Parsing, is cited nowhere in this repo.

## [0.13.1] - 2026-08-22

### Fixed

- **Quick mode was dispatching an agent type that had been retired for three merges.** Its Phase 5-lite row named `hackify:code-reviewer-quality`, which stopped existing when Reviewer C folded into B, and its `description` still advertised a five-to-six-reviewer panel. A dead type in a live dispatch line fails at dispatch, not at validation, which is why a green validator and a tagged release both went past it. The sweep that found it also found `references/goal-anchor.md` still addressing "Phase 2.5 Reviewer A" after the three spec reviewers became one; that file is the one both surviving reviewers load for their verdict wording, so the stale name was being read by the agent that enforces the anchor.
- **The retired-type check now scans directories, not a list of files.** The first version of it named four skill files by hand, which is the same shape as the bug it was meant to prevent: nothing had looked outside the hackify skill, and a hand-kept list of places to check is what goes stale next. It now sweeps every skill, command and agent file, excluding by path the two files that name the retired types in order to record the retirement. Planting a dead type in groom, codewalk, lawkeeper and the summary command, four places the file list would have missed, is caught.
- **Two pieces of dead validator code.** `20-templates.sh` carried a `for` loop over exactly one item, left behind when the read-oriented tool check narrowed to the single investigator in 0.13.0, and it silently skipped rather than failing when the file was absent; it is now a direct check that fails loudly. `75-ship-bar.sh` assigned a path variable that nothing reads, since the only module that reads it runs earlier and sets its own. That one predates the 0.13.0 merges.

## [0.13.0] - 2026-08-22

> **Twelve agent types become nine, by merging the ones no gate could ever reach.** v0.11.0 sliced the reviewer panel and v0.12.0 batched the builders, both by gating work that did not need doing. What was left is the work gating cannot touch: agents that run unconditionally on overlapping inputs. Phase 2.5 is non-skippable by design, so its three reviewers ran on every sprint whatever the diff looked like, and two of them read the same work-doc. Phase 5's Reviewers B and C were the only two on the panel that always ran and never folded, both reading the same diff. Those are the shape a merge fixes and a gate cannot, and both are now one agent. A third merge, the Phase 1 researcher and the Phase 3b debug gatherer into one mode-switched investigator, saves nothing at runtime and says so; it buys one prompt to maintain instead of two.

### Changed

- **Phase 2.5 went from three reviewers to one, and every merge is a union.** Reviewer C folded into A first, then Reviewer B folded in too, leaving the single `hackify:spec-reviewer` carrying all three lenses over one read: internal consistency and goal drift, the topological wave plan and its dispatch batches, and architectural risk quoted against the project rule files. Phase 2.5 is non-skippable by design, so unlike the Phase 5 panel no evidence gate could ever have taken this saving instead. **Every METHOD step, VERIFICATION item and anchored severity example from all three lenses is carried**, 21 METHOD steps, 20 VERIFICATION items, 18 severity anchors. Two of B's verification items said "every finding", which stops being true once the agent also produces findings with no rule sentence to quote, so each keeps its original wording and gains an explicit carve-out clause naming the one case it does not reach. Every read is front-loaded into steps 1 and 2, so B's verbatim rule quoting no longer lands after thirteen steps of unrelated analysis. Findings are tagged `[consistency]`, `[plan]` or `[rules]`, because one undifferentiated list is how the strictest lens's citation discipline decays to the loosest.
- **What the B fold actually saves, stated plainly.** C's read set was a strict subset of A's, so folding C removed a whole duplicate read. B is different: it reads three files A never opened (the project `CLAUDE.md`, the user-global rules, and `rules/code-quality.md`), and those reads still happen. Folding B buys one agent's fixed cost and one duplicate work-doc read, not the rule-file reads. It also means nothing gives the work-doc an independent second pass any more; the lenses are checklist-driven rather than judgment-driven, which is what makes that acceptable and does not make it free.
- **`hackify:spec-reviewer-dependencies` and `hackify:spec-reviewer-rules` are retired, and the letters A, B and C go with them.** Phase 2.5 has one reviewer and it has no letter. A future second spec lens starts from a clean naming slate rather than inheriting a retired one, so a work-doc or transcript naming "Spec-review B" or "Spec-review C" can only be describing history. Phase 5's Reviewers A through F are a different panel in a different phase and are untouched.
- **Phase 5's Reviewer C folded into Reviewer B, and the panel is four standing reviewers instead of five.** B (quality, layering, engineering law) and C (plan consistency, scope, goal drift) were the only two members that ran on every wave and never folded, so they were paying for two reads of one diff with no evidence a gate could have used to skip either. The merged `hackify:code-reviewer-quality-plan` carries **20 METHOD steps, 20 VERIFICATION items and 12 severity anchors**, the union of both, with the plan lens tagged `[plan]` in the report so the aggregator can still tell them apart. All three reads are front-loaded into steps 1 to 3. **The letter C is retired, not reassigned.** E now joins as the fifth on UI-bearing diffs, and the cap is 5.
- **What the C fold costs, stated plainly.** C used to be sliced: on a settle round it re-read only the files whose bytes had moved. B is never sliced, because its semantic tier applies to every touched file and it re-judges every law-scout row, so the folded lens inherits B's terms and re-reads the whole diff every round. Coverage goes up, since C's slice was always a subset of what B was already reading, and the wave drops from two diff reads to one. The settle-round saving on that lens is what the merge gives back, and on a large sprint that is a real cost rather than a rounding error. It is written into `references/review-scope.md` beside the table it changed, not left to be inferred from a missing row.
- **The Phase 1 researcher and the Phase 3b debug gatherer merged into `hackify:codebase-investigator`, and this one does not pay for itself.** Every other merge in this release removed a duplicated read. These two never run in the same phase and neither is standing, so folding them saves no runtime cost at all. What it buys is one agent type to maintain and one place where the citation discipline lives instead of two. The price is that about a quarter of the METHOD steps sit idle on any given run, so each step carries its `[both]` / `[research]` / `[debug]` tag inline and a step tagged for the other mode is skipped rather than half-applied. The union is 10 METHOD steps and 11 VERIFICATION items, and two of those verification items are new: the research lens never checked that it dropped non-contributing citations, and the debug lens never checked its own failure-path trace.
- **Phase 2.5's word budget follows the lenses.** The single reviewer gets ≤900 words, the sum of the three budgets it absorbed (600 + 300), and the cap says explicitly that it is a sum rather than a licence to spend it all on one lens. Its wave plan and dispatch batches sit outside that budget because they are enumerations that scale with task count rather than prose, and they are emitted FIRST so a truncated report still carries what Phase 3 consumes.

### Added

- **`hackify:codebase-investigator`**, read-only investigation as a registered agent type serving both Phase 1 and Phase 3b. Phase 1 research and Phase 3b debug evidence were paste-only templates, so the parent read each prompt into its own context to compose a dispatch, charging the same text twice, exactly the cost v0.11.0 removed for the reviewer panel. Its frontmatter `tools:` line is read-oriented, which keeps `Edit`, `Write` and `NotebookEdit` off the harness surface entirely. `Bash` stays because the prompt runs `git grep`, and `Bash` can write, so the no-edits rule is still carried by the prompt; the tool list shrinks the surface, it does not police it.
- **Every agent is now an enforced mirror, with no exceptions left.** The set went from four pairs to nine, and `agents/` and the pair list are the same nine things. Getting there meant splitting `phase-5-multi-review.md`, which held three prompts in three fenced blocks while the sync script splits on the first, so neither Reviewer A nor Reviewer C could ever be checked against it. Folding C into B and giving A its own `phase-5-multi-review-a-security.md` fixed both at once. Check `[75h]` covers all nine pairs.
- **Check `[36b]`**, the first thing in this repo to validate agent frontmatter `tools:` names against an allowlist, plus a rule that the read-oriented investigator never declares `Edit`, `Write` or `NotebookEdit`. Nothing validated these strings before, not the plugin loader and not any other check, so a typo or a retired name changed an agent's reach without erroring. This release shipped `NotebookRead` in the read-oriented agents until the check went in; that tool does not exist, so it was doing nothing while looking deliberate.
- **Check `[57]`**, resolving every documentation pointer to a file on disk. Nothing verified that a cited `.md` still existed, and this release showed the bill: four pointers to a deleted template survived a fully green validator, in two sibling prompts and in `review-triage/SKILL.md`. A prompt is executable text on Claude Code, so an agent told to read a file that is gone is a degraded agent, not a docs typo. All four were bare backticked paths rather than markdown links, so the check reads both forms, and it holds them to different standards: a link must resolve file-relative, because that is what following it does, while a prose path may resolve against any ancestor directory or skill root, because prose has cited the same reference from two depths for as long as the repo has existed and both readings are fine. That split found eight markdown links under `references/phases/` that had been broken since 0.11.0, all now repointed. Archived work-docs and this changelog are out of scope by design, both are records of what was true then, and this very entry names files the release deleted. The check runs twice, once over the source tree and once over the built `dist/claude-code/`, since that is the runtime that registers what it ships and a pointer surviving in source proves nothing about the copy. Running it against the built trees is what caught the check's own blind spot: Reviewer B's inputs cite the project's `CHANGELOG.md`, meaning the one in the repo under review, and that had been resolving against this repo's changelog by coincidence.

- **Check `[38g]`**, pinning the guard rails all three merges depend on: Phase 2.5 states **one** reviewer and Phase 5 states **four** standing reviewers, in every file that states a count and with the superseded phrasings banned outright; the retired letters are not reassigned and no agent file references a dead type; the merged spec reviewer takes `{{wave_size_target}}`; the merged Reviewer B carries the four inputs C owned and B never had, and is still never sliced; and the investigator still carries both of its modes. The count half is not cosmetic. Six live files still said three reviewers after the first merge and nothing caught it, and that number is what an orchestrator dispatches on. The check earned itself repeatedly: it caught a dead agent type left in a `description:` field, then caught every stale count again on the second merge, then caught four more on the third.

### Fixed

- **Both Reviewer Bs were auditing without the doctrine file they cite.** The Phase 2.5 and Phase 5 quality reviewers had each drifted behind their canonical template and lost the step that loads `rules/code-quality.md`, and both still named TypeScript file suffixes where their templates had moved to stack-agnostic module roles. On Claude Code the registered agent copy is what runs, so this was a real and silent loss of review depth, not a docs mismatch. Both were resynced from their templates; Phase 5's Reviewer B now sits under check `[75h]`, and the Phase 2.5 one carried its repaired text into the merged spec reviewer, which sits there too. `[38g]` pins the load step in both so it cannot drop out again. The safety question before overwriting was whether the newer templates, which replaced an inlined list of the four literal lint-suppression tokens with a pointer to `rules/hard-caps.md`, would delete the scan targets; `rules/hard-caps.md:14` still carries all four, so nothing was lost.

- **Three reviewer agents kept telling the orchestrator to dispatch a reviewer that no longer exists.** Folding C into B left D, E and F each naming `Multi-reviewers A, B, C ...` in their frontmatter `description`, and D and E still promised E would join "as a sixth". A description sits outside the fenced block, so `[75h]` structurally cannot see it, and on Claude Code it is the line the orchestrator reads when it decides who to dispatch. `skills/quick/SKILL.md` still called the panel "five-to-six" for the same reason. All five are corrected, and `[38g]` now pins the five agent descriptions alongside the prose files, banning every letter-list variant that names C.

- **Retired agent files used to survive in `dist/`.** The runtime sync pruned `dist/<runtime>/skills` before mirroring but never `dist/<runtime>/agents`, so a retired agent kept shipping. That is worse than dead weight for the Claude Code target, where the runtime registers whatever sits in that directory: all three retired spec reviewers stayed dispatchable for anyone installing from `dist` after the source stopped shipping them. `prune_runtime_dist` now clears both directories.

- **Phase 5's Reviewers A and C had drifted from their canonical templates in both directions, unnoticed, because neither could be checked.** They shared `phase-5-multi-review.md` and the sync script splits on the first fenced block, so `[75h]` had never covered either. Splitting that file to enable the check surfaced what the gap had been hiding: A's agent copy carried two instructions its template never got (skip the `Execution waves` block when reading Approach, and the placeholder explainer) while A's template carried broader phrasing of two ROLE clauses; C's agent copy had gained the Execution-waves clause and lost the `goal-anchor.md` pointer its template still had. Neither side was uniformly newer, so both merges took the union by hand rather than letting the sync script pick a winner by overwriting. Size does not settle drift direction, reading both sides does.

## [0.12.0] - 2026-08-22

> **Fewer agents, same rigor.** v0.11.0 stopped six reviewers reading the same diff. This release goes after what is left: agents that exist because the work was split one way rather than another. Fourteen implementers each re-read the same module and re-quoted the same six rule sentences. Every Critical finding got two refuters even when the first one had already settled it. Reviewers read a block of the work-doc that only Phase 3 uses. None of that bought a better answer. Measured on real sprint diffs from this repo's history, a typical sprint drops another 10%, and about 19% when the diff touches a single module.

### Added

- **Dispatch batches in the wave plan.** The wave planner already knew every task's files and already built the waves; it now also groups the tasks WITHIN a wave that share a module, capped at 3, and emits those groups. Phase 3 dispatches one implementer per batch instead of one per task. A task with no module sibling is a batch of one, which is the normal result and not a failure to optimise.
- **Check `[38f]`**, pinning every guard rail this release depends on: batches are grouped by module and capped at 3, a batch stops at the first task it cannot finish, and the conditional second refuter stays tied to the rule that makes it free.

### Changed

- **One implementer per task batch, not per task.** Same-module tasks share types, neighbours and conventions, so one agent reads them once instead of three agents reading them three times. It also pays the rule-file reads once: every implementer quotes the same six rule sentences from `CLAUDE.md`, a fixed cost that has nothing to do with task size. Each task keeps its OWN file allowlist and the union is only an outer bound, so batching never widens what a task may touch. **A batch runs its tasks in order and stops at the first one it cannot finish**, so a bad task costs one task rather than the batch, and the parent re-dispatches just that one. **Tasks in different modules are never batched**, because there are no shared reads to save and grouping them would only cost the agent its focus. This trades wall-clock for tokens on purpose: nine agents instead of fourteen is about twice the duration for about a third less, and the 3-task cap is what stops that becoming ten times.
- **The second refuter on a Critical is now conditional, and the verdicts are identical.** A Critical dies only when BOTH of its refuters refute it. So once the first refuter upholds or escalates, the finding survives and no verdict the second could return would change that. The first refuter now runs on every Critical with the reproduction lens, and the second runs with the authority lens only where the first came back REFUTED. **The bar to kill a Critical is untouched**, and the second opinion still arrives in exactly the case it exists for, when one agent is about to delete a real defect. Reproduction goes first on the merits: a failure that genuinely reproduces is a real defect whether or not the finding cited the perfect rule.
- **Reviewer F is now evidence-gated instead of standing.** F is the only lens that compares a producer against its consumers, so on a diff confined to a single module it spends a full reviewer's budget proving a negative it was never given the material to prove. It now runs whenever the diff crosses a module boundary and folds into Reviewer B when it does not. **The bar is deliberately low and errs toward running F:** two touched modules is enough, and so is one touched file that anything outside its module imports, because that import IS the seam even when only one side of it moved. A diff you cannot classify in one sentence crosses a boundary and F runs. This is a different gate from A's and D's, which fold when the diff has no risky surface; F folds when the diff has no seam. B inherits F's residual checklist exactly as it inherits A's and D's, findings are tagged `[folded: F]`, and a seam B finds after F folded is Critical because the gate decision was wrong.
- **Reviewers A, C and D skip the `Execution waves` block.** It is Phase 3 dispatch bookkeeping, it just grew a batch list, and no reviewer lens reads it.
- **The Phase 5 self-review table is retired.** Every row it carried is checked by a reviewer that cites file:line and a verbatim rule sentence. A hand-ticked table beside that was the same audit run twice, once with evidence and once without.
- **The update log has a budget**, one block per user-visible change and 120 words per block. It had none, so it grew. The cap is a writing instruction rather than a token trick: the length that serves a person deciding whether the work is done is short, and every field still has to earn its line with something real.

## [0.11.1] - 2026-08-22

### Fixed

- **`references/review-scope.md` was missing from the runtime sync manifest**, so the six non-Claude-Code distributions in `dist/` shipped without it while five reviewer prompts pointed at it for the scope grammar and the carry-over rules. On the runtimes with no agent registry, where the templates are pasted by hand, that file is the only place the four `{{review_scope}}` value forms are defined. Claude Code installs were unaffected, they carry the whole repo.
- **Check `[55]` now sees untracked files too** (`git ls-files --others --exclude-standard`, so `.gitignore` still governs). Reading only the tracked set made the check useless at the moment it was needed most: a brand-new reference file is invisible to it, the validator goes green, and CI fails as soon as the file is committed. That false green is exactly how the manifest gap above reached a tagged release.

## [0.11.0] - 2026-08-22

> **The workflow was paying for the same text over and over.** Three always-on rules files were re-injected on every single prompt, and because injected context stays in the transcript, a thirty-turn session carried thirty copies of rules that never left the context window. Six reviewers each opened every touched file in full, and then the settle round sent all of them back over files nobody had touched since they were last judged clean. Fifteen implementers each rediscovered the same stack. The parent read a reviewer's prompt out of a template to build a message for an agent that already carried that prompt. None of it bought rigor; all of it bought repetition. This release removes the repetition and redistributes the reading: the rules arrive once and stay in force, every lens gets the part of the diff it can actually act on, a verdict survives as long as the bytes it was recorded against, and the one reviewer that genuinely needs everything keeps getting everything. Every gate, every lens and every proof stays exactly where it was. Measured against real sprint diffs from this repo's own history, the reviewer changes alone cut a typical sprint by about a third and a large one by about half.

> *The 0.10.0 entry is folded in here. That version was finished but never tagged or published, so both halves of the work reach users for the first time in this release.*

### Added

- **A session-aware context injector** (`hooks/inject_context.py` behind the existing `hooks/inject-context.sh`). The always-on rules arrive in full on the first prompt of a session, as a one-line pointer on later prompts, and in full again every 25 prompts so a very long session cannot drift. Every failure path, no `session_id`, unparseable stdin, an unwritable state dir, no `python3`, degrades to injecting the FULL body, never to injecting nothing: a repeated injection costs tokens, a dropped one costs the law. The pointer carries the file's own bolded rule leads with it, so a session that gets summarised still has the caps and the bans stated on every prompt rather than a reference to text a summary may have dropped. Covered by `hooks/test_inject_context.sh` (23 cases) and pinned by check `[38b]`.
- **A reviewer relevance gate.** B (quality and engineering law), C (plan consistency and drift) and F (cross-module coherence) are standing members of every wave, unchanged. A (security) and D (performance) now run on evidence that their lens has something to look at: A on auth / session / token / permission / crypto, network, database or migration, filesystem or shell, untrusted deserialization, or a dependency manifest, or any `sec.*` law-scout row; D on any staged perf candidate or a loop, query, cache, fan-out, list endpoint or render path. **Folding moves a lens, it never removes one.** The gate decision is written into the Sprint Review with the evidence that let it fold, and that same line is handed to Reviewer B as `{{folded_lenses}}`; B runs each inherited lens's residual checklist over the same hunks and tags every resulting finding `[folded: A]` or `[folded: D]`. A finding that contradicts the evidence line is Critical, because the gate decision was wrong. When the evidence is ambiguous the reviewer runs.
- **`references/repo-brief.md`**, the sprint's shared repo-context brief. Built once at the end of Phase 2 as a `### Repo Brief` block in the work-doc (Phase 2 step 5 builds it, the work-doc template holds it) and passed as `{{repo_brief}}` to every implementer and every reviewer, capped at ~200 words, carrying stack, the verbatim test / lint / typecheck commands, layout, the layering rule that matters, the rules source, the test convention, and the landmines an agent would otherwise get wrong. Every receiving prompt says the same thing: treat it as given, do NOT re-derive it, spend your reads on the diff.
- **`scripts/sync_agent_mirrors.py`**, which regenerates the four agent files that promise byte-for-byte identity with a template's fenced block. Check `[75h]` now reads its pair list from `--list` instead of keeping a second hand-maintained copy.
- **`references/phases/`**, one file per phase (1, 2.5, 3, 4, 5, 6), plus **`design-spec/directions/<slug>.md`**, one file per visual direction.
- **`references/review-scope.md`**, the single definition of `{{review_scope}}`: the four value forms (`.`, a pathspec list, `settle all`, `settle <paths>`), which reviewer is sliced and which is not and why, how the dispatcher builds the manifest, and the rules for carrying a verdict into the settle round. One file so the A block and the C block cannot drift apart on what `settle ` means.
- **`skills/hackify/scripts/render-report.py`**, which fills the Phase 6 HTML report from a JSON payload. It derives files changed, lines added and removed and commit count from git, draws the severity chart as inline SVG, renders the phase pills and every table row, HTML-escapes all prose, and refuses to write a page that still holds an unfilled token. The report was previously typed out by hand, inline SVG included, at roughly 5.5k output tokens a time.
- **`references/parallel-agents/phase-5-multi-review-b-quality.md`.** Reviewer B's prompt now has its own file, the same layout D, E and F already use. D moved out in v0.9.0 for the same reason: a new input pushed the shared file past the 500-line cap.
- **Check `[38e]`**, pinning every mechanism this release depends on: the five sliced reviewers carry `{{review_scope}}` in both copies of their prompt, Reviewer B carries it in neither, carry-over is keyed on `git rev-parse` blob hashes rather than paths, an unclassifiable file defaults to B, and the report is rendered rather than hand-written. Same discipline as `[38c]`, for the same reason: prose nothing checks is prose that drifts back.

### Changed

- **`SKILL.md` is a router, 493 lines down to 357.** Each phase now states its goal, its hard gates, its exit artifact and the mechanisms it may not skip; the protocol for that phase loads from `references/phases/` when the phase opens. A task that ends at Phase 3 no longer pays for the Phase 5 and Phase 6 bodies. Every gate, every validator-pinned law and every always-on mechanism stayed in `SKILL.md` on purpose, the split moved the *how*, never the *must*.
- **Dispatch is by registered agent type on runtimes that have a registry.** Every reviewer, spec reviewer, implementer and refuter prompt is already installed as a subagent type, so the parent dispatches the type and passes only its INPUTS. Opening the template to paste a prompt the agent already carries charged the same text twice. `references/parallel-agents/README.md` is now a dispatch index (agent type → INPUTS → fallback template) rather than a prose description of each file, and the templates stay exactly where they are for the six runtimes with no agent registry, where pasting is the only path.
- **Reviewers read hunks, not whole files.** Every `For each touched file, audit X line by line` step is now `For each touched hunk`, with an explicit escalation clause: open a file in full only when a candidate finding needs the contract around it, and say in the finding why you opened it. **Reviewer B is deliberately exempt** where its lenses are genuinely file-scoped (file-size caps, one-construct-per-file). The refuter now scopes its diff to the paths a finding cites instead of reading the whole range.
- **The address-all loop no longer re-runs the whole panel over the whole diff every round.** Round one is the full gated panel over `<base>..HEAD`. Middle rounds re-dispatch only the reviewers whose findings that batch fixed, plus F, scoped to the fix diff. The final settle round is the full panel over the full range again. **The settled-diff guarantee is untouched:** the loop may only close on a FULL round that finds nothing AND whose scanned diff is byte-identical to what is on disk, and a middle round can never close it no matter how clean.
- **`direction-library.md` is a picker, 21.4 KB down to 4.1 KB.** The table and the choosing rules stay; each direction's profile moved to `directions/<slug>.md` so a UI task loads the picker plus the one direction in play instead of all twelve.
- **`rules/performance.md` gained a load-by-role table.** Reviewer D still loads the whole catalog, because it judges every staged candidate and needs every fix direction. Implementers load the severity model, the ID scheme, and only the domain sections their task touches. The catalog itself is unchanged; cutting its depth would have cost the quality of every finding that cites it.
- **`quick` and `yolo` follow the same changes, not the old path.** Both now dispatch by registered agent type instead of pasting templates, both carry a repo brief (yolo in its in-chat plan block, quick as the two or three lines it already knows), and yolo's Phase 5 is the evidence-gated panel with folded lenses handed to B and the loop closing only on a full round. Quick's single reviewer still carries every lens on every diff, the gate does not apply there. Pinned by check `[38c]`, because a mode left describing the old world is exactly the half-updated defect Reviewer F exists to catch.
- **The eight skill descriptions are trimmed from 11.7 KB to 7.6 KB.** These sit in the system prompt of every session whether hackify fires or not. Every trigger phrase and every routing boundary the eval suites discriminate on was kept verbatim; what went was the internal narration a model only needs after it has already invoked the skill.
- **Reviewers A, C, D, E and F take `{{review_scope}}` and diff only their own slice.** The dispatcher builds the manifest once from `git diff --name-only`, which costs no extra reads because both scouts already walked that file list. Coverage is proved by a scope ledger in the Sprint Review, one row per changed path with its blob hash, its assigned lenses and each round's verdict. **Anything the dispatcher cannot confidently classify goes to Reviewer B**, so an unclassifiable file is never an uncovered file, and **an absent value means the whole diff**, so a forgotten slice costs tokens and never coverage. A lens whose slice comes out empty is not dispatched, and that decision is written on the gate line exactly like a folded lens. Every reviewer echoes the scope it received as its report's first line, which is what makes the claim auditable instead of asserted. Reviewer E is the cleanest case: filtering the diff to UI-bearing files was already its own first step, so this just moves that filter one context earlier and its behaviour is unchanged.
- **Reviewer B is never sliced, and that is deliberate.** B applies the semantic tier to every touched file and re-judges every law-scout row, so no subset of the diff is safe to withhold from it. B instead takes **`{{metrics_table}}`**, a precomputed table of function length, parameter count, nesting depth and file length built from the project's own linter and an AST pass, and judges those rows rather than counting by reading. The literal `unavailable` sends it back to counting, so a project whose tooling cannot produce the table loses nothing.
- **A verdict now carries into the settle round while the bytes it was recorded against are unchanged.** What counts as a FULL round changed with it, from "the panel re-read every byte" to **"every byte is covered by a live verdict, and F re-read its whole boundary set"**. That is a different guarantee, not a weaker one, and it is only as good as the ledger, which is why the ledger is mandatory the moment anything carries. The ledger keys on the blob hash and never the path: a path-keyed ledger would carry a verdict across a file that changed twice in one sprint, which is a clean round over content no reviewer ever read. **Reviewer F never carries over** and always runs `settle all`, because every other lens judges a file against itself while F judges it against its counterparts, and a counterpart moving breaks coherence while both files' own hashes sit still. The settle round is marked by a `settle ` prefix so a deliberately narrowed scope can be told apart from one the dispatcher never set, and a lens holding a bare pathspec list was running a middle round and cannot close the loop.
- **Reviewers A, C and D read only the work-doc sections their lens uses.** Daily Updates, Sprint Review and Retrospective grow all sprint and carry nothing any of the three checks.
- **Check `[80]` measures Python files.** `render-report.py` was the first plugin file with real logic that the 500-line cap could not see. Every existing `.py` in the repo was already well under it.
- **`quick` and `yolo` follow the same changes.** yolo dispatches the sliced panel and passes B the metrics table; quick's single reviewer still carries every lens over the whole diff, because slicing one reviewer would only remove coverage. Both now render the HTML report from a payload instead of writing it out, and quick passes its stats explicitly since it has no base SHA before its first commit.

### Fixed

- **Two routing trigger phrases were dropped by the description trim and are restored.** `lawkeeper` lost "validate the architecture" and `quick` lost its promotion literals ("switch to full", "promote to full", "/hackify:hackify"). A description is the router, so a lost trigger silently re-routes real user phrases. Check `[38d]` now pins all 64 trigger literals across all eight skills and fails the build if a future trim takes one.
- **`skills/lawkeeper/SKILL.md` used a folded YAML description block** (`description: >-`) where every sibling used a single line. Normalized to a single line, and all eight frontmatter blocks are now verified to parse with a real YAML loader rather than by grep.

## [0.9.4] - 2026-08-18

> **Every check on "done" was hackify checking its own work.** The evidence ledger, the three-layer re-verify, the goal-drift trace at Phase 2.5 and Phase 5, the ship gate, the reviewer panel, all of them are run by the same parent that wrote the plan and dispatched the diff. That is the judge marking its own homework, and no amount of added rigor inside the loop escapes it. Claude Code ships a session-goal condition that a **separate evaluator** re-checks after every turn, which is the one mechanism available that sits outside the loop. 0.9.3 wired the other two native orchestration primitives (`ultracode`, `/loop`) and left this one on the table.

### Added

- **The completion sentinel, a third orchestration primitive, on by default in all three modes.** `references/orchestration.md` now carries `ultracode` (how hard we fan out), `/loop` (what re-enters until the work is done) and `/goal` (what condition, judged by something else, says it is done). The file states plainly why the driver and the sentinel are opposites and get conflated anyway: the driver is the engine, the sentinel is the brake. Full hackify prints the condition as the first line of the turn that Phase 2.5 opens, quick prints it beside the Phase 1 goal-anchor line, yolo prints it in the in-chat plan block, and yolo is where it matters most because both of its sign-off points auto-pass, leaving the evaluator as the only external check that exists. **The placement in full hackify is deliberate and was corrected during review:** the instruction started life as step 7 under the Phase 2 gate, which is a step that can never run, the gate ends the turn and the next one resumes at Phase 2.5, not at "step 7 of Phase 2". It also happens to be the first point where the native tool is not blocked by plan mode.
- **Precedence between the sentinel and the driver, in writing.** Two mechanisms that both decide when to stop will disagree, and without a stated winner they fight while the token budget loses. Five-row table: condition met and ledger ticked → stop; condition unmet and ledger open → keep working; condition unmet but **a gate is open** → the driver wins, stop and surface, because an evaluator cannot answer a question addressed to the user; condition unmet after **two firings that advanced nothing** → the driver wins, hand back, because an unreachable condition is a planning problem and not a persistence problem; condition met with the ledger still open → the ledger wins, and say the condition was written too loose.
- **A fourth enforcement point in `references/goal-anchor.md`.** The anchor's three existing drift-checks (Phase 2.5 Reviewer A, Phase 4 Layer 2, Phase 5 Reviewer C) are all self-checks. The sentinel is the one that is not, and the section says how to distil five Success Signals into one condition under the 500-character cap: name the exit artifact that cannot be true unless the signals are, and prefer files, exit codes and artifacts over adjectives. `docs/work/done/<date>-<slug>.md exists with status: done` is rulable; "the refactor is complete" is not.
- **`completion sentinel` is the 11th abstract primitive** in `references/runtime-adapters.md`, with the first honest `conditional` cell in the mapping table: `/goal` needs a trusted workspace and unrestricted hooks, and hackify ships a `UserPromptSubmit` hook, so that is a live constraint rather than a footnote. Every non-Claude-Code runtime degrades to the anchor's Success Signals plus the Phase 4 acceptance rows, coverage unchanged, with the *independent* re-check being the part that is lost. The "8 primitives are the only load-bearing contract" framing is corrected to name which 8 and to say that the last 3 raise a ceiling rather than carry weight.

### Changed

- **"Never call other skills" is now three tiers instead of one blanket ban.** The rule and the ship bar had contradicted each other since 0.9.3, which told the workflow to invoke the `loop` skill on the same page that forbade calling any skill, so the cheapest reading always won. `SKILL.md` now states the test: (a) **runtime-native** skills are allowed, but only where `runtime-adapters.md` maps them to a primitive with a written degrade cell and the phase still completes when the skill is absent; (b) **skills bundled in this plugin** (`/codewalk` at Step D.5, `/hackify:summary`) are allowed, they install together, and running a bundled script by path was never a skill call; (c) **third-party plugin skills are never invoked**. When in doubt, inline the behavior. Two sites that still carried the old blanket ban are brought in line: `skills/quick/SKILL.md` said "never call other skills" three lines above its own instruction to run the iteration driver, and `references/law-scout.md` justified the bundled scanner by citing a `Never call other skills` sentence that no longer exists, so it now says plainly that running a bundled script sits outside the rule entirely because no skill is invoked. `skills/groom/SKILL.md` and `skills/review-triage/SKILL.md` keep their blanket statement, it is still true of them.

### Fixed

- **The sentinel is written as a line the parent prints, never as one it sets, because it cannot set one.** This is the failure mode the whole feature turns on. `ProposeGoal` is absent from most sessions, throws in agent contexts, refuses in plan mode, and needs an interactive local session; a workflow that announces "goal set" when none is has faked an independent check, which is strictly worse than shipping no sentinel at all. So printing the paste-ready line is the primary path and always possible, calling the tool is an optional upgrade taken only when it is genuinely in scope and only from the parent, and the parent never waits on the answer, never re-proposes a declined condition, never proposes a second condition for the same task, and never softens one to make it pass. Only the user clears a goal (`/goal clear`). Seven new anti-rationalization rows (five in `orchestration.md`, two in `SKILL.md`) name each of these by the thought that produces it.
- **Check `[75i]` extended, `scripts/validate-dod.d/75-ship-bar.sh`.** It covered the tier and the driver; it now covers the sentinel with the same shape. Adds `/goal <condition>` to the native-token sweep and `completion sentinel` to the primitive sweep over `runtime-adapters.md`, requires all three of `/goal <condition>`, `paste-ready` and `from a subagent` in every mode file (the second and third are the honesty tokens: they fail if the sentinel ever drifts into a claim the workflow sets the goal itself, or loses the parent-only fence the runtime enforces by throwing), pins the precedence section in `orchestration.md` so the two stop-mechanisms cannot silently start fighting again, and region-anchors the hackify instruction to the Phase 2.5 body so a sentinel that drifts back under the Phase 2 gate's numbered steps fails instead of passing on a file-wide match.
- **The sentinel token had to be `/goal <condition>`, not `/goal`.** Worth recording because the first version of the region check passed while genuinely broken: `references/goal-anchor.md` is linked twice inside Phase 2.5 and the path contains the substring `/goal`, so every mode file satisfied a bare grep for free. Caught by running the regression the check exists to catch and getting a green result. Every check in `[75i]` is now proven by moving or deleting the thing it guards, watching it fail, and reverting.

## [0.9.3] - 2026-08-16

> **Two contracts that existed only as prose now exist as behavior.** Parallel dispatch was called "the default, not the exception" while the same page carved out one-line typo fixes and quick mode was told to write small edits inline, and nothing anywhere forbade the parent from simply editing files itself, so the cheapest reading always won. Separately, the orchestration defaults claimed the `ultracode` keyword was "in scope for the turn" and named `/loop` as the iteration driver, neither of which a skill can bring about by describing itself that way, so in practice neither ever fired.

### Changed

- **The no-parent-authored-diff law.** Every change to code, in every phase and every mode, is written by a dispatched implementer agent under a file allowlist. The parent plans, dispatches, aggregates, verifies and reviews; it does not type the change. There is no size threshold: a one-character typo goes through the dispatch path exactly as a new module does, and the workflow never waits to be asked. Splitting is the first move rather than the fallback, so a wave that looks like one task gets split before it dispatches alone, and the wave log records why it could not be split. The law is now stated at every point where the diff changes: Phase 3 waves, the Phase 3b fix that closes a hypothesis, the Phase 5 address-all loop (findings grouped into file-disjoint clusters, one agent per cluster in a single message), and the Phase 6 Step C.5 cleanup sweep. The two carve-outs that made it optional are deleted: `one-line typo fixes (overhead exceeds value)` from `SKILL.md` and `or write inline for 1-3-line single-file edits` from `skills/quick/SKILL.md`. **Cost note:** quick mode's "~one-third the tokens/wall-clock" promise no longer holds for the very smallest fixes, which now pay one subagent round-trip. That is the deliberate trade.
- **One exception, in writing.** A runtime with no subagent primitive degrades the machinery, never the discipline: the parent executes the implementer prompt itself against the same file allowlist and the same Template Contract, and records `dispatch degraded, no subagent primitive` in the wave log. Never a free-hand edit.

### Fixed

- **The orchestration defaults were unreachable, so they never ran.** `references/orchestration.md` said Phase 2.5 / Phase 3 / Phase 5 dispatches "run in ultracode mode: the `ultracode` keyword is in scope for the turn". A skill cannot put a user-typed keyword in scope, and what that keyword actually does is opt the turn into the Workflow tool, so the described state simply never arrived and every fan-out fell back to a plain subagent batch. The mapping is now an action: a **pipelined** fan-out (a wave feeding per-task verification, a reviewer panel feeding per-finding refutation, a loop-until-dry sweep) **calls the Workflow tool**, while a flat same-shaped batch stays a single parallel message. Because that tool refuses to run without an explicit opt-in, the file now states that invoking hackify **is** the opt-in, so a model does not fall back out of uncertainty. Raising the whole session stays the user's move (`ultracode` in a prompt, or `"ultracode": true` in settings) and is named once in the announcement instead of assumed.
- **The iteration driver was described rather than invoked.** `/loop` was documented as the Claude Code mapping, but nothing told the model to call it, so a turn could end with half the phase ledger open and no continuation armed. Any turn that leaves a ledger item open now **invokes the `loop` skill** self-paced on `continue work on <slug>`, and the file says plainly that a turn ending with open work and no such call has dropped the task.
- **New validator check `[78]`, `scripts/validate-dod.d/78-dispatch-mandate.sh`.** Pins the law's presence in all three modes and the three code-changing references, the two deleted carve-outs' continued absence, the degradation exception, and the three actuation verbs (`Call the Workflow tool`, `invoke the loop skill`, the opt-in statement). Every check proven to fire by breaking its contract and watching it fail, then reverting.

## [0.9.2] - 2026-08-16

> **Patch: the update log's five field headings were paraphrased instead of used verbatim, and the HTML report still wrapped the log in the table it replaced.** 0.9.0 was asked for the fields `Problem`, `Root cause`, `Solution`, `Verification evidence`, `Deployment status`, and shipped them as the conversational questions `What was wrong`, `Why it happened`, `What I did about it`, `How I know it works`, `Status`. Same five slots, wrong labels, and the labels are the part of a format contract that gets read.

### Fixed

- **The five update-log field headings are now the specified ones, verbatim.** Renamed across `references/finish.md` (the shape block, the field table, the voice rules, and the two-update worked example), `commands/summary.md` (frontmatter, METHOD, VERIFICATION, the OUTPUT template and the nothing-yet fallback block), `SKILL.md` Step F, `skills/quick/SKILL.md`, and checks `[18]` and `[20]`, which pin the headings as the format contract. Both checks were proven to still bind by reintroducing an old label and watching them fail, then reverting.
- **The HTML report rendered the update log inside the Area/Change table it was supposed to replace.** 0.9.0 swapped the `{{AREA_CHANGE_TABLE}}` token for `{{UPDATE_LOG}}` but left the `<table><thead><tr><th>Area</th><th>Change</th></tr></thead><tbody>` scaffolding around it, so a report would have shown a stray "Area | Change" header row above `<section>` elements that browsers hoist straight out of the table body. The scaffolding is gone, and `section.update` finally has the styling it was already being asked to use: uppercase field headings and a rule between blocks, drawn by the stylesheet rather than emitted by the filler.

## [0.9.1] - 2026-08-16

> **Patch: 0.9.0's headline reviewer was advertised out of existence.** The release wired Reviewer F, the standing cross-module coherence lens, into `SKILL.md` and every reference file, but two sibling reviewers still described the wave as A/B/C/D in their `description:` frontmatter. That field is not prose, it is the live agent metadata a model reads when it composes the Phase 5 fan-out, so the surface closest to the dispatch decision was the one still naming four reviewers. This release corrects that surface, the escalation baseline that depended on it, and the README sections 0.9.0 left behind.

### Fixed

- **Two agent `description:` fields still advertised the pre-0.9.0 review wave, and the harness reads them at dispatch time.** `agents/code-reviewer-security.md` said "Dispatch one of these in parallel with Multi-reviewers B, C and D" and `agents/code-reviewer-performance.md` said "in parallel with Multi-reviewers A, B and C". Those strings are rendered as live agent metadata, so a model composing the Phase 5 wave from them would fan out four reviewers and never dispatch **Reviewer F**, the standing coherence lens 0.9.0 shipped as its headline. `SKILL.md` said the right thing, which made the wrong source the one closest to the dispatch decision. Both now name the five standing reviewers and note that E joins on UI-bearing diffs; the security agent's pre-fence "Dispatch FOUR reviewers" line is corrected the same way. All three edits sit outside the fenced block, so check `[75h]`'s byte-for-byte mirror comparison is unaffected.
- **`phase-5-escalation.md` defined escalation as going beyond "the four baseline Phase 5 reviewers (A / B / C / D)".** The baseline is five (A/B/C/D/F, plus E on UI-bearing diffs), so the file understated what a specialist reviewer is additive to. `phase-5-multi-review-d-performance.md`'s pointer to its sibling reviewers omitted F for the same reason.
- **README shipped 0.9.0 with no "New in 0.9.0" section**, still called four parallel reviewers the default under Design principles, and listed 8 of the 11 files in its `agents/` map: Reviewer E has been missing since 0.8.0, Reviewer F and the refuter since 0.9.0. The 0.8.0 and 0.7.0 blurbs were compressed to pay for the new section, keeping the file inside check `[7]`'s 250..450 line bound rather than raising it.

## [0.9.0] - 2026-08-16

> **The workflow now proves the app runs, enforces the engineering law during the build, and checks that the parts agree with each other.** Before this release hackify could finish a task with a green test suite, a clean linter, and an app that does not boot; with a 600-line file and an empty catch that the project's linter never configured; and with two halves of a feature that each pass their own tests and disagree at the seam. Four mechanisms close those gaps, all always-on in full, quick and yolo, none of them asking the user to opt in.

### Added

- **The law-scout (`references/law-scout.md`), lawkeeper's engineering law inside the build loop.** Runs the bundled deterministic scanner over the files this sprint touched at every Phase 3 wave-end and at Phase 5 start, keyed to lawkeeper's stable `rule_id` catalog, with the same staging and triage contract the perf-scout already uses. Its output becomes Reviewer B's `{{law_scout_report}}`, and B must return one verdict per row. A `sec.hardcoded-secret` row can never be dismissed by the implementer. Alongside it, Reviewer B gains the seven semantic lenses no grep reaches and no reviewer previously owned: one-construct-per-file, folder/topology conformance, controller purity, single responsibility, reuse and magic literals, SOLID/YAGNI, and test coverage of what the diff added.
  - This is a **bundled script run by path**, not a skill call. `SKILL.md` now states that carve-out where the `Never call other skills` rule lives, so a future reader cannot resolve the apparent conflict by deleting the scout.
- **`--paths-from` on `skills/lawkeeper/scripts/audit_scan.py`.** Narrows a scan to a newline-delimited path list (a `git diff --name-only` dump) instead of walking the tree, so a per-wave scan costs the touched files rather than the whole repo. Deleted paths and paths inside skipped directories are dropped. Three unit tests cover scoping, missing/skipped paths, and the unchanged whole-tree default; the recall corpus still matches its oracle exactly.
- **The ship gate (`references/ship-gate.md`), Phase 4 Part 3.** A green triad proves the code is well-formed, not that it starts. Three legs, three mandatory Evidence Ledger rows: `ship.build` (cold-cache build, artifact on disk), `ship.boot` (starts, reaches a real ready signal, tears down clean), `ship.smoke` (the critical path this sprint touched, driven against the running app). **A leg is blocking whenever the diff touched something that leg's target consumes (source the build compiles, config read at startup, the touched flow); a written `skipped` row with the reason otherwise; never silently absent.** The trigger is deliberately the diff rather than "a run command exists": almost every repo has one, and gating a README typo fix on booting the app is how a mandatory check gets quietly disabled. Ships with a per-ecosystem detection table, readiness-probe rules that ban `sleep`-based waiting, migration handling, and a hard rule against inventing credentials or disabling auth to make a smoke pass.
- **Reviewer F, cross-module coherence (`phase-5-multi-review-f-coherence.md` + `agents/code-reviewer-coherence.md`).** A standing member of every review wave. Builds a seam list of every boundary-crossing symbol, names its producer and every consumer repo-wide, and checks five kinds of agreement: shape (fields, optionality, enum sets), semantic (units, timezones, identifier space, ordering, range bounds), error contract (throw vs null vs result object), duplicate concepts that should have reused a shared definition, and wiring completeness. It audits same-wave seams first, because files written in the same wave were produced by agents blind to each other. Every finding cites file:line for **both** sides.
- **Adversarial refuters (`phase-5-refute.md` + `agents/finding-refuter.md`).** A reviewer finding is a claim, not a fact. Before a fix is spent on one, two independent refuters with distinct lenses (reproduction, authority) judge each Critical and one batched agent judges the Important+Minor set. Verdicts are UPHELD / REFUTED / ESCALATED and fill the `Decision` and `Evidence` columns the address-all loop already required evidence for. **The bias is deliberately inverted from a content-generation refuter panel: the default is to KEEP the finding**, uncertainty is never a refutation, and a Critical dies only when both refuters refute it with a file:line counter-citation, because dropping a real defect costs more than fixing a phantom.
- **Reference-image mode on Reviewer E.** When the project supplies reference frames of the intended design, E renders the touched screen and compares the two side by side, judging the rendered result rather than the source. This is the only surface in the workflow where an external visual bar exists, and the template says so explicitly so the technique is not generalized to code where it has no meaning.
- **`ultracode` and `/loop` are now workflow defaults in every mode** (`references/orchestration.md`), expressed as two new abstract primitives so the Claude-Code-native tokens live in the adapter layer and the *behavior* is the default on all seven runtimes.
  - **Orchestration tier.** Every mandatory fan-out (Phase 2.5's three spec reviewers, each Phase 3 wave, Phase 5's five-to-six reviewers plus the refuter panel) runs at the heaviest orchestration the runtime offers. On Claude Code that means `ultracode` in scope plus the Workflow tool for fan-outs a flat batch serves poorly; a flat parallel batch stays the right shape for three reviewers, the tier raises the ceiling rather than mandating a script. On best-effort runtimes max tier means the same phases run inline: coverage never drops, only concurrency.
  - **The standing authorization is stated, announced, and revocable.** `ultracode` normally means the user typed a keyword authorizing heavy spend; making it a default means installing and invoking hackify IS that grant. So the tier is announced once per task in the Phase 2 plan (Phase 1 for quick, the in-chat plan block for yolo), and `light mode` / `no ultracode` / `cheap mode` / `single agent` drop it at any point, with the drop recorded. A default grant that could not be revoked would be lock-in, not a default.
  - **Iteration driver.** The workflow re-enters itself across turns until the phase ledger is fully ticked (Claude Code: `/loop` self-paced, carrying `continue work on <slug>`). Three exit conditions, any one ends it: the ledger is complete and the doc archived; a hard gate or circuit breaker is open (never loop at a question only the user can answer); or two consecutive firings advance nothing.
  - **Deliberate layering call.** The driver sits ABOVE the phases, not inside one. `/loop` re-fires a prompt across turns, so pointing it at the Phase 5 address-all loop or the Phase 3b hypothesis cycle would schedule a wake-up mid-phase and break the phase ledger's one-item-in-progress rule. Those loops stay inline; the driver carries the task from phase to phase. The fence is written into the contract and checked.
- **`scripts/validate-dod.d/75-ship-bar.sh`**, eleven checks that make the contract un-droppable: the four protocol files exist, **every mode wires all four mechanisms**, all three ship-gate ledger rows are named in each mode, the law-scout invokes the bundled scanner with `--paths-from`, `SKILL.md` carries the bundled-script carve-out, the review loop states its settled-diff exit, the refuter keeps its keep-by-default asymmetry, and the orchestration defaults stay wired (every mode cites the contract and names an opt-out, both native tokens resolve through the adapter table, the iteration driver stays fenced out of intra-phase loops, the question banks pass the Clarity law, and the wizard contract still states the always-wizard rule). The eighth closes a drift path this release widened: **four agent files now claim byte-for-byte mirroring of a canonical template and nothing checked it** (0.8.1 verified the one existing mirror by hand). Each check was proven to fire by reintroducing the defect it guards, then reverting.

### Changed

- **Every clarify question is now written so the user can answer it without knowing how hackify works.** The banks had been asking things like *"How is the user-visible goal already specified?"* with an option reading *"I'll write a one-sentence DoD now in chat"*. A new **Clarity law** in `wizard-contract.md` splits every question by audience: `text`, option labels and option descriptions are user-facing and plain; `why-this-matters` and COMPOSITION stay model-facing and as internal as they need to be.
  - **Hard ban list on user-facing text**: work-doc identifiers (`T3`, `D5`, `AC2`, `W2`), phase and wave references, and internal artifact names (DoD, work-doc, Sprint Backlog, goal anchor, sub-agent, perf-scout, law-scout, ship gate, Reviewer B, decision table, phase ledger). If an answer changes something internal, the question states the *effect* in plain words instead.
  - **Every option now carries a mandatory `What happens:` line** saying what the user actually gets if they pick it, not a restatement of the label.
  - **Questions must carry the facts needed to answer them**: the real file, the real current value, the real names, since the model has read the code and the user has not.
  - **All seven banks rewritten** (universal preamble, feature, fix, refactor, revamp/redesign, debug, research), 126 defects cleared to zero.
  - **Wizard delivery is now every phase, not just clarify.** Phase 5 fix-approval batches, the Phase 6 finish menu, and any mid-task fork go through `AskUserQuestion` too. Only statements stay plain chat.
  - **`scripts/check_question_clarity.py`** enforces all of it in CI: banned tokens in user-facing lines, missing or label-restating descriptions, and questions cited in COMPOSITION/EXIT that the bank no longer defines. Both defect classes were proven to fire by reintroducing them.
- **The end-of-task summary is now a plain-language update log instead of a two-column table.** One block per change the user would recognize, five fields in a fixed order, separated by a line of `----`:
  **What was wrong** / **Why it happened** / **What I did about it** / **How I know it works** / **Status**.
  Written the way you would explain the work out loud: everyday words, no jargon the user did not introduce, no phase numbers or task IDs or reviewer letters, and an honest Status saying whether the thing is usable and where it is. "How I know it works" must carry real trimmed output pulled from the Evidence Ledger, never a bare "verified". Replaces the Area/Change table across `finish.md`, `commands/summary.md`, both companion modes, the phase-ledger exit artifact, the HTML report (`{{AREA_CHANGE_TABLE}}` is now `{{UPDATE_LOG}}`), the quick-mode evals, and checks [18], [19], [20] and [23], which now pin the five field headings and the `----` separator rather than `| Area |`.
- **The Phase 5 review loop exits on a settled diff, not the first clean scan.** Previously a round could clear the table, fixes could land, and the phase could end on a scan that described the pre-fix diff. Now a round that changed any code mandates another round, and the loop exits only when a full round finds nothing **and** `git diff <base>..HEAD` is byte-identical to what that round scanned. Encoded in `review-and-verify.md`, all three mode files, the phase-ledger exit-artifact table, and check [75f].
- **Reviewer cap raised from 5 to 6.** A, B, C, D and F always run; E takes the sixth slot on UI-bearing diffs. Coherence is the lens with no other owner, so it does not compete for a slot.
- **Quick mode keeps every lens, drops only the parallelism.** Both scouts, the ship gate, the coherence lens, the refuter and the settled-diff exit all run in quick. What quick skips is the parallel panel: one reviewer carries every lens, and one batched refuter judges the findings.
- **Phase 6 Step C.5 runs the law-scout** over the touched files, so a pre-existing cap break or ownerless debt marker that the project's linter never configured is surfaced and offered rather than shipped. The sweep also confirms the ship gate left no process holding a port and no fixture staged into the diff.
- **`phase-5-multi-review.md` split.** Reviewer D moved to `phase-5-multi-review-d-performance.md`, matching the one-file-per-reviewer layout E already used and F now uses. The immediate cause was the 500-LOC hard cap: Reviewer B's law-scout hookup did not fit with D still inline. `agents/code-reviewer-performance.md` follows the moved canonical source.

### Fixed

- **Reviewer E was never structurally validated and had drifted.** It sat outside `20-templates.sh`'s template arrays, so its missing canonical SEVERITY line (it said "against the spec or the live diff" where the contract mandates "against live docs or live code") went unnoticed since 0.8.0. D, E, F and the refuter are now all registered, and the contract-mandated sentence is verbatim in every one.
- **`template-contract.md:15` still described Phase 5 as "three foreground reviewers"**, stale since Reviewer D landed. It now names all five standing reviewers plus the conditional sixth, and documents the refuter dispatch.
- **Stale reviewer counts** in `communication-voice.md`, `parallel-agents/README.md`, `README.md` and the quick-mode skill description and body.
- **`phase-3-implementation.md`'s "After all wave agents return" steps never ran a scout at all**, so the dispatched wave template contradicted `SKILL.md`'s wave loop and went straight from the triad to ticking checkboxes. Predates this release (the perf-scout was already missing); now runs both scouts before anything is ticked.
- **Two dispatcher-built maps with overlapping meaning merged into one.** Reviewer C's `{{task_file_index}}` (Task→files) and the coherence reviewer's originally separate wave map are now a single wave-qualified `{{task_file_index}}` keyed `W<n>/T<m>`, built once and passed to both. F reads the `W<n>` prefix to find same-wave seams; C matches on `T<m>`. Two names for one concept is a `style.reuse` finding under the lens table this release adds, so it was not going to survive its own review.
- **`SKILL.md` Phase 5 now names all three dispatcher-built inputs** (`law_scout_report`, `perf_scout_report`, `task_file_index`) and where each comes from. Reviewer F refuses to proceed on an unfilled placeholder, so a mechanism with no documented producer would have failed on every dispatch, the exact unwired-symbol defect F exists to catch.
- **`review-triage`'s description** listed four reviewer lenses and did not say where it sits relative to refutation. It now names all six and states that it runs after the refuters, whose verdicts fill its Decision and Evidence columns.
- **`runtime-adapters.md` now records `python3` as a dependency of the core workflow**, not only of the optional lawkeeper skill, plus the ship gate's need for background process control and a readiness probe, with the documented degradation for each. Best-effort runtimes lose coverage to a written gap, never to a silent pass.
- **`work-doc-template.md`'s Evidence Ledger skeleton** was missing the second scout row and all three ship rows.

**Verified.** `validate-dod.sh` exit 0 with the seven new checks; each new check proven to fail when its guarded contract is broken, then restored. Lawkeeper scanner suite 28/28 (25 prior + 3 new). Recall corpus matches its oracle exactly. Ban-blocker hook suite green. `sync-runtimes.sh --dry-run` covers all 7 runtime targets with 0 errors. Every primitive file at or under the 500-LOC cap.

## [0.8.1] - 2026-07-26

> **Patch: the 0.8.0 release was invisible to clients, plus two hardening follow-ups.** 0.8.0 bumped every `version` field but left the stable channel's `source.ref` pinned to `v0.7.1`. `version` is display metadata; `ref` is what Claude Code actually fetches, so clients resolved the plugin to the old tag and reported "hackify is already at the latest version (0.7.1)". Every file was correct and every check was green. This release fixes the pin, guards it, makes catalog conformance permanent, and removes em dashes from prose per the project's writing rules.

### Fixed

- **Stable channel pin.** `hackify` channel `source.ref` `v0.7.1` to `v0.8.0` (and now `v0.8.1`). Without it the 0.8.0 design-spec pipeline never reached any client.
- **Stale `dist/` manifest.** The ref fix landed without re-running `sync-runtimes.sh`, leaving `dist/claude-code/.claude-plugin/marketplace.json` pointing at the old tag. Re-synced and byte-identical to source.
- **Missing marketplace keywords.** `design-system` and `design-tokens` reached `plugin.json` in 0.8.0 but not the marketplace entries, so the headline capability was invisible to keyword search. Added to both channels.

### Added

- **`scripts/validate-dod.d/27-marketplace-ref-pin.sh`** guards the defect above: the stable channel's `ref` MUST equal `v<plugin.json version>`, the edge channel MUST stay on `main`, and every channel `version` MUST equal `plugin.json`. Verified by reintroducing the exact bug and confirming the validator exits 1.
- **`scripts/check_design_specs.py` + `scripts/validate-dod.d/85-design-spec-conformance.sh`** enforce the design-spec contract on every run: nine token blocks, twelve typography roles, ten components, every `{token.ref}` resolves, no raw hex or bare px inside `components:`, font stacks ending in a generic family, WCAG 2.1 AA on every role rendered as text, the 380-470 line band, and eleven prose sections. Proven by a mutation test over a throwaway catalog copy: all ten defect classes caught.
- **`accentIsFill: true`** optional frontmatter key, documented in `spec-contract.md` and declared by `playful-pop`. Directions whose accent is a fill carrying dark text are measured against that text rather than against `canvas`, so an intentional decision no longer reads as an accessibility failure.

### Changed

- **Em dashes and en dashes removed from prose** across `skills/`, `rules/`, `agents/`, `commands/`, `hooks/`, `scripts/`, `README.md`, `CHANGELOG.md` and the plugin manifests: 3,031 replacements over 138 files, per the project's writing rules. Commas, periods and parentheses replace them; numeric ranges become hyphens. Code is untouched: language-tagged fences, inline code spans and URLs were masked before replacement, and shell/Python files skip the markdown heading rule so `#` comments are not treated as headings.
- **`scripts/validate-dod.d/20-templates.sh`** heading literals and its awk end-pattern realigned to the rewritten `## Phase 5, Multi-reviewer X` headings. The scrub broke this coupling loudly, which is how it was found.
- Literals that appear in two places were re-aligned so they still agree: the `/hackify:summary` follow-up line, the `DESIGN.md` `name:` and `reduced:` templates versus the twelve real specs, and the skillsmith heading template.

**Left deliberately unchanged.** Three CHANGELOG entries quote heading names as they existed in earlier releases; rewriting them would falsify the record. Archived work-docs under `docs/work/done/` were excluded entirely for the same reason: their Evidence Ledgers quote verbatim tool output as proof, so editing them would falsify evidence.

**Verified.** `validate-dod.sh` exit 0, all checks green. 29 shell files parse, 11 Python files compile, every JSON parses, 12 catalog specs pass all 9 contract checks, the hooks ban-blocker suite passes 41/41, zero broken markdown links, the Reviewer E agent mirror is still byte-identical, and `sync-runtimes.sh` writes 629 files across 7 runtimes with 0 errors.

## [0.8.0] - 2026-07-26

> **Design work now produces an artifact.** Hackify's visual law told the model what good looks like but never wrote anything down, so design intent evaporated between sessions and no reviewer could check whether the code matched the intent. 0.8.0 adds the missing half: a committed design specification in the user's own project, twelve deeply-specified directions to author it from, twelve ready-to-drop specs, a self-contained visual preview, and a standing Phase 5 reviewer that audits diffs against it. `references/frontend-design.md` remains the law and now owns the pipeline.

### Added

- **`references/design-spec/`, the design artifact package.**
  - `spec-contract.md`, the binding `DESIGN.md` anatomy: a nine-block YAML token layer (colors, fonts, typography, spacing, rounded, elevation, motion, components, platform), the `{token.ref}` cross-reference syntax, twelve required typography roles, ten required components with their interactive states, eleven prose sections, authoring rules, and a twelve-item validation checklist.
  - `direction-library.md`, twelve visual directions, each with palette logic, type pairing, motion character, a signature move, **anti-tells** (the specific ways that direction gets built wrong), and best-fit product types. This is now the plugin's **single canonical direction list**; `frontend-design.md`'s former nine-item list was removed rather than duplicated.
  - `extract-protocol.md`, deriving a spec from an existing codebase (Mode A), a reference site (Mode B), or screenshots (Mode C), plus REFRESH mode with a drift / evolution / gap / dead classification, merge rules, and an extraction-report format.
  - `catalog/`, twelve complete, original specs: `industrial-precision`, `editorial-print`, `retro-terminal`, `warm-organic`, `brutalist-mono`, `neo-luxury`, `swiss-grid`, `data-dense`, `playful-pop`, `nordic-calm`, `cyber-neon`, `soft-depth`. Six dark-canonical, six light-canonical. No real brand identity is reproduced; every font is freely licensed and ships an offline fallback stack.
- **Web ↔ native from one spec.** The token layer is platform-neutral with a `platform.native` block (touch targets, safe area, status bar, elevation model, haptics, Dynamic Type) and a normative mapping table across CSS, React Native, Flutter and SwiftUI, including the line-height rule, the one token the four platforms genuinely disagree about.
- **`assets/design-preview-template.html`**, a self-contained visual catalog rendering color swatches with live computed contrast, the type ramp, spacing and radius scales, elevation on the spec's own canvas, the motion table, and real components built from the token entries, with a light/dark toggle. Zero network references. Broken `{token.ref}` values render as visible chips, so the preview doubles as a reference checker.
- **Phase 5 Reviewer E, design conformance.** A standing fifth reviewer on UI-bearing diffs (`references/parallel-agents/phase-5-multi-review-e-design.md`, mirrored byte-for-byte at `agents/design-conformance-reviewer.md`). Audits hardcoded color/size/shadow literals where a token exists, off-ramp type sizes, components missing documented hover/focus/press/disabled states, violations of the spec's own Don'ts list, WCAG AA contrast and focus regressions, and physical properties where logical are required. Every finding names the exact replacement token. Falls back to the `frontend-design.md` visual law when no spec exists.
- **`/hackify:designify`** (`commands/designify.md`), author, extract, refresh, or validate a spec standalone, in four resolved modes. Computes real WCAG contrast rather than asserting it, and runs the contract's validation checklist before finishing.
- **Clarify-bank design questions.** `revamp-redesign.md` gains Q4b (change *within* the direction vs change *of* direction, the latter making a new spec an explicit gated Phase 2 deliverable); `feature.md` gains Q6b (design authority for a UI-bearing feature).
- **Eval case 4**, `design-spec-pipeline-ui-redesign`, twelve assertions covering direction choice, spec-before-components ordering, the native platform block, AI-slop rejection, computed contrast, and Reviewer E dispatch.

### Changed

- **`references/frontend-design.md` is now the law layer that owns the pipeline** (197 → 225 lines). Adds the spec-first binding sequence and the `docs/design/` output contract, defers the direction list to `direction-library.md` so exactly one list exists in the plugin, generalizes the reusable-visual-moments section across directions, and adds an Enforcement section pointing at Reviewer E. Its bans gain default backdrop blur; its musts gain the reachable-fonts rule.
- **Phase 5 reviewer roster.** The 5th slot is now explicitly Reviewer E on UI-bearing diffs; `phase-5-escalation.md` keeps every other specialist surface. Boundary documented in both files so the two lenses cannot collide. Cap stays at 5.
- **Companion skills mirrored.** `yolo` names Reviewer E in its Phase 5 table; `quick` folds the design-conformance lens into its single-lens 5-lite review, since a one-line CSS tweak is exactly where token drift starts.
- **`scripts/validate-dod.d/60-primitives.sh`**, `AGENTS_EXPECTED` grows to 9 with `design-conformance-reviewer`.
- **`scripts/sync-runtimes.d/00-helpers.sh`**, 22 new canonical files added to `MIRROR_SOURCES` / `CLAUDE_CODE_EXTRA`.

### Fixed

- **Four catalog specs shipped semantic colors below WCAG AA as text** and were corrected before release, caught by computing every ratio rather than eyeballing it: `soft-depth` positive/caution/negative (3.20 / 3.19 / 4.06 → 5.00 / 5.26 / 5.30), `nordic-calm` caution (4.00 → 5.41), `warm-organic` caution (3.66 → 5.30), `neo-luxury` negative (4.36 → 6.49). `playful-pop` documents explicitly that its hues are fill colors measured against the near-black text on them, never text colors on the canvas.

## [0.7.1] - 2026-07-03

> **Patch: version-only alignment release, no functional changes since 0.7.0.** Cut so the marketplace channels serve a fresh tag; every feature listed under 0.7.0 is unchanged.

### Changed

- **Release plumbing only.** Version → `0.7.1` (`plugin.json`, both `marketplace.json` plugins, README badge; hackify channel `source.ref` → `v0.7.1`). No code, doctrine, or behavior changes.

## [0.7.0] - 2026-07-03

> **Minor: a trackable phase ledger forces the phases in order and closes the "forgot to archive" gap, and an always-on expert mindset raises how the model approaches every task.** Every task now runs against a **phase ledger**, a to-do list (the runtime's todo tracker) with one item per phase and an ordering law: one item `in_progress` at a time, and no later phase starts until the current phase's exit artifact exists. Phase 6 splits into sub-items so archiving the work-doc to `done/` is its own tracked step that **gates the summary**, the recap is unreachable until the doc is filed, so "finished the work, forgot to archive" cannot happen by construction. A new always-on **expert mindset** doctrine casts the model as a senior, multi-disciplinary engineer (problem-solver, security, performance, architect, advisor, verifier) and stresses that the work ships to real users; a tight version is injected on every prompt beside the hard caps, and the fuller hat-by-hat doctrine loads from Phase 1. Applied across `hackify`, `quick`, and `yolo`. **This release also makes performance a first-class, enforced concern on every scanning surface**: a canonical violation catalog (`rules/performance.md`, 95 stable `perf.<domain>.<slug>` IDs across 10 domains) is distilled into an always-on `rules/perf-guardrails.md` (the third every-prompt injection); a deterministic **perf-scout** greps every diff at each Phase 3 wave-end and again at Phase 5 start; and a dedicated **Reviewer D (performance)** joins Phase 5, growing the multi-reviewer default to four parallel lenses (A/B/C/D). A whole-plugin audit fixed ~25 findings at every severity, and the DoD validator gained checks that enforce the new surfaces.

### Added

- **`references/phase-ledger.md`, the trackable, ordered phase ledger.** One canonical contract: creation timing (Phase 2 for full hackify; task start for quick/yolo), the ordering law (one item `in_progress`, no jumping ahead, no silent skip, a carve-out is marked `completed` with a one-line reason), a per-phase **exit-artifact table** (Phase 6c archive's artifact = the doc physically in `docs/work/done/` with `status: done`), reflect-after-step, per-mode item lists, and pause/resume rebuild. Wired into `SKILL.md` as an always-on section + a Phase 2 creation step + a file-map entry; compact mirrors added to `quick` and `yolo`.
- **`rules/expert-mindset.md` + `references/expert-mindset.md`, the always-on expert mindset.** The tight `rules/` stub (stakes + six hats + deliberate-work rules) is injected every prompt; the fuller `references/` doctrine (a hat → when-it-leads → what-it-checks table) loads from Phase 1 like the communication voice. Wired as an always-on section in `SKILL.md`, compact pointers in `quick`/`yolo`, and file-map entries.
- **8th runtime primitive `todo tracker`.** `references/runtime-adapters.md` registers the phase-ledger substrate (Claude Code → `TodoWrite`, OpenCode → `todowrite`, best-effort runtimes → emulate as an in-chat markdown checklist), keeping the "identical design law across runtimes" invariant intact.
- **`rules/performance.md`, the canonical performance-violation catalog.** 95 stable `perf.<domain>.<slug>` IDs across 10 domains (algorithmic, memory/allocation, data access/N+1, network/API, async/concurrency, frontend/rendering, caching, I/O/serialization, build/bundle, logging/observability), each with a severity, why it hurts, a detection hint, and a fix direction, plus a severity model and a "When NOT to optimize" section. Loaded on demand by implementers, Reviewer D, and scout triage; a perf gate joins the Phase 4 acceptance rows.
- **`rules/perf-guardrails.md`, the always-on performance tier.** A tight stub injected on every prompt as the **third** `UserPromptSubmit` entry, beside the hard caps and the expert mindset. It points to `rules/performance.md` as the canonical source instead of restating it (the inverse of the hard-caps direction, stated in both files).
- **`references/perf-scout.md`, the deterministic perf-scout.** BSD-grep-safe pattern tables for JS/TS, Python, and SQL, each pattern keyed to a catalog ID, plus a staging-table format, false-positive triage rules, and wrong→right micro-examples for the top offenders. The scout runs at **every Phase 3 wave-end and again at Phase 5 start**; surviving candidates are staged into the address-all decision table. `quick` runs it in Phase 4 and adds performance to its single-lens review; `yolo` stages scout findings into its auto-fix loop.
- **`agents/code-reviewer-performance.md`. Phase 5 Reviewer D.** The multi-reviewer default grows to **four parallel reviewers A/B/C/D** (security, quality, plan-consistency, performance) in `hackify` and `yolo`, and the multi-concern reviewer cap rises 4 → 5. Reviewer D consumes the scout report and cites catalog IDs in every finding. Perf rows join the self-review checklist (14 → 16 items), the work-doc template, `review-triage`'s severity rubric, and `lawkeeper`'s rule catalog.

### Changed

- **Archive-before-summary gate (the "forgot to archive" fix).** `SKILL.md` Phase 6 Step F is now hard-gated on Step D (archive), and `references/finish.md` Step D states the gate + fixes a stale sentence that encoded the old "summary before archive" ordering. New anti-rationalization + anti-pattern rows in `SKILL.md` and `finish.md`.
- **Injection hook generalized.** `hooks/inject-hard-caps.sh` → `hooks/inject-context.sh`, parameterized over the file path (`$1`) so one script injects any always-on file (DRY). `hooks/hooks.json` invokes it once per file (`hard-caps.md`, `expert-mindset.md`, `perf-guardrails.md`); the fail-open + JSON-envelope contract is preserved.
- **Validator + registration hardening.** The expected agent count is now derived from the roster instead of hard-coded at 7 (8 agents ship today); mirror-completeness `[55]` forward-checks `agents/` and `hooks/` too; skill-dir coverage `[25]` gains `codewalk` + `lawkeeper`; new checks land, `agents/*.md` template-contract conformance (`[36]`), every `hooks.json` command target exists on disk (`[37]`), perf-guardrails is really injected (`[38]`), Reviewer D + perf-scout wiring invariants (`[39]`); `check-collisions.sh` gains the `lawkeeper` slug.
- **Hook scanners hardened.** `scan_edit.py` / `scan_bash.py` keep the fail-open contract even when detection itself crashes (a hook bug must never wedge editing); multi-heredoc Bash commands now attribute each heredoc to its own redirect target, with a superset rule on count mismatch (every heredoc checks ALL candidate targets, so redirect-after-body forms cannot bypass the blocker); every fail-open exit now leaves a one-line stderr breadcrumb; the `tee` filter in `block-banned-tokens.sh` is BSD-safe. Hook test suite grown 29 → 41 cases.
- **`references/runtime-adapters.md`, native-tier enhancements.** A new "optional, never load-bearing" section maps structured subagent outputs, background subagents, per-agent model/effort tiers, task-tracker dependency ordering, and batched wizard rounds to the runtimes that have them, each with an explicit degrade path. The stale "seven primitives" claim corrected to eight.
- **Release plumbing.** Version → `0.7.0` (`plugin.json`, both `marketplace.json` plugins, README badge; hackify channel `source.ref` → `v0.7.0`); a "New in 0.7.0" README blurb plus hooks / file-map / phase-notes updates; `phase-ledger.md`, both `expert-mindset.md` files, and the `inject-context.sh` rename registered in the sync manifests (`MIRROR_SOURCES` + `CLAUDE_CODE_EXTRA`). This sprint registers the perf trio (`rules/performance.md`, `rules/perf-guardrails.md`, `references/perf-scout.md`) and the Reviewer D agent in the same manifests, rewires the README for the performance law (four reviewers, 16-item checklist, new file-map rows, the three named injections), and regenerates `dist/` + the demo GIF.

### Fixed

- **~25 whole-plugin audit findings, at every severity.** Highlights: `references/finish.md` regained the `## Step F` heading that four files cite; both Reviewer B templates (Phase 2.5 + Phase 5) now actually load `rules/code-quality.md` as `SKILL.md` claims; `/hackify:summary` parses the current sprint-vocabulary work-doc labels (with a legacy fallback) and appends to `Retrospective`; `review-triage`'s broken reference paths, `phase-ledger.md`'s wrong sibling link, stale version tags, and `skillsmith`'s over-broad SEVERITY frontmatter all fixed; repeated hard-cap restatements replaced with pointers to the canonical `rules/hard-caps.md`; the duplicated drift-verdict blocks now each carry a canonical-source pointer.

## [0.6.1] - 2026-07-02

> **Minor: Phase 4 proves every item, re-proves it in layers, and reports it in plain words.** Verify gains a per-item **Evidence Ledger**, one row per Sprint Backlog task AND per acceptance bullet, each carrying a real, trimmed proof sample instead of a bare checkmark. A named **three-layer re-verify** (fresh triad → goal-drift re-check against the Primary Goal & Guardrails anchor → independent re-prove) lets you re-earn the proof on demand without wandering off the goal. The Phase 6 HTML report now opens with a plain-language **"What changed & why it matters"** summary and closes with a cumulative **Evidence appendix**, so a non-technical reader can follow it end to end. A new always-on **communication voice** doctrine keeps chat in B2 (upper-intermediate) English and self-explanatory. Applied to `hackify` (full ledger + 3 layers), `yolo` (same), and `quick` (lite ledger + Layers 1-2).

### Added

- **`references/communication-voice.md`, the B2 + self-explanatory chat doctrine.** Short sentences, common words, define jargon once, active voice, lists over walls of text, and a lead-with-intent narration rule (say WHAT then WHY before each phase/tool batch). Governs chat prose ONLY, code, commands, file paths, identifiers, and commit messages stay exact. Wired into `SKILL.md` as an always-on section + file-map entry, registered in `MIRROR_SOURCES`, and mirrored to every runtime under `dist/`.
- **Evidence Ledger (Phase 4).** `references/review-and-verify.md` + `SKILL.md` Phase 4 define a per-item ledger (`Item | Type | Claim | What I ran | Proof sample | Result`) covering every task and acceptance bullet; a missing or ❌ row blocks Phase 5. `references/work-doc-template.md` gains the ledger table in Sprint Review so it persists in the work-doc.
- **Three-layer re-verify.** Layer 1 fresh triad, Layer 2 goal-drift re-check (trace every proof to the North-Star Goal + Success Signals, `goal-anchor.md` now lists Phase 4 Layer 2 as a third drift-trace point), Layer 3 independent re-prove. `hackify`/`yolo` run all three; `quick` runs Layers 1-2.
- **Plain-language report + evidence appendix.** `assets/report-template.html` + `references/html-report.md` add a `{{PLAIN_SUMMARY}}` block at the top and a `{{EVIDENCE_APPENDIX}}` (the cumulative ledger) at the bottom; both entity-encoded, report stays self-contained (inline CSS + SVG, zero network deps).

### Changed

- **`skills/hackify/SKILL.md`. Phase 4 rewired** from a flat DoD checklist to the Evidence Ledger + three-layer re-verify (phase table row + body); a new **Communication voice (always-on)** section and file-map entry added. `references/finish.md` Step F now describes the plain summary + evidence appendix.
- **Companion skills reconciled.** `quick` Phase 4 row documents the lite ledger + Layers 1-2 (skips the heavy Layer 3); `yolo` Phase 4 row + flow line document the full ledger + all three layers. Both inherit the deep spec by pointer to `review-and-verify.md` (DRY).
- **Release plumbing.** Version → `0.6.1` (`plugin.json`, both `marketplace.json` plugins, README badge; hackify channel `source.ref` → `v0.6.1`); a "New in 0.6.1" README blurb; `communication-voice.md` registered in `MIRROR_SOURCES`.

## [0.6.0] - 2026-07-01

> **Minor: the four workflow phases get materially stronger, across every entry skill.** Clarify becomes a grooming session that captures a persisted **Primary Goal & Guardrails** anchor and enforces it with a drift-check in Phase 2.5 and Phase 5. Phase 6 emits a styled, self-contained **HTML summary report** (stats, inline-SVG charts, findings, action items, next steps) beside the archived work-doc. Phase 5 now **addresses ALL findings**, a lawkeeper-style address-all loop that tabulates every finding, fixes every severity (Minor included), and re-scans to zero, instead of deferring Minor to the Retrospective. The Step C.5 cleanup sweep flips from *defer* to *offer-to-fix* on **pre-existing errors** in touched files, so the change lands as the best version, not just a passing one. Applied consistently across `hackify`, `quick`, `yolo`, and `groom`.

### Added

- **`references/goal-anchor.md`, the Primary Goal & Guardrails doctrine.** A north-star anchor (North-Star Goal / In-Scope / Out-of-Scope-Non-Goals / Guardrails-Invariants / Success Signals) captured in Phase 1, persisted in the work-doc, and enforced by a drift-check. The `work-doc-template.md` gains a `## Primary Goal & Guardrails` section (numbered sprint headings unchanged); `clarify-questions/universal-preamble.md` gains **Q5. Goal & guardrails** (4-section wizard contract intact); Phase 1's question cap becomes a floor-not-ceiling with a grooming coverage checklist.
- **`references/html-report.md` + `assets/report-template.html`, the styled HTML summary report.** A single self-contained `.html` (inline CSS + inline SVG charts, light/dark via `prefers-color-scheme`, **zero external network dependencies**) written beside the archived work-doc at `<slug>.report.html` (quick/yolo: `docs/work/reports/<date>-<slug>.report.html`). The Area/Change chat table still prints and is embedded in the report.
- **Goal drift-check in both reviewer roles.** Phase 2.5 Reviewer A (`phase-2.5-spec-review-a-consistency.md` + `agents/spec-reviewer-consistency.md`) traces every task/DoD bullet to the anchor; Phase 5 Reviewer C (`phase-5-multi-review.md` + `agents/code-reviewer-plan-consistency.md`) traces every changed hunk, untraceable → Important, guardrail/non-goal violation → Critical. 7-section template contract, canonical severity phrase, and OUTPUT word caps preserved.

### Changed

- **`skills/hackify/SKILL.md`, all four phases rewired.** Phase 1 grooming + anchor capture; Phase 2.5 + Phase 5 drift-check; Phase 5 **address-all loop** (Minor no longer auto-deferred, defer only with explicit sign-off); Step C.5 class (g) flips to offer-to-fix; Step F emits the HTML report. `references/finish.md` rewrites class (g) with baseline + offer-to-fix and adds the Step F report pointer; `references/review-and-verify.md` adds the decision-table address-all loop; `commands/summary.md` emits the report at finish (and fixes a stale `Post-mortem`→`Retrospective` append target).
- **Companion skills reach parity.** `quick` (per user choice) gains trimmed clarify + a single-lens address-all review + offer-to-fix cleanup + the HTML report, while KEEPING its "Skipped phases" identity (skips Plan+Gate, Spec-review, the 3-lens Phase 5, the four-options menu). `yolo` auto-fixes **every** severity (incl. Minor) and re-scans to zero, auto-fixes pre-existing errors in touched files, and emits the report. `groom` graduation seeds the `## Primary Goal & Guardrails` section from its distillation.
- **Release plumbing.** Version → `0.6.0` (`plugin.json`, both `marketplace.json` plugins, README badge; hackify channel `source.ref` → `v0.6.0`); the three new files registered in `MIRROR_SOURCES`; a "New in 0.6.0" README blurb.

## [0.5.0] - 2026-06-20

> **Minor: file-separation doctrine + the reusable-by-default prime directive.** Adds a new always-on rule cluster, one component per file, one construct per file, a dedicated file per concern (types / constants / config / schemas / styles), and a consistent documented folder structure, plus a "reusable, generic, shareable" prime directive that frames DRY and Simplicity First as its guardrails. Injected every prompt via `rules/hard-caps.md`, detailed in `rules/code-quality.md`, and made auditable by lawkeeper (`scope.one-construct`, `scope.one-component`, `folder.one-component`, `style.reuse`).

### Added

- **`rules/hard-caps.md`, "File separation (one thing per file)" + the reusable-by-default prime directive.** The always-on injected caps now mandate one component per file (no second component, public or private, sub-components move to a `<component>/` folder), one class per file, a dedicated file per concern (types/constants/config/schemas/style maps), and a consistent documented folder skeleton; technical exceptions MUST cite the concrete compiler/linter error they prevent. A new lead principle, write every unit reusable / generic / shareable / testable, extract on the second use, never speculatively, heads the always-on principles.
- **`rules/code-quality.md`, two new doctrine sections.** "Reusable, generic, shareable, the prime directive" (the rule every other rule serves) and "One construct per file & dedicated-file separation" (single component/class per file, a dedicated file per concern, consistent folders), plus an **extraction-floors** subsection mashed in from lawkeeper's carve-outs, single-use read-in-place values, correctness floors (schema-builder args, object keys, SQL, `${…}` templates, imports, regex, union members, ORM defaults), lint-ban tokens, and framework typed-path floors, each with the documented-exception requirement. The existing inline-type ban broadens from service/controller/guard/router/middleware to ALL implementation files (components, pages, routes included).
- **lawkeeper audits the new rules.** `references/rule-catalog.md` gains `scope.one-construct` (impl file declares a type/const/config/schema/style not in its dedicated file), `scope.one-component` (2+ components in a file), `folder.one-component` (multi-part component not foldered), and `style.reuse` (near-duplicate that should be generalized into a shared parameterized helper); `folder.type-home` widens to config/schema/style homes.

### Changed

- **lawkeeper carve-outs, react-refresh floor narrowed.** `references/carve-outs.md` records the clean resolution that satisfies the new one-construct rule: relocate BOTH the runtime schema and its inferred type to dedicated files (the component then exports no runtime value, so hot-reload stays green). The inline carve-out now applies ONLY when a project deliberately keeps the runtime schema in-file for locality; otherwise an inline component schema is a `scope.one-construct` finding.
- **`skills/hackify/SKILL.md` "Code quality (always-on)"** recaps the new file-separation caps (one component per file, dedicated file per concern) and the reusable-by-default prime directive so the main workflow stays consistent with the injected rules.

## [0.4.7] - 2026-06-10

> **Patch-level: the semantic tier is now measured wall-to-wall.** Broadens the recall-corpus oracle from 8 to 20 `(file, rule)` pairs across 11 of lawkeeper's semantic concerns. SOLID, testing, cleanup, magic-literals, and function caps join the original six, and re-measures the whole tier. Dev/CI internals only: nothing a plugin user loads or runs changes.

### Added

- **Recall-corpus breadth: oracle 8 → 20 pairs, concerns 6 → 11.** New deterministically-clean fixtures plant `solid.yagni` (speculative transport knobs) and `solid.ocp` (xml bolted on beside a renderers registry), `test.untested` + `test.edge-cases` (a branching service with no test; a happy-path-only test whose clamp branch is never exercised), `clean.dead-flag` / `clean.orphan-env` / `clean.unused-dep` (each with a contrast control so the violation is localizable in a tiny tree; the manifest marker rides a legal `"//"` key in `package.json`), `style.magic-literal` (un-named rates/thresholds in two services), and `cap.fn-lines` / `cap.fn-params` / `cap.fn-nesting` (the shape caps the deterministic scanner does not check). The blind-copy strip is now JSON-aware (drops marker lines whole in `.json` instead of `//`-stripping them into broken JSON). Three rules are *deliberately excluded* with documented rationale: `clean.commented-code` (the comment-strip erases the violation itself), `clean.unref-file`/`scope.dead-code` (everything in a disconnected corpus is unreferenced), and `solid.lsp/isp/dip` (need type hierarchies a tiny corpus cannot plausibly host).
- **Full-tier measurement (2026-06-10, 3 rounds × 11 concerns, sonnet):** strict recall **59/60 pair-runs (98%), 19/20 pairs at 3/3**, true recall 20/20 (the lone 2/3 is the documented DRY symmetric-attribution nuance). Every newly added concern scored 3/3 on first measurement; the 0.4.6 `sec.authz` fix held at 3/3; the carve-out-floors mandate held (zero exempt-file artifacts). One oracle calibration came out of the run: test-coverage findings pin to the **source** file where the under-tested behavior lives (matching the rule text), so the `test.edge-cases` marker moved from `users.test.ts` to `users.service.ts`, detection was 3/3 throughout; the marker placement was the error.

## [0.4.6] - 2026-06-10

> **Patch-level: close the authz blind spot the corpus found.** Strengthens lawkeeper's `security` semantic prompt to catch missing-authz on service/domain-layer mutations (not just route handlers), the gap surfaced and then re-verified by the recall corpus.

### Changed

- **lawkeeper now catches service-layer authorization gaps.** The recall corpus surfaced a real blind spot: the `security` semantic-pass prompt led with "routes/handlers missing an authz check," so the pass flagged missing-authz on a controller mutation but consistently missed it on a service-layer `deleteUser` (0/3 rounds; the opus run missed it too). Rewrote the `sec.authz` clause in `references/semantic-pass.md` to cover any state-changing op, write/update/**delete** at the route, handler, OR service/domain layer, reachable with no guard, with destructive ops as the canonical case and an explicit "do not assume an upstream caller checks." Re-verified against the corpus: `auth.service.ts: sec.authz` now flags **3/3** rounds. The corpus working as designed, surfacing a prompt weakness and confirming the fix.

## [0.4.5] - 2026-06-10

> **Patch-level: honesty + measurement follow-ups.** Re-tiers two deterministic rules whose "exact / zero-false-positive" label overclaimed (they need a one-step scope/threshold check), and turns the recall corpus's semantic tier into a real multi-round measurement that surfaces a standing judgment-tier gap. Output metadata + dev/eval tooling; no workflow behavior changes.

### Changed

- **Honest confidence tiers for the deterministic scanner**, `ban.bare-error` and `ban.inline-type` were labelled `confidence: exact` and the rule-catalog claimed the deterministic tier is "zero false positives," but the scanner cannot tell domain from non-domain code (bare-error) or count props (inline-type, which the rule bans only at 2+). Both are now `confidence: syntactic`, matched exactly in syntax, but a true positive needs a one-step scope/threshold check. The other 8 rules stay `exact`. Catalog, SKILL.md, and the `checks.py` docstring corrected; pinned by a `test_audit.py` case so the honesty cannot silently regress. No detection behavior changes.

### Added

- **Semantic-tier recall is now a real multi-run measurement.** Broadened the recall corpus oracle from 5 to **8 `(file, rule)` pairs across 6 concerns** (added `style.srp`, `perf.n-plus-1`, `style.ternary` via a deterministically-clean `orders.service.ts` with neutral identifiers so the blind copy leaks nothing). `score_semantic.py` now aggregates **N rounds** into a hit-rate per pair + mean recall (one file = a single illustrative read; several = variance-aware). Observed baseline (2026-06-10, 3 rounds, sonnet): 18/24 pair-runs strict, 7/8 attribution-corrected, with one **consistent real gap**, the security pass flags missing-authz on a controller mutation but misses it on a service-layer mutation (recorded in `semantic-runner.md`). The runner now also mandates handing subagents the carve-out floors (else they flag exempt files like a migration).

## [0.4.4] - 2026-06-10

> **Patch-level: measure the auditor, fix the flaky gate.** Adds the lawkeeper recall corpus, a known-oracle fixture set that converts the rulebook from *asserted* to *measured* (deterministic tier: 9/10 rules at 100% recall / 0 false positives, CI-gated; semantic tier scored on demand), and fixes a SIGPIPE flake in DoD check `[24]` that had silently failed the first-ever CI run. Dev/CI internals only: nothing a plugin user loads or runs changes.

### Added

- **lawkeeper recall corpus** (`skills/lawkeeper/evals/corpus/`), a synthetic project of deliberately-violating fixtures that measures the auditor's precision/recall against a known oracle, closing the "rules asserted, not measured" gap surfaced in the evaluation-coverage audit. Every planted violation carries an inline `// EXPECT:` / `// EXPECT-CLEAN:` / `// EXPECT-SEMANTIC:` marker, the self-maintaining oracle (no separate line-numbered file to rot; markers carry the bare rule_id only, so they never trip the scanner they exercise).
  - **Deterministic tier** (`run_corpus.py`, in CI): runs `audit_scan.py` and asserts findings equal the `EXPECT:` set **exactly**, today 9/10 deterministic rules at 100% recall with **0 false positives** across 7 carve-out traps (test-file waivers, non-scoped inline types, the env-name secret guard, owned/ticketed debt markers, generated/migration exemption). A `ground-truth.json` freshness check fails CI on marker drift. `ban.custom` stays covered by `test_audit.py` (needs a project `ban-patterns.txt`).
  - **Semantic tier** (`score_semantic.py` + `semantic-runner.md`, on demand): dispatches the judgment-rule subagent pass over a **comment-stripped blind copy** (so headers/markers can't leak the answers) and scores recall by `(file, rule)`. First illustrative run scored **4/5**, the lone miss being a missing-authz on a service-layer mutation, proving the harness surfaces real judgment-tier gaps. Non-deterministic, so it is out of CI and explicitly labelled illustrative (run each concern a few times for a stable number).
  - Fixtures are **never mirrored to `dist/`** (`validate-dod [55]` excludes `*/evals/corpus/*`), shipping deliberately-broken code into the generated runtime trees would be wrong. They still live in the repo (and so in plugin caches), but carry no `SKILL.md`, so they are never loaded as a skill, and the planted secret is an inert fake literal already present in `test_audit.py`. The corpus is also exempt from a `/lawkeeper` self-audit of this repo (added to the scanner's generated-globs) and allow-listed for the ban-blocker so the on-by-default hook does not block authoring it.
- **CI step** running the corpus deterministic scorer (`.github/workflows/ci.yml`).

### Fixed

- **Flaky DoD gate `[24]`** (`scripts/validate-dod.d/50-runtimes-and-companions.sh`), the runtime-target check piped a ~40KB `$DRY_OUT` into `grep -q`, which short-circuits on first match and closes the pipe; the upstream `printf` then took SIGPIPE and, under `set -o pipefail`, the pipeline reported non-zero even though `grep` matched, a spurious "missing dist/<runtime>/" failure. It silently failed the **first-ever CI run** (0.4.2 `a5a8972`) and surfaced locally as an intermittent "N CHECK(S) FAILED." Replaced the pipe with a here-string (no upstream producer to receive SIGPIPE). A flaky gate is itself an evaluation-integrity defect, the same class this release set out to close.

## [0.4.3] - 2026-06-10

> **Patch-level: edit-time secret blocking.** Extends the on-by-default `PreToolUse` ban-blocker to catch hardcoded secrets, `sec.hardcoded-secret`, lawkeeper's only critical-severity rule and the one deterministic check the edit-time hook did not enforce. Surfaced by auditing hackify's own principle/standards *evaluation* coverage (edit-time enforcement was a strict subset of audit-time).

### Added

- **Edit-time hardcoded-secret blocking**, the `PreToolUse` ban-blocker (`hooks/scan_edit.py` / `hooks/scan_bash.py`) now also blocks `Write`/`Edit`/`Bash` actions that introduce a hardcoded secret (AWS/GitHub/Slack/Google keys, PEM private keys, assigned `api-key`/`password`/`token` literals) into JS/TS source. `sec.hardcoded-secret` is lawkeeper's only **critical**-severity rule, yet it was the single deterministic check the edit-time hook did not enforce, so a credential could reach disk and wait for a full audit that might never run. Detection reuses `FileContext.check_secrets` (the same provider patterns, env-name carve-out, and redaction the scanner uses, single source of truth); the secret value is never echoed back in the block message. **Net-new only** for Write/Edit (a secret already on an untouched line is grandfathered) and honors the `.claude/hooks/ban-allowlist` escape hatch. Hook test suite grown 25 → 29 cases.

## [0.4.2] - 2026-06-09

> **Patch-level: the plugin-hardening pass.** Bundles edit-time ban enforcement (a new `PreToolUse` hook), the first CI gate, and two new Definition-of-Done checks that close the holes which let a stale README badge and 5 unmirrored evals ship. Areas surfaced by auditing hackify against its own doctrine.

### Added

- **`hooks/block-banned-tokens.sh` + `hooks/scan_edit.py` + `hooks/scan_bash.py`**, a `PreToolUse` (Write|Edit|Bash) hook that blocks edits **introducing** zero-tolerance banned tokens into JS/TS source: lint/type suppressions (`@ts-ignore`, `@ts-nocheck`, `eslint-disable`, `biome-ignore`; `@ts-expect-error` outside test files), non-null `!`, empty `catch {}`, and bare `throw new Error(`. **Net-new only** for Write/Edit, a banned line already present in the file (Write) or the replaced `old_string` (Edit) is grandfathered, so the hook blocks what you add, not pre-existing violations on lines you carry past untouched. **Bash coverage**, also scans source written via a heredoc or `echo`/`printf` redirect to a JS/TS file (the shell path that would otherwise bypass Write/Edit); it does NOT see content produced by `cp`/`mv`/`sed`/`awk` (not statically knowable). Detection reuses lawkeeper's tested `lexer.py` + `checks.py` regexes (single source of truth), semantic bans are matched on lexer-MASKED text, so a token inside a string or comment never false-fires; suppressions are matched on raw text. **On by default** (claude-code only). Per-path escape hatch: list a path (literal or glob) in `<project-root>/.claude/hooks/ban-allowlist` (e.g. standalone front-end assets where a bare `Error` is acceptable). Fail-open by design: any internal failure (missing `jq`/`python3`, unparseable input) allows the edit, a hook bug must never wedge editing. 25-case test suite (`hooks/test_block_banned_tokens.sh`).
- **`.github/workflows/ci.yml`**, the first automated gate. Runs the lawkeeper scanner tests, the ban-blocker hook tests, `validate-dod.sh`, and `sync-runtimes.sh --dry-run` on every push + PR to `main`. The 0.4.0 stale badge shipped precisely because the only gate was a human running the validator locally.
- **`validate-dod` [55] mirror-completeness** (`scripts/validate-dod.d/55-mirror-completeness.sh`), diffs `git ls-files skills/ commands/ rules/` against `MIRROR_SOURCES ∪ CLAUDE_CODE_EXTRA` (read straight from the sync manifest, not re-listed). Fails on any tracked canonical file absent from the manifest (which would ship missing from `dist/`) or any stale manifest entry. `git ls-files` (not `find`) excludes `dist/` and build artifacts for free. Regression-tested (probe file → FAIL).
- **`validate-dod` [16b] README-badge version check**, the shields.io badge must equal `plugin.json .version`; closes the unstructured-string drift the jq-only [16] check could not see.
- **`.claude/hooks/ban-allowlist`**, hackify's own dogfood allowlist, exempting the codewalk browser viewers (standalone assets, not domain code) from the bare-`Error` ban so the hook never blocks editing the plugin itself.

### Changed

- **`scripts/sync-runtimes.d/00-helpers.sh`**, fixed the bug check [55] surfaced: 5 companion-skill `evals.json` (groom, quick, review-triage, skillsmith, yolo) were tracked but never mirrored to `dist/`; added them to `MIRROR_SOURCES`. Registered the two new hook files in `CLAUDE_CODE_EXTRA`.
- **`skills/hackify/SKILL.md`**, honest runtime caveat on the "parallelism is the default" claim: on best-effort runtimes (no subagent primitive) the mandatory phases still run, but inline and sequentially, degraded concurrency, never dropped coverage.
- **`README.md`**, new **Skill routing** matrix (intent → skill, with the "audit / review / check" overlap disambiguated across all 8 skills); the hooks-primitive and repository-layout sections now document the `PreToolUse` ban-blocker; version badge → 0.4.2.

## [0.4.1] - 2026-06-09

> **Patch-level: `lawkeeper` ↔ hackify alignment polish + `validate-dod` hardening.** No workflow behavior change, voice/portability seams on the `lawkeeper` skill closed, the multi-runtime story made honest about its one host dependency, and a binary-artifact false-positive class removed from the DoD validator.

### Changed

- **`skills/lawkeeper/SKILL.md`**, documented the `python3` host dependency the Phase 2 deterministic scanner assumes (now framed as running "through the shell primitive"), with a graceful-degradation note: if `python3` is absent, report it and fall through to the interpreter-free semantic pass rather than silently skipping a whole engine. Neutral-primitive voice pass, `AskUserQuestion` → "wizard tool", matching `runtime-adapters.md`'s primitive vocabulary. Phase 5 now offers a compressed clarify→implement→verify framing for genuinely substantive fixes (file split, N+1, layering surgery) instead of folding a real structural change into an inline propose-confirm, without calling sibling skills.
- **`skills/hackify/references/runtime-adapters.md`**, new **Host-interpreter dependencies** table documenting the two skills that ship an executable engine riding the `shell` primitive (`lawkeeper`'s `python3` scanner, `codewalk`'s `node` viewer/builder), each with its stated non-silent fallback. No runtime adapter can conjure a missing interpreter, so the dependency is named rather than papered over.
- **`README.md`**, version badge corrected (was stale at `0.3.3`; the `0.4.0` release shipped without bumping it) → `0.4.1`.

### Fixed

- **`scripts/validate-dod.d/00-helpers.sh` + `10-required-files.sh`**, the token-scrub and absolute-path checks now pass `-I` to `grep` so binary files are skipped. Running `skills/lawkeeper/scripts/test_audit.py` writes `__pycache__/*.pyc` bytecode whose embedded absolute source paths were counted by `grep -c` as personal-handle / leaked-path matches, a false positive that failed an otherwise-clean tree. Binary artifacts can no longer trip these checks.
- **`.gitignore`**, added `__pycache__/` and `*.pyc` so Python bytecode never enters the tracked working tree.

## [0.4.0] - 2026-06-09

> **Minor-level scope: new `lawkeeper` skill, full-codebase engineering-rules auditor.** The detect-and-fix counterpart to a setup harness: it reads the effective rule set from a project's own harness (`.claude/rules`, `ban-patterns.txt`, `CLAUDE.md`/`AGENTS.md`) with stricter-wins fallback to global doctrine, runs a bundled deterministic scanner plus a semantic subagent pass, reports every finding with `file:line` grouped by category/severity, then fixes them one at a time with approval. Mirrored to all full-mirror runtimes.

### Added

- **`skills/lawkeeper/`**, new skill. `SKILL.md` (6-phase workflow: resolve rule set → deterministic scan → semantic pass → report → propose-confirm remediation → verify), a bundled Python scanner under `scripts/` (`audit_scan.py` CLI + `lexer.py` string/comment masker + `checks.py` exact checks + `exemptions.py` carve-out matcher + `test_audit.py` with 23 unit tests), four `references/` (rule-catalog, carve-outs, semantic-pass, porting-scanner), `assets/report-template.md`, and `evals/evals.json` (happy-path + edge + non-trigger). Deterministic checks are exact and zero-false-positive: file-line cap; lint suppressions, non-null `!`, empty catch, bare `Error`, hardcoded secrets, inline types in scoped modules; `// removed:` markers and ownerless TODO/FIXME (comment-anchored so the word inside a string literal is not flagged). The semantic subagent pass covers DRY, layering, controller-purity, naming, SRP, folder-structure, security, performance, testing, full SOLID + YAGNI, and cross-file cleanup, reusing the project's installed `.claude/agents/` reviewers when present. TS/JS core with `--text-only-ext` for any file (file-cap + project bans on non-JS) and an ephemeral on-demand scanner for deep non-JS audits. Bundled-file references use the `<skill-dir>` convention (resolved from the `Base directory for this skill:` line), never a hardcoded user path; every bundled `*.md` is ≤ 500 LOC and the scripts hold to the same caps the skill enforces (≤ 500/file, ≤ 40/function, ≤ 3 params).
- **`MIRROR_SOURCES` entries for `skills/lawkeeper/`** (`scripts/sync-runtimes.d/00-helpers.sh`), all 12 canonical lawkeeper files explicitly enumerated so every full-mirror runtime carries the skill; `scripts/sync-runtimes.sh` mirrors them into `dist/{claude-code,codex-cli,codex-app,gemini-cli,opencode,cursor}/` (copilot-cli stays MANIFEST-only by design).

### Changed

- **`README.md`**, `lawkeeper` added to the plugin-primitives skill list, the per-skill blurb section, the command table, and the source-tree diagram.

## [0.3.3] - 2026-05-25

> **Patch-level scope: codewalk viewer follow-up, type-token hyperlinks, light-mode skipped-line legibility, clickable header breadcrumb.** Three additive fixes surfaced when actually using the v0.3.2 playbook end-to-end on a real 53-endpoint NestJS service. User-visible polish only; no schema change, no trace re-walk required.

### Added

- **`skills/codewalk/assets/viewer.js` `_byTypeName` index + `_linkTypeTokens()` Prism post-processor.** On every trace load, `_index()` now builds a PascalCase-name → node-id lookup over every node whose simple name (last `.` segment) matches `^[A-Z][A-Za-z0-9_$]*$`, preferring `layer: "type"` nodes when two layers share a name. `renderSource()` then wraps every Prism `class-name` token whose text matches a known node in a `.cw-call.cw-type-link` anchor, so a class/interface/type/DTO/Zod-schema identifier appearing anywhere in the source pane is now clickable and jumps to that node's viewer. Self-references (same node) and missing matches stay un-wrapped. Works alongside the existing line-level `call_sites[]` wrap; both can co-exist on the same line and the inner type-link wins on click (via `closest('[data-callee-id]')`).
- **`.cw-type-link` styling.** Dotted underline (vs the dashed underline used by the line-level `.cw-call`) so the user can distinguish "click this whole call-site line" from "click this one type identifier" at a glance. Color tracks Prism's `class-name` palette per theme.

### Changed

- **`skills/codewalk/assets/viewer.html` header breadcrumb is now interactive (since v0.3.3).** The previously-decorative `codewalk` span is a back-link to `../` (the playbook index), with a `← codewalk` label + hover affordance, so a user reading any per-trace viewer can one-click back to the catalog. The entry-point label (e.g., `GET /api/admin/products`) became a `<button>` that calls `select(data.nodes[0].id)` and jumps to the entry node, useful after the user has navigated several layers deep through call-site clicks and wants to reset to the root without using the Back arrow.
- **`skills/codewalk/assets/viewer.css` light-mode skipped-line styling.** The dark-mode rule applies `opacity: 0.32 + font-style: italic` to non-invoked lines; on a white background this rendered as faded grey-on-grey italic that the user reported as unreadable. Light mode now overrides with solid `color: #6b7280`, no opacity, no italic, and force-overrides every nested Prism token to the same grey via `body.cw-light .cw-line.cw-skipped .cw-line__code *`, so non-invoked branches stay legible without visually competing with the green-highlighted invoked block. The gutter line-numbers stay lighter (#c4c7cc) to preserve the invoked/skipped contrast in the gutter.

### Rationale

The v0.3.2 deep-trace mandate produced rich traces where every controller/service/repository/external boundary AND every type/interface/DTO referenced on the path emitted its own node, but the viewer only hyperlinked the FUNCTION nodes via line-level `call_sites[]` wraps. The TYPE nodes were reachable from the file tree but not from the source pane where the user actually reads them, a `ProductFilter` identifier in a method signature led nowhere. v0.3.3 closes that gap by hyperlinking at the Prism-token level so the type/class/DTO identifier the user sees in the source IS the click target. Two adjacent gaps surfaced the same session: the decorative `codewalk` breadcrumb suggested a back-link that wasn't there (the user expected to click it to return to the playbook), and the light-mode skipped-line styling was inherited from dark mode where italic+0.32-opacity is legible on `#0d0d0d` but unreadable on `#fbfbfd`. Patch-level (not minor) because every change is additive: existing v0.3.2 traces render correctly without re-walking, the breadcrumb still works without a parent playbook (404 on `../` is acceptable for one-off traces), and the dark theme styling is untouched.

## [0.3.2] - 2026-05-25

> **Patch-level scope: codewalk depth & types mandate, update-by-default, light theme by default, hackify finish hand-off.** Six additive changes to the codewalk + hackify skills, surfaced when re-running the v0.3.1 playbook against a real 53-endpoint NestJS API and finding: every trace stopped at the controller boundary (one node per slug); re-runs blind-overwrote existing files; the dark-by-default viewer didn't match the user's expectation that tooling demos open light. Backwards-compatible, single-entry and playbook traces written under v0.3.1 still load; users who prefer dark can `?theme=dark` or click the header ☾ toggle.

### Added

- **`skills/codewalk/SKILL.md` § "Depth & Completeness Mandate"**, new top-level section (between the intro and "When to invoke") that bans the failure modes the v0.3.1 audit surfaced: traces that stop at the controller, traces that gesture at "calls `service.foo`" without recursing into `foo`, type references that resolve to nothing because the type body wasn't emitted. Codifies a rough-size reference table (trivial endpoint 1-3 nodes / standard CRUD 5-10 / hot-path search 20-40 / heavy pipelines 30+) so the trace agent can self-correct when it shipped a 1-node trace for a 30-node endpoint. The 5-function depth-check pause is now explicitly **off** in playbook mode or whenever the user pre-approved depth with "all" / "every" / "deep" / "end to end" / "full" / "complete".
- **`skills/codewalk/references/data-schema.md` § "Type-definition nodes (`layer: "type"`)"**, new section documenting the sixth layer value. Type nodes share the same JSON shape as function nodes but with `invoked_lines: []`, `call_sites: []`, and `branches_not_taken: []`; they're reached via `call_sites` entries on function nodes whose `callee_id` points at the type node id, so the viewer renders the type name as a clickable cw-call span. The `layers` top-level object now requires a `type` key (array of type-node ids). The Mermaid sequence-diagram layer-name capitalization list grew to include `Type` (though type nodes generally don't appear as participants, they're referenced in message labels).
- **`skills/codewalk/assets/viewer.js` `layerClass(layer)` helper + type-aware tooltip preview.** Layer chips render in colored Tailwind pairs (`controller:sky`, `service:violet`, `repository:fuchsia`, `external:amber`, `type:emerald`, `other:neutral`) instead of the previous monochrome neutral chip. When hovering a call-site whose callee is `layer: "type"`, the tooltip body now shows the first ~6 lines of the type body alongside the docblock purpose, types ARE their declarations, so previewing them is the primary signal in the tooltip.

### Changed

- **`skills/codewalk/SKILL.md` Phase 3**, extended the node-field extraction order to include type/interface/Zod/DTO/entity emission; documented the rule that `call_sites` on function nodes must include both function-call callees AND type-reference callees so the viewer hyperlinks the type name in `data_in`/`data_out`/parameter signatures. The anti-rationalizations table grew three new rows banning shortcuts that surfaced in the audit: "Stopping at the controller is fine", "Tracing into the type definitions would bloat the trace", "I'll list `service.foo(...)` as a call_site but skip the node, they can grep".
- **`skills/codewalk/SKILL.md` Phase 4**, validation list now requires every `nodes[*].call_sites[*].callee_id` to resolve to a `nodes[].id` (no dangling links, the viewer logs a warning and renders the cw-call as un-clickable). Mentions that `layer: "type"` nodes are expected to carry `invoked_lines: []`.
- **`skills/codewalk/assets/index.html`**, the per-trace code-pane header now shows the layer-colored chip next to the function name (was: only in story-mode); the chip uses `layerClass(currentNode?.layer)` so dark + light themes pick up the right pair.
- **`skills/codewalk/assets/viewer.css`**, added per-layer light-mode color overrides (`bg-sky-900/40` → light sky, `text-violet-200` → deep violet, etc.) so layer chips stay legible on the white background. Dark palette unchanged.
- **`skills/codewalk/SKILL.md` frontmatter `description`**, workflow shape clause updated to mention "deep depth-first walk to leaves (controller → service → repository/external + every type/interface/DTO/Zod schema crossed on the path)"; locked-contract clause says "the trace is deep-by-default" + "include every type definition referenced on the path as a separate type-layer node" + "never collapse a sub-path because 'it's a service / repo / external client'".

### Added (continued)

- **`skills/codewalk/SKILL.md` "Locked Contract" callout at the top of the body.** Six numbered rules the trace agent reads before anything else: deep-by-default, types-as-nodes, no dangling links, update-existing-not-overwrite, light-mode default, stop-on-ambiguity. Plus a "your trace is REJECTED if …" acceptance checklist (1-node trace for non-trivial endpoint, dangling callee_id, missing type node for referenced shape, etc.). The callout exists so future trace agents can self-reject without the user catching the failure.
- **Phase 4 Step 4.0, "Update existing trace by default".** When `/codewalk` is re-invoked for an entry whose `.codewalk/<slug>/data.json` already exists, the skill loads the previous file, runs the fresh deep walk, preserves manual edits to `docblock.purpose` / `docblock.ownership` / `risk` / `branches_not_taken[].name` where `function_range` is unchanged, replaces the live fields (source / invoked_lines / call_sites / data_in / data_out / git_blame), sets `previous_generated_at`, and populates `diff_vs_previous` (added_nodes / removed_nodes / signature_drift / new_side_effects). The viewer's amber diff callout becomes the standard surfacing for re-traces. The user must type "regenerate" or "fresh" to opt INTO a blind overwrite.
- **`skills/codewalk/assets/build-playbook.mjs` idempotency guard.** The catalog-driven builder no longer clobbers existing rich `data.json` files (≥2 nodes) when running without a `_traces.json`. Previously a re-run of the builder would replace every walked trace with a 1-node stub, the v0.3.1 playbook rebuild lost ~800 nodes the first time we ran it after dispatching deep agents. Now the builder skips slugs whose `data.json` already carries ≥2 nodes and no fresh entry in `_traces.json` is present.
- **`skills/hackify/SKILL.md` + `references/finish.md` Step D.5. Codewalk follow-up at end of task.** When Phase 6 Finish archives a work-doc whose change-set touched an entry-point file (controller / CLI command / Inngest function / UI action / route handler, detected by file-pattern match against `*.controller.ts`, `*.cli.ts`, `inngest/*.ts`, `app/**/route.ts`, etc.), hackify asks the user via `AskUserQuestion` whether to update an existing `.codewalk/<slug>/` trace, create a new codewalk for the touched entry, or skip. On Update/Create, invokes `/codewalk <entry-point>` immediately. Skip silently when no entry-point files were touched.

### Changed (continued)

- **Viewer default theme flipped dark → light.** `viewer.js` now boots with `theme: 'light'`; the body class is preset to `cw-light`; `index.html` Mermaid init flips its `wantsDark` check accordingly. `localStorage["codewalk-theme"]` still persists user overrides. The header toggle still works, ☾ switches to dark. Existing v0.3.1 traces continue to honor a user's stored `codewalk-theme=dark` preference; new users see light first.

### Rationale

A user re-ran the v0.3.1 playbook against their 53-endpoint NestJS service and found that every slug's `data.json` had exactly 1 node, the controller method itself. The trace agent had treated "trace this endpoint" as "show me the entry point", not as "walk the full call stack". The schema permitted depth; the SKILL.md description didn't insist on it. v0.3.2 closes that gap by making depth-by-default + type-as-node a **non-negotiable** contract surface, with a sized expectation table the agent can self-check against. Two adjacent gaps surfaced in the same session: blindly overwriting an existing `data.json` on re-run destroyed manual edits and the diff signal, and the dark-by-default viewer didn't match user expectations for tooling demos; both got their own additive fix. Hackify's Phase 6 Finish now closes the loop by asking, after every shipped task that touches an entry-point file, whether to update the corresponding codewalk trace, turning the codewalk catalog from a one-time artifact into a continuously-refreshed team mental model. Patch-level (not minor) because every change is additive: existing 1-node v0.3.1 traces still load, the viewer is still functional without `layer: "type"` nodes, and a stored dark-theme preference is honored.

## [0.3.1] - 2026-05-25

> **Patch-level scope: codewalk skill upgrades.** Three additive changes to the `/codewalk` skill, surfaced after dog-fooding it against a real 53-endpoint NestJS API. All changes are backwards-compatible, existing `.codewalk/<slug>/` traces keep working; the dark theme stays the default. No changes to other skills, hooks, validators, hard-caps, agents, or rules. Bumping minor isn't warranted, the contract grows, no surface narrows.

### Added

- **`skills/codewalk/assets/playbook.html` + `playbook.js` + `playbook.css`**, new playbook mode for multi-entry codewalks. Light-mode-first index page that lists every traced entry in a service, grouped by domain, with a live filter input, method-color chips (`GET`/`POST`/`PATCH`/`PUT`/`DELETE`/`SSE`/`CLI`/`JOB`/`UI`), and a one-click theme toggle. Each row links into its sibling slug folder's per-trace viewer in a new tab, propagating the theme via `?theme=light|dark` so the viewer opens in the same mode. Catalog-driven: reads `.codewalk/_catalog.json` at runtime.
- **`skills/codewalk/assets/build-playbook.mjs`**, new catalog-driven builder. Reads `.codewalk/_catalog.json` (and optional `_traces.json`), copies the playbook + per-trace viewer assets to disk, and writes one `<slug>/data.json` per catalog entry. When `_traces.json` carries a rich entry for a slug, that entry's nodes/edges populate the per-trace viewer directly; otherwise the slug gets a stub `data.json` that the user can deepen later with `/codewalk <entry>`. Single file, 198 LOC, under the cap.
- **Light-mode viewer support in `assets/viewer.css`, `assets/viewer.js`, `assets/index.html`.** Toggle in the per-trace viewer header (☀/☾). Theme precedence: URL `?theme=light|dark` → `localStorage["codewalk-theme"]` → default `dark`. Persistent across reloads via `localStorage`. Prism stylesheet (`#cw-prism-css`) and Mermaid (`theme: 'default'` vs `'dark'`) swap in lockstep. Dark mode stays the default, no behavior change for users who don't touch the toggle.
- **`skills/codewalk/references/data-schema.md` § "Playbook mode, multi-entry catalog"**, documents the new `_catalog.json` and optional `_traces.json` formats with field-by-field schemas, slug rules, color palette, and builder invocation. Legacy `endpoints` is accepted as an alias for `entries` in the catalog.
- **`skills/codewalk/SKILL.md` § "Playbook mode, multi-entry codewalks"**, full workflow shape (Phase 1' → 7'), the "single-entry vs playbook" decision table, file-map update with the four new asset files, and the rule that playbook mode only fires on explicit triggers ("all endpoints", "every endpoint", "index playbook", "browse all routes"). Single-entry mode remains the default.

### Changed

- **`skills/codewalk/assets/viewer.js` HTML entity decode in `renderSource`.** Source strings authored by sub-agents and round-tripped through JSON often carry `&lt;`, `&gt;`, `&amp;`, `&quot;`, `&#39;` instead of their literal characters (typically when the agent inlined TypeScript generics or JSX in a JSON code block). Previously these reached Prism un-decoded and rendered as visible entity text in the viewer's source pane. A new `decodeEntities()` helper runs before Prism highlighting; safe because the source is rendered, not executed.
- **`skills/codewalk/assets/viewer.js` dangling-`callee_id` guard in `renderSource`.** Call sites whose `callee_id` doesn't resolve to a node in `data.json` now render as plain text instead of a broken-link `cw-call` span. The console-warning in `_index` (pointing the trace author at the missing node) is unchanged. Fixes a viewer dead-click on stub data.json files where the controller references a service that isn't yet walked.
- **`skills/codewalk/assets/index.html` Prism stylesheet now has `id="cw-prism-css"`** so the viewer can swap dark→light at runtime. Mermaid initialization now reads the same theme signal at boot (URL param OR localStorage) so the first render lands in the correct theme without a flash.

### Rationale

Three improvements surfaced in one session of dog-fooding `/codewalk` against a NestJS API with 53 endpoints. The playbook mode + builder are the headline, single-entry codewalks scale poorly past ~10 entries because there's no top-level index to navigate from, and operators were stitching their own index together by hand. The light-mode + entity-decode + dangling-callee fixes are smaller-surface but all came from the same session, so they ship together rather than spread across three patch releases. Patch-level (not minor) because every change is additive: dark mode is still default, the schema is opt-in (only fires when the user authors a `_catalog.json`), and existing `.codewalk/<slug>/` folders keep loading exactly as before.

## [0.3.0] - 2026-05-22

> **Minor-level scope.** Six plugin enhancements ship together: file-size cap validator, sync-runtimes prune-on-mirror with modular per-runtime emitters, two-channel marketplace (`hackify` stable tag + `hackify-edge` main), `scripts/release.sh` tag-on-version-bump helper, sibling-plugin collision-detection script wired as a soft warning, eval coverage for the six non-hackify skills, and a README version-label drift sweep. Closes six known gaps in one release. Tagged via the new `scripts/release.sh`, eating own dog food.

### Added

- **`scripts/validate-dod.d/80-file-size-caps.sh`**, new validator module that enforces the project-agnostic ≤500 LOC hard cap across `skills/`, `agents/`, `rules/`, `scripts/`, `hooks/`, `commands/` for every `*.md`, `*.sh`, `*.json` file. Closes the v0.2.7-retrospective gap where the rules said one thing (≤500 LOC) and the validator enforced another (nothing). The check fails red on any over-cap file; the orchestrator at `scripts/sync-runtimes.sh` was split first to pass its own check (was 528 LOC; now 94 LOC orchestrator + 7 per-runtime emitters of 35-68 LOC each + 199 LOC shared helpers, all under cap).
- **`scripts/validate-dod.d/90-collisions.sh`**, new validator module (soft warning, never fails) that invokes `scripts/check-collisions.sh` and reports any sibling-plugin slug substring overlaps as yellow `WARN` lines. Soft on purpose: a hostile or unrelated sibling plugin must never break our CI.
- **`scripts/check-collisions.sh`**, new standalone script that scans installed Claude Code plugins under `~/.claude/plugins/cache/` (overridable via `CLAUDE_PLUGINS_ROOT` env var), extracts every `name:` frontmatter value from sibling `SKILL.md` files, and reports `EXACT MATCH` / `SUBSTRING OVERLAP` / `OK` per hackify slug. Handles four empty-state branches gracefully (missing plugins root, empty cache, zero SKILL.md, malformed frontmatter), always exits 0.
- **`scripts/release.sh`**, new tag-on-version-bump helper. Reads `version` from `.claude-plugin/plugin.json` (prefers `jq`, falls back to `grep`), refuses on dirty working tree, refuses if tag `v<version>` already exists locally OR on origin, refuses on missing/empty `version` field, creates annotated tag at HEAD with message `Release v<version>`, prompts before pushing main + tag. Supports `--dry-run` to print planned commands without executing. On push failure: leaves the local tag in place and prints a `git tag -d` rollback hint.
- **`scripts/sync-runtimes.d/`**, new directory holding the per-runtime emitter modules + shared helpers. `00-helpers.sh` (199 LOC) exports `MIRROR_SOURCES`, `CLAUDE_CODE_EXTRA`, `RUNTIMES`, plus the helper surface (`red`/`green`/`yellow`, `write_or_announce_copy`, `write_or_announce_heredoc`, `mirror_canonical_files`, `prune_runtime_dist`, `print_runtime_summary`). Seven per-runtime modules (`claude-code.sh`, `codex-cli.sh`, `codex-app.sh`, `gemini-cli.sh`, `opencode.sh`, `cursor.sh`, `copilot-cli.sh`) each define an `emit_<runtime>` function with only runtime-specific install-notes prose, no duplicated mirror/prune/summary logic.
- **`skills/groom/evals/evals.json`, `skills/skillsmith/evals/evals.json`, `skills/review-triage/evals/evals.json`, `skills/codewalk/evals/evals.json`, `skills/yolo/evals/evals.json`, `skills/quick/evals/evals.json`**, eval coverage for the six non-hackify skills. Each file follows the exact schema of `skills/hackify/evals/evals.json` (`skill_name` + `evals[]` with `{id, name, prompt, assertions[].text, files}`). Three cases per skill: happy-path trigger, edge trigger, explicit non-trigger (proving the auto-discovery boundary).

### Changed

- **`scripts/sync-runtimes.sh` split into orchestrator + per-runtime modules.** Was a 528-LOC monolith (over the cap). Now a 94-LOC orchestrator that sources `scripts/sync-runtimes.d/00-helpers.sh` + the seven per-runtime emitter modules and dispatches each. Behavior is identical: 270 files mirrored across 7 runtimes; idempotent on second run; `--dry-run` flag preserved. Spot-checked byte-for-byte against the pre-split tree.
- **`scripts/sync-runtimes.sh` now prunes `dist/<runtime>/skills/` before each mirror** via `prune_runtime_dist` called at the start of every per-runtime emitter. Renaming or removing a source skill no longer leaves stale destination directories, the v0.2.9 rename surfaced this when 18 leftover dirs from old slugs (`brainstorm`, `writing-skills`, `receiving-code-review`) needed manual cleanup. With prune-on-mirror, that's gone for good.
- **`.claude-plugin/marketplace.json` rewritten as two channels.** Entry one (`hackify`) pins `ref: v0.3.0`, the stable tagged release recommended for production users. Entry two (`hackify-edge`) keeps `ref: main`, bleeding-edge, for early adopters who want to test pre-release features. Both reference the same source URL. Tag-on-version-bump discipline (via `scripts/release.sh`) keeps the stable channel current.
- **`README.md` version-label drift sweep.** Eight in-prose `(v0.2.2)` / `v0.2.0 ships` / `(v0.2.0) sprint vocabulary` / `v0.2.2 \`UserPromptSubmit\` hook` labels reframed to `(since vX.Y.Z)` framing, preserves introduction-version provenance without implying current-version. Current-version surface is now limited to the version badge, the Install snippet, and the `plugin.json` link.

### Rationale

Six distinct gaps shipped together because each had a small surface and they share a verify-and-tag cycle. The file-size cap had been a v0.2.7 retrospective follow-up; without it the cap doctrine was advisory-only. The sync-runtimes prune-on-mirror was a v0.2.9 retrospective follow-up; without it every source-side rename leaked stale dirs that local-dev installs would ship to consumers. The marketplace tag-pin was a v0.2.8 gap surfaced when consumers asked how to pin to a release, `ref: main` was always bleeding-edge with no opt-out. The collision-detection script was the natural complement to the v0.2.9 rename, proving the rename worked AND giving consumers a tool to spot future collisions. Evals for the six non-hackify skills filled a measurement hole, only `hackify` itself had eval coverage before this release. The README label sweep ended the long-running pattern of `(v0.2.2)` reading like "current version 0.2.2" to casual readers. `scripts/release.sh` makes the tag-on-version-bump discipline executable rather than a doc-only checklist, and v0.3.0 itself was tagged with it, dog-fooding the new tool.

## [0.2.9] - 2026-05-22

> **Companion-skill rename pass.** Three companion skills are renamed to avoid auto-discovery substring collisions with the Anthropic Superpowers plugin and other third-party skill packs that ship near-identical slugs. No behavior change to any skill, workflow phase, sub-agent contract, hard-cap, hook wiring, or DoD-validator check, only the slugs, their directory paths, and every cross-reference to them moved. `codewalk` is unchanged (already hackify-distinctive).

### Changed

- **`skills/brainstorm/` → `skills/groom/`** (Socratic pre-task refinement). Frontmatter `name:` updated, `# Brainstorm` heading rewritten to `# Groom`, `Brainstorm Provenance` work-doc block renamed to `Groom Provenance`, slash trigger `/brainstorm` → `/hackify:groom`. Auto-discovery trigger list drops the bare `brainstorm` substring and adopts `groom` (sprint-vocab fit alongside the existing `Sprint Backlog` / `Daily Updates` / `Sprint Review` labels in work-docs).
- **`skills/writing-skills/` → `skills/skillsmith/`** (meta-skill that authors hackify-conformant skills). Frontmatter `name:` updated, `# Writing-Skills` heading rewritten to `# Skillsmith`, slash trigger `/writing-skills` → `/hackify:skillsmith`. Bare `writing-skills` substring dropped from auto-discovery.
- **`skills/receiving-code-review/` → `skills/review-triage/`** (per-finding reviewer-response decision table). Frontmatter `name:` updated, `# Receiving-Code-Review` heading rewritten to `# Review-Triage`, slash trigger `/receiving-code-review` → `/hackify:review-triage`. Bare `receiving-code-review` substring dropped from auto-discovery.
- **Cascading cross-reference updates across active files**, `README.md` (Companion-skills bullets, Slash-commands table, Repository layout, Plugin-primitives skill list), `scripts/sync-runtimes.sh` (`MIRROR_SOURCES` array + 6 install-note paragraphs), `scripts/validate-dod.d/50-runtimes-and-companions.sh` (`NEW_SKILL_FILES` + `NEW_SKILL_SLUGS`), and `hooks/inject-hard-caps.sh` (one comment line). The legacy-pattern phrase `plan/spec/brainstorm/execute/verify/review/finish ceremony` in `skills/hackify/SKILL.md` is intentionally preserved, it names the historical multi-skill pattern hackify replaces, not our renamed skill.

### Rationale

The `brainstorm`, `writing-skills`, and `receiving-code-review` slugs were generic enough to substring-collide with Anthropic's Superpowers plugin and other third-party skill packs. When two plugins offer auto-discovery-triggered skills with overlapping substrings, the harness has no deterministic tiebreaker, invocation depends on plugin load order or description-field ranking, neither of which is portable across runtimes. The rename moves all three to hackify-distinctive slugs that signal craft (`skillsmith`), sprint vocabulary (`groom`, `review-triage`), and consequently de-collide with any plugin's generic naming. Archived work-docs under `docs/work/done/` and pre-v0.2.9 CHANGELOG entries retain the original names verbatim, they are a frozen historical record and re-writing them would violate the work-doc immutability convention.

## [0.2.8] - 2026-05-22

> **New companion skill: `codewalk`.** Interactive call-stack viewer for code you didn't write, a senior-peer walkthrough of one execution path from a single entry point (route, handler, CLI command, queue job, UI action), rendered as a GitHub-PR-style three-pane app under `.codewalk/<slug>/` in the target repo. Bundled viewer assets (Tailwind + Alpine + Prism + Mermaid via CDN) plus a Node-stdlib server with a cross-platform fallback chain. No behavior change to any existing skill or workflow phase.

### Added

- **`skills/codewalk/SKILL.md`**, new top-level companion skill. Phase 1-7 workflow (confirm entry → read repo conventions → depth-first walk → emit `data.json` → materialize viewer by copying assets → launch `node serve.js` → 5 comprehension questions + decisions checklist). Mandatory 5-function depth-check block printed to chat. Auto-discovery triggers: `/codewalk`, `walk this code`, `walk me through`, `trace this call stack`, `trace this flow`, `explain this flow`, `what happens when`, `onboard me to`, plus six more substring matches. On ambiguity (env flags, feature gates, tenant guards, DI tokens, dynamic dispatch) the skill STOPS and asks rather than guessing the runtime path. Self-contained, never calls other skills.
- **`skills/codewalk/references/data-schema.md`**, exact JSON contract between trace and viewer (nodes, edges, layers, diagrams, deferred_branches, diff_vs_previous). Slug convention is documented per entry-point shape: HTTP routes → `<method-lowercase>-<path-sanitized>`, CLI commands → `cli-<sanitized>`, queue jobs → `job-<queue>-<job-name>`, UI actions → `ui-<component>-<action>`.
- **`skills/codewalk/references/trace-rubric.md`**, how to walk the stack with rigor. Covers invoked-block identification (the hardest field, only lines that fire on this path), side-effect classification (`db` / `queue` / `http` / `cache` / `auth` / `fs`), picking the one risk per node, branches-not-taken listed by name and never expanded, and the procedural format for the depth-check block.
- **`skills/codewalk/assets/{index.html, viewer.js, viewer.css, serve.js}`**, bundled viewer template copied per trace into `.codewalk/<slug>/`. Three-pane layout (file tree by visit order with function-count badges / code viewer with green-border invoked lines + dimmed-italic skipped lines + clickable call-site anchors + hover docblock tooltip / right-rail metadata pane). Diagrams tab renders a Mermaid sequence diagram by architectural layer, module-dependency map, data-shape evolution chain, invariants per boundary, failure modes with blast radius, deferred branches, and an amber diff banner when `data.json` re-trace differs from the prior run. `serve.js` picks a free port starting at 8765 using only Node stdlib, opens the default browser cross-platform; fallback chain to `python3 -m http.server`, `python -m http.server`, `npx serve`, `php -S`, `ruby httpd` is documented when Node is missing.

### Changed

- **`README.md`**, version badge synced to `0.2.8`. "Plugin primitives" sentence and "Companion skills" section now enumerate `codewalk`. Companion-skills heading no longer carries the `(v0.2.0)` suffix since the section now spans v0.2.0, v0.2.8 introductions. Slash-commands table gains a `/codewalk` row. Repository-layout block adds `skills/codewalk/` with its `references/` and `assets/` children. FAQ gains a codewalk entry (offline behavior + repo-source isolation). Troubleshooting table gains three codewalk-specific rows (Node missing → fallback chain, viewer doesn't open → copy URL manually, port range exhausted → kill range or edit `START_PORT`).

### Fixed

- **`README.md`**, pre-existing v0.2.4 oversights swept up while integrating codewalk: `skills/yolo/` is now listed in the repository-layout block, the "Plugin primitives" sentence now enumerates `yolo`, and the line `Both skills auto-trigger from natural-language prompts` now reads `All three skills auto-trigger from natural-language prompts` (the table above had grown from two to three flows when yolo shipped). Overview paragraph now mentions `/hackify:yolo` alongside `/hackify:quick` instead of introducing yolo cold further down the page.

## [0.2.7] - 2026-05-21

> **Patch-level scope, patch-level label.** Two oversized reference files split into per-topic subdirs, all cross-references migrated, and Phase 6 gains a mandatory pre-archive cleanup sweep. No phase, wizard, sub-agent contract, hard-cap, hook-wiring, or DoD-validator behavior change, the substrate stays identical; only file layout and one new Phase 6 step move.

### Changed

- **`skills/hackify/references/parallel-agents.md` (1783 LOC) split into 12 files under `skills/hackify/references/parallel-agents/`.** Each sub-topic (orchestration, dispatch model, file allowlists, wave structure, sub-agent contract, review parallelism, failure handling, etc.) becomes its own file under the new subdir. The old monolithic file is deleted with no forwarding stub, consumers update their cross-refs to the new paths.
- **`skills/hackify/references/clarify-questions.md` (639 LOC) split into 10 files under `skills/hackify/references/clarify-questions/`.** Same pattern: each question category becomes its own file under the new subdir, monolithic file deleted with no forwarding stub.
- **11 cross-references migrated** across consuming files (skills, agents, validator modules) to point at the new subdir paths; 1 fix-up applied to `agents/spec-reviewer-dependencies.md`. No reader follows a broken link after the split.
- **`scripts/sync-runtimes.sh`**, `MIRROR_SOURCES` extended with 22 new entries (12 + 10) covering every file under the two new subdirs. New ATTENTION-future-maintainers header comment explains that `MIRROR_SOURCES` is enumerated (not glob-discovered) so future file additions must be appended explicitly. Idempotent regen now mirrors 270 files across 7 runtimes (was 150).
- **`scripts/validate-dod.d/20-templates.sh`**, checks `[9]`, `[13]`, and `[14]` rewired to iterate the new `parallel-agents/` and `clarify-questions/` subdirs instead of grepping the deleted monolithic files. Same assertions, new traversal target.

### Added

- **Phase 6 cleanup step (Step C.5), new mandatory pre-archive sweep.** Covers 8 cleanup classes before the work-doc is archived: stale cross-refs, broken anchors, TODO without owner, empty directories, dead branches, scope creep, surfaced dead code, and work-doc path drift. Applied to this very sprint's Phase 6 as proof-of-concept; the sweep is now part of every future task's Phase 6.

### Rationale

`parallel-agents.md` and `clarify-questions.md` had grown past the 500 LOC hard cap, with `parallel-agents.md` at 3.5× the cap and `clarify-questions.md` at 1.3×. Both files mixed many sub-topics that readers consult independently, so the natural split was per-topic subdirs rather than arbitrary line-count chunks. Behavioral guarantees preserved, 7-section sub-agent contract, 4-section wizard contract, lint-suppression carve-out tokens, hook wiring, hard caps, all unchanged. The Phase 6 cleanup step closes a recurring failure mode where finished sprints left stale cross-refs, empty dirs, or surfaced dead code in the tree because the finisher had no checklist to sweep against.

## [0.2.6] - 2026-05-21

> **Patch-level scope, patch-level label.** Tech-neutral rewrite plus four-principles integration. No phase, wizard, sub-agent contract, hard-cap, hook-wiring, or DoD-validator behavior change, the substrate stays identical; the prose substrate becomes runtime-agnostic and the doctrinal core becomes explicit.

### Added

- **`rules/four-principles.md`**, new canonical always-on rules file enumerating the four principles that gate every substantive turn: **Think Before Coding**, **Simplicity First**, **Surgical Changes**, **Goal-Driven Execution**. Attributed to Andrej Karpathy's framing. Sits alongside `rules/hard-caps.md` and `rules/code-quality.md` as the third always-on engineering law; the hard caps and code-quality rules operationalize these four principles, and the workflow phases enforce them. Canonical home, other files link here rather than restating the principle bodies.
- **`skills/hackify/references/anti-patterns.md`**, new polyglot reference with at least six wrong-vs-right worked examples covering the failure modes the four principles guard against (assumption-skipping, speculative abstraction, scope creep, drive-by edits, premature optimization, hidden coupling). Each example is paired so reviewers can cite a concrete contrast when flagging a finding.
- **Work-doc per-task `→ verify: <check>` suffix.** `references/work-doc-template.md` Sprint Backlog rows gain a SHOULD-suffixed `→ verify: <check>` clause so each task carries its own acceptance signal inline, the Phase 4 verifier reads the suffix rather than reverse-engineering intent from the task body.

### Changed

- **Pure-abstract neutralization pass across `rules/`, `agents/`, `skills/`, and `README.md`.** Ecosystem brand names stripped from prose in favor of role nouns, `linter`, `test runner`, `package manager`, `type checker`, `formatter`. The lint-suppression scan-target tokens carved out, those literal directive strings stay as-is because the rule that bans them must name them. `CHANGELOG.md` historical entries also carved out, prior versions retain their original wording.
- **Behavioral guarantees preserved.** Phase structure, the Wizard contract, the 7-section sub-agent contract, the hard caps (40 LOC / 3 params / 3 nesting / 500 LOC), hook wiring (`UserPromptSubmit` injects `rules/hard-caps.md`), and the DoD validator's check set all unchanged. Reviewers verifying upgrades read the same surface they read on `0.2.5`; only the prose substrate moved.
- **`scripts/sync-runtimes.sh` `MIRROR_SOURCES` extended** with the two new canonical files (`rules/four-principles.md` + `skills/hackify/references/anti-patterns.md`) so all seven runtime distributions under `dist/<runtime>/` ship them. Direct corollary of the two new files above; idempotent regen confirmed at 150 files across the 7 runtime targets.

### Rationale

The v0.2.5 surface had two latent fragilities. First, the prose hard-coded a single runtime's tool names in places where role nouns would have done the same job, every new runtime adapter inherited that drift and had to be re-scrubbed. Second, the doctrinal core of hackify ("think before you code, ship the minimum, change only what was asked, drive every line to the stated goal") lived implicitly across `skills/hackify/SKILL.md`, `rules/code-quality.md`, and the reviewer prompts, with no canonical home. v0.2.6 promotes that doctrine to `rules/four-principles.md` so it can be cited, audited, and extended in one place, and finishes the runtime-agnostic prose pass so the substrate is portable to any AI coding tool that honors the four primitives.

## [0.2.5] - 2026-05-16

> **Patch-level scope, patch-level label.** Closes two v0.2.4 retrospective follow-ups in one commit. No behavior change to any skill or workflow phase.

### Added

- **`scripts/gen-demo-gif.py`**, new Python+Pillow generator for the README hero GIF. Renders a 1200×675, 7-frame, 600 ms/frame animation showing the 6-phase pipeline (1 Clarify → 2 Plan → 3 Implement → 4 Verify → 5 Review → 6 Finish) with sequential phase highlight. Requires Pillow (`pip install Pillow>=10`). Run with `python3 scripts/gen-demo-gif.py [output_path]`, defaults to `docs/assets/hackify-demo.gif`. Solves the "no source committed" problem the v0.2.1 → v0.2.4 GIF transition hit.
- **`scripts/validate-dod.d/*.sh`**, 8 new modules (`00-helpers.sh`, `10-required-files.sh`, `20-templates.sh`, `30-version-and-summary.sh`, `40-quick-skill.sh`, `50-runtimes-and-companions.sh`, `60-primitives.sh`, `70-invariants-and-new.sh`) sourced in order by the orchestrator. Each module is well under the 500 LOC hard cap; `00-helpers.sh` exports all shared color printers + `check_*` helpers used by the 34 check groups distributed across the 7 check modules.

### Changed

- **`docs/assets/hackify-demo.gif`**, regenerated. The title label is now just `Hackify` (the explicit `v0.2.1` version overlay is removed) so future version bumps no longer require a GIF refresh unless phases or install commands change.
- **`scripts/validate-dod.sh`**, rewritten as a thin orchestrator (≤60 LOC, was 723 LOC). Responsibilities reduced to: define `REPO_ROOT` / `FAILED` / `DOD_MODULES_DIR`, `cd` to repo root, explicitly `source` each of the 8 `scripts/validate-dod.d/*.sh` modules in lexicographic order, print the final summary line. No `shellcheck disable` directives, modules are sourced by explicit path, not by glob.

### Rationale

The v0.2.4 retrospective surfaced two follow-ups: refresh the README hero GIF (drifted to a stale `v0.2.1` label) and split `scripts/validate-dod.sh` past the 500 LOC hard cap. Both ship here as pure housekeeping in one commit, no skill content changes, no plugin contract changes, no auto-discovery behavior changes. The GIF now has a committed source script, so future regenerations are reproducible; the validate-dod script no longer violates its own hard cap.

## [0.2.4] - 2026-05-16

> **Patch-level scope, patch-level label.** Adds a new sibling skill `/hackify:yolo` (full-autopilot mode) and a one-sentence exploration nudge to quick mode. No phase change to full or quick.

### Added

- **`skills/yolo/SKILL.md`**, new full-autopilot sibling skill. Same workflow phases as `/hackify:hackify` (Clarify with exploration, in-chat Plan, Spec-review, parallel Implement, Verify, Multi-reviewer, Finish) but two gates auto-pass: Phase 2 plan sign-off and Phase 6 4-options finish menu. The in-chat plan block (assistant message) replaces the on-disk work-doc as the Phase 2.5 / Phase 5 reviewer audit subject. Phase 5 multi-reviewer findings auto-fix in-place at every severity (Critical AND Important); Minor findings logged to chat (no Retrospective doc exists). Phase 6 default is commit to current branch locally, no push, user inspects with `git log -1` / `git diff HEAD~1` afterward. Auto-discovery triggers include `/hackify:yolo`, `yolo`, `just do it`, `don't ask me` and 7 other autonomy phrases, the canonical list lives in `skills/yolo/SKILL.md` frontmatter. No work-doc → no pause/resume across sessions.
- **`scripts/sync-runtimes.sh`**, `MIRROR_SOURCES` array gains the entry `"skills/yolo/SKILL.md"` so the new skill mirrors into all 7 runtime distributions.
- **`scripts/validate-dod.sh`**, two new check groups. Check `[34]` validates `skills/yolo/SKILL.md` exists, has `name: yolo` frontmatter matching the slug regex, has `description:` frontmatter, and the body contains the 10 required tokens (`Phase 1`, `Phase 2.5`, `Phase 3`, `Phase 4`, `Phase 5`, `Phase 6`, `in-chat plan`, `auto-pass`, `commit to current branch locally`, `no work-doc`). Check `[35]` validates `skills/quick/SKILL.md` contains the verbatim string `read it end-to-end before judging ambiguity`. A new positive-match helper `check_token_present` (mirror of the existing `check_no_token` shape) is added and reused by both check groups.

### Changed

- **`skills/quick/SKILL.md`**, the Phase 1 row in the "Kept phases" table gains a bolded sentence: `**If the ask names a file or symbol but not a fix, read it end-to-end before judging ambiguity.**` No other change to quick mode.
- **`skills/hackify/SKILL.md`**, the "When to invoke" section gains a new bullet introducing YOLO as the full-autopilot alternative alongside the existing Compressed-flow alternative.
- **`README.md`**, hero callout "Two flows, one discipline" rewritten to "Three flows, one discipline"; the flow comparison table gains a `Hackify YOLO` row between the existing Full and Quick rows; a new `### YOLO mode` subsection describes when to use YOLO and the no-work-doc trade-off; the slash-command reference table gains a `/hackify:yolo <ask>` row.

### Rationale

Full hackify and quick mode together left a middle-ground gap: substantive tasks where the user trusts the pipeline and doesn't want to gate on plan sign-off or the finish menu, but still wants spec-review, parallel implementation, and multi-reviewer rigor. YOLO fills it. The auto-fix-Critical contract is deliberate, the user opted into autopilot; surfacing findings mid-flow would defeat the purpose. The "When NOT to use YOLO" table flags auth/crypto/migration/secret as the load-bearing carve-out where auto-fix is risky. The quick-mode exploration nudge is unrelated and small: it tells the AI to read a named file end-to-end before judging ambiguity, addressing a quiet failure mode where the AI guessed at intent instead of consulting the file the user named.

## [0.2.3] - 2026-05-16

> **Patch-level scope, patch-level label.** Quick mode is now user-locked. Workflow phases are unchanged; only one runtime contract, auto-fallback, is removed.

### Changed

- **`skills/quick/SKILL.md`**, quick mode is now user-locked. Once `/hackify:quick` is invoked (explicitly or via auto-discovery), it stays in quick mode for the entire task. Promotion to full hackify requires an explicit user phrase: `switch to full`, `go to full mode`, `promote to full`, `/hackify:hackify`, `do full review`, `run Phase 5`, or `run multi-reviewer` (case-insensitive, scanned in the most recent user message only). The promotion procedure (write work-doc from accumulated context, hand off to full hackify Phase 2, preserve intent + partial diff in Daily Updates) is preserved verbatim under the new section heading "Promotion to full hackify (user-initiated only)", only the trigger surface changes from automatic to manual.
- **`skills/quick/SKILL.md`** frontmatter description, the "Falls back to full hackify automatically on any of 4 testable signals" sentence replaced with a "User-locked mode" sentence stating quick mode stays in quick mode until the user explicitly promotes; also documents non-resumability (no work-doc → no pause/resume across sessions). The auto-discovery routing guidance ("Do NOT auto-fire on cross-file refactors, redesigns, debug…") is preserved, it controls which skill the harness picks when no slash command is typed, not the runtime fallback contract.
- **`skills/hackify/SKILL.md`** line 17, the cross-reference to quick mode's fallback signals replaced with `stays in quick mode until you explicitly switch to full hackify`.
- **`README.md`** lines 28 and 95-104, fallback-trigger paragraph and 4-row trigger list replaced with a "User-initiated promotion to full hackify" subsection listing the explicit promotion phrases.

### Removed

- **Four auto-fallback signals from `/hackify:quick`**, (a) implementation-attempt counter reaching 2, (b) `(git diff --name-only HEAD; git ls-files --others --exclude-standard) | sort -u | wc -l > 3`, (c) `grep -iE 'auth|crypto|migration|secret|token|password'` against touched paths, (d) most-recent-user-message scan for `Phase 5` / `multi-reviewer` / `do full review`. Triggers (a), (c) are removed entirely; (d) is preserved as an explicit user-initiated promotion phrase, no longer described as a fallback.
- **Scratch `.quick-<slug>.md` attempt-counter file**, no longer created; the attempt counter is gone.
- **Anti-rationalization rows** in `skills/quick/SKILL.md` that referenced fallback triggers ("It's only one file, no need to check the diff scope" / "Attempt 2 failed but I have a great idea for attempt 3" / "The diff touches an `auth_helper.ts` file but it is just a comment edit"), removed; one replacement row added stating quick mode never auto-promotes.

### Rationale

The 4-signal auto-fallback was intended as a safety net but conflicted with user-stated intent: when a user explicitly invokes `/hackify:quick`, they have opted into a single-session, no-work-doc, no-resume flow and expect the AI to comply for the duration of the task. Silently switching modes mid-task violated that contract. The carve-out routing list in the skill description (which steers auto-discovery toward full hackify for cross-file refactors / redesigns / auth-crypto-migration work) remains the safety net at the routing layer, before quick mode is ever invoked.

## [0.2.2] - 2026-05-14

> **Patch label, refactor + additive scope.** Removes the prompt-based smart router that picked between full hackify, quick, and brainstorm, routing is now handled entirely by each skill's frontmatter `description` field via the harness's native auto-discovery. In its place, hackify graduates to a four-primitive plugin layout: `skills/` (workflows), `rules/` (always-on engineering law), `agents/` (formal sub-agent definitions), `hooks/` (UserPromptSubmit reminders). Each primitive owns the concern it is best at, and ONLY that concern. The hook is explicitly NON-routing: it injects `rules/hard-caps.md` into context every prompt, never classifies full vs quick from prompt content. Moving the classifier into the hook would just relocate the problem; this release deletes the classifier instead.

### Why

The v0.2.1 smart-router classifier was a custom prompt-content matcher embedded in two SKILL files plus a shared reference. Claude Code already does this work natively via skill `description` auto-discovery. The router added a second classifier on top of the native one, doubling the surface area, requiring its own validator check, and creating an ongoing maintenance contract between three files. v0.2.2 deletes the router, sharpens the three SKILL descriptions to do the same job through harness-native means, and uses the recovered conceptual space to ship the three plugin primitives that were always implicit in hackify's design.

### Changed (Smart router removed)

- **`skills/hackify/references/smart-router.md`**, **deleted.** The canonical classifier file from v0.2.1 is gone. Routing is now description-based.
- **`skills/hackify/SKILL.md`**, `## Pre-flight: smart router — pick the right flow` stub block removed.
- **`skills/quick/SKILL.md`**, same stub block removed.
- **`skills/brainstorm/SKILL.md`**, `## When to invoke` section cross-reference paragraph to the smart router removed; `## File map` reference rewritten to point at description-based routing.
- **`README.md`**, "Smart router (v0.2.1)" paragraph removed; replaced with a "Plugin primitives (v0.2.2)" paragraph that lists `skills/ rules/ agents/ hooks/ commands/` and their respective concerns.
- **`scripts/validate-dod.sh`**, check `[27]` (smart-router cross-reference) deleted in W1; a new check `[33]` (router-excision invariant) added at the tail of the script to assert the file stays deleted and neither SKILL re-introduces a link to it.

### Added (Plugin primitives at the repo root)

- **`rules/hard-caps.md`**, new short always-on engineering law (~40 lines). Function/file/param/nesting caps, lint-suppression ban, no-`!` rule, no-empty-catch rule, named-types rule, single-responsibility, refuse-on-sight anti-patterns. Injected into every prompt by the new UserPromptSubmit hook so the hard caps are always loaded.
- **`rules/code-quality.md`**, relocated canonical content of the deeper SOLID / DRY / types / layering doctrine (formerly `skills/hackify/references/code-rules.md`). 231 lines, skill-loaded on demand by Phase 2.5 Reviewer B and Phase 5 Reviewer B. The legacy `references/code-rules.md` path is preserved as a 6-line forwarding stub so existing intra-skill links keep working; both paths mirror to all 7 runtimes via `sync-runtimes.sh`.
- **`agents/`**, 7 formal Claude Code sub-agent definitions extracted from the templates in `skills/hackify/references/parallel-agents.md`. Three Phase 2.5 spec reviewers (`spec-reviewer-consistency`, `spec-reviewer-rules`, `spec-reviewer-dependencies`), three Phase 5 code reviewers (`code-reviewer-security`, `code-reviewer-quality`, `code-reviewer-plan-consistency`), and one Phase 3 wave task implementer (`wave-task-implementer`). Each file has YAML frontmatter (`name`, `description`) plus the canonical 7-section sub-agent contract (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY / OUTPUT. SEVERITY omitted on the implementer). claude-code-only, non-claude-code runtimes fall back to the inline templates in `parallel-agents.md`, which stays untouched.
- **`hooks/hooks.json`** + **`hooks/inject-hard-caps.sh`**, single UserPromptSubmit hook. The shell script emits a JSON envelope (`{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<rules>"}}`) so the harness treats the rules as injected context rather than a transcript message. NON-routing, the script never inspects the user prompt; it just reads `${CLAUDE_PLUGIN_ROOT}/rules/hard-caps.md`. claude-code-only.

### Changed (Skill descriptions are the new routing mechanism)

- **`skills/hackify/SKILL.md`** description, sharpened (1177 chars) to enumerate broad-spectrum verbs (`add`, `build`, `implement`, `refactor`, `redesign`, `restyle`, `migrate`, `debug`, `polish`, `audit`) AND architecture/scope/security surface (`auth`, `crypto`, `migration`, `secret`, `token`, `password`, `schema`, `data model`, `API surface`, `refactor everywhere`, `across all`). Explicit "When in doubt, invoke this skill" contract preserved.
- **`skills/quick/SKILL.md`** description, sharpened (1458 chars) to lead with explicit small-fix triggers (`quick fix`, `small change`, `just fix the`, `one-line fix`, `tiny edit`, `small fix`, `small bug`, `quick patch`, `minor tweak`, `just rename`, `fix typo`); explicit non-trigger list (cross-file refactor, redesign, debug, auth/crypto/migration); four fallback signals (attempt counter, file count, security path, user-invokes-full) kept intact as post-implementation circuit breakers.
- **`skills/brainstorm/SKILL.md`** description, sharpened (1273 chars) to enumerate idea-exploration triggers (`/brainstorm`, `let's discuss`, `let's think`, `what if`, `brainstorm`, `explore the idea`, `what do you think`, `considering`, `thinking about`); explicit non-trigger rule for build verbs that route to hackify/quick directly.

### Changed (sync-runtimes + validator)

- **`scripts/sync-runtimes.sh`** `MIRROR_SOURCES` appended with `rules/hard-caps.md` and `rules/code-quality.md` (mirrors to all 7 runtimes). `CLAUDE_CODE_EXTRA` appended with the 7 `agents/*.md` files + `hooks/hooks.json` + `hooks/inject-hard-caps.sh` (mirrors to `dist/claude-code/` only). Both arrays remain explicit flat enumerations, not globs.
- **`scripts/validate-dod.sh`**, gained five new checks: `[29]` rules/ existence + non-empty, `[30]` agents/ has exactly the 7 expected files with matching frontmatter `name:`, `[31]` hooks/hooks.json parses as JSON and declares `UserPromptSubmit`, `[32]` `hooks/inject-hard-caps.sh` is executable, `[33]` smart-router file stays deleted and no SKILL re-introduces a link to it.

### Migration

No migration for skill users, slash commands, descriptions, and the work-doc contract are unchanged on the user-facing surface. Plugin authors who fork hackify pick up the new four-primitive contract: `rules/` for always-on law, `agents/` for parallel-dispatch defs, `hooks/` for prompt-time reminders, `skills/` for workflows.

## [0.2.1] - 2026-05-11

> **Patch label, refactor-only scope.** Pure refactor, no new features, no bug fixes against shipped behavior. Extracts the smart-router block to a single canonical reference shared by both SKILLs, hardens two validator checks flagged in the v0.2.0 Retrospective, and honestly retires the v0.2.0 AC10 gross target as a documented incompatibility (the router block was post-v0.2.0 additive prose, not pre-existing prose, so its extraction is gross-neutral against AC10's anchor). Wins are measured in net SKILL-file line reduction (−37 / −39) and single-source-of-truth architecture for the router rules.

### Changed (Smart-router single source of truth)

- **`skills/hackify/references/smart-router.md`**, new canonical reference (62 lines). Holds the H1 title, rationale paragraph, three verbatim H3 signal-group sections (`### Signal group (i) — Brainstorm triggers`, `### Signal group (ii) — Full-mode triggers`, `### Signal group (iii) — Quick-eligible`), the 5-row decision table, the explicit default-to-full fallback rule (signal-group count ≠ 1), a `## Consumers` subsection naming both SKILLs that link here, and a `## Stub template (verbatim — for T2.1 and T2.2)` subsection containing the exact byte-stable stub used in both SKILL files.
- **`skills/hackify/SKILL.md`** smart-router section replaced with a 5-line stub linking to `references/smart-router.md`. File shrinks 386 → 349 lines (−37).
- **`skills/quick/SKILL.md`** smart-router section replaced with the same byte-stable stub. File shrinks 134 → 95 lines (−39).
- **Eliminates the ~42-line near-verbatim duplication** flagged in the v0.2.0 Retrospective as documented-but-fragile. Future router-rule edits land in ONE place; both SKILLs inherit by reference.

### Changed (Validator hardening)

- **`scripts/validate-dod.sh` check `[2]`** (references count) switched from hardcoded equality (`-eq 10`) to minimum threshold (`-ge 11`), closing the v0.2.0 Retrospective follow-up that flagged the `eq N` pattern as fragile across version bumps.
- **`scripts/validate-dod.sh` check `[27]`** (router classifier) rescoped: greps each SKILL for the literal repo-rooted markdown link `(/skills/hackify/references/smart-router.md)`, not the bare filename, which would leak into CHANGELOG/README/work-doc occurrences, and separately greps `references/smart-router.md` for the three exact verbatim H3 headings. Same "router is documented" invariant, new anchors aligned to the post-extraction layout.
- **Stub link path** uses the repo-rooted leading-slash form `(/skills/hackify/references/smart-router.md)` so the same byte-stable stub works from both `skills/hackify/SKILL.md` AND `skills/quick/SKILL.md` (bare relative paths break for the second consumer because the reference lives under `skills/hackify/references/`, not `skills/quick/references/`).

### Changed, v0.2.0 AC10 disposition (retired, not recovered)

- **AC10 disposition reframed honestly.** The v0.2.0 work-doc Retrospective flagged AC10's gross-20%-on-pre-existing-prose target as missed and deferred to v0.2.1. v0.2.1 reframes that disposition: the router block was post-v0.2.0 additive prose, NOT pre-existing prose, so its extraction is gross-neutral against AC10's anchor. AC10's gross target is hereby **retired as a documented incompatibility** rather than "recovered." v0.2.1's win is measured in net SKILL-file line reduction (−37 / −39 across the two SKILLs) and single-source-of-truth architecture for the router.

## [0.2.0] - 2026-05-11

> **Minor-level scope, minor-level label.** First release where the plugin source is tool-agnostic: the canonical hackify source no longer hard-codes Claude Code tool names, and a runtime-sync script emits per-runtime distributions. Ships three new skills (`brainstorm`, `writing-skills`, `receiving-code-review`), a sprint-style work-doc vocabulary, a smart pre-Phase-1 router shared by full and quick modes, wave-end persistence + pause-checkpoint behavior, and a tightened token + soft-language pass on both SKILL files. No breaking change to the workflow phases, the 7-section sub-agent contract, or the Wizard contract; archived pre-0.2.0 work-docs work without migration.

### Added (Multi-runtime support)

- **Tool-agnostic prose pass on `skills/hackify/SKILL.md`.** Concrete Claude Code tool names replaced with runtime primitive names (`wizard tool` / `subagent dispatcher` / `file-read op` / `file-write op` / `file-edit op` / `search` / `shell`). Wizard contract, Template contract, and 7-section sub-agent contract tokens preserved verbatim.
- **`references/runtime-adapters.md`**, new reference. 7×8 primitive-to-native-tool mapping table plus a 3-tier (`native` / `best-effort` / `not supported`) plugin-support matrix covering Claude Code, OpenAI Codex CLI, OpenAI Codex App, Google Gemini CLI, OpenCode, Cursor, and GitHub Copilot CLI.
- **`scripts/sync-runtimes.sh`**, new script (479 lines, POSIX/macOS-portable, `--dry-run` aware, idempotent). Converts the canonical hackify source into runtime-specific plugin packages under `dist/<runtime>/`. New `dist/.gitignore` (`*` plus `!.gitignore`) keeps generated output untracked while pinning the directory shape.
- **`## Runtime primitives — where the tool names go`**, new trailing section in `skills/hackify/SKILL.md` cross-referencing `references/runtime-adapters.md` so authors land on the mapping table the first time they hit a primitive.

### Added (New skills)

- **`skills/brainstorm/SKILL.md`** (97 lines). Socratic pre-task refinement mode. Auto-discovery triggers: `/brainstorm`, "let's discuss", "let's think", "what if", "brainstorm", "explore the idea". Graduation rule: when the user signals "build this", lazily creates the work-doc with a `## Brainstorm Provenance` block and hands off to Phase 1 of full hackify. One-doc-per-task philosophy preserved.
- **`skills/writing-skills/SKILL.md`** (128 lines), hackify-specific meta-skill for authoring new hackify-conformant skills. Bundles a 9-check self-validation checklist covering frontmatter, triggers, required sections, the 7-section sub-agent contract, the Wizard contract, OUTPUT word-caps, soft-language scan, file size, and path conventions.
- **`skills/receiving-code-review/SKILL.md`** (109 lines), structured per-finding response. Required table columns: Finding / Severity / Decision / Evidence; Decision ∈ {`accept`, `push-back`, `defer`}. Two trigger paths: Phase 5 internal multi-reviewer findings AND external feedback paste (PR comments, Slack quotes). Critical-findings guardrail: no bare push-back without Phase 5 escalation.

### Added (Sprint-style work-doc)

- **`references/work-doc-template.md`** body sections relabeled to sprint vocabulary: `Definition of Done` → `Acceptance Criteria`, `Tasks` → `Sprint Backlog`, `Implementation Log` → `Daily Updates`, `Verification` → `Sprint Review`, `Post-mortem` → `Retrospective`. New `sprint_goal` frontmatter field. Back-compat: `skills/hackify/SKILL.md` resume-mode accepts either label set, so archived pre-v0.2.0 docs in `docs/work/done/` work without migration.

### Added (Smart router)

- **Pre-Phase-1 router block** added to both `skills/hackify/SKILL.md` and `skills/quick/SKILL.md`. Three signal groups: (i) brainstorm triggers, (ii) full-mode triggers (auth/crypto/migration keywords, multi-file scope keywords, architecture keywords, prompt length > 80 chars, explicit `/hackify:hackify`), (iii) quick-eligible. Default-to-full rule fires when the matched signal-group count ≠ 1.

### Added (Wave-end persistence + pause checkpoint)

- **Phase 3 wave-end persistence rule.** Parent MUST update the work-doc (tick checkboxes, append a Daily Updates entry, run verification, advance `current_task`) BEFORE dispatching wave N+1. Stops the "all waves done, no work-doc updates" failure mode.
- **Pause-keyword detection** during an active wave. Trigger words: `pause`, `stop`, `exit`, `later`, `tomorrow`, `come back`, `pick this up later`. Match runs the 5-step Pause Checkpoint procedure ending with the surface text "Resume with 'continue work on <slug>'".

### Changed (Token + Haiku pass)

- **`skills/hackify/SKILL.md`** Token-efficiency pass: 422 → 378 lines (T4.1, net 10.4%). Mandatory pause-checkpoint + wave-end-persistence insertion (T4.3) then added 8 lines, landing the final file at **386 lines**. Net AC10 target (≤380) missed by 6 lines because T4.3 is contract-required. Gross 20% target on pre-existing prose was deemed incompatible with AC fidelity; both gaps documented in the v0.2.0 work-doc Retrospective.
- **`skills/quick/SKILL.md`** 162 → 134 lines (net 17.3%, gross ~28 lines). Three prose-to-table conversions land most of the saving.
- **Soft-language audit** across both SKILL files: 0 matches for `if reasonable`, `consider`, `maybe`, `try to`, `usually`, `as appropriate`, `where possible` outside the Anti-rationalizations block and explicit examples.

### Changed (Validator)

- **`scripts/validate-dod.sh`** extended with five new check groups: `[24]` `sync-runtimes` dry-run output; `[25]` new-skill SKILL.md presence + frontmatter + `name` regex (`^[a-z0-9-]{1,64}$`) for `brainstorm`, `writing-skills`, `receiving-code-review`; `[26]` sprint vocabulary tokens present in `references/work-doc-template.md`; `[27]` router classifier block present in both SKILL files; `[28]` pause-keyword list present in `skills/hackify/SKILL.md`.

### Fixed (Internal)

- **`references/` count check** in `scripts/validate-dod.sh` updated from 9 to 10 to reflect the new `runtime-adapters.md` added by T3.2.

## [0.1.4] - 2026-05-11

> **Patch label, minor-level scope.** Two new ergonomics features ship under a patch label per release-cadence preference. No breaking change to the workflow shape or template contracts; v0.1.3 templates and wizard banks ship unchanged.

### Added (Summary table feature)

- **Phase 6 Step F. Summary table.** Full hackify now ends with a concise 2-column Area/Change markdown table printed to chat AND appended to the archived work-doc under `## Summary of changes shipped`. Authoring rules + worked example in `references/finish.md`.
- **`/hackify:summary` slash command** at `commands/summary.md`, invokable any time during a task to print the current Area/Change recap on demand. Body conforms to the v0.1.3 7-section sub-agent contract (Shape B Self-checklist VERIFICATION; SEVERITY omitted as it is a generation task).
- **Phrase triggers**, saying "show summary", "summarize", "summary table", or "show me what changed" routes to the same logic as `/hackify:summary`.
- **Authoring guidance**, `references/finish.md` gains a "Summary table, authoring guidance" subsection covering Area-label rules (1-4 words, concept/theme), Change-cell rules (≤25 words, backticks for tech terms), grouping heuristics, and a 5-row worked example.

### Added (Compressed-flow `/hackify:quick` skill)

- **New skill at `skills/quick/SKILL.md`** registers `/hackify:quick` as a compressed alternative to full hackify for small bug fixes, single-file edits, polish/typo work, and quick direct-effort tasks.
- **Workflow shape:** Phase 1 Clarify (full wizard if ambiguous; zero questions otherwise) → Phase 3 Implement (single agent or inline) → Phase 4 Verify (test + lint + typecheck) → Phase 6 Step F (Summary table, mandatory).
- **Skipped phases:** Phase 2 Plan+Gate, Phase 2.5 Spec self-review, Phase 5 Multi-reviewer, Phase 6 four-options finish. Phase 3b Debug-when-stuck is NOT skipped, the fallback rule below escalates to full hackify which handles Phase 3b normally.
- **Fallback-to-full-hackify** triggers (all testable predicates): (a) implementation-attempt counter reaches 2; (b) `git diff --name-only HEAD | wc -l > 3`; (c) any touched path matches `*auth*`/`*crypto*`/`*migration*`/`*secret*`/`*token*`/`*password*`; (d) user prompt during the task contains `Phase 5`, `multi-reviewer`, or `do full review`. Fallback procedure writes a work-doc from accumulated context and re-enters full hackify Phase 2.
- **Single-implementation-agent cap**, quick mode dispatches at most one implementation subagent. Needing parallel agents is a fallback signal.

### Changed

- **`skills/hackify/SKILL.md`** Phase 6 section gains explicit Step F (Summary table) between Step E and the section trailer; "When to invoke" section gains a one-line carve-out pointing readers at `/hackify:quick` for small tasks.

### Validator

- **Checks `[18]`, `[23]` added** to `scripts/validate-dod.sh`: `[18]` `commands/summary.md` exists with `description:` frontmatter and `Area`/`Change` body tokens; `[19]` SKILL.md Phase 6 section contains `Summary table` and references `/hackify:summary`; `[20]` `references/finish.md` contains the Summary-table authoring subsection with `| Area |` worked-example header; `[21]` `skills/quick/SKILL.md` exists with `name:` (regex `^[a-z0-9-]{1,64}$`) and `description:` frontmatter; `[22]` quick-mode SKILL.md contains `Skipped phases` and the 4 skipped-phase tokens (Phase 2, Phase 2.5, Phase 5, four-options); `[23]` quick-mode SKILL.md contains `Summary table` (mandatory step is documented).

## [0.1.3] - 2026-05-11

> **Patch label, minor-level scope.** Despite being a patch release, this is a substantial rewrite of every sub-agent prompt and every clarify-wizard bank in the plugin. The label reflects the maintainer's release-cadence preference, not the underlying change size. Users upgrading from 0.1.2 should expect templates to look different, the workflow phases and DoD shapes are unchanged.

### Closed (the six canonical bugs from the v0.1.0 post-mortem)

1. **Soft severity language let unverifiable schema findings get downgraded.** Reviewer A flagged `"source": "."` as "Important, may break under future schema tightening." That qualifier let it be deferred. Result: v0.1.0 install rejected; v0.1.1 + v0.1.2 reshipping cost.
2. **No cross-file consistency requirement in author prompts.** The README author agent had no rule binding its hero tagline to the `plugin.json` / `marketplace.json` descriptions. Phase 5 caught the four-way drift after the fact.
3. **No inline verification scripts in many templates.** Agents reported "done" without running the checks that would have caught their own gaps (evals.json contamination almost shipped).
4. **No anchored severity rubrics.** "Mark Critical / Important / Minor" without anchored examples produced inconsistent reviewer outputs.
5. **No placeholder syntax for dispatch-time values.** Each dispatching call handwrote paths and constraints; drift between calls was inevitable.
6. **Research-phase prompts didn't verify the architectural behaviors the plan depended on.** The "commands inside a plugin are namespaced" property wasn't asked about explicitly, only Phase 2.5 caught it.

### Added

- **`references/parallel-agents.md` "Template Contract" preamble**, canonical 7-section structure (ROLE / INPUTS / OBJECTIVE / METHOD / VERIFICATION / SEVERITY [review-only] / OUTPUT). Every sub-agent template in the file conforms. ROLE has 5 mandatory elements: identity + seniority, domain expertise, named standards (cited from a version-pinned allowlist. OWASP Top 10 2021, NIST SP 800-63B, RFC 6749, RFC 7519, WCAG 2.2 AA, SOLID, Clean Code, Conventional Commits 1.0.0, Semantic Versioning 2.0.0, Keep a Changelog 1.1.0, ISO 8601, Postel's law, expand-then-contract migrations), rejected anti-patterns (≥3), behavioral bias (`Bias to:` / `Bias against:`). VERIFICATION comes in two shapes: Executable bash for filesystem-touching templates, Self-checklist yes/no list for prose-producing ones.
- **`references/clarify-questions.md` "Wizard Contract" preamble**, canonical 4-section structure for every task-type bank (SCENARIO / COMPOSITION / QUESTIONS / EXIT CRITERIA). Recommended-first rule documented (option A suffixed " (Recommended)"). Decision-rule COMPOSITION replaces free-choice "use judgment" guidance.
- **`{{snake_case}}` placeholders** for every dispatch-time runtime value. Placeholders are documentation to the dispatching agent (not the sub-agent); a sub-agent receiving literal `{{...}}` text is a dispatch bug.
- **Verbatim canonical SEVERITY line** in every review template: "If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important."
- **`scripts/validate-dod.sh`** extended with six new checks: [9] template structural conformance, [10] SEVERITY conditional (review templates have it, build/research don't), [11] canonical SEVERITY phrase, [12] ROLE 5-element substance check, [13] no leaked absolute paths in template bodies, [14] wizard structural conformance. Existing checks [1], [8] unchanged.

### Changed

- All 11 sub-agent templates in `references/parallel-agents.md` rewritten to the 7-section contract: Phase 1 Research, Phase 2.5 Spec-review A/B/C, Phase 3 Implementation wave, Phase 3b Debug evidence, Phase 4 Cross-package verification, Phase 5 Multi-reviewer A/B/C, Phase 5 Code-review escalation. Six are review/audit templates (SEVERITY mandatory); four are build/research (SEVERITY omitted); Code-review escalation is a single-specialist review (SEVERITY mandatory).
- All 7 clarify wizard banks in `references/clarify-questions.md` rewritten to the 4-section contract: Universal preamble, feature, fix, refactor, revamp/redesign, debug, research.
- The escalation reviewer in `references/review-and-verify.md` rewritten to the 7-section contract.
- `skills/hackify/SKILL.md` adds two short cross-references pointing readers at the Template Contract and the Wizard Contract; no other content drift.

### Migration notes (for users running 0.1.2)

- Existing in-flight work-docs need no migration, the workflow shape is unchanged.
- Custom sub-agent prompts in user projects can adopt the 7-section contract incrementally. Running `bash scripts/validate-dod.sh` from the plugin source after editing surfaces the same checks the plugin's own templates pass.

## [0.1.2] - 2026-05-11

### Fixed

- `marketplace.json` plugin source switched from `github` type (which delegates to the user's local git protocol. SSH by default for many setups) to the explicit `url` type with an HTTPS clone URL. Public-repo HTTPS clones need no SSH key or GitHub auth, so the plugin now installs for any user who can `git clone https://github.com/nadyshalaby/hackify.git` from their machine. Resolves "Permission denied (publickey)" install errors on machines without GitHub SSH access.

### Added

- README "Troubleshooting" section covering the three most common install failures: source-type rejection (fixed in 0.1.1), SSH host-key prompts (one-liner with `ssh-keyscan`), and SSH auth errors (the protocol switch shipped in 0.1.2).

## [0.1.1] - 2026-05-11

### Fixed

- `marketplace.json` `plugins[0].source` was set to the bare string `"."`, which the current Claude Code plugin-marketplace schema rejects with "This plugin uses a source type your Claude Code version does not support." Replaced with the documented typed-object form `{"source": "github", "repo": "nadyshalaby/hackify"}`. `/plugin install hackify@hackify-marketplace` now succeeds against the published GitHub repo.

## [0.1.0] - 2026-05-11

### Added

- Initial public release.
- Single skill `hackify` invokable as `/hackify:hackify` after install.
- Six-phase workflow: Clarify → Plan + Gate → Spec self-review → Implement (parallel waves) → Verify → Review (parallel reviewers) → Finish.
- Per-task markdown work-doc convention at `<project>/docs/work/<YYYY-MM-DD>-<slug>.md`.
- Nine reference files covering: clarify question banks, code rules, debug playbook, finish protocol, frontend-design heuristics, TDD walkthrough, parallel-agent dispatch templates, review checklist, work-doc template.
- Optional `evals/evals.json` for use with the `skill-creator` plugin (harmless if not installed).
- Self-hosted marketplace metadata in `.claude-plugin/marketplace.json` so the plugin is installable via `/plugin marketplace add nadyshalaby/hackify` → `/plugin install hackify@hackify-marketplace`.

## Maintenance notes

- **Every release MUST bump `version` in `.claude-plugin/plugin.json`.** Claude Code uses that field to detect updates for installed users, pushing further commits without a version bump is invisible to existing installs.
- Pair every `version` bump with a new entry in this CHANGELOG and a corresponding git tag (`v0.x.y`).
- Breaking workflow changes (e.g., a renamed phase, a removed reference file, a different work-doc schema) bump the minor version while the plugin is on `0.x.y`, and the major version once it reaches `1.0.0`.
