// Corpus fixture: judgment-tier (semantic) violations a subagent must find.
// Deterministically CLEAN — no banned tokens — so the scanner reports nothing
// here and only the semantic pass has anything to say. Markers are scored by
// file+rule (a subagent won't pin the exact line), not exact line.
export function findUser(db, userId) {
  return db.query('SELECT * FROM users WHERE id = ' + userId) // EXPECT-SEMANTIC: sec.injection
}

// deleteUser mutates without any permission/ownership check before the write.
export function deleteUser(db, userId) { // EXPECT-SEMANTIC: sec.authz
  return db.query('DELETE FROM users WHERE id = ' + userId) // EXPECT-SEMANTIC: sec.injection
}

// pageBounds re-implements users.service.ts pageBounds verbatim instead of
// importing it — the canonical copy already exists.
export function pageBounds(page, size) { // EXPECT-SEMANTIC: style.dry
  const limit = size > 100 ? 100 : size
  return { limit, offset: page * limit }
}
