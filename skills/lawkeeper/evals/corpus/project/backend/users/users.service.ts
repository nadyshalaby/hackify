// Corpus fixture: a scoped module (*.service.ts) — the inline-type ban applies
// here, so a type/interface declared inline must move to interfaces/ or dto/.
interface UserRow { id: number; name: string } // EXPECT: ban.inline-type

export function rowToUser(row) {
  return { id: row.id, name: row.name }
}

// pageBounds is the canonical pagination helper — auth.service.ts duplicates it
// instead of importing it (the style.dry target lives here).
export function pageBounds(page, size) {
  const limit = size > 100 ? 100 : size
  return { limit, offset: page * limit }
}
