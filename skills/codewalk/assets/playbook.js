// codewalk playbook — multi-entry index. Reads _catalog.json, filters live,
// links each row into its sibling slug folder's viewer. No build step.

function playbook() {
  return {
    catalog: { title: '', description: '', domains: [], entries: [] },
    filter: '',
    methodFilter: new Set(),
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'SSE', 'CLI', 'JOB', 'UI'],
    loadError: null,
    theme: 'light',

    async boot() {
      this._applyInitialTheme()
      try {
        const res = await fetch('./_catalog.json', { cache: 'no-store' })
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        const json = await res.json()
        this.catalog = this._normalize(json)
      } catch (err) {
        this.loadError = err.message
        console.error('[playbook] _catalog.json load failed', err)
      }
      this.$watch('theme', (v) => this._persistTheme(v))
      document.addEventListener('keydown', (e) => this._onKey(e))
    },

    _normalize(json) {
      // Accept either { domains, endpoints } (legacy) or { domains, entries } (canonical).
      const entries = Array.isArray(json.entries) ? json.entries : (json.endpoints || [])
      return {
        title: json.title || '',
        description: json.description || '',
        domains: Array.isArray(json.domains) ? json.domains : [],
        entries: entries.map((e) => ({ ...e, method: (e.method || 'GET').toUpperCase() })),
      }
    },

    _applyInitialTheme() {
      const fromUrl = new URLSearchParams(location.search).get('theme')
      const fromStorage = (() => { try { return localStorage.getItem('codewalk-theme') } catch { return null } })()
      this.theme = (fromUrl || fromStorage || 'light') === 'dark' ? 'dark' : 'light'
      this._applyThemeClass()
    },

    _applyThemeClass() {
      const cls = document.body.classList
      const bg = this.theme === 'light' ? 'bg-slate-50 text-slate-900' : 'bg-slate-900 text-slate-100'
      cls.remove('bg-slate-50', 'text-slate-900', 'bg-slate-900', 'text-slate-100')
      bg.split(' ').forEach((c) => cls.add(c))
    },

    _persistTheme(v) {
      try { localStorage.setItem('codewalk-theme', v) } catch { /* private mode */ }
      this._applyThemeClass()
    },

    toggleTheme() { this.theme = this.theme === 'light' ? 'dark' : 'light' },

    _onKey(e) {
      const t = e.target
      if (t && ['INPUT', 'TEXTAREA'].includes(t.tagName)) return
      if (e.key === '/') {
        const input = document.querySelector('input[type="text"]')
        if (input) { input.focus(); e.preventDefault() }
      }
    },

    get filtered() {
      const q = this.filter.trim().toLowerCase()
      const useMethod = this.methodFilter.size > 0
      return this.catalog.entries.filter((ep) => {
        if (useMethod && !this.methodFilter.has(ep.method)) return false
        if (!q) return true
        const hay = [ep.route, ep.method, ep.summary, ep.controller, ep.entry, ep.slug, ep.domain]
          .filter(Boolean).join(' ').toLowerCase()
        return hay.includes(q)
      })
    },

    get entriesByDomain() {
      const groups = {}
      for (const ep of this.filtered) {
        const k = ep.domain || '_uncategorized'
        if (!groups[k]) groups[k] = []
        groups[k].push(ep)
      }
      return groups
    },

    toggleMethod(m) {
      if (this.methodFilter.has(m)) this.methodFilter.delete(m)
      else this.methodFilter.add(m)
      this.methodFilter = new Set(this.methodFilter)
    },

    methodActive(m) { return this.methodFilter.has(m) },

    methodClass(m, active) {
      const colors = {
        GET: active ? 'bg-emerald-100 text-emerald-700 border-emerald-300' : 'bg-emerald-50 text-emerald-700 border-emerald-200',
        POST: active ? 'bg-sky-100 text-sky-700 border-sky-300' : 'bg-sky-50 text-sky-700 border-sky-200',
        PATCH: active ? 'bg-amber-100 text-amber-700 border-amber-300' : 'bg-amber-50 text-amber-700 border-amber-200',
        PUT: active ? 'bg-amber-100 text-amber-700 border-amber-300' : 'bg-amber-50 text-amber-700 border-amber-200',
        DELETE: active ? 'bg-rose-100 text-rose-700 border-rose-300' : 'bg-rose-50 text-rose-700 border-rose-200',
        SSE: active ? 'bg-violet-100 text-violet-700 border-violet-300' : 'bg-violet-50 text-violet-700 border-violet-200',
        CLI: active ? 'bg-fuchsia-100 text-fuchsia-700 border-fuchsia-300' : 'bg-fuchsia-50 text-fuchsia-700 border-fuchsia-200',
        JOB: active ? 'bg-indigo-100 text-indigo-700 border-indigo-300' : 'bg-indigo-50 text-indigo-700 border-indigo-200',
        UI: active ? 'bg-teal-100 text-teal-700 border-teal-300' : 'bg-teal-50 text-teal-700 border-teal-200',
      }
      return (colors[m] || 'bg-slate-100 text-slate-700 border-slate-300') + ' border'
    },

    domainPillClass(color) {
      const palette = {
        emerald: 'bg-emerald-100 text-emerald-800',
        violet: 'bg-violet-100 text-violet-800',
        sky: 'bg-sky-100 text-sky-800',
        indigo: 'bg-indigo-100 text-indigo-800',
        fuchsia: 'bg-fuchsia-100 text-fuchsia-800',
        rose: 'bg-rose-100 text-rose-800',
        amber: 'bg-amber-100 text-amber-800',
        teal: 'bg-teal-100 text-teal-800',
      }
      return palette[color] || 'bg-slate-100 text-slate-800'
    },

    entryShort(p) {
      if (!p) return ''
      const parts = p.split('/')
      return parts.slice(-2).join('/')
    },
  }
}

window.playbook = playbook
