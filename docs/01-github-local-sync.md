# 01 — GitHub remote → your local folder

> *"THE MOST IMPORTANT THING IS THAT I WANT github remote on my local folder access!"*

This is the whole answer. Read it once, do it once, and every repo you own lives
in a real folder on your machine that Claude Code can read, edit, and push from.

---

## What you're actually asking for

"GitHub remote on my local folder" = a **clone**. A clone is a normal folder on
your disk that remembers where it came from (its *remote*). You edit files like
any other folder; `push` sends changes up, `pull` brings changes down.

```
GitHub (cloud)                      Your laptop
┌────────────────────┐              ┌────────────────────┐
│ abishek.../AIS-OS  │◄── push ─────│ ~/code/AIS-OS      │
│      "origin"      │──── pull ───►│  (a real folder)   │
└────────────────────┘              └────────────────────┘
```

There is **no mounting, no syncing daemon, no Dropbox**. It's copy-down,
edit, copy-up. That's git.

---

## Step 1 — Install the tools

**Windows** (PowerShell as Admin):
```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
```

**macOS**:
```bash
xcode-select --install          # gives you git
brew install gh
```

**Linux (Debian/Ubuntu)**:
```bash
sudo apt update && sudo apt install -y git
sudo apt install -y gh          # or: see cli.github.com for the apt repo
```

Verify:
```bash
git --version
gh --version
```

---

## Step 2 — Log in to GitHub (once per machine)

```bash
gh auth login
```

Answer the prompts:
- **GitHub.com**
- **HTTPS** ← pick this, it's simpler than SSH and works behind school/uni firewalls
- **Login with a web browser** → copy the one-time code → paste in browser

That's it. `gh` stores a token in your OS keychain and teaches `git` to use it,
so you'll never be asked for a password again.

Confirm:
```bash
gh auth status
```

> **Why not SSH keys?** SSH is fine and slightly nicer long-term, but port 22 is
> blocked on a lot of school and campus networks. HTTPS via `gh` just works
> everywhere. If you want SSH anyway, see the appendix at the bottom.

---

## Step 3 — Set your identity (once per machine)

```bash
git config --global user.name  "Abishek Ashwin Akash"
git config --global user.email "mohan33133@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase false
```

---

## Step 4 — Clone your repos

One repo:
```bash
mkdir -p ~/code && cd ~/code
gh repo clone abishekashwinakash3-dotcom/AIS-OS
cd AIS-OS
```

**All of them at once** (this kit ships a script):
```bash
./scripts/sync-repos.sh
```

It clones every repo on your account into `~/code/`, and for ones already
cloned it pulls the latest instead. Safe to run daily. Run it on every new machine.

---

## Step 5 — Point Claude Code at the folder

```bash
cd ~/code/AIS-OS
claude
```

Claude Code now has that folder as its working directory. It reads the files,
edits them, and runs your tests. Nothing else to configure.

---

## Step 6 — The daily loop (memorise this)

```bash
git pull                       # 1. get the latest BEFORE you start
# ... work, or let Claude work ...
git add -A                     # 2. stage everything you changed
git commit -m "what changed"   # 3. save a checkpoint locally
git push                       # 4. send it to GitHub
```

Four commands. `pull` at the start, `push` at the end. If you only remember one
rule: **pull before you start, push before you close the laptop.**

Check what's going on at any time:
```bash
git status        # what's changed
git log --oneline -10   # recent history
```

---

## Working across machines (school laptop ⇄ home PC)

This is the payoff. On each machine, once:

```bash
gh auth login
./scripts/sync-repos.sh
```

Then the rule is just: **`git pull` when you sit down, `git push` before you leave.**
Your work follows you. If you forget to push and then pull elsewhere, you'll see
old files — that's not a bug, that's you forgetting to push.

---

## Making a new project

```bash
cd ~/code
mkdir my-new-thing && cd my-new-thing
git init
echo "# My New Thing" > README.md
git add -A && git commit -m "initial commit"
gh repo create my-new-thing --private --source=. --push
```

The last line creates it on GitHub *and* links it *and* pushes, in one go.
Use `--public` instead of `--private` when you want it on your profile for
university applications.

---

## When it goes wrong

| Error | What it means | Fix |
|---|---|---|
| `Authentication failed` | Token expired/missing | `gh auth login` again |
| `Updates were rejected... behind` | GitHub has commits you don't | `git pull` then `git push` |
| `CONFLICT (content): Merge conflict in X` | You and the remote edited the same lines | Open X, look for `<<<<<<<`, keep what you want, delete the markers, then `git add X && git commit` |
| `fatal: not a git repository` | You're in the wrong folder | `cd` into the cloned folder |
| `Permission denied (publickey)` | SSH not set up | Use HTTPS: `git remote set-url origin https://github.com/OWNER/REPO.git` |
| `Your local changes would be overwritten` | Uncommitted edits block the pull | `git stash` → `git pull` → `git stash pop` |

**Panic button** — you broke something local and just want GitHub's version:
```bash
git fetch origin
git reset --hard origin/main    # ⚠️ DESTROYS local uncommitted changes
```
Only run that when you're certain nothing local is worth keeping.

---

## Security: never commit secrets

Your `.env` file holds API keys. If you push it to a public repo, bots scrape it
within minutes and your keys get abused.

Every repo you make should have a `.gitignore` containing:
```
.env
.env.local
*.key
*.pem
node_modules/
__pycache__/
.DS_Store
```

This kit's `.gitignore` already does it. If you *have* pushed a key by accident:
**revoke it at the provider immediately** — deleting the file doesn't help, it's
still in git history.

---

## Appendix — SSH instead of HTTPS

If you'd rather use SSH keys:

```bash
ssh-keygen -t ed25519 -C "mohan33133@gmail.com"     # press Enter 3x
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
ssh -T git@github.com                                # should greet you by username
```

Then clone with `git clone git@github.com:OWNER/REPO.git`.

---

## Cheat sheet

```bash
gh auth login                      # log in (once per machine)
gh repo clone OWNER/REPO           # bring a repo down
./scripts/sync-repos.sh            # bring ALL your repos down / update them
git pull                           # get latest
git add -A && git commit -m "msg"  # checkpoint
git push                           # send up
git status                         # what changed
gh repo create NAME --private --source=. --push   # new repo from current folder
gh repo list                       # what do I even own
```
