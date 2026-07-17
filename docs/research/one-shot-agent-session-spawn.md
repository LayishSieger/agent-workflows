# Research: one-shot agent session spawn options

**Ticket:** [#9](https://github.com/LayishSieger/agent-workflows/issues/9) (map [#1](https://github.com/LayishSieger/agent-workflows/issues/1))  
**Date:** 2026-07-17  
**Goal:** Feed Shell packaging and spawn decision for v0.3 — inventory practical ways to spawn a **non-interactive / one-shot agent session with clean context** from a shell. **Not** pick a winner.

**Sources:** Official vendor docs + `--help` from installed binaries on this machine (noted where versioned). Prefer primary sources over blogs.

| Tool | Binary probed | Version / note |
| --- | --- | --- |
| Cursor Agent CLI | `cursor-agent` / `cursor agent` | `2026.05.09-0afadcc` |
| Claude Code | `claude` | `2.1.92` |
| OpenAI Codex CLI | `npx @openai/codex` (not permanently installed) | help from current package |
| Grok Build | `grok` (also `agent` symlink → same binary) | `0.2.102` |

---

## Summary comparison (spawn-relevant)

| Dimension | Cursor Agent CLI | Claude Code | Codex CLI | Grok Build | Plain scripted prompt |
| --- | --- | --- | --- | --- | --- |
| **One-shot flag / entry** | `-p` / `--print` | `-p` / `--print` | `codex exec` (alias `e`) | `-p` / `--single` | HTTP client or SDK one-call |
| **Clean context default** | New process; omit `--continue` / `--resume` | New process; omit `-c` / `--resume`; optional `--no-session-persistence`, `--bare` | New `exec`; optional `--ephemeral` | New process; omit `-c` / `-r`; optional new `--session-id` UUID | Always clean (stateless API call) |
| **Working directory** | `--workspace <path>` (else cwd); `-w` worktree under `~/.cursor/worktrees/…` | Process cwd; `--add-dir`; `-w` / `--worktree` | `-C` / `--cd <DIR>`; `--add-dir` | `--cwd <PATH>`; `-w` / `--worktree` | Caller sets process cwd; no agent FS tools unless you build them |
| **Auth (automation)** | `CURSOR_API_KEY` or `agent login` | `ANTHROPIC_API_KEY` (preferred with `--bare`); or `CLAUDE_CODE_OAUTH_TOKEN` via `claude setup-token` (not with `--bare`); login OAuth | `CODEX_API_KEY` for `exec`; or saved `codex login` | `XAI_API_KEY` or `grok login` | Provider API keys only |
| **Unattended tool / edit approval** | `--force` / `--yolo` (+ headless docs show edits need force); `--trust` for workspace in print mode; `--sandbox enabled\|disabled` | `--permission-mode …`, `--allowedTools`, or `--dangerously-skip-permissions`; bare mode still needs tool allow rules | Default **read-only** sandbox; edits: `--sandbox workspace-write`; full: `danger-full-access` or `--dangerously-bypass-approvals-and-sandbox` | `--always-approve` and/or `--permission-mode …`; `--sandbox` profile | N/A (no agent tools) |
| **Machine-readable stdout** | `--output-format text\|json\|stream-json` | `--output-format text\|json\|stream-json` (+ `--json-schema`) | Final message on stdout; progress on stderr; `--json` JSONL; `-o` last message file; `--output-schema` | `--output-format plain\|json\|streaming-json` (+ `--json-schema`) | Response body as designed |
| **Exit status** | Documented in headless examples (`if [ $? -eq 0 ]`); process exit available | Non-zero on hard failures (e.g. oversized stdin, auth/schema errors); auth status command exits 0/1 | Non-zero on failures (e.g. required MCP init fail); process exit available | Process exit available (standard CLI); not deeply documented for “task quality” | HTTP/SDK error codes only |
| **ACP / protocol spawn** | `agent acp` (docs) | Agent SDK / print stream | `codex app-server`, `mcp-server` | `grok agent stdio` (ACP) | Custom |

**Shell packaging implication:** every major coding agent already exposes a **one process = one turn/session** headless entry. Clean context is “don’t pass resume/continue.” Working directory is either explicit flag or spawn `cwd`. Auth is env-key friendly for CI. **Exit codes signal infrastructure failure more reliably than “agent decided the task failed.”** Prefer structured output (json / last-message file / schema) for host-side success criteria.

---

## 1. Cursor Agent CLI

### Official model

- Install: `curl https://cursor.com/install -fsS | bash` ([Headless CLI](https://cursor.com/docs/cli/headless)).
- Primary binary names: docs/install often expose `agent`; this machine also has `cursor-agent` and `cursor agent`. **PATH note:** `agent` may be shadowed by Grok Build’s `agent` symlink (see §4). Prefer `cursor-agent` or `cursor agent` when both are installed.
- Headless: `-p` / `--print` ([Using Agent in CLI](https://cursor.com/docs/cli/using#non-interactive-mode), [Headless](https://cursor.com/docs/cli/headless)).

### Flags (one-shot / automation)

From `cursor-agent --help` (2026.05.09-0afadcc) + docs:

| Flag | Role |
| --- | --- |
| `-p, --print` | Non-interactive; print and exit |
| `--output-format text\|json\|stream-json` | With `--print` |
| `--stream-partial-output` | Stream text deltas (with stream-json) |
| `-f, --force` / `--yolo` | Auto-allow commands / apply changes in scripts |
| `--trust` | Trust workspace without prompt (**print mode only**) |
| `--sandbox enabled\|disabled` | Sandbox override |
| `--workspace <path>` | Workspace root (default: process cwd) |
| `-w, --worktree [name]` | Isolated git worktree under `~/.cursor/worktrees/<repo>/<name>` |
| `--worktree-base <branch>` | Base ref for worktree |
| `--model <model>` | Model selection |
| `--mode plan\|ask` / `--plan` | Read-only plan or Q&A |
| `--continue` / `--resume [chatId]` | **Reuse** prior context (avoid for clean one-shot) |
| `--api-key` / `CURSOR_API_KEY` | Auth for scripts |
| `--approve-mcps` | Auto-approve MCP servers |
| `create-chat` | Create empty chat, return ID (pre-seed ID without content) |

Docs note: without `--force`, print-mode may propose but not apply file changes; with `--force`, agent modifies files ([Headless](https://cursor.com/docs/cli/headless)). Separate docs line: “Cursor has full write access in non-interactive mode” ([Using](https://cursor.com/docs/cli/using)) — treat **force/yolo + trust** as the safe automation set until verified for your version.

### Auth

- Interactive: `agent login` / `cursor-agent login` (browser); `NO_OPEN_BROWSER=1` to print URL ([Authentication](https://cursor.com/docs/cli/reference/authentication)).
- Automation: `export CURSOR_API_KEY=…` or `--api-key` ([Authentication](https://cursor.com/docs/cli/reference/authentication), [Headless](https://cursor.com/docs/cli/headless)).
- Status: `agent status` / `whoami`.

### Working directory

- Default: current working directory of the process.
- Explicit: `--workspace <path>`.
- Isolation: `--worktree` creates a separate checkout; combine with `--workspace` for repo root selection ([Using](https://cursor.com/docs/cli/using)).

### Exit status

- Headless sample scripts check `$?` after `agent -p …` ([Headless](https://cursor.com/docs/cli/headless)).
- Treat non-zero as process/run failure; task semantic success should still be parsed from output/artifacts.

### Clean context recipe

```bash
cursor-agent -p --force --trust --workspace "$REPO" \
  --output-format text \
  "…tick prompt…"
# omit --continue / --resume
```

ACP alternative: `agent acp` for JSON-RPC stdio clients ([Using](https://cursor.com/docs/cli/using)).

---

## 2. Claude Code (`claude`)

### Official model

- Interactive by default; **non-interactive = `-p` / `--print`** ([CLI reference](https://code.claude.com/docs/en/cli-reference), [Run programmatically / headless](https://code.claude.com/docs/en/headless)).
- Same agent loop/tools as interactive; Agent SDK is the programmatic sibling.

### Flags (one-shot / automation)

From `claude --help` (2.1.92) + docs:

| Flag | Role |
| --- | --- |
| `-p, --print` | Print response and exit; **skips workspace trust dialog** (only use in trusted dirs) |
| `--output-format text\|json\|stream-json` | With `-p` |
| `--json-schema <schema>` | Structured final payload |
| `--bare` | Minimal discovery: skip hooks, plugins, MCP auto, CLAUDE.md, auto-memory, keychain OAuth; faster/cleaner for scripts. Auth must be `ANTHROPIC_API_KEY` or `apiKeyHelper` via `--settings` |
| `--no-session-persistence` | With `-p`: do not save session (cannot resume) |
| `--permission-mode acceptEdits\|auto\|bypassPermissions\|default\|dontAsk\|plan` | Approval policy |
| `--allowedTools` / `--disallowedTools` | Tool allow/deny |
| `--dangerously-skip-permissions` | Bypass permission checks (sandbox recommendation) |
| `--system-prompt` / `--append-system-prompt` | Prompt control |
| `--add-dir <dirs…>` | Extra tool-access directories |
| `-w, --worktree [name]` | New git worktree for session |
| `-c, --continue` / `-r, --resume` | **Reuse** context (avoid for clean one-shot) |
| `--session-id <uuid>` | Pin session ID for a **new** conversation |
| `--max-budget-usd` | Cost cap (`-p` only) |
| `--model` / `--effort` | Model controls |
| `--settings` / `--setting-sources` | Explicit settings injection |

### Auth

Documented precedence and automation options ([Authentication](https://code.claude.com/docs/en/authentication)):

1. Cloud provider flags (Bedrock / Vertex / Foundry) when enabled  
2. `ANTHROPIC_AUTH_TOKEN` (Bearer)  
3. `ANTHROPIC_API_KEY` — **always used in `-p` when set**  
4. `apiKeyHelper`  
5. `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token` (subscription; **not** read in `--bare`)  
6. Interactive `/login` OAuth  

`claude auth status` exits **0 if logged in, 1 if not** ([CLI reference](https://code.claude.com/docs/en/cli-reference)).

### Working directory

- Tool root = process cwd (spawn with desired `cwd` or `cd` first).
- `--add-dir` grants additional paths (file access, limited config discovery).
- `-w/--worktree` for isolated git checkout.

### Exit status

- Documented non-zero exits for failures such as stdin > 10MB cap, invalid `--json-schema`, auth/helper failures ([Headless](https://code.claude.com/docs/en/headless), [Authentication](https://code.claude.com/docs/en/authentication)).
- Successful completion returns 0 even if the model’s *content* reports task failure — host must parse output.

### Clean context recipe

```bash
claude --bare -p --no-session-persistence \
  --permission-mode acceptEdits \
  --allowedTools "Bash,Read,Edit" \
  --output-format json \
  "…tick prompt…"
# or subscription CI without --bare:
# CLAUDE_CODE_OAUTH_TOKEN=… claude -p --no-session-persistence "…"
```

---

## 3. OpenAI Codex CLI (`codex exec`)

### Official model

- Interactive: `codex` TUI.
- Non-interactive: **`codex exec`** ([Non-interactive mode](https://learn.chatgpt.com/codex/non-interactive-mode), [Developer commands](https://learn.chatgpt.com/codex/developer-commands)).
- Alias: `codex e`.

### Flags (one-shot / automation)

From `codex exec --help` + docs:

| Flag | Role |
| --- | --- |
| `codex exec [PROMPT]` | One-shot agent run; prompt optional if stdin |
| `codex exec -` | Force full prompt from stdin |
| `-C, --cd <DIR>` | Working root before agent starts |
| `--add-dir <DIR>` | Extra writable directories |
| `-s, --sandbox read-only\|workspace-write\|danger-full-access` | Sandbox (default for `exec`: **read-only**) |
| `--dangerously-bypass-approvals-and-sandbox` | Full unattended (externally sandboxed envs only) |
| `--ephemeral` | No session rollout files on disk |
| `--ignore-user-config` | Skip `$CODEX_HOME/config.toml` (auth still uses CODEX_HOME) |
| `--ignore-rules` | Skip execpolicy `.rules` |
| `--json` | JSONL event stream on stdout |
| `-o, --output-last-message <FILE>` | Write final agent message |
| `--output-schema <FILE>` | JSON Schema for final response |
| `-m, --model` | Model override |
| `--skip-git-repo-check` | Allow non-git directories (default requires git repo) |
| `codex exec resume --last` / `resume <ID>` | Continue prior non-interactive session (**not** clean) |
| Deprecated | `codex exec --full-auto` still works with warning; prefer explicit `--sandbox workspace-write` |

Progress streams to **stderr**; final message to **stdout** (unless `--json`) ([Non-interactive](https://learn.chatgpt.com/codex/non-interactive-mode)).

### Auth

- Default: reuse CLI login state.
- Automation: **`CODEX_API_KEY` scoped to the single `exec` process** (docs warn not to expose key to untrusted sibling steps) ([Non-interactive](https://learn.chatgpt.com/codex/non-interactive-mode)).
- `codex login` / `logout`; advanced ChatGPT-account CI via seeded `~/.codex/auth.json`.
- GitHub: prefer [`openai/codex-action`](https://github.com/openai/codex-action) over raw key-in-shell.

### Working directory

- `-C/--cd <DIR>` is first-class.
- Must be a git repo unless `--skip-git-repo-check`.

### Exit status

- Process exit available; docs: required MCP server init failure causes `exec` to **exit with error** ([Non-interactive](https://learn.chatgpt.com/codex/non-interactive-mode)).
- Semantic task success: parse last message / schema / git diff, not only exit code.

### Clean context recipe

```bash
CODEX_API_KEY=… codex exec --ephemeral \
  --sandbox workspace-write \
  -C "$REPO" \
  -o /tmp/last-message.txt \
  "…tick prompt…"
```

---

## 4. Grok Build (`grok`)

### Official model

- Install: `curl -fsSL https://x.ai/cli/install.sh | bash` ([Grok Build overview](https://docs.x.ai/build/overview)).
- Interactive TUI: `grok`.
- Headless: `grok -p "…"` (`--single`) ([Headless & Scripting](https://docs.x.ai/build/cli/headless-scripting)).
- Protocol: `grok agent stdio` (ACP over JSON-RPC); also `headless` / `serve` / `leader` subcommands (`grok agent --help`).

### Flags (one-shot / automation)

From `grok --help` (0.2.102) + docs:

| Flag | Role |
| --- | --- |
| `-p, --single <PROMPT>` | One-shot; print to stdout and exit |
| `--prompt-file` / `--prompt-json` | Prompt from file or JSON blocks |
| `--output-format plain\|json\|streaming-json` | Headless output (default plain) |
| `--json-schema` | Constrained JSON (implies json format) |
| `--cwd <CWD>` | Working directory |
| `-w, --worktree [name]` | New git worktree; `--worktree-ref` base |
| `--always-approve` | Auto-approve tools |
| `--permission-mode default\|acceptEdits\|auto\|dontAsk\|bypassPermissions\|plan` | Permission mode |
| `--sandbox <PROFILE>` / `GROK_SANDBOX` | FS/network sandbox profile |
| `-m, --model` | Model |
| `--max-turns <N>` | Cap agent turns |
| `--no-memory` / `--experimental-memory` | Cross-session memory control |
| `-c, --continue` / `-r, --resume` | **Reuse** sessions (avoid for clean) |
| `-s, --session-id <UUID>` | Explicit **new** session UUID (must not exist) |
| `--system-prompt-override` / `--rules` | Prompt control |
| `--check` | Self-verification loop (headless) |
| `--best-of-n` | Parallel N runs pick best (headless) |
| Docs also | `--no-auto-update` for CI headless (headless-scripting page) |

### Auth

- Browser: first launch / `grok login`.
- Non-browser: `export XAI_API_KEY=…` ([Overview](https://docs.x.ai/build/overview)).
- SuperGrok / X Premium Plus subscription path for product access (product announcements); API key still the automation primitive.

### Working directory

- `--cwd <PATH>` explicit.
- Else process cwd.
- Worktree isolation via `-w`.

### Exit status

- Standard process lifecycle; headless intended for scripts/CI ([Headless](https://docs.x.ai/build/cli/headless-scripting)).
- No rich public matrix of “task failed” exit codes found; use output + host verification.

### Clean context recipe

```bash
XAI_API_KEY=… grok -p "…tick prompt…" \
  --cwd "$REPO" \
  --always-approve \
  --output-format json \
  --no-memory
# omit -c / -r
```

**PATH collision:** on this research host, `agent` → Grok Build binary, while Cursor docs brand their CLI as `agent` (`cursor-agent` remains unambiguous). Shell packaging should **pin absolute or disambiguated binary names**.

---

## 5. Plain scripted prompts (no coding-agent CLI)

Still relevant when the host only needs a model judgment, summary, or structured decision without FS tools.

| Approach | What you get | Tradeoff vs agent CLIs |
| --- | --- | --- |
| **Provider HTTP APIs** (OpenAI Responses, Anthropic Messages, xAI Responses — see Grok docs curl samples) | Stateless one-shot; full control of prompt, schema, timeout, retries | No built-in repo tools, permissions, worktrees, or AGENTS.md loading |
| **Official SDKs** (OpenAI, Anthropic, xAI Python/JS) | Same as API with typed clients | Same tool gap unless you implement a tool loop |
| **Agent SDKs that wrap CLIs** (Claude Agent SDK; Codex SDK; Grok ACP client sample) | Programmatic one-shot with tools | Heavier dependency; still vendor-specific |
| **Unix composition** | `cat prompt.md \| claude -p` / `codex exec -` / pipes | Still using an agent CLI under the hood |

**Spawn properties:**

- **Clean context:** inherent (no session store unless you add one).
- **Auth:** API keys / OAuth tokens only.
- **cwd:** irrelevant to the model unless you inject file contents into the prompt.
- **Exit status:** curl/httpx exit or HTTP status; map to host policy yourself.

Use when the tick is pure reasoning/routing; use an agent CLI when the tick must edit/run/test in a repo.

---

## Cross-cutting notes for Shell packaging

### Clean context (host requirement)

| Mechanism | Clean one-shot | Contaminates context |
| --- | --- | --- |
| Fresh process | Yes (all CLIs) | — |
| Resume/continue flags | — | Cursor `--continue`/`--resume`; Claude `-c`/`-r`; Codex `exec resume`; Grok `-c`/`-r` |
| Session persistence on disk | Claude `--no-session-persistence`; Codex `--ephemeral`; Grok new `--session-id` / no resume | Default save may allow later accidental resume |
| Shared “memory” features | Grok `--no-memory`; Claude `--bare` skips auto-memory | Cross-session memory if left on |
| Project instruction files | Always loaded from cwd/workspace unless bare/ignore flags | CLAUDE.md / AGENTS.md / `.cursor/rules` are **workspace** context, not chat history — usually desired |

### Working-directory control patterns

1. **Spawn with `cwd=`** (all tools).  
2. **Explicit flag** when available: Cursor `--workspace`, Codex `-C`, Grok `--cwd`.  
3. **Git worktree isolation:** Cursor / Claude / Grok all offer `--worktree` (paths differ).  
4. **Extra roots:** Claude `--add-dir`, Codex `--add-dir`.

### Auth for unattended multi-tick hosts

| Preference | Cursor | Claude | Codex | Grok |
| --- | --- | --- | --- | --- |
| Env API key | `CURSOR_API_KEY` | `ANTHROPIC_API_KEY` | `CODEX_API_KEY` (exec) | `XAI_API_KEY` |
| Long-lived OAuth | login store | `claude setup-token` → `CLAUDE_CODE_OAUTH_TOKEN` | ChatGPT auth.json (advanced) | `grok login` store |
| Minimal CI surface | API key | API key + `--bare` | Action proxy / scoped key | API key |

### Exit status — what the host can trust

| Layer | Reliable? |
| --- | --- |
| CLI process crash / auth fail / bad flags / sandbox init | Yes (non-zero) |
| Model says “I failed” or partial edits | **No** — usually still exit 0 |
| Host criteria | Prefer: expected files, tests, structured JSON schema, tracker state |

Cursor’s own headless sample treats `$?` as success of the **run**, not of the engineering goal ([Headless](https://cursor.com/docs/cli/headless)).

### Output contracts for a host

| Need | Cursor | Claude | Codex | Grok |
| --- | --- | --- | --- | --- |
| Final text only | `-p` text | `-p` text | stdout last message | `-p` plain |
| Single JSON blob | `--output-format json` | `--output-format json` | `-o` + schema / parse JSONL | `--output-format json` |
| Live event stream | `stream-json` | `stream-json` | `--json` JSONL | `streaming-json` |
| Schema-constrained | (limited vs peers) | `--json-schema` | `--output-schema` | `--json-schema` |

---

## Practical spawn skeletons (not a recommendation)

```bash
# Cursor
cursor-agent -p --force --trust --workspace "$REPO" --output-format json "$PROMPT"

# Claude (script-minimal)
claude --bare -p --no-session-persistence --permission-mode acceptEdits \
  --allowedTools "Bash,Read,Edit" --output-format json "$PROMPT"

# Codex
CODEX_API_KEY=… codex exec --ephemeral --sandbox workspace-write -C "$REPO" \
  -o "$OUT/last.txt" "$PROMPT"

# Grok
XAI_API_KEY=… grok -p "$PROMPT" --cwd "$REPO" --always-approve \
  --output-format json --no-memory

# Plain API (illustrative)
curl -sS https://api.x.ai/v1/responses \
  -H "Authorization: Bearer $XAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"grok-4.5\",\"input\":$(jq -Rs . <<<"$PROMPT")}"
```

---

## Gaps / caveats (for decision tickets)

1. **Binary name collisions** (`agent` = Cursor docs vs Grok symlink) — host must pin binaries.  
2. **Exit codes ≠ task success** across all agents.  
3. **Print-mode permission semantics** differ (Cursor force/yolo vs Claude permission-mode vs Codex sandbox default read-only).  
4. **Version drift:** flags move quickly; pin CLI versions in shell packaging.  
5. **“Clean context” ≠ “empty workspace policy”:** AGENTS.md / CLAUDE.md / rules still load unless bare/ignore modes.  
6. **Codex not permanently installed** on research host; flags taken from current `npx @openai/codex` help + official docs.  
7. This research does **not** evaluate quality, cost, latency, or product fit — only spawn mechanics.

---

## Source index

| Source | URL |
| --- | --- |
| Cursor Headless CLI | https://cursor.com/docs/cli/headless |
| Cursor Using Agent (non-interactive, worktree) | https://cursor.com/docs/cli/using |
| Cursor Authentication | https://cursor.com/docs/cli/reference/authentication |
| Claude CLI reference | https://code.claude.com/docs/en/cli-reference |
| Claude Headless / programmatic | https://code.claude.com/docs/en/headless |
| Claude Authentication | https://code.claude.com/docs/en/authentication |
| Codex Non-interactive mode | https://learn.chatgpt.com/codex/non-interactive-mode |
| Codex Developer commands | https://learn.chatgpt.com/codex/developer-commands |
| Grok Build overview | https://docs.x.ai/build/overview |
| Grok Headless & Scripting | https://docs.x.ai/build/cli/headless-scripting |
| Local `--help` | `cursor-agent`, `claude`, `codex exec`, `grok` (versions above) |
