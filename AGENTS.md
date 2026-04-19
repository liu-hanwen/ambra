# Ambra - Root Orchestration Spec

## Role

The root agent coordinates the DIKW pipeline. It keeps cross-layer invariants intact, enforces execution order, and ensures that downstream admission always goes through the pipeline gate instead of ad-hoc scans.

## Loading Strategy

1. Read this file first whenever work crosses layer boundaries, changes root-owned state, or needs vault-wide judgment.
2. Descend only into the subtree you are about to touch next.
3. Let the nearest child `AGENTS.md` add local rules for that subtree, but keep the root invariants in force unless a narrower child rule explicitly specializes them.

---

## Execution Order

```text
material -> brief -> knowledge -> wisdom
                             \-> idea (parallel)
```

Run layers in this order:

1. `material` fetches or converts source content, writes `materials`, and publishes `pipeline_units` plus `pipeline_unit_members`.
2. `brief` consumes ready material units and writes `briefs`.
3. `knowledge` consumes ready brief units and writes `knowledges`.
4. `wisdom` consumes ready knowledge units and writes `wisdoms`.
5. `idea` also consumes ready knowledge units, independently of wisdom.

`idea` may run in parallel with `wisdom`. Everything else is sequential.

---

## Core Gate Model

- A **publish unit** is the smallest upstream object a downstream layer may consume.
- `single` units have one required member.
- `collection` units have multiple members; body chapters or parts are usually `required`, appendices or indexes may be `optional`.
- A unit becomes `ready` only when every required member is `done`.
- Every transition into `ready` increments `ready_version`.
- Each downstream layer records its consumed version in `pipeline_consumptions`.
- When `ready_version > consumed_version`, downstream work must rerun.

### Aggregation rules

Recompute the parent unit in the same transaction whenever a member changes:

1. any required member `blocked` -> unit `blocked`
2. all required members `done` -> unit `ready`, increment `ready_version`, refresh `ready_at`
3. otherwise, any member started -> unit `in_progress`
4. otherwise -> unit `pending`

### Collection rules

- For books, create the book unit as soon as the book is split.
- Brief executes at chapter granularity for books, but knowledge consumes the full brief collection.
- A single material file may also become a brief-side collection when it bundles multiple clearly independent subcontents.
- In that case, brief publishes one required member per independent part, and knowledge consumes the full brief collection while extracting from each required part separately.

---

## Global Invariants

- `material/` stays source-faithful.
- `brief/`, `knowledge/`, `wisdom/`, `idea/`, and `tags.md` must follow `vault-language.txt` unless the user explicitly requests bilingual output.
- `changelog/` stores root-level update briefs in `vault-language.txt`; entries may use Obsidian links to changed notes and are exempt from reverse backlink maintenance because they are observational summaries rather than durable business relationships.
- Downstream note filenames should also follow `vault-language.txt`; do not keep English slugs as the default note names in a non-English vault.
- `user.md`, when present at repository root, is the durable vault-level user preference profile. The path stays fixed as `user.md`, but its content may follow the user's own language.
- One vault should not keep parallel bilingual tag branches for the same concept.
- Downstream may not mutate upstream business tables. Required backlink updates in upstream Markdown front matter are allowed when a layer spec requires them.
- Bidirectional links are mandatory. If A links B, B must link back.
- All operations must be idempotent: check by path first, then `UPDATE` or `INSERT`.
- Use soft deletion: set `deleted_at` instead of deleting rows or files.
- The gate is mandatory. No downstream admission logic may bypass `pipeline_units` or `pipeline_consumptions`.
- Everything durable must remain traceable through the repository plus `queue.db`.

---

## User Preference Profile

`user.md` stores stable user preferences for this vault.

Apply it with this precedence:

1. hard repository invariants and layer contracts
2. the user's explicit current request
3. `user.md` as the default policy for ranking, filtering, framing, and synthesis when the current request is silent

Use `user.md` to:

- steer source selection, ranking, and durable source-side filters
- decide whether a source-specific `material/{source}/AGENTS.md` needs stable scope or filtering guidance
- bias downstream explanation style, concept selection, synthesis priorities, and idea generation
- carry vault-level git maintenance preferences, which are opt-in and default to disabled

