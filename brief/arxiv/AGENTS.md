# brief/arxiv - arXiv Brief Plugin Spec

## Role

This plugin is the arXiv-specific brief agent. It follows all generic rules from `brief/AGENTS.md` and adds paper-oriented expectations for academic information restoration.

---

## Scope

- **May operate on:** files under `brief/arxiv/`, the `briefs` table, and the `brief` row in `layer_state`
- **Read-only:** Markdown under `material/arxiv/` and the `materials` table
- **May update in upstream Markdown only:** the `brief` front matter backlink in referenced `material/arxiv/...` files when refreshing required backlinks
- **Must not operate on:** other source plugins or downstream layers

## Read Order

- Read `brief/AGENTS.md` first.
- Use this file only when the active source is arXiv.
- Treat it as a paper-specific output-shape overlay on top of the generic brief-layer fidelity, language, and gate rules.

---

## Processing Flow

1. Run `./scripts/init-db.sh` at repository root to ensure the schema is ready.
2. Filter the generic brief-layer ready query to material units where:
   - `source_kind='paper'`
   - `root_path` starts with `material/arxiv/`
   - the upstream unit id follows `material:paper:arxiv/{arxiv_id}`
   - `source_key = 'arxiv/{arxiv_id}'`
3. Generate the paper brief using the structure below.
4. Choose a concise note name in the vault language and write the result to `brief/arxiv/{note-name-in-vault-language}.md`.
5. Register the file in `briefs` and update `material/arxiv/{arxiv_id}.md` so its front matter points back to that localized brief note.
6. Create or update the brief-layer publish unit and member state exactly as described in `brief/AGENTS.md`.

---

## Brief Structure for Papers

```markdown
---
material: "[[material/arxiv/{arxiv_id}]]"
knowledge: []
tags: []
---

# {Paper brief title in vault language}

## {Core theme section in vault language}

## {Background and motivation section in vault language}

## {Method section in vault language}

## {Experimental results section in vault language}

## {Conclusions and contributions section in vault language}

## {Why it matters section in vault language}
```

> Business rule: the title and section headings should follow `vault-language.txt` and should help the user understand the paper's real contribution and structure instead of copying the source title mechanically.

---

## Quality Constraints

- Include the most important experimental numbers: accuracy, speedup, dataset names, or equivalent evidence.
- If the paper contains an architecture or workflow that fits Mermaid well, include a Mermaid diagram.
- Use LaTeX syntax for formulas: inline `$...$`, block `$$...$$`.
- Treat a paper as one coherent brief unless the source file literally bundles multiple independent papers or appendices as separate stand-alone pieces.
- If the paper is already concise and information-dense, keep nearly all important content and mainly improve structure, grouping, and readability.
- If the paper is verbose or repetitive, deduplicate repeated explanations but preserve the method, assumptions, evidence, limitations, and conclusions.

## Checklist

- [ ] `brief/AGENTS.md` was used as the baseline contract
- [ ] the source was confirmed to be an arXiv paper before applying this overlay
- [ ] the brief keeps the paper's contribution, method, evidence, limitations, and conclusions intact
- [ ] important experimental numbers and datasets were preserved when present
- [ ] formulas and architecture/workflow structure were rendered in a readable form when useful
- [ ] the resulting file was registered and linked exactly as required by the generic brief layer

---

## Tooling Reference

| Tool | Purpose |
|---|---|
| `sqlite3` | Same responsibilities as the generic brief layer |
| `python3` + `pyyaml` | Same front matter workflow as the generic brief layer |
