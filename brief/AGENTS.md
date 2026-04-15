# Brief Layer - Information-Restoration Spec

## Role

The brief agent consumes `ready` material publish units and rewrites them in the user's vault language so the source becomes easier to understand without losing important information.

The brief layer is **not** a forced compression layer. Its job is to restore the source in a clearer and more accessible shape:

- if the source is already concise and high-density, keep nearly all important information and mainly reorganize the structure
- if the source is verbose or repetitive, extract, deduplicate, and integrate the information points without dropping material facts, arguments, evidence, or conclusions

---

## Scope

- **May operate on:** everything under `brief/`, the `briefs` table, and the `brief` row in `layer_state`
- **May operate on gate tables:** `pipeline_units` where `layer='brief'`, their `pipeline_unit_members`, and `pipeline_consumptions` where `consumer_layer='brief'`
- **Read-only:** the `materials` table, Markdown files under `material/`, and `pipeline_units` where `layer='material'`
- **May update in upstream Markdown only:** the `brief` front matter backlink in referenced `material/...` files when refreshing required backlinks
- **Must not operate on:** `knowledge/`, `wisdom/`, `idea/`, or the `materials` table

---

## Inputs

Query material publish units that are `ready` and either unconsumed by brief or republished with a newer version:

```bash
./scripts/sqlite.sh "SELECT pu.unit_id, pu.ready_version, pu.root_path, pu.unit_type, pu.source_kind
  FROM   pipeline_units pu
  LEFT JOIN pipeline_consumptions pc
    ON pu.unit_id = pc.unit_id AND pc.consumer_layer = 'brief'
  WHERE  pu.layer  = 'material'
    AND  pu.status = 'ready'
    AND  pu.ready_version > COALESCE(pc.consumed_version, 0);"
```

For each unit, fetch the completed members:

```bash
./scripts/sqlite.sh "SELECT member_path, member_role FROM pipeline_unit_members
  WHERE unit_id='{material_unit_id}' AND member_status='done';"
```

Before writing any brief output, read `vault-language.txt` from repository root. Use that language for the brief filename, title, section headings, and body prose. Do not switch languages mid-pipeline just because the source material uses a different language. If `user.md` exists, read it too and use it to adjust terminology, framing, and emphasis, but never as permission to omit material facts, reasoning, evidence, caveats, or conclusions.

---

## Outputs

- **Files:** Markdown brief files under `brief/` whose note names should follow `vault-language.txt`, while usually mirroring the `material/` directory structure unless one material item is split into part briefs because it contains multiple independent subcontents
- **Business table:** one row per output in `briefs`
- **Gate tables:** a publish unit plus publish unit members for the brief output
- **Bidirectional links:**
   - single brief: `material.brief = [[brief/{source}/{filename}]]`
   - multipart brief: `material.brief = [[brief/{source}/{bundle-index-note-name-in-vault-language}]]` where that file is an index pointing to the part briefs
   - every brief or brief-part file keeps `brief.material = [[material/{source}/{filename}]]`

Front matter template:

```yaml
---
material: "[[material/source/item-name]]"
knowledge: []
tags: []
---

# {Brief title in vault language}
```

> Business rule: the H1 title and section headings in a brief file should follow `vault-language.txt` and should help the user understand the source quickly without narrowing or distorting its real scope.

---

## Processing Flow

