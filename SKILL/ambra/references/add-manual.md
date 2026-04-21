# Workflow: `ambra:add`

Use this when the user wants to manually add content—raw text, a URL, or a search keyword—to the vault and run it through the full pipeline immediately.

## Steps

1. Read `preflight.md`.
2. Read `user.md` if it exists.
3. Identify the content type provided by the user:
   - **URL** — starts with `http://` or `https://`, or is clearly a web link.
   - **Keyword** — a search phrase with no URL scheme; the user wants Ambra to find and fetch relevant pages.
   - **Text / file path** — raw article content or a local file path pointing to a PDF, EPUB, HTML, TXT, or Markdown file.
4. Ensure `material/manual/` exists. Create it if needed.
5. Ensure `material/manual/queue.md` exists with the expected YAML front-matter structure. Create it if needed:
   ```yaml
   ---
   pending_urls: []
   pending_keywords: []
   processed_urls: []
   processed_keywords: []
   ---
   ```
6. Register the content according to its type:
   - **URL:** append to `pending_urls` in `material/manual/queue.md` front matter.
   - **Keyword:** append to `pending_keywords` in `material/manual/queue.md` front matter.
   - **Raw text:** write directly to `material/manual/{slug}.md` with appropriate front matter (`source_url: ""`, `fetched_at` set to now, `format: text`). Do not add it to the queue file.
   - **Local file path:** copy or move the file to `material/manual/` under its original name (or a normalized slug). Do not add it to the queue file; it will be picked up as a file drop.
7. Read `material/AGENTS.md` and `material/manual/AGENTS.md`.
8. Run the manual source agent to process all pending queue items and any unprocessed dropped files:
   - Fetch URLs from `pending_urls`.
   - Search and fetch from `pending_keywords`.
   - Convert and register all unprocessed file drops.
9. Before downstream processing, read `vault-language.txt` and confirm the target vault language.
10. Read `AGENTS.md` and the relevant downstream layer contracts (`brief/AGENTS.md`, `knowledge/AGENTS.md`, `wisdom/AGENTS.md`, `idea/AGENTS.md`) and `references/update-changelog.md`.
11. Continue through the full downstream pipeline:
    - brief
    - knowledge
    - wisdom and idea (may run in parallel)
12. Synchronize bidirectional links if the workflow changed linked content.
13. Update `changelog/` with a linked summary of what changed.
14. If git maintenance is enabled or the user explicitly asks for a commit, make sure a git repository is active for the vault by reusing a parent repo or initializing a standalone repository if needed, then commit durable changes with an `ambra` marker in the subject.

## Checklist

- [ ] preflight passed
- [ ] `user.md` was consulted if present
- [ ] content type correctly identified (URL, keyword, or text/file)
- [ ] `material/manual/queue.md` exists with the expected structure
- [ ] content registered: URL appended to `pending_urls`, keyword to `pending_keywords`, or raw text/file written directly
- [ ] `material/AGENTS.md` and `material/manual/AGENTS.md` were read before processing
- [ ] manual source agent ran: pending URLs fetched, keywords searched and fetched, file drops converted
- [ ] every output registered in `materials` and gate tables
- [ ] `material/manual/memory.md` updated
- [ ] `vault-language.txt` consulted before downstream generation
- [ ] root and downstream layer contracts consulted before downstream processing
- [ ] downstream pipeline ran: brief → knowledge → wisdom + idea
- [ ] `changelog/` updated with a linked summary
- [ ] bidirectional links checked
- [ ] durable changes committed only when git maintenance was enabled or explicitly requested
