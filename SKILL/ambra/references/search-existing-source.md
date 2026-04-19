# Workflow: `ambra:search`

Use this when the user wants content discovered through an already registered source.

## Steps

1. Read `preflight.md`.
2. Read `user.md` if it exists.
3. Identify the relevant source plugin under `material/{source}/`.
4. Read that source's search instructions.
5. Use `user.md` to refine ranking, default result count, or stable filters unless the current user request already specifies them.
6. Run the search using the user's query and intended result count.
7. Fetch and convert the selected item(s).
8. Register `materials` rows and publish ready material units.
9. Before downstream processing, read `vault-language.txt` and confirm the target vault language.
10. Read `AGENTS.md`, the relevant layer contracts, and `references/update-changelog.md` before continuing through downstream processing.
11. If any ingested material item is a bundled issue or digest with clearly independent subcontents, ensure brief uses multipart handling instead of one blended summary.
12. Continue through downstream processing so the ingested material reaches brief, knowledge, wisdom, and idea.
13. Synchronize bidirectional links if the workflow changed linked content.
14. Update `changelog/` with a linked summary of what changed.
15. If git maintenance is enabled or the user explicitly asks for a commit, commit durable changes with an `ambra` marker in the subject.

## Checklist

- [ ] preflight passed
- [ ] `user.md` was consulted if present
- [ ] correct source plugin selected
- [ ] search query and result scope align with user intent
- [ ] selected items fetched or refreshed
- [ ] material rows and ready units registered
- [ ] `vault-language.txt` consulted before downstream generation
- [ ] root and downstream layer contracts were consulted before downstream processing
- [ ] multipart brief handling applied when bundled independent subcontents were detected
- [ ] downstream processing completed
- [ ] `changelog/` updated with a linked summary
- [ ] bidirectional links checked
- [ ] durable changes committed only when git maintenance was enabled or explicitly requested
