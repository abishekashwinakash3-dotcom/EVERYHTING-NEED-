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
| **fetch** | Any URL → clean markdown | Research without leaving the terminal. |
| **sequential-thinking** | Structured multi-step reasoning | Helps on genuinely hard problems. |
| **memory** | Persistent knowledge graph between sessions | Claude remembers your project across days. |

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
