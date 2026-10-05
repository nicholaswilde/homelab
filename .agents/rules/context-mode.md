# Context-Mode Rules

Keep raw bytes out of the conversation context. Use context-mode MCP tools to process data in-sandbox:

- `ctx_batch_execute`: Run multiple commands in parallel, auto-index, and return matched sections (replaces sequential bash + grep).
- `ctx_execute`: Run JavaScript or Shell code over data in-sandbox and print only derived answers.
- `ctx_execute_file`: Analyze large files in-sandbox via `FILE_CONTENT` instead of dumping full content.
- `ctx_fetch_and_index`: Fetch web pages and index them into FTS5 for efficient re-querying.
- `ctx_index`: Chunk markdown/documentation into FTS5 for fast search.
- `ctx_search`: Query indexed content and session memory.
- `ctx_stats`: View token savings statistics.

When source > 200 lines/KB or multi-source, use context tools. Use native shell only for state-mutating commands (git, mkdir, rm, mv) or short fixed outputs.