1. Query material units that brief has not consumed yet.
2. For each material unit:
   1. fetch member file paths
   2. inspect each material member and decide whether it is:
      - one coherent document, or
      - a bundled document with multiple clearly independent subcontents
   3. treat a document as **multipart** only when the parts can stand alone without relying on the surrounding sections, such as separate magazine articles, newsletter entries, or anthology pieces
    4. create the matching brief publish unit:
       - coherent document -> one mirrored brief file
       - multipart bundle -> one optional index file plus one required brief member per independent part
    5. for each required output member:
       - mark the matching brief member `in_progress`
       - read the material file or the extracted independent part
       - decide the transformation mode:
         - **structure-first mode** for already concise, information-dense source material -> preserve nearly all important content and mainly improve ordering, grouping, and wording clarity
         - **extraction-first mode** for verbose or repetitive source material -> extract, deduplicate, and integrate repeated points while preserving all material information
       - write the brief in plain, accessible language without omitting important facts, claims, reasoning steps, evidence, caveats, or conclusions
       - prefer restructuring and clarification over aggressive shortening
       - choose a concise note name in the vault language
       - map `material/...` to the correct `brief/...` path using that localized note name
       - create parent directories if needed
       - write the brief Markdown file
       - register every created brief file in `briefs`
       - mark the brief member `done` and aggregate the unit
   6. if multipart mode is active, write or refresh one localized navigation index under `brief/{source}/` that links to the part briefs, then register that index file in `briefs`
   7. update `material.brief` with the Python helper:
       ```bash
       python3 material/skills/scripts/update-frontmatter.py \
         "{material_path}" set brief "[[brief/{source}/{localized-filename-or-localized-index}]]"
       ```
3. Record consumption in `pipeline_consumptions`.
4. Optionally update `layer_state.last_visited_at` for `brief`.
5. Record counts, timestamps, and exceptions in `memory.md`.

Consumption recording example:

```bash
./scripts/sqlite.sh "INSERT INTO pipeline_consumptions (unit_id, consumer_layer, consumed_version, consumed_at)
  VALUES ('{material_unit_id}', 'brief', {ready_version}, datetime('now'))
  ON CONFLICT(unit_id, consumer_layer) DO UPDATE SET
    consumed_version=excluded.consumed_version,
    consumed_at=excluded.consumed_at;"
```

---

## Pipeline Gate Operations

### Single-file objects

```bash
./scripts/sqlite.sh "
  INSERT OR IGNORE INTO pipeline_units
    (unit_id, layer, unit_type, source_kind, source_key, root_path, required_count)
    VALUES ('brief:document:{source}/{item_slug}', 'brief', 'single', 'document', '{source}/{item_slug}', 'brief/{source}/{note-name-in-vault-language}.md', 1);

  INSERT OR IGNORE INTO pipeline_unit_members
    (unit_id, member_path, member_role, member_type)
    VALUES ('brief:document:{source}/{item_slug}', 'brief/{source}/{note-name-in-vault-language}.md', 'required', 'file');
"
```

### Multi-chapter objects

```bash
./scripts/sqlite.sh "
  INSERT OR IGNORE INTO pipeline_units
    (unit_id, layer, unit_type, source_kind, source_key, root_path, required_count)
    VALUES ('brief:book:books/{slug}', 'brief', 'collection', 'book', 'books/{slug}', 'brief/books/{book-note-dir-in-vault-language}/', {required_chapter_count});
"

./scripts/sqlite.sh "
  INSERT OR IGNORE INTO pipeline_unit_members
    (unit_id, member_path, member_role, member_type, member_key)
    VALUES ('brief:book:books/{slug}', 'brief/books/{book-note-dir-in-vault-language}/c01-{chapter-note-name-in-vault-language}.md', 'required', 'chapter', 'c01');
"
```

### Independent multi-part documents

Use this when one material file bundles multiple clearly independent subcontents.

```bash
./scripts/sqlite.sh "
  INSERT OR IGNORE INTO pipeline_units
    (unit_id, layer, unit_type, source_kind, source_key, root_path, required_count)
    VALUES ('brief:bundle:{source}/{item_slug}', 'brief', 'collection', 'bundle', '{source}/{item_slug}', 'brief/{source}/{bundle-note-dir-in-vault-language}/', {part_count});
"

./scripts/sqlite.sh "
  INSERT OR IGNORE INTO pipeline_unit_members
    (unit_id, member_path, member_role, member_type, member_key)
    VALUES ('brief:bundle:{source}/{item_slug}', 'brief/{source}/{bundle-index-note-name-in-vault-language}.md', 'optional', 'index', 'index');

  INSERT OR IGNORE INTO pipeline_unit_members
    (unit_id, member_path, member_role, member_type, member_key)
    VALUES ('brief:bundle:{source}/{item_slug}', 'brief/{source}/{bundle-note-dir-in-vault-language}/part-01-{part-note-name-in-vault-language}.md', 'required', 'part', 'part-01');
"
```

