// Corpus fixture: function-shape caps the deterministic scanner does NOT check
// (it only caps file length) — these belong to the linter→semantic `caps`
// concern. One function per cap: body over 40 lines, over 3 parameters, over 3
// levels of control-flow nesting. The file itself stays under the 500-line cap.
export function buildReport(rows) { // EXPECT-SEMANTIC: cap.fn-lines
  const report = {}
  report.count = rows.length
  report.sum = 0
  for (const row of rows) {
    report.sum += row.amount
  }
  report.min = null
  for (const row of rows) {
    if (report.min === null || row.amount < report.min) {
      report.min = row.amount
    }
  }
  report.max = null
  for (const row of rows) {
    if (report.max === null || row.amount > report.max) {
      report.max = row.amount
    }
  }
  report.names = []
  for (const row of rows) {
    report.names.push(row.name)
  }
  report.active = []
  for (const row of rows) {
    if (row.active) {
      report.active.push(row.id)
    }
  }
  report.inactive = []
  for (const row of rows) {
    if (!row.active) {
      report.inactive.push(row.id)
    }
  }
  report.byRegion = {}
  for (const row of rows) {
    if (!report.byRegion[row.region]) {
      report.byRegion[row.region] = []
    }
    report.byRegion[row.region].push(row.id)
  }
  report.regions = Object.keys(report.byRegion)
  report.mean = 0
  if (report.count > 0) {
    report.mean = report.sum / report.count
  }
  report.header = 'rows: ' + report.count
  report.footer = 'total: ' + report.sum
  return report
}

export function mergeRows(left, right, keys, fill, sorted) { // EXPECT-SEMANTIC: cap.fn-params
  const merged = left.concat(right)
  if (sorted) {
    merged.sort()
  }
  return { merged, keys, fill }
}

export function walk(tree) { // EXPECT-SEMANTIC: cap.fn-nesting
  const out = []
  for (const node of tree) {
    if (node.active) {
      for (const child of node.children) {
        if (child.value) {
          out.push(child.value)
        }
      }
    }
  }
  return out
}
