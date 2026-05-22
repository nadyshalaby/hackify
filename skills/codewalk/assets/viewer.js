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

    async boot() {
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
      document.addEventListener('keydown', (e) => this._onKey(e))
      this._renderMermaid()
      queueMicrotask(() => this._wireTooltips())
    },

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

    renderSource(node) {
      const lang = this._prismLang(node.language || this.data.language)
      const grammar = Prism.languages[lang] || Prism.languages.javascript || Prism.languages.markup
      const highlighted = grammar ? Prism.highlight(node.source || '', grammar, lang) : escapeHTML(node.source || '')
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
        const code = call
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
      this.tooltip = {
        visible: true,
        x: Math.min(rect.left, window.innerWidth - 480),
        y: rect.bottom + 6,
        title: `${callee.name}  ·  ${callee.layer}`,
        body: callee.docblock?.purpose || '(no purpose recorded)',
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

window.codewalk = codewalk
