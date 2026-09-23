# 03 — Skills

## What a skill actually is

A folder with a `SKILL.md` inside. The frontmatter has a `name` and a
`description`; the body is instructions. When your request matches the
description, Claude loads the body and follows it.

```
~/.claude/skills/
  slopmonster/
    SKILL.md          ← name + description + instructions
    references/       ← optional supporting files
    tools/            ← optional scripts the skill can run
```

That's the whole format. **Which also means a skill can contain scripts that run
on your machine as you** — read [06-security.md](06-security.md) before installing
anything you didn't write.

## Where they live

| Scope | Path | Applies to |
|---|---|---|
| Personal | `~/.claude/skills/` | every project |
| Project | `<repo>/.claude/skills/` | that repo only, shared via git |
| Plugin | bundled in a plugin | wherever the plugin is enabled |

`install.sh --skills` writes to the personal scope so they follow you everywhere.

## What's installed

### AIS-OS — life/career operating system
| Skill | Use it for |
|---|---|
| `/onboard` | Day-1 setup wizard. Run this first. |
| `/audit` | Scores your setup, finds stale/unlinked stuff |
| `/link` | Connects projects and context together |
| `/level-up` | Picks your biggest constraint, ships one fix |
| `/3d-brain` | Visualises your knowledge/project graph |
| `/grill-me` | **Interrogates you on a plan and saves every answer.** Use before IB orals, interviews, and uni applications. |

### HyperFrames — video from the terminal
| Skill | Use it for |
|---|---|
| `/make-a-video` | Start here if you've never used it. Concept → finished MP4. |
| `/edit-video` | Full long-form pipeline |
| `/short-form-edit` | Reels / Shorts / ads |
| `/cut-silences`, `/cut-mistakes` | Remove dead air, stutters, bad takes |
| `/video-storytelling` | Visual layer design — stops edits looking AI-made |
| `/website-to-hyperframes` | Paste a URL → promo video |
| `/gsap`, `/style-library`, `/hyperframes-cli` | Animation + tooling reference |

### SlopMonster
| Skill | Use it for |
|---|---|
| `/slopmonster` | Lints prose for AI tells, rewrites, re-lints. **Run on every essay, TOK draft, and personal statement.** |

Plus 292 more from the ECC plugin — see [04-plugins.md](04-plugins.md).

## Using one

Usually you just describe what you want and the right skill loads itself:

> "turn this recording into a 60-second reel"

Or call it explicitly: `/short-form-edit`

## Writing your own

```bash
claude plugin init my-skill
```
Scaffolds `~/.claude/skills/my-skill/`. Edit `SKILL.md`:

```markdown
---
name: ib-lab-report
description: Write an IB Physics IA lab report section. Use when the user mentions IA, lab report, uncertainty analysis, or DCP.
---

# IB Physics Lab Report

## Structure
1. Research question with independent/dependent/controlled variables
2. Raw data table — every value with absolute uncertainty
3. Processed data — propagate uncertainties, don't guess them
...
```

Rules that make skills actually fire:
- **description does the work.** Write it as "Use when the user…" with concrete
  trigger words. A vague description never triggers.
- **Keep SKILL.md short.** Push detail into `references/` and point at it.
- **One job per skill.** Split rather than branch.

Restart Claude Code to load it.

## Updating / removing

```bash
./install.sh --skills          # re-pull bundles (old copies → ~/.claude/skill-backups/)
rm -rf ~/.claude/skills/NAME   # remove one
ls ~/.claude/skills/           # what do I have
./scripts/doctor.sh            # flags duplicates and non-skill dirs
```

Replaced versions go to `~/.claude/skill-backups/<timestamp>/`, **never** beside
the original — anything with a `SKILL.md` inside `skills/` is loaded as a live
skill, so a `.bak` sitting there would shadow-compete with the real one.

If a bundle can't be cloned from your fork (no `gh auth login` yet), the
installer falls back to the upstream repo automatically and tells you it did.

## A second skill source: the Vercel `skills` CLI

[vercel-labs/skills](https://github.com/vercel-labs/skills) is the official
package manager for the broader open agent-skills ecosystem — the same tool
behind [skills.sh](https://skills.sh/). It's a genuinely different mechanism
from everything above, so it gets its own install step:

```bash
./install.sh --vercel-skills
```

**How it differs from the rest of this kit:**

| | `install.sh --skills` (AIS-OS, HyperFrames, SlopMonster) | `install.sh --vercel-skills` |
|---|---|---|
| Install location | copied into `~/.claude/skills/<name>/` | symlinked from a universal `~/.agents/skills/<name>/`, shared across every agent it detects (Claude Code, Cursor, Codex, …) |
| Security scan | every skill scanned by `claude-skill-antivirus` before it's placed — see [06](06-security.md) | **not scanned** — there's nothing to scan-then-copy, and scanning a live shared symlink after the fact wouldn't mean much. npm's own registry is the only trust boundary. |
| In `--all`? | yes | **no, by design.** Folding it into `--all` would quietly break the guarantee that everything `--all` installs went through the scanner. Run it as its own explicit step so that stays true. |

**What ships today:** `vercel-labs/skills@find-skills` — a meta-skill that
teaches Claude how to search and recommend *other* skills from the ecosystem
using `npx skills find` / `npx skills add`. Read before installing: pure
instructional markdown, no scripts, no network calls beyond the documented
`npx skills` commands.

**Using the CLI directly**, once `find-skills` is installed — just ask Claude
things like *"is there a skill for X"* and it'll search for you, or run it
yourself:

```bash
npx skills find react performance      # search by keyword
npx skills add owner/repo@skill-name   # install a specific one
npx skills update                      # update everything installed this way
```

Same caution as anything in [06](06-security.md) applies harder here, since
there's no scan step: check install counts and source reputation (`vercel-labs`,
`anthropics` are more trustworthy than an unknown author) before installing
something this CLI surfaces.
