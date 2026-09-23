# 02 — MCP servers

## What MCP is

**Model Context Protocol** — a standard way to give Claude *tools*. Without MCP,
Claude can read and write files and run shell commands. With MCP it can search the
web, drive a browser, query your database, or hit any API — through a small server
process that exposes those actions.

In Claude Code they're called **MCP servers**. In claude.ai chat the same idea is
called **Connectors**. Same protocol, different UI, configured separately.

## What this kit installs

### Keyless — installed by default

| Server | What it does | Why it earns a slot |
|---|---|---|
| **context7** | Fetches current, version-correct docs for any library | The single best fix for hallucinated APIs. Claude stops inventing methods that don't exist. |
| **playwright** | Drives a real browser — click, type, screenshot | Claude can *look at* the UI it just built and fix it. Essential for front-end. |
| **fetch** | Any URL → clean markdown | Research without leaving the terminal. Needs [`uv`](https://docs.astral.sh/uv/); skipped automatically if absent. |
| **sequential-thinking** | Structured multi-step reasoning | Helps on genuinely hard problems. |
| **memory** | Persistent knowledge graph between sessions | Claude remembers your project across days. |
| **findskills** | Searches a 93,000+ entry directory of agent skills (`search_skills`, `list_skills`, `get_skill`, `get_stats`, `list_tags`) | Discover skills for a new task before writing one from scratch. Pinned to `findskills-mcp@0.1.23` — see the note below. |

### Needs a free key — activate by filling `.env`

| Server | Key | Get it |
|---|---|---|
| **exa** | `EXA_API_KEY` | [dashboard.exa.ai](https://dashboard.exa.ai/api-keys) — neural search built for agents |
| **tavily** | `TAVILY_API_KEY` | [app.tavily.com](https://app.tavily.com/home) — 1,000 free credits/mo, cited results |
| **firecrawl** | `FIRECRAWL_API_KEY` | [firecrawl.dev](https://www.firecrawl.dev/app/api-keys) — crawl whole sites to markdown |
| **supabase** | `SUPABASE_ACCESS_TOKEN` | [supabase.com](https://supabase.com/dashboard/account/tokens) — Claude manages your Postgres |

```bash
cp .env.example .env    # paste keys
./install.sh --mcp      # they activate
```

### GitHub — OAuth, one manual step

```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp
claude mcp login github
```

Opens a browser once. After that Claude can read and write issues, PRs, and code
across your repos.

## Managing them

```bash
claude mcp list              # what's configured + health
claude mcp get <name>        # details on one
claude mcp remove <name>     # remove
claude mcp add <name> --scope user -- npx -y <package>
claude mcp add --transport http <name> <url>      # remote server
claude mcp login <name>      # OAuth
```

**Scopes:** `user` = all your projects (what this kit uses) · `project` = written to
`.mcp.json`, shared with anyone who clones the repo · `local` = this project, just you.

## Troubleshooting

**`claude mcp list` is the source of truth.** It health-checks every server. Run it
after installing — a server can be *configured* and still not *work*.

| Symptom | Cause | Fix |
|---|---|---|
| `Failed to connect — CONNECTION_CLOSED` | The server process starts and dies. Usually a broken/wrong package. | Run its command by hand (`npx -y <pkg>`) and read the error. |
| First health check fails, second passes | Cold `npx` download timed out | Re-run `claude mcp list`. If it fails twice, it's real. |
| `fetch` missing after install | `uv` isn't installed | Install [uv](https://docs.astral.sh/uv/), re-run `./install.sh --mcp`. Playwright covers page fetching meanwhile. |
| Keyed server skipped | Key not in `.env` | Add it, re-run `./install.sh --mcp` |

> A note on `fetch`: this kit originally used the npm package `fetcher-mcp`. Testing
> showed it fails to start (`CONNECTION_CLOSED`) even with a warm cache, so it was
> replaced with the official Python server `uvx mcp-server-fetch`, which was verified
> connecting. That's why `uv` is a dependency for this one server.

> A note on `findskills`: `findskills-mcp@latest` (currently `0.1.25`) is broken —
> its `api.js` imports `./lib/auth-error.js`, a file the maintainer's own
> `package.json` `"files"` allowlist never ships, so every fresh install crashes
> with `ERR_MODULE_NOT_FOUND`. Confirmed by unpacking the actual npm tarball, not
> just from the connection error. `0.1.23` predates that import and was verified
> starting cleanly and answering `tools/list` over the raw MCP protocol, so this
> kit pins to it explicitly rather than tracking `@latest`. Worth re-checking
> upstream occasionally — this is a one-line fix on the maintainer's end.

## Adding one you found

```bash
claude mcp add my-server --scope user -e API_KEY=xxx -- npx -y some-mcp-package
```

Or with JSON:
```bash
claude mcp add-json my-server '{"command":"npx","args":["-y","some-mcp"]}' --scope user
```

`config/mcp-servers.json` in this repo is a readable reference copy of everything above.

## Cost discipline

Every connected server's tool definitions consume context **on every request**,
whether used or not. Ten servers is a real tax on every message.

Rule of thumb: keep 4–6 connected. Add one when a task needs it, remove it when
the project's done. `claude mcp list` is your audit.

## Security

An MCP server runs as a process on your machine with your permissions, and its
*output* enters Claude's context — which makes it a prompt-injection surface. A
scraped page can contain text aimed at your agent.

- Install servers from sources you can identify. Read the repo.
- Never put a key in a shell command that gets saved to history — use `.env`.
- Be deliberate about servers that both read the web **and** write to your systems;
  that's the combination that turns injected text into real actions.
