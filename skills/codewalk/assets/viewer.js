// codewalk viewer — Alpine component. Loads data.json and renders the panes.
// No build step. Depends on globals from index.html: Alpine, Prism, mermaid, marked.

function codewalk() {
  return {
    data: {},
    loadError: null,
    tab: 'code',
    storyMode: false,
    currentNodeId: null,
    history: [],
    historyIdx: -1,
    tooltip: { visible: false, x: 0, y: 0, title: '', body: '' },
    _byId: {},
    _callers: {},

    theme: 'light',

    async boot() {
      this._applyInitialTheme()
      try {
        const res = await fetch('./data.json', { cache: 'no-store' })
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        const json = await res.json()
        this._validate(json)
        this.data = json
        this._index()
        if (json.nodes?.length) this.select(json.nodes[0].id, { push: true })
      } catch (err) {
        this.loadError = err.message
        console.error('[codewalk] data.json load failed', err)
        return
      }
      this.$watch('tab', () => this._renderMermaid())
      this.$watch('storyMode', () => queueMicrotask(() => this._wireTooltips()))
      this.$watch('theme', (v) => this._persistTheme(v))
      document.addEventListener('keydown', (e) => this._onKey(e))
      this._renderMermaid()
      queueMicrotask(() => this._wireTooltips())
    },

    _applyInitialTheme() {
      // Precedence (since v0.3.2): URL ?theme=light|dark → localStorage codewalk-theme → default 'light'.
      const params = new URLSearchParams(location.search)
      const fromUrl = params.get('theme')
      const fromStorage = (() => { try { return localStorage.getItem('codewalk-theme') } catch { return null } })()
      const next = fromUrl || fromStorage || 'light'
      this.theme = next === 'dark' ? 'dark' : 'light'
      this._applyThemeClass()
    },

    _applyThemeClass() {
      const cls = document.body.classList
      if (this.theme === 'light') cls.add('cw-light')
      else cls.remove('cw-light')
      // Swap Prism stylesheet href so token colors track the theme.
      const prism = document.getElementById('cw-prism-css')
      if (prism) {
        const light = 'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism.min.css'
        const dark = 'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism-tomorrow.min.css'
        prism.href = this.theme === 'light' ? light : dark
      }
    },

    _persistTheme(v) {
      try { localStorage.setItem('codewalk-theme', v) } catch { /* private mode */ }
      this._applyThemeClass()
      // Re-render mermaid in the new theme.
      if (window.mermaid?.initialize) {
        window.mermaid.initialize({ startOnLoad: false, theme: v === 'light' ? 'default' : 'dark', securityLevel: 'loose' })
      }
      if (this.tab === 'diagrams') this._renderMermaid()
    },

    toggleTheme() { this.theme = this.theme === 'light' ? 'dark' : 'light' },

    _validate(d) {
      if (d.version !== 1) console.warn('[codewalk] expected schema version 1, got', d.version)
      if (!Array.isArray(d.nodes) || !d.nodes.length) throw new Error('data.json has no nodes')
      if (!Array.isArray(d.edges)) throw new Error('data.json missing edges array')
    },

    _index() {
      this._byId = {}
      this._callers = {}
      for (const n of this.data.nodes) this._byId[n.id] = n
      for (const e of this.data.edges) {
        if (!this._callers[e.to]) this._callers[e.to] = []
        this._callers[e.to].push(e.from)
      }
      for (const n of this.data.nodes) {
        for (const cs of n.call_sites || []) {
          if (!this._byId[cs.callee_id]) console.warn('[codewalk] dangling callee_id', cs.callee_id, 'at', n.id)
        }
      }
    },

    get currentNode() {
      return this._byId[this.currentNodeId] || null
    },

    get breadcrumb() {
      if (!this.currentNodeId) return []
      const trail = []
      let id = this.currentNodeId
      const seen = new Set()
      while (id && !seen.has(id)) {
        const node = this._byId[id]
        if (!node) break
        trail.unshift({ id, label: node.name })
        seen.add(id)
        const callers = this._callers[id] || []
        id = callers[0]
      }
      return trail
    },

    get fileTree() {
      const byFile = {}
      for (const node of this.data.nodes || []) {
        if (!byFile[node.file]) byFile[node.file] = []
        byFile[node.file].push(node)
      }
      const byDir = {}
      for (const file of Object.keys(byFile)) {
        const parts = file.split('/')
        const dir = parts.slice(0, -1).join('/')
        const name = parts[parts.length - 1]
        if (!byDir[dir]) byDir[dir] = []
        byDir[dir].push({ path: file, name, nodes: byFile[file], expanded: true })
      }
      const sortedDirs = Object.keys(byDir).sort()
      return sortedDirs.map((d) => ({ path: d, files: byDir[d].sort((a, b) => a.name.localeCompare(b.name)) }))
    },

    select(id, opts = {}) {
      if (!this._byId[id]) return
      this.currentNodeId = id
      if (opts.push !== false) {
        this.history = this.history.slice(0, this.historyIdx + 1)
        if (this.history[this.history.length - 1] !== id) {
          this.history.push(id)
          this.historyIdx = this.history.length - 1
        }
      }
      this.tooltip.visible = false
      queueMicrotask(() => this._wireTooltips())
    },

    goBack() {
      if (this.historyIdx <= 0) return
      this.historyIdx -= 1
      this.select(this.history[this.historyIdx], { push: false })
    },

    goForward() {
      if (this.historyIdx >= this.history.length - 1) return
      this.historyIdx += 1
      this.select(this.history[this.historyIdx], { push: false })
    },

    _onKey(e) {
      const target = e.target
      if (target && ['INPUT', 'TEXTAREA'].includes(target.tagName)) return
      if (e.altKey && e.key === 'ArrowLeft') { this.goBack(); e.preventDefault() }
      else if (e.altKey && e.key === 'ArrowRight') { this.goForward(); e.preventDefault() }
    },

    nodeName(id) {
      const n = this._byId[id]
      return n ? n.name : id
    },

    callersOf(id) {
      return this._callers[id] || []
    },

    sideEffectClass(se) {
      const palette = {
        db: 'bg-blue-900/40 text-blue-200',
        queue: 'bg-purple-900/40 text-purple-200',
        http: 'bg-cyan-900/40 text-cyan-200',
        cache: 'bg-pink-900/40 text-pink-200',
        auth: 'bg-rose-900/40 text-rose-200',
        fs: 'bg-amber-900/40 text-amber-200',
      }
      return palette[se] || 'bg-neutral-800 text-neutral-300'
    },

    layerClass(layer) {
      const palette = {
        controller: 'bg-sky-900/40 text-sky-200',
        service: 'bg-violet-900/40 text-violet-200',
        repository: 'bg-fuchsia-900/40 text-fuchsia-200',
        external: 'bg-amber-900/40 text-amber-200',
        type: 'bg-emerald-900/40 text-emerald-200',
        other: 'bg-neutral-800 text-neutral-300',
      }
      return palette[layer] || 'bg-neutral-800 text-neutral-300'
    },

    renderSource(node) {
      const lang = this._prismLang(node.language || this.data.language)
      const grammar = Prism.languages[lang] || Prism.languages.javascript || Prism.languages.markup
      // Decode HTML entities that may appear in agent-generated source strings
      // (e.g. `Promise&lt;X&gt;` from JSON-escaped TypeScript). Without this,
      // Prism receives the entity text and tokens render wrong (since v0.3.1).
      const raw = decodeEntities(node.source || '')
      const highlighted = grammar ? Prism.highlight(raw, grammar, lang) : escapeHTML(raw)
      const lines = highlighted.split('\n')
      const startLine = node.function_range?.[0] ?? 1
      const invoked = new Set(node.invoked_lines || [])
      const callsByLine = {}
      for (const cs of node.call_sites || []) callsByLine[cs.line] = cs
      const out = []
      for (let i = 0; i < lines.length; i++) {
        const absLine = startLine + i
        const isInvoked = invoked.has(absLine)
        const call = callsByLine[absLine]
        // Only wrap as a clickable call site when the callee_id resolves to a
        // node we have — dangling refs render as plain text (since v0.3.1).
        const isResolvedCall = call && this._byId[call.callee_id]
        const code = isResolvedCall
          ? `<span class="cw-call" data-callee-id="${escapeAttr(call.callee_id)}">${lines[i] || '&nbsp;'}</span>`
          : lines[i] || '&nbsp;'
        const cls = `cw-line ${isInvoked ? 'cw-invoked' : 'cw-skipped'}`
        out.push(`<div class="${cls}" data-line="${absLine}"><span class="cw-line__num">${absLine}</span><span class="cw-line__code">${code}</span></div>`)
      }
      return out.join('')
    },

    _prismLang(l) {
      const map = {
        typescript: 'typescript',
        javascript: 'javascript',
        python: 'python',
        ruby: 'ruby',
        go: 'go',
        rust: 'rust',
        java: 'java',
        kotlin: 'kotlin',
        csharp: 'csharp',
        php: 'php',
        swift: 'swift',
      }
      return map[l] || 'javascript'
    },

    _renderMermaid() {
      if (this.tab !== 'diagrams') return
      queueMicrotask(async () => {
        try {
          const blocks = document.querySelectorAll('.mermaid')
          for (const el of blocks) el.removeAttribute('data-processed')
          if (window.mermaid?.run) await window.mermaid.run({ querySelector: '.mermaid' })
        } catch (err) {
          console.warn('[codewalk] mermaid render failed', err)
        }
      })
    },

    _wireTooltips() {
      const root = document.querySelector('main')
      if (!root || root._cwTooltipsWired) return
      root._cwTooltipsWired = true
      root.addEventListener('mouseover', (e) => this._tooltipShow(e))
      root.addEventListener('mouseout', (e) => this._tooltipHide(e))
      root.addEventListener('click', (e) => this._tooltipClick(e))
    },

    _tooltipShow(e) {
      const target = e.target.closest?.('[data-callee-id]')
      if (!target) return
      const id = target.getAttribute('data-callee-id')
      const callee = this._byId[id]
      if (!callee) return
      const rect = target.getBoundingClientRect()
      // For type-layer nodes, show the first ~6 lines of the type body alongside
      // the purpose — types ARE their declarations, so previewing them is the
      // primary signal in the tooltip (since v0.3.2).
      let body = callee.docblock?.purpose || '(no purpose recorded)'
      if (callee.layer === 'type' && callee.source) {
        const preview = String(callee.source).split('\n').slice(0, 6).join('\n')
        body = `${body}\n\n${preview}`
      }
      this.tooltip = {
        visible: true,
        x: Math.min(rect.left, window.innerWidth - 480),
        y: rect.bottom + 6,
        title: `${callee.name}  ·  ${callee.layer}`,
        body,
      }
    },

    _tooltipHide(e) {
      const target = e.target.closest?.('[data-callee-id]')
      if (!target) return
      this.tooltip.visible = false
    },

    _tooltipClick(e) {
      const target = e.target.closest?.('[data-callee-id]')
      if (!target) return
      e.preventDefault()
      const id = target.getAttribute('data-callee-id')
      this.select(id)
    },
  }
}

function escapeHTML(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

function escapeAttr(s) {
  return escapeHTML(s).replace(/"/g, '&quot;')
}

// Decode the small set of HTML entities that show up in agent-generated source
// strings (TypeScript generics, JSX, etc.). Kept here rather than in renderSource
// so the same helper is available to playbook.js (since v0.3.1).
function decodeEntities(s) {
  return String(s)
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
}

window.codewalk = codewalk
