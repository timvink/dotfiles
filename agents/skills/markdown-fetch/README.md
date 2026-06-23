# markdown-fetch

Fetch web content as clean markdown using the markdown.new proxy. 80% fewer tokens than raw HTML.

## What It Does

- Converts any webpage to clean markdown automatically
- Uses Cloudflare's three-tier conversion pipeline
- Works on ANY website, not just Cloudflare-enabled ones
- Includes token estimation in response headers

## Background

Cloudflare's "Markdown for Agents" (February 2026) enables sites to serve markdown directly via content negotiation. markdown.new extends this to ANY website on the internet — even those that haven't enabled the feature.

**Reference:** https://blog.cloudflare.com/markdown-for-agents/