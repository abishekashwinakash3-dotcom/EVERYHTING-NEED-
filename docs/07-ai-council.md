# 07 — AI Council

> *"AI COUNCIL FOR IDEAS"*

## The idea

One model has one set of biases. Ask the same question to several models in
parallel, then have Claude synthesise the answers and flag where they disagree.
**Disagreement is the signal** — it tells you where the question is genuinely
hard versus where the answer is settled.

Good for: choosing between architectures, stress-testing a business idea, checking
an essay thesis, deciding which university to target, any decision where being
wrong is expensive.

## Options

| Project | Backend | Best when |
|---|---|---|
| [0xAkuti/ai-council-mcp](https://github.com/0xAkuti/ai-council-mcp) | OpenRouter (multi-provider) | **Start here** — one key, several models, synthesised output |
| [Yersultan04/llm-council](https://github.com/Yersultan04/llm-council) | Multi-provider | 6 models in parallel; `ask_council`, `ask_quick`, `ask_model`, `list_models` |
| [YuChenSSR/multi-ai-advisor-mcp](https://github.com/YuChenSSR/multi-ai-advisor-mcp) | Ollama (local) | Free forever, private, needs a decent GPU |
| [gcpdev/llm-council-skill](https://github.com/gcpdev/llm-council-skill) | Skill, not MCP | Lightweight — brainstorm with other LLMs before planning |

## Setup (OpenRouter route)

**1.** Get an OpenRouter key → [openrouter.ai/keys](https://openrouter.ai/keys) — free, no card.
Put it in `.env` as `OPENROUTER_API_KEY`.

**2.** Install:
```bash
git clone https://github.com/0xAkuti/ai-council-mcp ~/code/ai-council-mcp
cd ~/code/ai-council-mcp
cat README.md            # ← follow ITS instructions, they're authoritative
```

**3.** Register it (adjust the command to match that README):
```bash
claude mcp add ai-council --scope user \
  -e OPENROUTER_API_KEY="$OPENROUTER_API_KEY" \
  -- python -m ai_council_mcp
```

**4.** Verify:
```bash
claude mcp get ai-council
```

> I've deliberately not hardcoded its run command into `install.sh` — this project
> moves, and a stale command that silently fails is worse than one honest manual step.
> Read its README, then wire it up. Five minutes.

## Cost

OpenRouter's `:free` models cost nothing but are rate-limited (~20 RPM / 50 RPD).
A council call is N requests, so a 5-model council burns 5 of those. Fine for a
few real decisions a day; not for a loop. Non-free models are cheap but not zero —
set a spend limit on your OpenRouter account before you build anything automated.

## Using it well

**Ask for disagreement, not consensus.** The value isn't a vote count.

Bad: *"Is this a good idea?"* → five models politely say yes.

Good:
> "Here's my plan: [plan]. Ask the council to each identify the single strongest
> reason this fails. Then tell me where they disagreed and why."

**Ask for the strongest counter-argument.** Models are agreeable by default. Force
the adversarial framing or you'll get flattery.

**Use it for decisions, not tasks.** Council for "which path", single model for
"write the code". Don't burn five calls on something one model does fine.
