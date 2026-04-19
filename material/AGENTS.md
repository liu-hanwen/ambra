# Material Layer - Source Ingestion Spec

## Role

The material agent is the entry point of the pipeline. It acquires source content, converts it into clean Markdown, and registers every output in both the business tables and the pipeline gate tables so downstream layers can consume only complete units.

---

## Scope

- **May operate on:** everything under `material/` plus the `materials` table in `queue.db`
- **May operate on gate tables:** `pipeline_units` rows where `layer='material'` and their matching `pipeline_unit_members`
- **Must not operate on:** `brief/`, `knowledge/`, `wisdom/`, `idea/`, or their business tables

## Recursive Loading Rule

- Read this file before any material-layer work.
- Read `material/{source}/AGENTS.md` only when a source plugin exists for the source you are touching.
- A source-plugin `AGENTS.md` should add source-specific fetching, filtering, and bookkeeping rules; it should not restate the generic gate and ingestion rules from this file.

---

## Tool Preflight

```bash
pandoc --version || { echo "ERROR: pandoc is required."; exit 1; }
python3 -c "import yaml; print('pyyaml ok')" || pip3 install pyyaml
sqlite3 --version || { echo "ERROR: sqlite3 is required."; exit 1; }
unzip -v > /dev/null 2>&1 || { echo "ERROR: unzip is required."; exit 1; }
./scripts/init-db.sh >/dev/null
```

---

## Input Modes

### 1. File Import

Users place source files such as PDF, EPUB, TXT, Markdown, or HTML under `material/{source}/`. The agent detects non-Markdown files and calls the appropriate skill to convert them.

Relevant shared skills:

- `skills/pdf-to-markdown.md`
- `skills/epub-to-markdown.md`
- `skills/html-to-markdown.md`

### 2. Incremental Source Fetching

Each source plugin may define its own `material/{source}/AGENTS.md` that explains where the source lives, how to access it, and how to fetch incrementally. The material agent reads that plugin spec and its `memory.md`, pulls only new content, converts it, and records progress.

### 3. Source Search

If a source plugin supports search, the user can provide keywords through the source-specific `AGENTS.md` or `memory.md`. The material agent then calls the source search skill and processes matching content.

Before adding or tuning a source plugin, searching a source, or pulling incremental content, read `user.md` from repository root if it exists. Use it to apply durable source preferences such as domain focus, exclusions, ranking rules, or fetch limits. Treat explicit current user instructions as stronger than the standing profile.

---

## Outputs

- **Files:** Markdown under `material/{source}/`, preferably named with a stable slug such as `{date}-{slug}.md`
- **Business table:** one row in `materials`
- **Gate tables:** one publish unit and one or more publish unit members for every output

Front matter template:

```yaml
---
source_url: "https://example.com/article"
fetched_at: "2026-04-11T08:00:00Z"
format: "pdf"
brief: "[[brief/source/article-name]]"
---
```

---

## Processing Flow

1. **Scan for input** under `material/{source}/`, or inspect source-plugin instructions for new incremental work.
2. **Convert or fetch** content:
    - imported files: run the relevant conversion skill
    - remote sources: follow the source plugin's incremental strategy
   - if one source artifact bundles multiple clearly independent pieces, preserve heading boundaries, bylines, and section separators so brief can detect multipart structure downstream
3. **Write front matter** with fields such as `source_url`, `fetched_at`, and `format`.
4. **Register the output**:
   ```bash
   ./scripts/sqlite.sh "INSERT OR IGNORE INTO materials (path) VALUES ('material/{source}/{file}.md');"
   ./scripts/sqlite.sh "UPDATE materials SET updated_at=datetime('now') WHERE path='material/{source}/{file}.md';"
   ```
5. **Create or update the publish unit** for the output.
6. **Update `memory.md`** with processed files and timestamps.

---

## Pipeline Gate Operations

The material layer must publish ready units when outputs are complete.

### Single-file objects

