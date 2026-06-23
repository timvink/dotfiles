---
name: markdown-fetch
description: |
  Fetch web content as clean markdown using markdown.new proxy. Use when:
  (1) researching any topic online, (2) reading documentation or blog posts,
  (3) analyzing webpage content, (4) any web_fetch where you need the text content.
  Reduces token usage by 80% compared to raw HTML. Skip only for API endpoints,
  raw files, or when you specifically need HTML structure for scraping.
license: MIT
metadata:
  author: jeremyknows (original), timvink (enhancements)
  version: "1.0.1"
---

# Markdown Fetch

Fetch web content as clean markdown, not HTML bloat.

**TL;DR:** Prepend `markdown.new/` to any URL → 80% fewer tokens.

## Why This Matters

HTML wastes tokens. A typical blog post:
- **HTML:** 16,000 tokens
- **Markdown:** 3,000 tokens
- **Savings:** 80% reduction

More content fits in your context window. Lower costs. Better results.

## How It Works

**markdown.new** is a universal proxy that converts any webpage to markdown:

1. **Primary:** Tries Cloudflare's native `Accept: text/markdown` content negotiation
2. **Fallback 1:** Workers AI `toMarkdown()` conversion
3. **Fallback 2:** Browser Rendering API for JS-heavy pages

Every request gets the best possible markdown.

## Usage

### Basic Pattern

Prepend `markdown.new/` to any URL:

```
# Instead of:
web_fetch url="https://docs.example.com/guide"

# Use:
web_fetch url="https://markdown.new/https://docs.example.com/guide"
```

### Examples

Basic web fetch:

```
# blog
web_fetch url="https://markdown.new/https://blog.cloudflare.com/markdown-for-agents/"
# docs
web_fetch url="https://markdown.new/https://nextjs.org/docs/app/building-your-application"
# news article
web_fetch url="https://markdown.new/https://www.nytimes.com/2026/02/15/technology/ai-agents.html"
```

Control the conversion method and image handling via query parameters or POST body.

| PARAMETER | VALUES | DEFAULT |
| :--- | :--- | :--- |
| `method` | `auto`, `ai`, `browser` | `auto` |
| `retain_images` | `true`, `false` | `false` |

Examples:

```
# URL with query parameters
https://markdown.new/https://example.com?method=browser&retain_images=true

# Workers AI with images retained
curl -s 'https://markdown.new/' \ -H 'Content-Type: application/json' \ -d '{"url": "https://example.com", "method": "ai", "retain_images": true}'

# Force browser rendering for heavy JS page
curl -s 'https://markdown.new/' \ -H 'Content-Type: application/json' \ -d '{"url": "https://example.com", "method": "browser"}'
```


## When to Skip markdown.new

Use raw fetch (without markdown.new) when:

- **API endpoints** — Already return JSON/text, no conversion needed
- **Raw files** — `.txt`, `.md`, `.json`, `.csv` files
- **HTML scraping** — Need specific elements, attributes, or form structure
- **Binary content** — Images, PDFs (though markdown.new handles these too)
- **Internal/private URLs** — Don't proxy sensitive content through external services
- **Paywalled content** — markdown.new can't bypass authentication

## Response Format

Clean Markdown with metadata headers, including token count via x-markdown-tokens. For example:

```markdown
content-type: text/markdown; charset=utf-8 x-markdown-tokens: 725 // estimated token count vary: accept --- title: Markdown for Agents --- # Introducing Markdown for Agents The way content and businesses are discovered online is changing rapidly. Now the traffic is increasingly coming from AI crawlers and agents that demand structured data...
```

## Token Estimation

The response includes an `x-markdown-tokens` header with estimated token count. Use this for:
- Context window management
- Chunking decisions
- Cost estimation

## Troubleshooting

| Issue | Solution |
|-------|----------|
| 500 error from markdown.new | Site may block proxies — try direct fetch |
| 429 Too Many Requests | markdown.new has generous limits (~500/day), but if you hit them, space out requests. Consider caching results. |
| Content looks incomplete | JS-heavy page — markdown.new uses browser rendering as fallback |
| Need HTML structure | Skip markdown.new, use raw `web_fetch` |
| Authenticated or paywalled content | Skip markdown.new, fetch directly with proper authentication headers |
| Rate limited | Space out requests, markdown.new has generous limits |

## Privacy & Security

**markdown.new is an external proxy.** All URLs you fetch pass through Cloudflare's infrastructure.

- ✅ Fine for: Public docs, blogs, news, research
- ❌ Avoid for: Internal company URLs, authenticated sessions, sensitive data

If privacy is critical, fetch directly and accept the token overhead.
