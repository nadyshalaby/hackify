#!/usr/bin/env node
// build-playbook.mjs — copy playbook + viewer assets into a target directory,
// then materialize one slug folder per catalog entry. Each slug folder gets the
// per-entry viewer assets + (optionally) a starter data.json stub when the
// caller hasn't already authored one. The deliverable is a static directory
// the user opens with `node serve.js`.
//
// Usage:
//   node build-playbook.mjs --out .codewalk
//
// Inputs (relative to --out):
//   _catalog.json   — required. { domains[], entries[] }. See data-schema.md.
//   _traces.json    — optional. { entries: [{ slug, nodes[], edges[] }, ...] }
//                     If present, per-slug data.json uses the rich trace.
//
// Outputs:
//   <out>/index.html, playbook.{js,css}      ← copied from this skill's assets/
//   <out>/_catalog.json                       ← left as-is (caller-authored)
//   <out>/serve.js                            ← copied
//   <out>/<slug>/{index.html,viewer.{js,css},data.json}  ← per entry
//
// File-size cap: this builder is intentionally ≤ 500 LOC (no helpers split).

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ASSETS_DIR = __dirname;
const PLAYBOOK_FILES = ['playbook.js', 'playbook.css', 'serve.js'];
const VIEWER_FILES = ['index.html', 'viewer.js', 'viewer.css'];

function parseArgs(argv) {
  const args = { out: '.codewalk' };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--out' && argv[i + 1]) { args.out = argv[++i]; continue; }
    if (a === '--help' || a === '-h') { args.help = true; continue; }
  }
  return args;
}

function printHelp() {
  console.log(`build-playbook — multi-entry codewalk builder

USAGE:
  node build-playbook.mjs --out <dir>

REQUIRED FILE in <dir>:
  _catalog.json   { title?, description?, domains: Domain[], entries: Entry[] }

OPTIONAL FILE in <dir>:
  _traces.json    { entries: TraceEntry[] }   — see references/data-schema.md
`);
}

function readJsonOrDie(file) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); }
  catch (err) { console.error(`could not read ${file}: ${err.message}`); process.exit(1); }
}

function copyAssets(outDir, files) {
  for (const f of files) {
    const src = path.join(ASSETS_DIR, f);
    const dst = path.join(outDir, f);
    if (!fs.existsSync(src)) continue;
    fs.copyFileSync(src, dst);
  }
}

function writePlaybookEntrypoint(outDir) {
  // The playbook lives at <out>/index.html; rename playbook.html on copy.
  const src = path.join(ASSETS_DIR, 'playbook.html');
  const dst = path.join(outDir, 'index.html');
  if (fs.existsSync(src)) fs.copyFileSync(src, dst);
}

function buildStubEntry(entry) {
  // Minimal data.json that satisfies the viewer's validation (≥1 node + edges array).
  // The caller is expected to overwrite this via /codewalk <slug> later.
  return {
    version: 1,
    entry_point: entry.entry || `${entry.method || ''} ${entry.route || ''}`.trim() || entry.slug,
    slug: entry.slug,
    language: entry.language || 'typescript',
    generated_at: new Date().toISOString(),
    previous_generated_at: null,
    repo_root: process.cwd(),
    nodes: [{
      id: `${entry.slug}:entry-stub`,
      name: entry.slug,
      file: entry.controller || entry.entry || '',
      depth: 0,
      layer: 'controller',
      language: entry.language || 'typescript',
      function_range: [1, 1],
      invoked_range: [1, 1],
      source: `// Stub entry. Run /codewalk ${entry.entry || entry.route || entry.slug} to fill in the depth-first walk.`,
      invoked_lines: [1],
      call_sites: [],
      docblock: {
        purpose: entry.summary || `Entry: ${entry.slug}`,
        inputs: [], outputs: '', side_effects: [], ownership: entry.domain || '',
      },
      data_in: '', data_out: '',
      risk: 'stub — not yet walked',
      branches_not_taken: [],
      git_blame: null,
    }],
    edges: [],
    diagrams: {
      sequence_mermaid: 'sequenceDiagram\n  participant Controller',
      module_deps_mermaid: '',
      data_evolution: [], invariants: [], failure_modes: [],
    },
    deferred_branches: [],
    diff_vs_previous: null,
  };
}

