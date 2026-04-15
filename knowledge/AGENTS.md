# Knowledge Layer - Atomic Knowledge Extraction Spec

## Role

The knowledge agent consumes `ready` brief publish units, extracts atomic and reusable knowledge items, and merges overlapping content instead of exploding the graph with duplicates.

> A knowledge item should be atomic, reusable, transferable, and explainable. A "model + example" structure is a common pattern, but not a requirement.

---

## Scope

- **May operate on:** everything under `knowledge/`, the `knowledges` table, and the `knowledge` row in `layer_state`
- **May operate on gate tables:** `pipeline_units` where `layer='knowledge'`, matching `pipeline_unit_members`, and `pipeline_consumptions` where `consumer_layer='knowledge'`
- **Read-only:** the `briefs` table and brief-layer publish units
- **May update:** `tags.md`, existing knowledge files when enriching or merging them, and required backlink fields in referenced `brief/...` files
- **Must not operate on:** `material/`, `wisdom/`, `idea/`, `materials`, or `wisdoms`

---

## Inputs

Query brief publish units that are `ready` and not yet consumed by knowledge at the current version:

```bash
./scripts/sqlite.sh "SELECT pu.unit_id, pu.ready_version, pu.root_path, pu.unit_type, pu.source_kind
  FROM   pipeline_units pu
  LEFT JOIN pipeline_consumptions pc
    ON pu.unit_id = pc.unit_id AND pc.consumer_layer = 'knowledge'
  WHERE  pu.layer  = 'brief'
    AND  pu.status = 'ready'
    AND  pu.ready_version > COALESCE(pc.consumed_version, 0);"
```

Fetch completed members for each brief unit:

```bash
./scripts/sqlite.sh "SELECT member_path, member_role FROM pipeline_unit_members
  WHERE unit_id='{brief_unit_id}' AND member_status='done';"
```

Before writing any knowledge output, read `vault-language.txt` from repository root. Use that language for the note filename, title, section headings, body prose, and newly added tags. If `user.md` exists, read it too and use it to rank candidate concepts, suppress low-value off-profile candidates only when the profile explicitly defines durable exclusions, and favor the user's preferred level of abstraction.

**Important:** for collection-style brief units such as books or multipart document bundles, knowledge consumes the full brief collection, not one member at a time.

---

## Outputs

- **Files:** flat Markdown files such as `knowledge/{note-name-in-vault-language}.md`
- **Business table:** one row in `knowledges`
- **Gate tables:** one publish unit per resulting knowledge file
- **Bidirectional links:**
  - single brief source: append `[[knowledge/{note-name-in-vault-language}]]` to that brief file's `knowledge` field
  - multipart brief source: append `[[knowledge/{note-name-in-vault-language}]]` to every contributing required part brief's `knowledge` field; do not use the optional index file as the sole backlink target
  - append every contributing brief path to `knowledge.briefs`

Front matter template:

```yaml
---
briefs:
  - "[[brief/source/{brief-note-name-in-vault-language}]]"
wisdoms: []
tags:
  - {tag-in-vault-language}
---
```

---

## Processing Flow

### Step 0: query ready units

Get all ready brief units whose latest version has not been consumed by knowledge.

### Step 1: extract candidate knowledge items

From the body of each brief, extract candidate items with:

- a clear title
- an explanation of what the concept is
- at least one usage context, example, or application pattern
- at least one tag chosen with reference to `tags.md`

For books, synthesize candidates across the entire set of chapter briefs.

For multipart document bundles, read each required part brief separately first. Only create cross-part synthesis when the same concept genuinely spans multiple independent parts. Do not let a navigation index or omnibus overview become the primary semantic source.

Apply `user.md` as a durable relevance lens when it defines stable domain priorities or exclusions, but do not suppress concepts the user explicitly requested or concepts needed to keep the extracted graph coherent.

### Step 2: decide whether to merge or create

For each candidate, use a progressive matching strategy:

#### 2a. Keyword and tag screening

```bash
./scripts/sqlite.sh "SELECT path FROM knowledges WHERE deleted_at IS NULL;"
```

Read candidate tags from those files and keep only plausible matches.

#### 2b. Title scan

Compare titles:

- clearly the same concept -> inspect the body
- clearly different -> create a new item

#### 2c. Body comparison

- **High overlap (roughly >= 70%)** -> merge into the existing file
- **New angle or example with the same core concept** -> enrich the existing file
- **Substantively different** -> create a new file

### Step 3: apply the change

#### Create a new knowledge file

```bash
./scripts/sqlite.sh "INSERT OR IGNORE INTO knowledges (path) VALUES ('knowledge/{note-name-in-vault-language}.md');"
for brief_note_name in {contributing-brief-note-names-in-vault-language}; do
  python3 material/skills/scripts/update-frontmatter.py \
    "brief/{source}/$brief_note_name.md" append knowledge "[[knowledge/{note-name-in-vault-language}]]"
  python3 material/skills/scripts/update-frontmatter.py \
    "knowledge/{note-name-in-vault-language}.md" append briefs "[[brief/{source}/$brief_note_name]]"
done
```

#### Enrich or merge an existing file

