# EVERYTHING-NEED — Abishek's AI Operating System

One repo that sets up **Claude Code** (CLI) on any machine you sit down at:
plugins, skills, MCP servers, free LLM API keys, security scanning, and — most
importantly — **your GitHub repos synced to a local folder you can actually edit.**

Built for: AI security work, IBDP (45), university applications, side hustles.

---

## ⚡ 60-second start

```bash
git clone https://github.com/abishekashwinakash3-dotcom/EVERYHTING-NEED-.git ~/ai-os
cd ~/ai-os
./install.sh --all
```

Then read **[docs/01-github-local-sync.md](docs/01-github-local-sync.md)** — that's the
"GitHub remote on my local folder" answer you asked for.

> **On Windows?** Run these in **Git Bash** (ships with Git for Windows) or **WSL**,
> not PowerShell or CMD. Claude Code itself works fine either way.

---

## 🚨 Read this before anything else

I have to be straight with you about what a script can and cannot do, because a
lot of the setup videos blur this line.

| Thing | Claude Code (CLI/terminal) | Claude.ai chat (web/desktop/mobile) |
|---|---|---|
| **Plugins** | ✅ scripted by `install.sh` | ❌ doesn't exist there |
| **Skills** | ✅ scripted (`~/.claude/skills/`) | ⚠️ Settings → Capabilities → Skills, **by hand** |
| **MCP servers** | ✅ scripted (`claude mcp add`) | ⚠️ called *Connectors*, added in Settings, **by hand** |
| **Hooks** | ✅ scripted (`settings.json`) | ❌ doesn't exist there |
| **API keys** | ✅ `.env` file | ❌ n/a |

**There is no file on disk that configures claude.ai chat.** Chat config lives on
Anthropic's servers, tied to your account. So `install.sh` gets Claude Code to 100%,
and [docs/09-claude-chat-setup.md](docs/09-claude-chat-setup.md) is a click-by-click
checklist for the chat side. Anyone who tells you a script does both is wrong.

**I cannot create API keys for you.** Signing up requires your email, a browser, and
sometimes a phone number. What I've done instead: [docs/05-free-api-keys.md](docs/05-free-api-keys.md)
ranks every free provider by what's actually worth your time, and `.env.example`
is pre-filled with the exact variable names so you paste and go.

---

## 📦 What gets installed

### Plugins (marketplaces)
| Plugin | Source | What it gives you |
|---|---|---|
| `ecc@ecc` | [affaan-m/ECC](https://github.com/affaan-m/ECC) | **68 agents, 292 skills, 94 commands.** The big one. Plan→test→implement→review→verify→remember loop, plus AgentShield security scanning. |
| `nateherk-design@nateherk` | [your scroll-craft fork](https://github.com/abishekashwinakash3-dotcom/scroll-craft) | Scroll-driven premium landing pages. Fixes Claude's bland front-end default. |

### Skills (copied into `~/.claude/skills/`)
| Bundle | Skills | Use |
|---|---|---|
| [AIS-OS](https://github.com/abishekashwinakash3-dotcom/AIS-OS) | `onboard`, `audit`, `link`, `level-up`, `3d-brain`, `grill-me` | Life/career operating system. `grill-me` is genuinely good for IB orals. |
| [hyperframes-student-kit](https://github.com/abishekashwinakash3-dotcom/hyperframes-student-kit) | 14 incl. `edit-video`, `short-form-edit`, `cut-silences`, `video-storytelling`, `gsap` | Reels/Shorts from the terminal. Side-hustle engine. |
| [SlopMonster](https://github.com/abishekashwinakash3-dotcom/SlopMonster) | `slopmonster` | Strips AI tells from prose. **Run this on every essay, PS, and TOK draft.** |

### MCP servers
Keyless ones install by default; keyed ones activate when you fill `.env`.
See [docs/02-mcp-servers.md](docs/02-mcp-servers.md) for the full table and why each earns its slot.

### Security
Skills are **executable code that runs as you**. Research cited by the scanner projects
found ~26% of public skills carry vulnerabilities and ~5% look outright malicious.
So `install.sh` scans **before** it installs, never after.
See [docs/06-security.md](docs/06-security.md).

---

## 📚 Docs

| # | Doc | Why |
|---|---|---|
| 00 | [START-HERE](docs/00-START-HERE.md) | Order of operations |
| 01 | [GitHub ⇄ local folder](docs/01-github-local-sync.md) | **Your #1 ask** |
| 02 | [MCP servers](docs/02-mcp-servers.md) | Tools Claude can call |
| 03 | [Skills](docs/03-skills.md) | How skills work, writing your own |
| 04 | [Plugins](docs/04-plugins.md) | Marketplaces, ECC |
| 05 | [Free API keys](docs/05-free-api-keys.md) | Ranked, with limits |
| 06 | [Security](docs/06-security.md) | Protecting your PC from skills |
| 07 | [AI Council](docs/07-ai-council.md) | Multi-model idea stress-testing |
| 08 | [Pentesting stack](docs/08-pentesting.md) | Your AI-security career path |
| 09 | [Claude.ai chat setup](docs/09-claude-chat-setup.md) | The manual half |
| 10 | [Sources](docs/10-sources.md) | Every link, verified |

---

## 🔧 Commands

```bash
./install.sh --all            # everything
./install.sh --plugins        # plugins only
./install.sh --skills         # skills only
./install.sh --mcp            # MCP servers only
./install.sh --dry-run --all  # print, change nothing
./scripts/doctor.sh           # what's installed / what's broken
./scripts/scan-skills.sh      # security-scan installed skills
./scripts/sync-repos.sh       # clone/pull all your GitHub repos locally
```

---

## ⚠️ About those links you sent

The GitHub URLs you pasted had `?mcp_token=...&fbclid=...` on them. That is
**Instagram/Facebook referral tracking**, not a credential and not part of the repo.
I stripped it. Don't paste those query strings into issues, Discords, or chats —
strip everything from the `?` onward before sharing a GitHub link.

I could **not** open the two Instagram reels or the YouTube video — they're blocked
on my network and login-walled. I identified the tools by searching instead and
listed exactly what I matched (and what I couldn't) in [docs/10-sources.md](docs/10-sources.md).
If a reel showed a specific repo I didn't name, send me the repo URL and I'll wire it in.

---

> **Heads up on ECC:** it installs a hook that gates *every* Bash command, not just
> risky ones. If Claude starts asking permission to run `ls`, that's why —
> [docs/04](docs/04-plugins.md#eccs-gateguard-blocks-every-bash-command) has the fix.

**License:** MIT for this kit. Each installed repo keeps its own license.
