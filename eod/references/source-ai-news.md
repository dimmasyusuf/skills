# AI News Source

Use this module for the `ai:` section.

## Rule

Include exactly one AI or developer-tooling item verified during report generation. Do not rely on model memory.

The item must be current for the report date when possible. If no same-day item is available after a reasonable search, use the most recent clearly dated developer-relevant item and make the date clear in the working notes before composing.

## Search Targets

Prefer primary or high-signal sources:

- official OpenAI, Anthropic, Google DeepMind, Meta AI, GitHub, Vercel, Supabase, Cloudflare, or browser/tooling blogs
- GitHub Blog and GitHub Changelog
- Hacker News front page or newest for engineering-relevant releases
- TLDR AI
- Latent Space
- official release notes for developer tools

Skip pure policy, fundraising, or general business news unless it materially affects engineering work.

## Extract

Capture:

- source title
- publication date
- canonical URL
- one-sentence relevance to AI, agents, coding tools, infra, or developer workflows

## Compose

Use this shape:

```text
ai:
<one current AI or developer-tooling news sentence>
<url>
```

Put the canonical source URL on its own bare line. Do not wrap it as `[source](url)`.
