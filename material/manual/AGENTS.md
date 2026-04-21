# material/manual - Source Plugin Spec

## Role

The manual source agent is a default, always-available inbox that lets users queue arbitrary content—raw text files, URLs, or search keywords—and have Ambra process it on the next run.

This plugin inherits the shared ingestion rules from `material/AGENTS.md` and adds only manual-source–specific behavior.

---

## Scope

- **May operate on:** everything under `material/manual/` plus the `materials` table
- **May operate on gate tables:** material-layer `pipeline_units` and `pipeline_unit_members` created by this source plugin
- **Must not operate on:** other source plugins or downstream layers such as `brief/` and `knowledge/`

## Read Order

- Read `material/AGENTS.md` first.
- Use this file only as the manual-source–specific delta for queue processing, fetching, and bookkeeping.

---

## Input Modes

### 1. File Drop

Users place files directly in `material/manual/`. Supported formats: Markdown (`.md`), plain text (`.txt`), PDF, EPUB, HTML.

- Markdown and plain text: normalize and add front matter.
- PDF: use `material/skills/pdf-to-markdown.md`.
- EPUB: use `material/skills/epub-to-markdown.md`.
- HTML: use `material/skills/html-to-markdown.md`.

A dropped file is considered **unprocessed** if it lacks a `fetched_at` front-matter field or if it does not yet have a matching row in `materials`.

### 2. URL Queue

Users add one URL per line under the `pending_urls` section of `material/manual/queue.md`. The agent fetches each URL using `material/skills/web-fetch.md`, converts the result to Markdown, writes it as `material/manual/{slug}.md`, and moves the entry from `pending_urls` to `processed_urls`.

### 3. Keyword Queue

Users add one keyword or phrase per line under the `pending_keywords` section of `material/manual/queue.md`. The agent executes a web search using `skills/web-search.md`, selects the top results, fetches and converts each result URL (same as URL queue), and moves the entry to `processed_keywords`.

---

## Queue File Format

`material/manual/queue.md` uses YAML front matter. Create it if it does not exist. The initial empty state looks like this:

```yaml
---
pending_urls: []
pending_keywords: []
processed_urls: []
processed_keywords: []
---
```

After the user adds items, the populated state looks like this:

```yaml
---
pending_urls:
  - "https://example.com/article"
pending_keywords:
  - "machine learning transformers"
processed_urls: []
processed_keywords: []
---
```

Keep the body of the file empty or use it for free-form notes; the agent reads and writes only the front-matter fields above.

---

## Slug Generation

- **URL items:** derive the slug from the URL hostname and path, normalized to lowercase ASCII with hyphens; prefix with `YYYYMMDD-` from today's date. Example: `20260421-example-com-article`.
- **Keyword items:** slugify the keyword phrase and prefix with `YYYYMMDD-kw-`. Example: `20260421-kw-machine-learning-transformers`.
- **File drops:** keep the original filename for Markdown/text; for binary formats (PDF, EPUB) use the original stem as the slug.

Deduplicate slugs by appending `-2`, `-3`, and so on if a file with the same name already exists.

---

## Processing Flow

### Step 0 – Preflight

```bash
./scripts/init-db.sh >/dev/null
python3 -c "import yaml; print('pyyaml ok')"
pandoc --version >/dev/null
curl --version >/dev/null
```

### Step 1 – Scan File Drops

```bash
find material/manual -maxdepth 1 -type f \
  \( -name "*.md" -o -name "*.txt" -o -name "*.pdf" \
     -o -name "*.epub" -o -name "*.html" \) \
  ! -name "queue.md" ! -name "memory.md"
```

For each file without `fetched_at` in its front matter, and without a matching `materials` row:

1. Convert if needed (PDF/EPUB/HTML).
2. Add front matter (`source_url` set to the file path or empty string, `fetched_at` set to now, `format` set to the source file type).
3. Register in `materials` and publish a ready unit (see Gate Operations below).
4. Append the processed filename to `memory.md`.

### Step 2 – Process URL Queue

Read `pending_urls` from `material/manual/queue.md` front matter.

For each URL:

1. Generate a slug.
2. If `material/manual/{slug}.md` already exists and has a `materials` row, skip.
3. Fetch using `material/skills/web-fetch.md` → `material/manual/{slug}.md`.
4. Add front matter with `source_url`, `fetched_at`, `format: html`.
5. Register and publish (see Gate Operations).
6. Move the URL from `pending_urls` to `processed_urls` in `queue.md` front matter.
7. Append the slug to `memory.md`.

