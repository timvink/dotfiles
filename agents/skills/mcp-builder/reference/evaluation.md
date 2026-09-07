# Evaluate an MCP workflow

Use end-to-end evaluation when a new server or substantial tool change needs
verification beyond unit tests. Choose representative tasks for the requested
workflows; there is no fixed question count or minimum number of tool calls.
A direct lookup is a valid test when direct lookup is the intended behavior.

## Choose cases

Inspect the server's tools and a bounded sample of accessible data. Use read-only
operations for discovery and paginate large results. Select cases that reveal
whether the tool names, input schemas, errors, and output shapes let a client
complete the task without knowledge of the implementation.

Include multi-tool cases when the workflow crosses resources, requires pagination,
or needs aggregation. Include relevant missing-data and invalid-input cases.
Keep each case independent so it can run alone.

Verify expected answers yourself. Prefer fixtures or a known snapshot; historical
data is not automatically immutable. Record enough context to tell a regression
from source data that changed. Specify units and answer formatting where exact
comparison matters.

## Running cases

A deterministic test client is sufficient for protocol and schema checks. An LLM
evaluation can test tool discovery and multi-step use, but adds model cost and
variability. Use it when those behaviors matter, not merely because the server
uses MCP. Keep mutation tests in an isolated environment with explicit task
authorization; the read-only suite should not require writes.

The bundled `scripts/evaluation.py` accepts XML question/answer pairs and calls
an external model. Read its command-line help and dependency requirements before
using it. Do not transmit private evaluation data or incur model usage without
appropriate authorization for that run.

```xml
<evaluation>
  <qa_pair>
    <question>In the test fixture, which project has the most completed tasks? Return its name.</question>
    <answer>Website Redesign</answer>
  </qa_pair>
</evaluation>
```

Use the project's existing evaluation format if it has one. For the bundled
runner, escape XML special characters and give an unambiguous expected value.

## Assess failures

Inspect the tool-call trace. Distinguish incorrect tool behavior, unclear tool
selection, incomplete pagination, wrong answer formatting, and changed source
data. Fix the responsible layer and rerun the affected cases. Report what was
covered and any remaining limits; a passing answer alone does not validate all
server workflows.