```bash
./scripts/sqlite.sh "
  INSERT OR IGNORE INTO pipeline_units
    (unit_id, layer, unit_type, source_kind, source_key, root_path, required_count)
    VALUES ('material:document:{source}/{item_slug}', 'material', 'single', 'document', '{source}/{item_slug}', 'material/{source}/{item_slug}.md', 1);

  INSERT OR IGNORE INTO pipeline_unit_members
    (unit_id, member_path, member_role, member_type)
    VALUES ('material:document:{source}/{item_slug}', 'material/{source}/{item_slug}.md', 'required', 'file');
"

./scripts/sqlite.sh "
  UPDATE pipeline_unit_members
    SET member_status='done', member_version=member_version+1, updated_at=datetime('now')
    WHERE unit_id='material:document:{source}/{item_slug}' AND member_path='material/{source}/{item_slug}.md';

  UPDATE pipeline_units SET
    done_count = 1,
    blocked_count = 0,
    status = 'ready',
    ready_version = ready_version + 1,
    ready_at = datetime('now'),
    updated_at = datetime('now')
  WHERE unit_id='material:document:{source}/{item_slug}';
"
```

### Multi-chapter objects such as books

Create the book-level unit immediately after chapter splitting:

```bash
./scripts/sqlite.sh "
  INSERT OR IGNORE INTO pipeline_units
    (unit_id, layer, unit_type, source_kind, source_key, root_path, required_count)
    VALUES ('material:book:books/{slug}', 'material', 'collection', 'book', 'books/{slug}', 'material/books/{slug}/', {chapter_count});
"

./scripts/sqlite.sh "
  INSERT OR IGNORE INTO pipeline_unit_members
    (unit_id, member_path, member_role, member_type, member_key)
    VALUES ('material:book:books/{slug}', 'material/books/{slug}/c01-intro.md', 'required', 'chapter', 'c01');
  INSERT OR IGNORE INTO pipeline_unit_members
    (unit_id, member_path, member_role, member_type, member_key)
    VALUES ('material:book:books/{slug}', 'material/books/{slug}/appendix-a.md', 'optional', 'chapter', 'appendix-a');
"
```

Then mark each completed chapter `done` and aggregate the unit exactly as defined in the root spec.

### Required versus optional chapters

- filenames like `c01-`, `c02-`, and similar body-chapter patterns -> `required`
- filenames containing `appendix`, `index`, `acknowledgment`, or `preface` -> `optional`
- when unsure, default to `required`

---

## Quality Constraints

- Output must be valid Markdown.
- Front matter must be complete; `fetched_at` may not be empty.
- The same source content must not be registered twice under different duplicate paths.
- Converted Markdown should preserve structure from the original source where possible.
- If one source artifact bundles multiple independent pieces, the converted Markdown should keep those boundaries legible instead of flattening them into one continuous blob.
- Stable source-side filters derived from `user.md` should live in source contracts or helper defaults only when they are durable, source-specific behavior rather than one-off task instructions.
- EPUB books should be split into chapter files named like `c01-chapter-name.md`.
- **Every material output must have a matching publish unit.**

---

## Layer Checklist

- [ ] required tools are available for this ingestion path
- [ ] the generic material contract was used as the baseline before any source-plugin overlay
- [ ] source input was fetched, converted, or normalized without losing key structure
- [ ] `user.md` was consulted if present before source filtering, search, or source-contract tuning
- [ ] front matter includes source metadata such as `source_url`, `fetched_at`, and `format`
- [ ] `materials` row exists for every durable output
- [ ] publish unit and members exist for every durable output
- [ ] required members were marked and aggregated correctly
- [ ] bundled independent pieces, if any, remain structurally separable for downstream multipart briefs
- [ ] `memory.md` was updated when the source plugin relies on durable bookkeeping

---

## Tooling Reference

| Tool | Purpose |
|---|---|
| `sqlite3` | Read and write `queue.db` |
| `python3` + `pyyaml` | Read and write YAML front matter |
| `pandoc` | Convert PDF, EPUB, or HTML to Markdown |
| `pdftotext` | PDF fallback when `pandoc` is insufficient |
| `curl` / `wget` | Fetch remote pages |
| `find` | Scan for non-Markdown source files |

---

## Error Handling

- **Conversion failure:** record the error in the source plugin's `memory.md`, skip the file, and mark the member as `blocked`.
- **Network failure:** retry up to three times; if it still fails, record the error and continue.
- **Unsupported format:** record a warning and skip the file.
