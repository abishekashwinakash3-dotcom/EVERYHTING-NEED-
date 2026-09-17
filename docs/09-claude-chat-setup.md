# 09 — Claude.ai chat setup (the manual half)

`install.sh` configured **Claude Code**. This page is the **claude.ai chat** side —
web, desktop, and mobile.

## Why there's no script

Claude Code reads config from files on your disk (`~/.claude/`), so a script can
write them. Claude.ai chat reads config from **your Anthropic account on
Anthropic's servers**. There's no local file to edit, so there's nothing a script
can change. It's clicks in Settings — about ten minutes, once, and it then syncs to
every device you're signed in on.

## What maps to what

| Claude Code | Claude.ai chat | Same thing? |
|---|---|---|
| MCP server | **Connector** | Yes — same protocol |
| Skill | **Skill** (Settings → Capabilities) | Yes — same format |
| Plugin | — | No equivalent |
| Hook | — | No equivalent |
| `CLAUDE.md` | **Project instructions** | Similar idea |

## 1. Connectors

**Settings → Connectors** (or claude.ai/settings/connectors)

Built-in ones worth enabling:

| Connector | Use |
|---|---|
| **Google Drive** | Claude reads your notes, IA drafts, past essays |
| **Gmail** | Draft replies to teachers, universities, sponsors |
| **Google Calendar** | IB deadlines, revision blocks |
| **GitHub** | Discuss your repos in chat, not just in the terminal |

Click **Connect**, complete the Google/GitHub OAuth, done. Same account = every device.

You can also add remote MCP servers here via **Add custom connector** with the
server's URL — but only HTTP/SSE servers. The `npx`-based ones from
[02](02-mcp-servers.md) run locally and are **Claude Code only**.

## 2. Skills

**Settings → Capabilities → Skills**

Skills you upload here work in chat. Same `SKILL.md` format as Claude Code, so you
can upload the same folders:

Worth uploading, from what this kit installed:

| Skill | Path on disk | Why in chat |
|---|---|---|
| `slopmonster` | `~/.claude/skills/slopmonster` | De-AI essays — you'll draft in chat, not the terminal |
| `grill-me` | `~/.claude/skills/grill-me` | Oral practice from your phone |

Zip the folder, upload it. **Upload only skills you've scanned** — see [06](06-security.md).

## 3. Projects

**Projects** in the sidebar. A Project = persistent instructions + files, scoped
to a topic. Make one per serious thread:

| Project | Put in it |
|---|---|
| **IBDP** | Syllabus, past IAs, mark schemes, your grade targets |
| **University applications** | CV, draft PS, shortlist, sponsor/scholarship notes |
| **AI Security** | Notes, writeups, papers you're working through |
| **Side hustles** | Ideas, numbers, what shipped and what didn't |

Project instructions are the chat equivalent of `CLAUDE.md`. Write down your
context once — IBDP, 45 target, AI-security direction — and stop re-explaining it
every conversation.

## 4. Memory

**Settings → Capabilities → Memory**, if available on your plan. Lets Claude carry
facts between chats. Worth turning on, worth reviewing occasionally.

## Checklist

- [ ] Google Drive connected
- [ ] Gmail connected
- [ ] Calendar connected
- [ ] GitHub connected
- [ ] `slopmonster` uploaded as a skill
- [ ] IBDP project created, with your targets in the instructions
- [ ] University applications project created
- [ ] AI Security project created
- [ ] Memory reviewed

## Where to do what

| Task | Use |
|---|---|
| Writing/editing code, running commands, git | **Claude Code** |
| Essays, brainstorming, reading, on your phone | **Claude chat** |
| Anything touching many files in a repo | **Claude Code** |
| Anything touching Drive/Gmail/Calendar | **Claude chat** |
