// Corpus fixture: cleanup-category hygiene markers (language-agnostic; these
// also fire in text-only mode). Owned/ticketed debt markers are CLEAN traps.
export function active() {
  return 1
}
// removed: legacy fallback path // EXPECT: clean.removed-comment
// TODO drop this once migrated // EXPECT: clean.debt-marker
// TODO(alice): tracked, has an owner // EXPECT-CLEAN: clean.debt-marker has an owner
// FIXME PROJ-1234 tracked by a ticket // EXPECT-CLEAN: clean.debt-marker has a ticket
