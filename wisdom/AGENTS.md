# Wisdom Layer - Synthesis Spec

## Role

The wisdom agent consumes `ready` knowledge publish units, clusters related knowledge into larger themes, and produces synthesis pieces that behave more like essays, decision frameworks, or playbooks than isolated notes.

---

## Scope

- **May operate on:** everything under `wisdom/`, the `wisdoms` table, and the `wisdom` row in `layer_state`
- **May operate on gate tables:** `pipeline_consumptions` where `consumer_layer='wisdom'`
- **Read-only:** the `knowledges` table, `tags.md`, and knowledge-layer publish units
- **May update:** existing wisdom files and the `knowledge.wisdoms` field in referenced `knowledge/...` files
- **Must not operate on:** `material/`, `brief/`, `idea/`, `materials`, `briefs`, or `knowledges`

## Recursive Loading Rule

- Read this file before any wisdom-layer work.
- Load deeper subtree contracts only when a narrower local space adds real constraints for the output you are about to touch.
- Keep the generic synthesis, clustering, and backlink rules from this file as the default.

---

## Inputs

Query knowledge publish units that are `ready` and not yet consumed by wisdom at the current version:

```bash
./scripts/sqlite.sh "SELECT pu.unit_id, pu.ready_version, pu.root_path, pu.source_key
  FROM   pipeline_units pu
  LEFT JOIN pipeline_consumptions pc
    ON pu.unit_id = pc.unit_id AND pc.consumer_layer = 'wisdom'
  WHERE  pu.layer  = 'knowledge'
    AND  pu.status = 'ready'
    AND  pu.ready_version > COALESCE(pc.consumed_version, 0);"
```

Before writing any wisdom output, read `vault-language.txt` from repository root. Use that language for the note filename, title, section headings, body prose, and any newly added tags. If `user.md` exists, read it too and use it to prioritize which themes deserve synthesis, what output shape is most useful, and which tradeoffs or applications should be foregrounded.

---

## Outputs

- **Files:** flat Markdown files such as `wisdom/{note-name-in-vault-language}.md`
- **Business table:** one row in `wisdoms`
- **Bidirectional links:**
  - `wisdom.knowledge` lists referenced knowledge items
  - referenced knowledge files append `[[wisdom/{note-name-in-vault-language}]]` to `knowledge.wisdoms`

Front matter template:

```yaml
---
knowledge:
  - "[[knowledge/{knowledge-note-name-a-in-vault-language}]]"
  - "[[knowledge/{knowledge-note-name-b-in-vault-language}]]"
tags:
  - {tag-in-vault-language}
---
```

---

## Processing Flow

### Step 0: query ready units

Fetch knowledge units that wisdom has not consumed yet.

### Step 1: detect change and cluster themes

1. Read each changed knowledge file.
2. Read tags from its front matter.
3. Group new or changed knowledge by shared tags and topic affinity.
4. Use `user.md` to prioritize clusters that match the user's durable questions, operating context, or preferred synthesis style.

### Step 2: decide whether to create or update wisdom

#### 2a. Inspect existing wisdom

Scan existing wisdom files and compare their tag sets and themes with the incoming cluster.

- If an existing wisdom file overlaps strongly with the new cluster, update it.
- If the cluster represents a new theme, decide whether it is mature enough to create a new wisdom file.

#### 2b. Conditions for creating a new wisdom file

Create a new wisdom piece when **any** of the following is true:

- the same theme is supported by at least three knowledge items
- the new cluster answers a complete higher-level question on its own
- an existing wisdom file is obsolete enough that a full rewrite is justified

If none of those conditions hold, record the cluster in `wisdom/memory.md` for later accumulation instead of forcing a weak synthesis.

Example:

```yaml
pending_wisdom_clusters:
  - theme: "Applications of attention mechanisms in NLP"
    knowledge_paths:
      - "knowledge/attention-mechanism.md"
    added_at: "2026-04-11T08:00:00Z"
```

### Step 3: apply the change

#### Create a new wisdom file

```bash
./scripts/sqlite.sh "INSERT OR IGNORE INTO wisdoms (path) VALUES ('wisdom/{note-name-in-vault-language}.md');"
for knowledge_note_name in {knowledge-note-names-in-vault-language}; do
  python3 material/skills/scripts/update-frontmatter.py \
    "knowledge/$knowledge_note_name.md" append wisdoms "[[wisdom/{note-name-in-vault-language}]]"
  python3 material/skills/scripts/update-frontmatter.py \
    "wisdom/{note-name-in-vault-language}.md" append knowledge "[[knowledge/$knowledge_note_name]]"
done
```

