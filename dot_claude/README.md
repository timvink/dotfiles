# Reproduce my claude setup

## MCP servers

```bash
# writes to ~/.claude.json
claude mcp add --transport http notion https://mcp.notion.com/mcp
claude mcp add --transport http activecampaign https://stilstaanbijjezelf1.activehosted.com/api/agents/mcp/http

# context7 via OAuth (keyless) — note the dedicated /mcp/oauth endpoint, and
# user scope so it's available in every project as a single definition.
# https://context7.com/docs/howto/oauth
claude mcp add --transport http context7 https://mcp.context7.com/mcp/oauth -s user
claude mcp login context7
```