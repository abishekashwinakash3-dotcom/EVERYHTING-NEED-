# 05 — Free API keys

Source list: [mnfst/awesome-free-llm-apis](https://github.com/mnfst/awesome-free-llm-apis)
(one of the links you sent — it's good, and maintained).

> **I can't create these for you.** Each needs your email, a browser, and sometimes
> a phone number. What follows is the ranked shortlist so you spend 20 minutes, not
> three hours. Limits change — check the provider page if something looks off.

## Do these three first (15 min)

| # | Provider | Free tier | Card? | Sign up |
|---|---|---|---|---|
| 1 | **Google Gemini** | Most generous free tier available | No | [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey) |
| 2 | **Groq** | Free tier, extremely fast LPU inference | No | [console.groq.com/keys](https://console.groq.com/keys) |
| 3 | **OpenRouter** | One key → many models; 17 carry a `:free` suffix. 20 RPM / 50 RPD | No | [openrouter.ai/keys](https://openrouter.ai/keys) |

**Why this order.** Gemini gives you the most raw free usage. Groq gives you speed —
it's the one to use when you're iterating and waiting hurts. OpenRouter gives you
*breadth* from a single key, which is exactly what the [AI Council](07-ai-council.md)
needs to query several models at once.

⚠️ **Gemini free tier: your prompts may be used by Google to improve their products.**
Don't put anything confidential through it. Same caution for most free tiers.

## Worth adding (10 min)

| Provider | Free tier | Sign up |
|---|---|---|
| **Mistral** | Free mode on by default, ~$10/mo credits, no card | [console.mistral.ai/api-keys](https://console.mistral.ai/api-keys) |
| **NVIDIA NIM** | 100+ models, free with Developer Program. 40 RPM / 10,000 RPD | [build.nvidia.com](https://build.nvidia.com/explore/discover) |
| **Cloudflare Workers AI** | 10,000 Neurons/day, 75+ models | [dash.cloudflare.com](https://dash.cloudflare.com/profile/api-tokens) |
| **Cohere** | 1,000 calls/month — **non-commercial only** | [dashboard.cohere.com/api-keys](https://dashboard.cohere.com/api-keys) |
| **Hugging Face** | Small monthly inference credit, thousands of models | [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) |

> Cohere's non-commercial restriction is real. Fine for IB work and learning.
> Not fine for a side hustle that charges money. Read the terms before you build on it.

## No signup at all

| Provider | Notes |
|---|---|
| **OVHcloud AI Endpoints** | Permanent free anonymous tier, 2 RPM per IP per model, no key. EU-hosted. |
| **LLM7.io** | Anonymous access with no key; a free token raises limits. 10 RPM anonymous. |
| **Kilo Code** | No card, no key. Auto-router. ~200 requests/hour. |

Good for quick experiments and for code you don't want to put a key in.

## Requires extra verification

**ModelScope** and **SiliconFlow** offer real free tiers but require Chinese
real-name / Alibaba Cloud verification. Skip unless you specifically need them.

## Also worth having (not LLMs)

| Service | Free tier | For |
|---|---|---|
| **Supabase** | Postgres + auth + storage | The best free backend for shipping a side project |
| **Exa** | Free tier | Neural search for agents |
| **Tavily** | 1,000 credits/mo | Cited search — good for EE and IA research |
| **Firecrawl** | Free tier | Site → markdown |
| **Cloudflare Pages / Vercel** | Generous | Hosting whatever you build |

## Wiring them up

```bash
cp .env.example .env
# paste your keys
./install.sh --mcp      # keyed MCP servers activate
./scripts/doctor.sh     # confirms which keys are set
```

## Key hygiene — this matters

Leaked keys get scraped off GitHub by bots **within minutes**.

1. **`.env` is gitignored here.** Keep it that way. `./scripts/doctor.sh` verifies it.
2. **Never paste a key into a chat, issue, Discord, or screenshot.**
3. **Never put a key in a shell command** — it lands in `~/.bash_history`.
4. **If a key leaks, revoke it at the provider.** Deleting the file does nothing —
   it's still in git history.
5. Set spending limits where the provider offers them, even on free tiers.

## Reading the limits

- **RPM** requests/minute · **RPD** requests/day · **TPM** tokens/minute
- A free tier is a *rate* limit, not a quality limit — models are usually the same.
- Hitting a limit gives you HTTP 429. Back off and retry; don't hammer it.
