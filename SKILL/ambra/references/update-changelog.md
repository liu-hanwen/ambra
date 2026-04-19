# Reference: update `changelog/`

Use this after a workflow finishes downstream processing or a deep reorganization pass.

## Goal

Leave a human-readable update brief so the user can see what actually changed.

## Steps

1. Read `changelog/AGENTS.md`, `vault-language.txt`, and the final changed-note paths after backlink synchronization.
2. Identify durable results from the completed workflow:
   - created notes
   - updated notes
   - merged or retired notes
   - especially changed wisdom outputs and their new synthesis
   - new ideas, including new recommended topic directories under `idea/recommend/`
3. Write one new Markdown brief under `changelog/` with Obsidian links to the changed notes.
4. If no durable notes changed, still write a short brief that says the run completed but produced no durable downstream updates.

## Checklist

- [ ] `changelog/AGENTS.md` was consulted
- [ ] the brief uses the vault language
- [ ] changed wisdom and idea outputs were called out explicitly
- [ ] the brief contains Obsidian links to the affected notes
- [ ] no-change runs were reported honestly when applicable
