# material/arxiv - Source Plugin Spec

## Role

The arXiv source agent fetches academic papers from [arXiv.org](https://arxiv.org), converts PDFs into Markdown, and registers the result in both `materials` and the pipeline gate tables. It supports incremental fetching and keyword-based search.

This plugin inherits the shared ingestion rules from `material/AGENTS.md` and adds only arXiv-specific source behavior.

---

## Scope

- **May operate on:** everything under `material/arxiv/` plus the `materials` table
- **May operate on gate tables:** material-layer `pipeline_units` and `pipeline_unit_members` created by this source plugin
- **Must not operate on:** other source plugins or downstream layers such as `brief/` and `knowledge/`

## Read Order

- Read `material/AGENTS.md` first.
- Use this file only as the arXiv-specific delta for fetching, filtering, and bookkeeping.
- Keep the generic material-layer registration and gate rules from the parent contract intact.

---

## Source Profile

| Property | Value |
|---|---|
| Site | https://arxiv.org |
| Type | Open-access academic paper platform |
| Access method | HTTPS API plus web pages |
| Main API | `http://export.arxiv.org/api/query` (Atom feed) |
| PDF endpoint | `https://arxiv.org/pdf/{arxiv_id}` |

---

## Incremental Strategy

1. Read the list of already fetched `arxiv_id` values from `memory.md`.
2. Run search or feed fetching.
3. Skip any `arxiv_id` already recorded in `memory.md`.
4. Process only new papers, then append each processed `arxiv_id` back to `memory.md`.

---

## Filtering Rules

- Prefer papers submitted within the last 30 days.
- Skip withdrawn papers.
- If a PDF is larger than 50 MB, record a warning in `memory.md` and skip it.
- For keyword search, fetch only the top N most relevant results. Default to 10 if the request does not specify N.
- If `user.md` defines durable topic filters, exclusions, or result-count preferences for this source, apply them before falling back to the defaults above.

---

## Processing Flow

### Incremental Fetch Mode

0. Run `./scripts/init-db.sh` at repository root so the local schema is ready.
1. Read processed `arxiv_id` values from `memory.md`.
2. Use `skills/search-paper.md` to run the preset topic search or feed fetch.
3. For each new paper:
   1. call `skills/fetch-paper.md` to download the PDF and convert it to Markdown
   2. write front matter with `source_url`, `fetched_at`, and `format: pdf`
   3. register the output in `materials` and publish a material-layer ready unit:
      ```bash
      ./scripts/sqlite.sh "INSERT OR IGNORE INTO materials (path) VALUES ('material/arxiv/{arxiv_id}.md');"
      ./scripts/sqlite.sh "
        INSERT OR IGNORE INTO pipeline_units
          (unit_id, layer, unit_type, source_kind, source_key, root_path, required_count)
          VALUES ('material:paper:arxiv/{arxiv_id}', 'material', 'single', 'paper', 'arxiv/{arxiv_id}', 'material/arxiv/{arxiv_id}.md', 1);

        INSERT OR IGNORE INTO pipeline_unit_members
          (unit_id, member_path, member_role, member_type)
          VALUES ('material:paper:arxiv/{arxiv_id}', 'material/arxiv/{arxiv_id}.md', 'required', 'file');

        UPDATE pipeline_unit_members
          SET member_status='done', member_version=member_version+1, updated_at=datetime('now')
          WHERE unit_id='material:paper:arxiv/{arxiv_id}' AND member_path='material/arxiv/{arxiv_id}.md';

        UPDATE pipeline_units SET
          done_count = 1,
          blocked_count = 0,
          status = 'ready',
          ready_version = ready_version + 1,
          ready_at = datetime('now'),
          updated_at = datetime('now')
        WHERE unit_id='material:paper:arxiv/{arxiv_id}';
      "
      ```
   4. append the `arxiv_id` to `memory.md`
4. Update the source plugin timestamp in `memory.md`.

### Keyword Search Mode

1. Read keywords from the user request or from `memory.md` under a field such as `pending_searches`.
2. Call `skills/search-paper.md`.
3. Process each new result exactly as in incremental fetch mode.

---

## Outputs

- **File:** `material/arxiv/{arxiv_id}.md`
- **Business row:** `materials.path = material/arxiv/{arxiv_id}.md`
- **Gate row:** `pipeline_units.unit_id = material:paper:arxiv/{arxiv_id}`

Front matter example:

```yaml
---
source_url: "https://arxiv.org/abs/2401.12345"
fetched_at: "2026-04-11T08:00:00Z"
format: "pdf"
arxiv_id: "2401.12345"
title: "Paper Title Here"
authors:
  - "Author One"
  - "Author Two"
brief: ""
---
```

---

## Tooling Reference

| Tool | Purpose |
|---|---|
| `sqlite3` | Register rows and publish gate units |
| `curl` | Query the arXiv API and download PDFs |
| `pandoc` / `pdftotext` | Convert PDF to Markdown |
| `skills/search-paper.md` | Search arXiv by keyword |
| `skills/fetch-paper.md` | Download, convert, and publish a paper |

Use the shared Python helper for front matter writes instead of shell-level YAML mutation.

---

## Error Handling

- **PDF conversion failure:** record the error in `memory.md`, do not register the paper, and leave no ready unit behind.
- **Network timeout:** retry up to three times with a five-second backoff, then record and skip.
- **Paper already exists:** rely on `INSERT OR IGNORE`; treat the operation as idempotent.

## Checklist

- [ ] `material/AGENTS.md` was read first
- [ ] arXiv-specific filters were applied without breaking the generic material contract
- [ ] `user.md` was consulted when it defines durable arXiv filtering preferences
- [ ] only new, non-withdrawn papers within the chosen fetch scope were processed
- [ ] every successful paper write was registered in `materials` and the material-layer gate
- [ ] `memory.md` was updated with processed IDs, timestamps, and any skipped-paper warnings
