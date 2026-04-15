# Idea Plugin - Idea Generation Spec

## Role

The idea agent consumes `ready` knowledge publish units and generates actionable ideas for user-defined research directions. Each idea is one localized Markdown note under its research-direction directory and is meant to be a launchpad for follow-up work.

---

## Scope

- **May operate on:** files under `idea/{research-direction}/` plus the `idea` row in `layer_state`
- **May operate on gate tables:** `pipeline_consumptions` where `consumer_layer='idea'`
- **Read-only:** the `knowledges` table, files under `knowledge/`, research-direction `AGENTS.md` files, and knowledge-layer publish units
- **Must not operate on:** `material/`, `brief/`, `wisdom/`, or any business table other than writing `layer_state` and `pipeline_consumptions`

---

## Inputs

Query knowledge publish units that are `ready` and either unconsumed by idea or republished with a newer version:

```bash
./scripts/sqlite.sh "SELECT pu.unit_id, pu.ready_version, pu.root_path, pu.source_key
  FROM   pipeline_units pu
  LEFT JOIN pipeline_consumptions pc
    ON pu.unit_id = pc.unit_id AND pc.consumer_layer = 'idea'
  WHERE  pu.layer  = 'knowledge'
    AND  pu.status = 'ready'
    AND  pu.ready_version > COALESCE(pc.consumed_version, 0);"
```

Before writing any idea output, read `vault-language.txt` from repository root. Use that language for the idea directory name, note filename, title, all section headings, and the body prose inside each section. If `user.md` exists, read it too and use it to prefer idea directions, opportunity sizes, constraints, and execution styles that match the user's standing profile.

---

## Research Directions

Research directions are created manually by the user:

1. create a subdirectory under `idea/`
2. add an `AGENTS.md` in that directory describing the background, interests, and the kinds of ideas that are useful

The idea agent should scan `idea/` for subdirectories that contain `AGENTS.md` and treat each one as an active direction.

---

## Processing Flow

### Step 0: query ready units

Fetch all ready knowledge units that idea has not consumed yet.

### Step 1: scan research directions

```bash
find idea/ -mindepth 1 -maxdepth 1 -type d | while read dir; do
  if [[ -f "$dir/AGENTS.md" ]]; then
    echo "$dir"
  fi
done
```

### Step 2: inspect changed knowledge

For each ready knowledge unit, read the knowledge file, its tags, and its main body.

### Step 3: generate ideas per direction

For each research direction:

1. read that direction's `AGENTS.md`
2. decide which changed knowledge items are relevant
3. cross-check `user.md` for durable opportunity filters, excluded areas, or preferred execution styles
4. generate ideas only when the connection is substantive
5. compare with existing idea note titles in that direction to avoid duplication
6. create a new idea only if it offers a materially new angle

### Step 4: write the idea file

```bash
IDEA_PATH="idea/{research-direction}/{idea-note-name-in-vault-language}.md"
```

Then write that note using the format below.

### Step 5: record consumption

```bash
./scripts/sqlite.sh "INSERT INTO pipeline_consumptions (unit_id, consumer_layer, consumed_version, consumed_at)
  VALUES ('{knowledge_unit_id}', 'idea', {ready_version}, datetime('now'))
  ON CONFLICT(unit_id, consumer_layer) DO UPDATE SET
    consumed_version=excluded.consumed_version,
    consumed_at=excluded.consumed_at;"
```

### Step 6: optionally update `layer_state`

```bash
./scripts/sqlite.sh "UPDATE layer_state SET last_visited_at=datetime('now') WHERE layer='idea';"
```

---

## Idea File Format

```markdown
# {Idea title in vault language}

> Inspiration: [[knowledge/{knowledge-note-name-in-vault-language}]]
> Research direction: {direction-name}
> Generated at: {datetime}

## {Core question section in vault language}

## {Why this idea appeared section in vault language}

## {Initial shape section in vault language}

## {Feasibility section in vault language}

## {Next step section in vault language}
```

> Business rule: the prompt may be written in English, but the final idea directory name, note filename, title, headings, and section body prose should follow `vault-language.txt`.

---

## Quality Constraints

- Every idea must revolve around a clear core question.
- The idea must be strongly relevant to the research direction.
- Idea directory names and note filenames should follow `vault-language.txt`.
- The displayed title, section headings, and section body prose must also follow `vault-language.txt`.
- Prefer fewer high-signal ideas over many weak ones.
- Generate at most three new ideas per direction per run.
- Repeated runs must not create duplicates.
- `user.md` may prioritize which directions matter most, but it must not override the local research-direction contract in `idea/{direction}/AGENTS.md`.
- **Admission must go through the pipeline gate, never by scanning `knowledges` directly.**

---

## Layer Checklist

- [ ] only ready knowledge publish units newer than the recorded idea consumption were processed
- [ ] `vault-language.txt` was read before generation
- [ ] `user.md` was consulted if present
- [ ] the idea directory name and note filename follow the vault language
- [ ] every active research direction was discovered from an `idea/*/AGENTS.md` file
- [ ] new ideas were created only for substantive matches with the direction prompt
- [ ] displayed titles, headings, and body prose follow the vault language
- [ ] no direction received more than three new ideas in one run
- [ ] consumption was recorded in `pipeline_consumptions`

---

## Tooling Reference

| Tool | Purpose |
|---|---|
| `sqlite3` | Query ready units, update `layer_state`, and record consumption |
| `python3` + `pyyaml` | Read knowledge front matter and tags |
| `find` | Scan research directions and existing ideas |
| `mkdir` | Create new idea directories |

---

## Error Handling

- **Research direction missing `AGENTS.md`:** skip it silently.
- **Knowledge unrelated to a direction:** skip it.
- **Idea generation failure:** record the issue beside that research direction's prompt if a `memory.md` exists, then continue.