#### Update an existing wisdom file

```bash
python3 material/skills/scripts/update-frontmatter.py \
  "wisdom/{existing-note-name-in-vault-language}.md" append knowledge "[[knowledge/{new-note-name-in-vault-language}]]"
./scripts/sqlite.sh "UPDATE wisdoms SET updated_at=datetime('now') WHERE path='wisdom/{existing-note-name-in-vault-language}.md';"
python3 material/skills/scripts/update-frontmatter.py \
  "knowledge/{new-note-name-in-vault-language}.md" append wisdoms "[[wisdom/{existing-note-name-in-vault-language}]]"
```

### Step 4: record consumption

```bash
./scripts/sqlite.sh "INSERT INTO pipeline_consumptions (unit_id, consumer_layer, consumed_version, consumed_at)
  VALUES ('{knowledge_unit_id}', 'wisdom', {ready_version}, datetime('now'))
  ON CONFLICT(unit_id, consumer_layer) DO UPDATE SET
    consumed_version=excluded.consumed_version,
    consumed_at=excluded.consumed_at;"
```

### Step 5: optionally update `layer_state`

```bash
./scripts/sqlite.sh "UPDATE layer_state SET last_visited_at=datetime('now') WHERE layer='wisdom';"
```

---

## Wisdom File Format

```markdown
---
knowledge:
  - "[[knowledge/{knowledge-note-name-a-in-vault-language}]]"
  - "[[knowledge/{knowledge-note-name-b-in-vault-language}]]"
tags:
  - {tag-in-vault-language}
---

# {Wisdom title in vault language}

## {Context section in vault language}

## {Core insight section in vault language}

## {Knowledge map section in vault language}

## {Practical guidance section in vault language}

## {Further questions section in vault language}
```

> Business rule: wisdom titles, section headings, prose, and new tags should all follow `vault-language.txt`, even if the operating instructions themselves are written in English.

---

## Quality Constraints

- Wisdom must synthesize multiple knowledge items rather than restate one note.
- A wisdom file should normally be supported by at least two knowledge items.
- Wisdom tags should cover the dominant tags of the cited knowledge, and may be more abstract than any single source tag.
- Check `tags.md` before minting a new tag.
- Keep wisdom tags in the same language and hierarchy style as `tags.md` and `vault-language.txt`.
- Wisdom should usually reuse the existing vault-language equivalents of the domain/topic/method/application/evidence families instead of creating a parallel branch for the same theme.
- The wisdom filename should also follow `vault-language.txt` instead of defaulting to an English slug.
- All bidirectional links must remain symmetric.
- Repeated runs must not create duplicate wisdom files.
- `user.md` may steer synthesis priorities and recommended formats, but it must not be used as a reason to bypass tag normalization or create shallow promotional writing.
- **Admission must go through the pipeline gate, never by scanning `knowledges` directly.**

---

## Layer Checklist

- [ ] only ready knowledge publish units newer than the recorded wisdom consumption were processed
- [ ] the generic wisdom contract remained the baseline for clustering and synthesis
- [ ] `vault-language.txt` was read before generation
- [ ] `user.md` was consulted if present
- [ ] the wisdom filename follows the vault language
- [ ] each wisdom file synthesizes multiple knowledge items instead of restating one note
- [ ] wisdom tags reuse or extend the canonical family structure from `tags.md`
- [ ] new or updated wisdom tags stay aligned with `tags.md` and the vault language
- [ ] referenced knowledge files were backlinked symmetrically
- [ ] weak clusters were deferred to `memory.md` instead of forced into low-signal wisdom
- [ ] consumption was recorded in `pipeline_consumptions`

---

## Tooling Reference

| Tool | Purpose |
|---|---|
| `sqlite3` | Query gate tables, write `wisdoms`, and record consumption |
| `python3` + `pyyaml` | Maintain front matter and read tags |
| `find` / `ls` | Inspect existing wisdom files |

---

## Error Handling

- **Knowledge file missing:** record a warning and skip it.
- **Clustering decision uncertain:** prefer deferring the cluster in `memory.md` over producing low-quality wisdom.
- **Conflict while updating a wisdom file:** keep the existing structure and append a dated update section rather than overwriting blindly.