### Member completion and aggregation

```bash
./scripts/sqlite.sh "UPDATE pipeline_unit_members
  SET member_status='done', member_version=member_version+1, updated_at=datetime('now')
  WHERE unit_id='brief:book:books/{slug}' AND member_path='brief/books/{book-note-dir-in-vault-language}/c01-{chapter-note-name-in-vault-language}.md';"
```

Use the canonical aggregation logic from the root spec immediately afterward.

### Key business rules

- Brief executes at the **chapter** level.
- Knowledge consumes at the **book** level once the entire brief collection is `ready`.
- Bundled-but-independent source documents should become **part-level brief collections**, not one blended brief.
- A missing required chapter keeps the downstream gate closed.

---

## Quality Constraints

Every brief should satisfy these standards:

1. **Do not drop important information.** Main arguments, important data, reasoning steps, evidence, caveats, and final conclusions must survive the rewrite.
2. **Compression is conditional, not mandatory.**
   - if the source is already concise, do not force a shorter summary
   - in that case, focus on restructuring, grouping, and clearer wording
3. **Deduplicate only true redundancy.**
   - if the source repeats itself, merge overlapping passages into one clearer explanation
   - do not delete distinct facts just because they look similar at first glance
4. **Use the clearest format available.**
   - process or causality -> Mermaid flowchart
   - comparisons or numeric results -> table
   - structured takeaways -> headings plus bullet lists
5. **Keep the structure legible.** A good default outline is:
   - `## {Core theme section in vault language}`
   - `## {Main content section in vault language}`
   - `## {Key conclusions section in vault language}`
   - `## {Why it matters section in vault language}`
6. **Use the vault language consistently.** H1 titles, section headings, and prose should all follow `vault-language.txt`.
7. **Do not blend independent pieces together.** If one material file really contains multiple stand-alone parts, produce one brief per part instead of a single mixed reconstruction.
8. **Stay idempotent.** Regeneration should overwrite the existing brief instead of creating duplicates.
9. **Use vault-language note names.** The brief filename should default to the vault language instead of an English slug, while staying concise and unambiguous.
10. **Use user preferences only as presentation guidance.** `user.md` may shape wording, examples, and emphasis, but it must not narrow the source so far that important information disappears.

---

## Layer Checklist

- [ ] only ready material publish units newer than the recorded brief consumption were processed
- [ ] `vault-language.txt` was read before generation
- [ ] `user.md` was consulted if present
- [ ] the brief note filename follows the vault language
- [ ] each source was classified correctly as coherent or multipart
- [ ] the brief used structure-first mode for concise sources and extraction-first mode for redundant sources
- [ ] all material facts, arguments, evidence, caveats, and conclusions were preserved
- [ ] every required brief member was written, registered, and aggregated through the gate
- [ ] multipart bundles use one brief per independent part instead of one blended summary
- [ ] `material.brief` backlinks point to the correct brief file or multipart index
- [ ] consumption was recorded in `pipeline_consumptions`
- [ ] `memory.md` reflects counts, timestamps, and exceptions when durable bookkeeping is used

---

## Tooling Reference

| Tool | Purpose |
|---|---|
| `sqlite3` | Query gate tables, write `briefs`, and record consumption |
| `python3` + `pyyaml` | Update YAML front matter with the shared helper |
| `mkdir` | Create output directories |

---

## Error Handling

- **Material file missing:** record a warning in `memory.md` and skip the item.
- **Summary generation failure:** record the error, set the member to `blocked`, aggregate the unit, and skip database registration for that item.
- **Database failure:** retry once; if it still fails, record the error and stop that item.
