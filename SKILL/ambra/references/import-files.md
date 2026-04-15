# Workflow: `ambra:import`

Use this when the user provides local files.

## Steps

1. Read `preflight.md`.
2. Read `user.md` if it exists.
3. Determine the target source bucket under `material/{source}/`.
4. Place the files there.
5. Choose the correct ingestion path:
   - PDF -> `material/skills/pdf-to-markdown.md`
   - EPUB -> `material/skills/epub-to-markdown.md`
   - HTML -> `material/skills/html-to-markdown.md`
   - TXT -> normalize plain text into Markdown, then add front matter
   - Markdown -> minimal normalization plus front matter
6. Register the resulting material artifact and publish the ready unit.
7. Use `user.md` only for durable classification, prioritization, and downstream emphasis. Do not refuse an explicitly supplied file just because it is off-profile unless the user profile contains a hard exclusion the user still wants enforced.
8. Before downstream processing, read `vault-language.txt` and confirm the target vault language.
9. Read `AGENTS.md` and the relevant layer contracts before downstream processing.
10. If the imported material contains multiple clearly independent subcontents, ensure brief uses multipart handling instead of one blended summary.
11. Continue through downstream processing.
12. Check bidirectional links if linked content changed.
13. Commit durable changes.

## Checklist

- [ ] preflight passed
- [ ] `user.md` was consulted if present
- [ ] source bucket chosen or created
- [ ] file types classified correctly
- [ ] conversion or normalization completed
- [ ] material rows and ready units registered
- [ ] `vault-language.txt` consulted before downstream generation
- [ ] root and downstream layer contracts were consulted before downstream processing
- [ ] multipart brief handling applied when bundled independent subcontents were detected
- [ ] downstream processing completed
- [ ] bidirectional links checked
- [ ] durable changes committed to git
