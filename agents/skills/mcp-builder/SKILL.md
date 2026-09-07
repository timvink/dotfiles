---
name: mcp-builder
description: Build or modify an MCP server that exposes an external service through tools, resources, or prompts. Includes Python and TypeScript implementation references.
license: Complete terms in LICENSE.txt
source: https://github.com/anthropics/skills/tree/main/skills/mcp-builder
local-edits: Short routing guide; implementation scope and evaluation effort follow the requested change rather than exhaustive API coverage or a fixed ten-question suite.
---

# MCP server development

Start with the workflows the server must support. Expose enough of the API to
complete those workflows; do not expand a narrow request into exhaustive coverage.
Follow an existing server's language and architecture. For a new server, choose
Python or TypeScript based on its environment and maintenance needs.

## Load the relevant reference

- For tool design, transports, authentication, and pagination, read
  [reference/mcp_best_practices.md](reference/mcp_best_practices.md).
- For Python implementation, read
  [reference/python_mcp_server.md](reference/python_mcp_server.md).
- For TypeScript implementation, read
  [reference/node_mcp_server.md](reference/node_mcp_server.md).
- For an evaluation suite, read [reference/evaluation.md](reference/evaluation.md)
  only when realistic multi-tool evaluation is needed or requested.

Verify uncertain APIs against the installed SDK and current official documentation
through Context7 when available. Consult the MCP specification for protocol
questions. Reference examples are starting points; adapt their scope and versions
to the project.

## Design constraints

Use consistent action-oriented tool names and descriptions that explain when to
call each tool. Validate inputs, return focused results, paginate large datasets,
and make errors actionable. Use structured output where the SDK supports it.
Set read-only, destructive, idempotent, and open-world annotations accurately;
annotations do not replace authorization checks.

Keep credentials out of tool output. Make mutations explicit and avoid hidden
writes in read tools. Choose stdio for local process integration or an appropriate
HTTP transport for remote clients.

## Verify the requested behavior

Run the project's build and checks, then exercise changed tools through an MCP
client or Inspector. Cover relevant error paths and response schemas. For a new
server or a substantial workflow change, test representative end-to-end tasks.
Scale the number and complexity of evaluations to the change; a small tool fix
does not require a ten-question XML suite.