```bash
./scripts/sqlite.sh "UPDATE knowledges SET updated_at=datetime('now') WHERE path='knowledge/{note-name-in-vault-language}.md';"
for brief_note_name in {contributing-brief-note-names-in-vault-language}; do
  python3 material/skills/scripts/update-frontmatter.py \
    "knowledge/{note-name-in-vault-language}.md" append briefs "[[brief/{source}/$brief_note_name]]"
  python3 material/skills/scripts/update-frontmatter.py \
    "brief/{source}/$brief_note_name.md" append knowledge "[[knowledge/{note-name-in-vault-language}]]"
done
```

### Step 4: create or refresh the knowledge publish unit

```bash
./scripts/sqlite.sh "
  INSERT OR IGNORE INTO pipeline_units
    (unit_id, layer, unit_type, source_kind, source_key, root_path, required_count)
    VALUES ('knowledge:generic:{slug}', 'knowledge', 'single', 'generic', '{slug}', 'knowledge/{note-name-in-vault-language}.md', 1);

  INSERT OR IGNORE INTO pipeline_unit_members
    (unit_id, member_path, member_role, member_type)
    VALUES ('knowledge:generic:{slug}', 'knowledge/{note-name-in-vault-language}.md', 'required', 'file');
"

./scripts/sqlite.sh "
  UPDATE pipeline_unit_members
    SET member_status='done', member_version=member_version+1, updated_at=datetime('now')
    WHERE unit_id='knowledge:generic:{slug}' AND member_path='knowledge/{note-name-in-vault-language}.md';

  UPDATE pipeline_units SET
    done_count = 1,
    blocked_count = 0,
    status = 'ready',
    ready_version = ready_version + 1,
    ready_at = datetime('now'),
    updated_at = datetime('now')
  WHERE unit_id='knowledge:generic:{slug}';
"
```

### Step 5: record consumption

```bash
./scripts/sqlite.sh "INSERT INTO pipeline_consumptions (unit_id, consumer_layer, consumed_version, consumed_at)
  VALUES ('{brief_unit_id}', 'knowledge', {ready_version}, datetime('now'))
  ON CONFLICT(unit_id, consumer_layer) DO UPDATE SET
    consumed_version=excluded.consumed_version,
    consumed_at=excluded.consumed_at;"
```

### Step 6: manage tags

1. Look up existing tags in `tags.md`.
2. Reuse an existing tag whenever possible.
3. Keep tag language aligned with `vault-language.txt`.
4. Prefer one primary branch from the vault-language equivalent of the domain/topic families, plus at most two supporting branches from the vault-language equivalent of the method/application/evidence families.
5. Normalize near-duplicate bilingual branches instead of preserving both.
6. Only append new tags when the concept genuinely needs a new branch.

### Step 7: optionally update `layer_state`

```bash
./scripts/sqlite.sh "UPDATE layer_state SET last_visited_at=datetime('now') WHERE layer='knowledge';"
```

---

## Knowledge File Format

```markdown
---
briefs:
  - "[[brief/source/{brief-note-name-in-vault-language}]]"
wisdoms: []
tags:
  - {tag-in-vault-language}
---

# {Knowledge title in vault language}

## {Definition section in vault language}

## {Mechanism section in vault language}

## {Usage section in vault language}

## {Limitations section in vault language}

## {References section in vault language}
```

---

## Quality Constraints

- Every knowledge item must have at least one tag.
- A single file should cover one concept only.
- Always check `tags.md` before creating a new tag.
- Titles, section headings, prose, and tags must all follow `vault-language.txt`.
- Tags should follow the reserved family structure from `tags.md` instead of minting ad-hoc mixed-purpose branches.
- The knowledge filename should also follow `vault-language.txt` instead of defaulting to an English slug.
- Do not keep parallel Chinese and English tags for the same concept in one vault.
- For multipart brief collections, backlinks must be written to every contributing required part brief, not just one representative file.
- Bidirectional links must stay symmetric.
- Repeated runs must merge or enrich instead of duplicating knowledge.
- `user.md` may shape which concepts are worth elevating, but it must not justify ad-hoc tags or broken traceability.
- **Admission must go through the pipeline gate, never by scanning `briefs` directly.**

---

## Layer Checklist

- [ ] only ready brief publish units newer than the recorded knowledge consumption were processed
- [ ] `vault-language.txt` was read before generation
- [ ] `user.md` was consulted if present
- [ ] the knowledge filename follows the vault language
- [ ] candidate items were merged or enriched instead of duplicated when overlap was high
- [ ] tags follow the canonical family structure from `tags.md`
- [ ] every resulting knowledge file has at least one tag aligned with `tags.md`
- [ ] multipart brief collections updated backlinks on every contributing required part brief
- [ ] knowledge front matter includes all contributing briefs
- [ ] publish units and members for changed knowledge files were refreshed
- [ ] consumption was recorded in `pipeline_consumptions`

---

## Tooling Reference

| Tool | Purpose |
|---|---|
| `sqlite3` | Query gate tables, write `knowledges`, and record consumption |
| `python3` + `pyyaml` | Maintain front matter, tags, and bidirectional links |
| `grep` / `find` | Scan existing knowledge files during rough matching |

---

## Error Handling

- **Brief file missing:** record a warning and skip it.
- **Tag write failure:** record the problem in `memory.md`, add the file to a `pending_tags` list, and continue without inserting a fake placeholder tag.
- **Merge decision uncertain:** prefer enriching an existing item over creating a new one.
