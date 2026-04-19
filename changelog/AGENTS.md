# Changelog - Update Brief Spec

## Role

The root agent writes concise update briefs under `changelog/` after a completed full downstream Ambra pass.

## Output rule

- Create one Markdown note per completed full downstream run, dream pass, or downstream-complete ingestion workflow.
- Use `vault-language.txt` for the filename, title, headings, and prose.
- Use Obsidian wikilinks to the affected notes.
- Build the brief after backlink synchronization so it reflects the final durable change set.
- Changelog links are observational only; they do not require reverse backlinks.

## Suggested structure

```markdown
# {Run summary title in vault language}

> Run type: ambra:run | ambra:dream | downstream-complete ingestion
> Completed at: {datetime}

## {What changed section in vault language}

## {Updated wisdom section in vault language}

## {Updated ideas section in vault language}

## {Key new insight section in vault language}

## {Follow-up section in vault language}
```

## Quality constraints

- Name the concrete notes that changed instead of speaking only in abstractions.
- Mention which wisdom notes changed and what new synthesis or insight they gained.
- Mention new recommended idea topics when `idea/recommend/` changed.
- If a run produced no durable note changes, say that explicitly instead of faking novelty.