If fetching fails after three retries, leave the URL in `pending_urls`, record the error in `memory.md`, and continue to the next entry.

### Step 3 – Process Keyword Queue

Read `pending_keywords` from `material/manual/queue.md` front matter.

For each keyword:

1. Run `skills/web-search.md` to obtain the top result URLs (default: 5).
2. For each result URL that has not already been processed (check `memory.md`), treat it as a URL queue item and follow Step 2.
3. Move the keyword from `pending_keywords` to `processed_keywords` in `queue.md` front matter.
4. Append the keyword to `memory.md` under `processed_keywords`.

---

## Gate Operations

For each successfully produced Markdown file at `material/manual/{slug}.md`, replace `{slug}` with the actual slug value (a shell variable such as `$slug`). Example:

```bash
./scripts/sqlite.sh "INSERT OR IGNORE INTO materials (path) VALUES ('material/manual/${slug}.md');"
./scripts/sqlite.sh "UPDATE materials SET updated_at=datetime('now') WHERE path='material/manual/${slug}.md';"

./scripts/sqlite.sh "
  INSERT OR IGNORE INTO pipeline_units
    (unit_id, layer, unit_type, source_kind, source_key, root_path, required_count)
    VALUES ('material:document:manual/${slug}', 'material', 'single', 'document', 'manual/${slug}', 'material/manual/${slug}.md', 1);

  INSERT OR IGNORE INTO pipeline_unit_members
    (unit_id, member_path, member_role, member_type)
    VALUES ('material:document:manual/${slug}', 'material/manual/${slug}.md', 'required', 'file');

  UPDATE pipeline_unit_members
    SET member_status='done', member_version=member_version+1, updated_at=datetime('now')
    WHERE unit_id='material:document:manual/${slug}' AND member_path='material/manual/${slug}.md';

  UPDATE pipeline_units SET
    done_count = 1,
    blocked_count = 0,
    status = 'ready',
    ready_version = ready_version + 1,
    ready_at = datetime('now'),
    updated_at = datetime('now')
  WHERE unit_id='material:document:manual/${slug}';
"
```

---

## Outputs

- **File:** `material/manual/{slug}.md`
- **Business row:** `materials.path = material/manual/{slug}.md`
- **Gate row:** `pipeline_units.unit_id = material:document:manual/{slug}`

Front matter template:

```yaml
---
source_url: "https://example.com/article"
fetched_at: "2026-04-21T08:00:00Z"
format: "html"
title: "Article Title"
brief: ""
---
```

---

## memory.md Bookkeeping

Maintain `material/manual/memory.md` with the following sections. Create the file if it does not exist.

```markdown
## Processed files
- 20260421-example-com-article.md  (fetched_at: 2026-04-21T08:00:00Z)

## Processed keywords
- machine learning transformers (searched_at: 2026-04-21T08:00:00Z, results: 5)

## Errors
- URL https://example.com/blocked — 3 retries failed (2026-04-21T08:05:00Z)
```

---

## Tooling Reference

| Tool | Purpose |
|---|---|
| `sqlite3` | Register rows and publish gate units |
| `curl` | Fetch remote pages |
| `pandoc` | Convert HTML / PDF / EPUB to Markdown |
| `python3` + `pyyaml` | Read and write YAML front matter |
| `material/skills/web-fetch.md` | Fetch a URL and produce Markdown |
| `skills/web-search.md` | Run a keyword search and return result URLs |

---

## Error Handling

- **Fetch failure:** retry up to three times with a five-second backoff; if it still fails, leave the item in `pending_urls`, record the error in `memory.md`, and continue.
- **Conversion failure:** record the error in `memory.md`, do not register the file, and mark the member `blocked`.
- **Duplicate slug:** append `-2`, `-3`, and so on until the name is unique.
- **Empty search results:** record a warning in `memory.md` and move the keyword to `processed_keywords`.

---

## Checklist

- [ ] `material/AGENTS.md` was read first
- [ ] dropped files were scanned and unprocessed ones converted
- [ ] `pending_urls` were fetched and registered
- [ ] `pending_keywords` were searched, results fetched and registered
- [ ] processed entries moved out of pending lists in `queue.md`
- [ ] every output file registered in `materials` and gate tables
- [ ] `memory.md` updated with processed items, timestamps, and errors
