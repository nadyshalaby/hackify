# Runtime adapters — primitive-to-native tool mapping

## Why this file exists

hackify is authored against 7 abstract primitives (wizard, subagent, file-read, file-write, file-edit, search, shell) rather than any single runtime's tool names. Each target runtime ships its own tool surface — Claude Code calls a file read `Read`, Gemini CLI calls it `read_file`, Codex CLI exposes it through MCP — so hackify decouples the workflow language from the tool language. This file is the single source of truth for how every primitive maps onto every supported runtime's native tools. `scripts/sync-runtimes.sh` reads this table to emit per-runtime skill bundles under `dist/<runtime>/` that reference the correct native names. When a runtime lacks a direct equivalent, the cell is marked `n/a — <reason>` honestly rather than papered over.

## The 7 primitives

- `wizard tool` — multi-question batched interactive question prompt to the user.
- `subagent dispatcher` — launches a foreground subagent with a self-contained prompt and waits for the result.
- `file-read op` — reads a local file.
- `file-write op` — writes/creates a local file.
- `file-edit op` — applies a targeted in-place edit to a local file.
- `search` — pattern search across the project (regex/literal).
- `shell` — executes a shell command (with optional timeout).

## Per-runtime mapping table

| Primitive | Claude Code | Codex CLI | Codex App | Gemini CLI | OpenCode | Cursor | Copilot CLI |
|---|---|---|---|---|---|---|---|
| wizard tool | `AskUserQuestion` | n/a — no batched-question primitive; emulate via single-shot chat turn | n/a — hosted UI handles questions inline; no programmatic batch tool | n/a — no batched-question primitive; emulate via single chat turn | n/a — no batched-question primitive; emulate via single chat turn | n/a — no programmatic question tool; emulate via inline prompt | n/a — no programmatic question tool; emulate via inline prompt |
| subagent dispatcher | `Agent` | n/a — no foreground subagent primitive; inline the prompt | n/a — no foreground subagent primitive; inline the prompt | n/a — no foreground subagent primitive; inline the prompt | `task` (custom mode dispatch) | n/a — no subagent primitive; inline the prompt | n/a — no subagent primitive; inline the prompt |
| file-read op | `Read` | `read_file` (MCP filesystem) | `read_file` (MCP filesystem) | `read_file` | `read` | built-in file context | built-in file context |
| file-write op | `Write` | `write_file` (MCP filesystem) | `write_file` (MCP filesystem) | `write_file` | `write` | inline edit via chat | inline edit via chat |
| file-edit op | `Edit` | `apply_patch` | `apply_patch` | `replace` | `edit` | inline edit via chat | inline edit via chat |
| search | `Grep` | `ripgrep` (via shell) | `ripgrep` (via shell) | `grep` | `grep` | built-in codebase search | n/a — no project-wide search tool; rely on shell `grep` |
| shell | `Bash` | `shell` | `shell` | `run_shell_command` | `bash` | built-in terminal | `shell` |

## Plugin model support matrix

| Runtime | Plugin model | Skill auto-discovery | Subagent dispatch | Notes |
|---|---|---|---|---|
| Claude Code | native | native | native | Reference runtime. Skills under `~/.claude/skills/` auto-load; `Agent` tool dispatches foreground subagents. |
| Codex CLI | best-effort | best-effort | not supported | MCP servers registered via TOML config provide tool surface. Skills emulated as prompt files referenced from `AGENTS.md`. |
| Codex App | best-effort | best-effort | not supported | Hosted plugin slots accept structured tool integrations. Skills uploaded as prompt files; no in-process subagent. |
| Gemini CLI | best-effort | best-effort | not supported | Extension JSON registers tools; `GEMINI.md` carries project context. Skills emulated as referenced markdown files. |
| OpenCode | native | native | native | Custom modes are markdown files mirroring Claude Code conventions; `task` mode dispatches subagents. |
| Cursor | best-effort | best-effort | not supported | `.mdc` rule files (legacy `.cursorrules`) carry skill content. No subagent primitive — workflows run inline. |
| Copilot CLI | not supported | not supported | not supported | No plugin or skill model. Install path is manual prompt-context copy-paste; ships best-effort only. |

## Sync output per runtime

- `dist/claude-code/` — full skill bundle with native tool names (`AskUserQuestion`, `Agent`, `Read`, `Write`, `Edit`, `Grep`, `Bash`); drop-in to `~/.claude/skills/hackify/`.
- `dist/codex-cli/` — prompt files plus `AGENTS.md` references; MCP filesystem config snippet for `read_file`/`write_file`/`apply_patch`.
- `dist/codex-app/` — prompt files structured for upload; manifest lists required MCP tools.
- `dist/gemini-cli/` — markdown files plus `GEMINI.md` include directives; extension JSON snippet registering `read_file`/`write_file`/`replace`/`grep`/`run_shell_command`.
- `dist/opencode/` — custom-mode markdown files using `read`/`write`/`edit`/`grep`/`bash`/`task` native names.
- `dist/cursor/` — `.mdc` rule files inlining the workflow; subagent steps rewritten as inline prompts.
- `dist/copilot-cli/` — single concatenated prompt-context file with manual-install instructions; no automatic discovery.

## When to update this file

Update this file whenever a target runtime adds, renames, or removes a tool that maps to one of the 7 primitives, whenever a new runtime is added to the support set, or whenever a runtime's plugin model crosses a tier boundary (best-effort gains native subagent dispatch, for example). The `scripts/sync-runtimes.sh` script reads this table directly — drifting it from the script's expectations will break the per-runtime bundles in `dist/`.
