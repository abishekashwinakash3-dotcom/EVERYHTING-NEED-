# 10 — Sources & verification

Every repo referenced in this kit was checked to exist via `git ls-remote` against
github.com on 2026-09-17. Structures (skill counts, marketplace manifests, binary
names) were confirmed by shallow-cloning and reading the files, not guessed.

---

## ✅ From your links — identified and wired in

| Your link | Repo | Verified | Where it's used |
|---|---|---|---|
| ECC ("AI COUNCIL FOR IDEAS") | [affaan-m/ECC](https://github.com/affaan-m/ECC) | ✅ marketplace `ecc`, plugin `ecc` v2.2.1 — 292 skills, 68 agents, 94 commands | [04](04-plugins.md), `install.sh` |
| Free LLM keys | [mnfst/awesome-free-llm-apis](https://github.com/mnfst/awesome-free-llm-apis) | ✅ read, providers + limits extracted | [05](05-free-api-keys.md), `.env.example` |
| Your fork | [AIS-OS](https://github.com/abishekashwinakash3-dotcom/AIS-OS) | ✅ 6 skills in `.claude/skills` | [03](03-skills.md), `install.sh` |
| Your fork | [hyperframes-student-kit](https://github.com/abishekashwinakash3-dotcom/hyperframes-student-kit) | ✅ 14 skills | [03](03-skills.md), `install.sh` |
| Your fork | [SlopMonster](https://github.com/abishekashwinakash3-dotcom/SlopMonster) | ✅ root `SKILL.md`, single skill | [03](03-skills.md), `install.sh` |
| Your fork | [scroll-craft](https://github.com/abishekashwinakash3-dotcom/scroll-craft) | ✅ marketplace `nateherk`, plugin `nateherk-design` | [04](04-plugins.md), `install.sh` |

---

## ⚠️ Links I could not open

Three of your links are behind a login wall or blocked on this network. **I did not
guess what they showed** — I searched for tools matching your one-line description
and listed the strongest candidates. Where I'm inferring, I say so.

| Your link | Your note | Status | What I did |
|---|---|---|---|
| `youtube.com/watch?v=92rma4chrIE` | "important!" | ❌ YouTube blocked here | **Nothing wired from this.** Tell me what it covered and I'll add it. |
| `instagram.com/reel/DblTPmfPCpB` | "opensource pentester for app! Must" | ❌ Instagram login-walled | Searched for open-source AI pentesting agents → [08](08-pentesting.md). **Strix** is my best guess at the one shown; PentAGI and PentestGPT are the other likely candidates. |
| `instagram.com/reel/Dc_iv4YKCAh` | "agents! Everything engineer" | ❌ blocked | Best match is ECC (68 agents) — already installed. Unconfirmed. |
| `instagram.com/reel/DcllmSNv_Bk` | "protection for ur pc from skills" | ❌ blocked | Searched skill-security scanners → [06](06-security.md). **claude-skill-antivirus** is wired into `install.sh`; SkillSpector/skillcop listed as alternatives. |
| `notion.site/5-Free-Tools-That-Fix-Claude-s-Front-End` | frontend design skills | ❌ Notion blocked here | Covered the front-end gap with **scroll-craft** (your fork) + **Playwright MCP** so Claude can screenshot and fix its own UI. If the page named specific tools, send them. |

**If a reel showed a specific repo I didn't name, paste the repo URL and I'll wire it in properly.**

---

## Tools I added that you didn't ask for

Justified, not padding:

| Tool | Why |
|---|---|
| [claude-skill-antivirus](https://github.com/claude-world/claude-skill-antivirus) | You asked for protection from skills. This is the enforcement, not just advice — `install.sh` scans before installing. Verified working: correct binary is `claude-skill-av`, not the package name. |
| [context7](https://github.com/upstash/context7) MCP | Biggest single quality win available. Stops hallucinated APIs. |
| [Playwright](https://github.com/microsoft/playwright-mcp) MCP | Lets Claude see the front-end it builds. Directly addresses the "fix Claude's front-end" theme. |
| Exa / Tavily / Firecrawl MCP | Research tooling — EE, IA, university research. Free tiers. |
| Supabase MCP | Best free backend for actually shipping a side hustle. |
| [PortSwigger Academy](https://portswigger.net/web-security) | Not a repo. The best free path into web security, and the foundation the AI pentest tools sit on top of. |

---

## Search sources

- [Strobes — Open Source Agentic Pentesting Tools 2026](https://strobes.co/blog/open-source-agentic-pentesting-tools/)
- [DEV — Open source autonomous AI pentesting tools in 2026](https://dev.to/darkmoonx/open-source-autonomous-ai-pentesting-tools-in-2026-an-honest-field-guide-3ad0)
- [AppSecSanta — AI Pentesting Agents 2026](https://appsecsanta.com/research/ai-pentesting-agents-2026)
- [GitHub topic: ai-council](https://github.com/topics/ai-council)
- [GitHub topic: ai-penetration-testing](https://github.com/topics/ai-penetration-testing)

---

## On those `?mcp_token=` query strings

Your GitHub links arrived as:

```
https://github.com/affaan-m/ECC?mcp_token=eyJwaWQiOjI1MDY1MzMs...&fbclid=PAVERT...
```

That is **Instagram/Facebook referral tracking** appended when you share out of the
app. It is not part of the repo, not an API key, and not something any tool needs.
Despite the name, `mcp_token` has nothing to do with Model Context Protocol.

It does encode a session/profile identifier tied to your social account, so:
**strip everything from the `?` onward before pasting a link anywhere public** —
issues, Discords, forums. The clean URL is `https://github.com/affaan-m/ECC`.

I stripped them and never sent them anywhere.
