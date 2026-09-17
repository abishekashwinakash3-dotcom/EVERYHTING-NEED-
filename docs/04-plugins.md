# 04 — Plugins

## Plugin vs skill

A **skill** is one capability. A **plugin** is a bundle — skills + slash commands
+ agents + hooks + MCP servers — installed and updated as a unit from a
**marketplace** (just a git repo with a `.claude-plugin/marketplace.json`).

## Installed by this kit

### ECC — `ecc@ecc`
[affaan-m/ECC](https://github.com/affaan-m/ECC) · MIT · v2.2.1

The big one. Verified contents:

| Component | Count |
|---|---|
| Agents | 68 |
| Skills | 292 |
| Commands | 94 |

It enforces a loop — *plan → test → implement → review → verify → remember → improve* —
rather than letting the model freestyle. Includes **AgentShield**, which scans
prompts and configs for injection and unsafe patterns. That pairs directly with
your AI-security interest: read its source, it's a good study of the threat model.

```bash
claude plugin marketplace add affaan-m/ECC
claude plugin install ecc@ecc --scope user
```

There's also an official wizard, if you'd rather:
```bash
npx ecc-universal@2.2.1 setup
```

> ⚠️ 292 skills + 68 agents is a lot of context. If sessions feel slow or
> unfocused, run `claude plugin details ecc` to see its projected token cost, and
> consider `claude plugin disable ecc` for small tasks. More is not always better.

### scroll-craft — `nateherk-design@nateherk`
[your fork](https://github.com/abishekashwinakash3-dotcom/scroll-craft)

Builds premium scroll-driven landing pages where scroll *is* the timeline. This is
the fix for Claude's default front-end, which trends generic. Pair it with the
Playwright MCP so Claude can screenshot its own output and iterate.

## Commands

```bash
claude plugin marketplace add <owner/repo>   # add a source
claude plugin marketplace list               # what sources do I have
claude plugin marketplace update             # refresh all
claude plugin install <plugin>@<market> --scope user
claude plugin list                           # what's installed
claude plugin details <name>                 # contents + token cost
claude plugin disable <name>                 # keep but turn off
```

Scopes: `user` (everywhere — the default here), `project` (this repo, shared via
git), `local` (this repo, just you).

## Troubleshooting

### "Failed to clone marketplace repository: HTTPS authentication failed"

`claude plugin marketplace add` clones over HTTPS using your **git credential
helper**. Public third-party repos (like ECC) clone anonymously and work
immediately. **Your own repos — including public forks — often do not**, because
git tries to authenticate as you and has no credentials to offer.

Fix:
```bash
gh auth login              # docs/01
./install.sh --plugins     # re-run
```

This is why `install.sh` warns in preflight when `gh` isn't authenticated. The
scroll-craft marketplace is one of your own forks, so it needs this; ECC doesn't.

### Checking what actually landed

```bash
claude plugin marketplace list   # sources
claude plugin list               # installed plugins
./scripts/doctor.sh              # everything at once
```

A plugin can be installed but not loaded until you **restart Claude Code**.

## Safety

Installing a plugin runs its code on your machine as you. Before installing
anything not in this kit:

1. Open the repo. Read `.claude-plugin/marketplace.json`.
2. Check `hooks/` — hooks fire automatically, they're the highest-risk part.
3. Look at stars, recent commits, and whether a real person's name is on it.
4. If a marketplace prints a command for you to confirm, **read it** before saying yes.

See [06-security.md](06-security.md).