Do not use `user.md` to:

- bypass the pipeline gate or soften required database bookkeeping
- silently ignore an explicitly requested source item or ingestion task
- drop material facts from brief or break the canonical tag taxonomy

---

## Change Briefs

`changelog/` stores per-run update briefs for Ambra.

- The root agent owns this folder.
- Write one Markdown brief for each completed full downstream run or deep reorganization pass, even if the result is "no durable changes".
- Each brief should summarize created, updated, merged, or retired outputs by layer, with extra attention on changed wisdom and idea outputs plus the most important new insight.
- Use Obsidian links to the changed notes so users can jump directly into the affected content.

---

## Database Conventions

- `queue.db` lives at repository root, is generated locally, and is never committed.
- Before database work, run `./scripts/init-db.sh`.
- Use `./scripts/sqlite.sh` for SQL so `PRAGMA foreign_keys=ON` is always enabled.
- Business tables (`materials`, `briefs`, `knowledges`, `wisdoms`) track durable outputs.
- Pipeline tables (`pipeline_units`, `pipeline_unit_members`, `pipeline_consumptions`) control cross-layer admission.
- `layer_state` is optional bookkeeping; never use it as a substitute for the gate.
- Keep member updates, unit aggregation, and consumption recording transactionally coherent.
- See `migrations/000_init_core_tables.sql` and `migrations/001_add_pipeline_gate_tables.sql` for the canonical schema.

---

## Root Scope

The root agent may:

- read every layer's `AGENTS.md`
- read and write `changelog/`
- read and write `layer_state`
- read and write every `pipeline_*` table
- inspect repository structure and shared tooling

The root agent should not write layer content directly. Content creation belongs to the owning layer agent.

---

## Sub-Agent Delegation

If the host agent supports sub-agents, use them for boundary-clear work that benefits from parallelism or context isolation, such as:

- one layer running independently after its inputs are already fixed
- disjoint batches of ready units that do not write the same files
- audits, searches, or reviews over unrelated files

Keep these responsibilities in the main agent:

- execution-order decisions across layers
- pipeline-gate admission and consumption bookkeeping
- cross-layer language, tag, and backlink policy decisions
- final reconciliation, completion judgment, and user-facing summary

Do not delegate work that depends on rapidly changing shared context or touches the same files or gate rows without explicit serialization.

---

## Shared Preflight

Before running any layer, confirm the common baseline:

```bash
python3 -c "import yaml; print('pyyaml ok')" || pip3 install pyyaml
sqlite3 --version || { echo "ERROR: sqlite3 is required."; exit 1; }
./scripts/init-db.sh >/dev/null
```

Deeper `AGENTS.md` files may add layer-specific tool requirements.

---

## Parallel Work

Parallelize only truly independent work, ideally through sub-agents when available, such as:

- briefs for separate source items
- idea generation for separate research directions
- backlink fixes across disjoint files

Do not parallelize writes that touch the same file or the same gate rows without explicit serialization.

---

## Shared Tooling

- `./scripts/sqlite.sh` for database access
- `material/skills/scripts/update-frontmatter.py` for front matter writes
- `material/skills/scripts/sync-bidirectional-links.py` for backlink checks
- `find` / `ls` / `yq` for repository inspection

---

## Error Handling

- If a layer fails, record it in that layer's `memory.md` and stop downstream progression.
- Before a root-level run, check unresolved issues in per-layer `memory.md` files.
- When a member fails, set `member_status='blocked'`, write `last_error`, and let aggregation block downstream consumption.

---

## Root Checklist

- [ ] this file was read before making cross-layer decisions
- [ ] only the relevant child `AGENTS.md` files were loaded for the active path
- [ ] execution order stayed `material -> brief -> knowledge -> wisdom`, with `idea` only after knowledge is ready
- [ ] all downstream admission went through `pipeline_units` and `pipeline_consumptions`
- [ ] `user.md` was applied with the correct precedence when relevant
- [ ] language, tag, backlink, and soft-delete invariants remained intact
- [ ] root-owned artifacts such as `changelog/` and `pipeline_*` rows were reconciled before completion
- [ ] layer-owned content creation stayed inside the owning layer
