# Ambra

> Chinese documentation: [README-zh.md](README-zh.md)

Ambra is a DIKW (Data -> Information -> Knowledge -> Wisdom) knowledge pipeline for personal research. It uses AI agents to turn raw source material into reusable briefs, atomic knowledge, synthetic wisdom, and research ideas.

---

## Usage

**Use `SKILL/ambra/SKILL.md` as the main way to operate Ambra.** The skill exposes these canonical workflow labels:

| Workflow | What to ask for |
|---|---|
| `ambra:init` | create and bootstrap a fresh vault |
| `ambra:user` | create, refine, or audit `user.md` |
| `ambra:localize` | localize an existing vault |
| `ambra:add-source` | register or extend a material source |
| `ambra:search` | search an existing source and ingest results |
| `ambra:import` | import local files and ingest them |
| `ambra:run` | run the full DIKW pipeline |
| `ambra:dream` | reorganize and deepen the vault globally |

These are **workflow names, not shell commands**. The user can invoke them either by name or in natural language, for example:

```text
Use ambra:init to create a new Chinese vault in ~/vaults/investing.
Use ambra:user to help me refine my profile for quant research and bilingual reading.
Use ambra:add-source to add a weekly magazine source and pull one recent item as a smoke test.
Use ambra:search to find three recent items about time-series momentum and ingest them.
Use ambra:import to ingest these local EPUB files into Ambra.
Use ambra:run to bring the vault fully up to date.
Use ambra:dream to consolidate overlapping knowledge and produce stronger wisdom.
```

If the workflow touches source filtering, downstream shaping, or idea generation, Ambra should also consult `user.md`. If the workflow writes downstream notes, Ambra should follow `vault-language.txt`.

---

## Architecture

```text
material -> brief -> knowledge -> wisdom
                             \-> idea (parallel to wisdom)
```

| Layer | Responsibility |
|---|---|
| **material** | Fetch or import raw sources such as papers, ebooks, and web pages, then convert them to Markdown |
| **brief** | Produce close-reading summaries for each material item, or split one bundled source into part briefs when it contains multiple independent pieces |
| **knowledge** | Extract atomic, reusable knowledge units from briefs and merge overlapping insights |
| **wisdom** | Cluster related knowledge units into higher-level essays, playbooks, or decision frameworks |
| **idea** | Generate actionable ideas for user-defined research directions from newly ready knowledge |

---

## Repository Layout

```text
.
|- AGENTS.md              # Root orchestration spec: global constraints and pipeline coordination
|- user.md                # Durable user preference profile used for source filtering and downstream shaping
|- SKILL/                 # Reusable skill entrypoints for operating or extending Ambra
|- brief/                 # Brief layer
|  \- AGENTS.md
|- idea/                  # Idea layer, organized by research direction
|  \- AGENTS.md
|- knowledge/             # Atomic knowledge layer
|  \- AGENTS.md
|- material/              # Source material in Markdown form
|  |- AGENTS.md
|  \- skills/            # Reusable conversion and maintenance skills
|     \- scripts/        # Shell and Python helpers referenced by the skills
|- migrations/            # Database schema and migrations
|- scripts/
|  |- init-db.sh          # Idempotent local database bootstrap
|  \- sqlite.sh           # SQLite wrapper with foreign keys enabled
|- tags.md                # Shared hierarchical tag taxonomy
|- tag-dataview.md        # Root Dataview dashboard that traverses tags across downstream layers
|- vault-language.txt     # Canonical downstream output language for brief/knowledge/wisdom/idea and tags
\- wisdom/                # Synthetic wisdom essays
   \- AGENTS.md
```

---

## Core Mechanics

### Pipeline Gate

Cross-layer progression uses a **publish unit + versioned consumption** model so downstream layers only consume upstream work after it is complete.

- **Single-file objects** such as one paper use a `single` unit with one `required` member.
- **Collections** such as ebooks use a `collection` unit whose body chapters are `required` members while appendices or prefaces can be `optional`.
- A downstream layer can only consume a unit when every required member is done and the unit becomes `ready`.

### Bidirectional Links

Cross-layer relationships live in YAML front matter and must stay symmetric:

```text
material.brief    <-> brief.material
brief.knowledge   <-> knowledge.briefs
knowledge.wisdoms <-> wisdom.knowledge
```

Use `material/skills/scripts/sync-bidirectional-links.py` to scan for missing reverse links and fill them in automatically.

### Vault Language Contract

`vault-language.txt` stores the canonical downstream output language for the vault.

- `material/` stays source-faithful.
- `brief/`, `knowledge/`, `wisdom/`, and `idea/` should write note filenames, titles, section headings, body prose, and newly added tags in the language declared in `vault-language.txt`.
- A single vault should not keep parallel Chinese and English tag branches for the same concept unless the user explicitly asks for bilingual output.
- If the vault is not meant to run in English, update `vault-language.txt` before the first downstream run.
- Keep tags semantic and hierarchical; do not use tags for workflow state when paths or front matter already carry that information.

### User Preference Contract

`user.md` stores durable vault-level preferences.

- Use it for stable source focus, exclusions, ranking, downstream emphasis, and idea-generation priorities.
- Treat explicit current user instructions as stronger than `user.md`.
- Do not let `user.md` override repository invariants, the pipeline gate, or the canonical tag taxonomy.
- Keep the file path fixed as `user.md`, but let the content follow the user's own language if that is more natural.

### Idempotency

All agents must be safe to rerun:

- check path uniqueness before inserting new rows
- update existing rows when content changes
- record downstream consumption by `ready_version`
- avoid duplicate wikilinks in front matter

---

## Tooling

| Tool | Purpose |
|---|---|
| `sqlite3` | Operate on the local queue database |
| `pandoc` >= 2.x | Convert PDF, EPUB, and HTML into Markdown |
| `python3` + `pyyaml` | Maintain YAML front matter and bidirectional links |
| `unzip` | Inspect EPUB internals before splitting |

Recommended preflight checks:

```bash
pandoc --version
python3 -c "import yaml; print('pyyaml ok')" || pip3 install pyyaml
```

Prefer `./scripts/sqlite.sh` for every database command; it enables `PRAGMA foreign_keys=ON` for each SQLite connection automatically.

---

## Quick Start

1. Run `./scripts/init-db.sh` at the repository root to create `queue.db`.
2. Create or refine `user.md` so the vault has a durable preference profile before you extend sources or run the downstream layers.
3. Set `vault-language.txt` to the intended downstream output language if you do not want the default `en`.
4. Put raw inputs such as PDFs or EPUBs under `material/{source}/`.
5. Run the material layer to convert files and register them in the database.
6. Trigger `brief -> knowledge -> wisdom / idea` in order.
7. Run `python3 material/skills/scripts/sync-bidirectional-links.py --dry-run --root .` regularly to verify link integrity.

> `queue.db` is generated locally and is intentionally not tracked by Git.
>
> Prefer `./scripts/sqlite.sh "SQL..."` instead of invoking `sqlite3 queue.db` directly.

---

## Extending the Framework

- Add a new research direction by creating a subdirectory under `idea/` with its own `AGENTS.md`.
- Add a new source plugin by documenting it in `material/{source}/AGENTS.md`.
- Put reusable helpers under `material/skills/scripts/` so every layer can reference the same tooling.
- Use `SKILL/ambra/SKILL.md` as the high-level operating skill for scaffolding new vaults, configuring `user.md`, extending sources, ingesting content, and running the full pipeline.
