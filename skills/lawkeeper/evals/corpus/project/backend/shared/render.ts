// Corpus fixture: OCP — an extension point (the renderers registry) exists, but
// the xml format was bolted on as a conditional inside render() instead of being
// registered. Stable code edited where an extension point already exists.
function renderCsv(rows) {
  return rows.map(function (row) { return row.join(',') }).join('\n')
}

function renderJson(rows) {
  return JSON.stringify(rows)
}

const renderers = { csv: renderCsv, json: renderJson }

export function render(kind, rows) { // EXPECT-SEMANTIC: solid.ocp
  if (kind === 'xml') {
    return '<rows>' + rows.map(function (row) { return '<row>' + row.join('|') + '</row>' }).join('') + '</rows>'
  }
  const fn = renderers[kind]
  if (!fn) {
    return null
  }
  return fn(rows)
}