function rewriteRichEntry(catalogEntry, traceEntry) {
  const nodes = (traceEntry.nodes || []).map((n) => ({ ...n, depth: n.depth ?? 0, language: n.language || 'typescript' }));
  const edges = (traceEntry.edges || []).map((e) => ({ from: e.from, to: e.to }));
  return {
    version: 1,
    entry_point: traceEntry.entry_point || catalogEntry.entry || `${catalogEntry.method || ''} ${catalogEntry.route || ''}`.trim(),
    slug: catalogEntry.slug,
    language: traceEntry.language || catalogEntry.language || 'typescript',
    generated_at: new Date().toISOString(),
    previous_generated_at: null,
    repo_root: process.cwd(),
    nodes, edges,
    diagrams: traceEntry.diagrams || {
      sequence_mermaid: 'sequenceDiagram\n  participant Controller',
      module_deps_mermaid: '', data_evolution: [], invariants: [], failure_modes: [],
    },
    deferred_branches: traceEntry.deferred_branches || [],
    diff_vs_previous: null,
  };
}

function buildOne(outDir, catalogEntry, traceMap) {
  const slugDir = path.join(outDir, catalogEntry.slug);
  fs.mkdirSync(slugDir, { recursive: true });
  copyAssets(slugDir, VIEWER_FILES);
  const traceEntry = traceMap.get(catalogEntry.slug);
  const dataPath = path.join(slugDir, 'data.json');
  if (!traceEntry && fs.existsSync(dataPath)) {
    const existing = readJsonOrDie(dataPath);
    if (Array.isArray(existing.nodes) && existing.nodes.length >= 2) return;
  }
  const data = traceEntry ? rewriteRichEntry(catalogEntry, traceEntry) : buildStubEntry(catalogEntry);
  fs.writeFileSync(dataPath, JSON.stringify(data, null, 2));
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) { printHelp(); return; }
  const outDir = path.resolve(args.out);
  fs.mkdirSync(outDir, { recursive: true });

  const catalogPath = path.join(outDir, '_catalog.json');
  if (!fs.existsSync(catalogPath)) {
    console.error(`missing ${catalogPath}`);
    console.error(`see references/data-schema.md for the catalog format`);
    process.exit(1);
  }
  const catalog = readJsonOrDie(catalogPath);
  const tracesPath = path.join(outDir, '_traces.json');
  const traces = fs.existsSync(tracesPath) ? readJsonOrDie(tracesPath) : { entries: [] };
  const traceMap = new Map((traces.entries || []).map((e) => [e.slug, e]));

  const entries = catalog.entries || catalog.endpoints || [];
  if (!Array.isArray(entries) || entries.length === 0) {
    console.error(`_catalog.json has no entries`); process.exit(1);
  }

  writePlaybookEntrypoint(outDir);
  copyAssets(outDir, PLAYBOOK_FILES);

  let rich = 0; let stub = 0; const failed = [];
  for (const ep of entries) {
    if (!ep.slug || !/^[a-z0-9-]{1,80}$/.test(ep.slug)) {
      failed.push(`invalid slug: ${JSON.stringify(ep.slug)}`); continue;
    }
    try {
      buildOne(outDir, ep, traceMap);
      if (traceMap.has(ep.slug)) rich++; else stub++;
    } catch (err) { failed.push(`${ep.slug}: ${err.message}`); }
  }

  console.log(`\n  codewalk playbook built at ${outDir}`);
  console.log(`    entries:  ${rich + stub}`);
  console.log(`    rich:     ${rich}`);
  console.log(`    stub:     ${stub}`);
  if (failed.length) {
    console.log(`    failed:   ${failed.length}`);
    for (const f of failed) console.log(`      - ${f}`);
  }
  console.log(`\n  Launch with: node ${path.relative(process.cwd(), path.join(outDir, 'serve.js')) || './serve.js'}\n`);
}

main();
