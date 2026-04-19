# Changelog - Update Brief Spec

## Role

The root agent writes concise update briefs under `changelog/` after a completed full downstream Ambra pass.

## Loading Rule

- Read this file only after the root agent has determined that a full downstream run, dream pass, or downstream-complete ingestion workflow has finished.
- Treat this folder as a root-owned reporting surface, not as a new downstream knowledge layer.

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

## Checklist

- [ ] the workflow actually completed downstream processing or a dream pass
- [ ] backlink synchronization already finished before drafting the brief
- [ ] filename, title, headings, and prose follow `vault-language.txt`
- [ ] concrete changed notes are linked with wikilinks
- [ ] changed wisdom and idea outputs received extra attention
- [ ] the key new insight is stated plainly
- [ ] a no-durable-change run is reported honestly instead of padded
