# 00 — Start here

Do these in order. Don't skip 1.

## 1. Get your repos on your machine (30 min, once)
→ **[01-github-local-sync.md](01-github-local-sync.md)**

Nothing else matters if your code only exists in a browser tab. Install git + `gh`,
log in, clone. This is the foundation.

## 2. Run the installer (10 min)
```bash
./install.sh --all
```
Plugins, skills, MCP servers. Restart Claude Code after.

## 3. Verify
```bash
./scripts/doctor.sh
```

## 4. Get free API keys (20 min, worth it)
→ **[05-free-api-keys.md](05-free-api-keys.md)**
```bash
cp .env.example .env    # then paste keys in
./install.sh --mcp      # re-run: keyed MCP servers now activate
```

## 5. Set up claude.ai chat (10 min, manual — no script can do this)
→ **[09-claude-chat-setup.md](09-claude-chat-setup.md)**

## 6. Lock it down
→ **[06-security.md](06-security.md)**
```bash
./scripts/scan-skills.sh
```

---

## Then: pick your track

| You want to… | Go to |
|---|---|
| Stress-test an idea against several models | [07 — AI Council](07-ai-council.md) |
| Build the AI-security career | [08 — Pentesting stack](08-pentesting.md) |
| Make reels / shorts for a side hustle | `/edit-video`, `/short-form-edit` (installed) |
| Stop your essays sounding like AI | `/slopmonster` (installed) |
| Build a front-end that doesn't look generic | `/scroll-craft` (plugin) |
| Get grilled before an IB oral | `/grill-me` (installed) |

---

## Daily rhythm

```bash
cd ~/code/<project>
git pull
claude
# ... work ...
git add -A && git commit -m "what changed" && git push
```
