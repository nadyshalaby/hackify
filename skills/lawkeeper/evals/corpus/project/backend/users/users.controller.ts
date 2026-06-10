// Corpus fixture: presentation-layer leaks a subagent must find. Deterministically
// CLEAN — no banned tokens. A controller is pure delegation: one handler = one
// service call, no business logic, no direct data access.
import { userService } from './users.service'

// list does its own DB access and branches on a query param — business logic and
// infrastructure in the presentation layer.
export function list(db, req) { // EXPECT-SEMANTIC: scope.layer
  const rows = db.query('SELECT * FROM users')
  return rows
}

// update makes two service calls and shapes the response with a conditional — a
// controller should delegate to a single call.
export function update(req) { // EXPECT-SEMANTIC: scope.controller-purity
  const current = userService.get(req.id)
  if (current) {
    return userService.save(req.id, req.body)
  }
  return userService.create(req.body)
}
