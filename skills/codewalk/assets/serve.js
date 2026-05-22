#!/usr/bin/env node
// codewalk viewer launcher — Node stdlib only. Works on Windows, macOS, Linux.
// Picks a free port starting at 8765, serves the folder, prints the URL on its
// own line, opens the default browser. If Node is missing, prefer the fallback
// chain printed by SKILL.md (python3 / python / npx serve / php -S / ruby httpd).

const http = require('http')
const fs = require('fs')
const path = require('path')
const { spawn } = require('child_process')

const ROOT = __dirname
const START_PORT = 8765
const MAX_PORT = START_PORT + 50

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.map': 'application/json; charset=utf-8',
}

function send(res, status, body, type) {
  res.writeHead(status, {
    'Content-Type': type || 'text/plain; charset=utf-8',
    'Cache-Control': 'no-store',
  })
  res.end(body)
}

function safeJoin(root, urlPath) {
  const decoded = decodeURIComponent(urlPath.split('?')[0])
  const cleaned = decoded === '/' ? '/index.html' : decoded
  const resolved = path.normalize(path.join(root, cleaned))
  if (!resolved.startsWith(root)) return null
  return resolved
}

function serve(req, res) {
  const filePath = safeJoin(ROOT, req.url)
  if (!filePath) return send(res, 403, 'forbidden')

  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) return send(res, 404, 'not found')
    fs.readFile(filePath, (rerr, buf) => {
      if (rerr) return send(res, 500, 'read error')
      const type = MIME[path.extname(filePath).toLowerCase()] || 'application/octet-stream'
      send(res, 200, buf, type)
    })
  })
}

function tryListen(port) {
  return new Promise((resolve, reject) => {
    const server = http.createServer(serve)
    server.once('error', (err) => {
      if (err.code === 'EADDRINUSE') resolve(null)
      else reject(err)
    })
    server.listen(port, '127.0.0.1', () => resolve(server))
  })
}

function openInBrowser(url) {
  const platform = process.platform
  const cmd = platform === 'darwin' ? 'open' : platform === 'win32' ? 'cmd' : 'xdg-open'
  const args = platform === 'win32' ? ['/c', 'start', '""', url] : [url]
  try {
    spawn(cmd, args, { detached: true, stdio: 'ignore' }).unref()
  } catch (_) {
    // Browser launch is best-effort; URL is printed below for manual open.
  }
}

;(async () => {
  for (let port = START_PORT; port <= MAX_PORT; port++) {
    const server = await tryListen(port)
    if (!server) continue
    const url = `http://127.0.0.1:${port}/`
    process.stdout.write(url + '\n')
    openInBrowser(url)
    return
  }
  process.stderr.write(`no free port between ${START_PORT} and ${MAX_PORT}\n`)
  process.exit(1)
})()
