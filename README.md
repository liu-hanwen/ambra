# Ambra

> Chinese documentation: [README-zh.md](README-zh.md)
>
> Turn papers, books, articles, newsletters, and local files into a living Markdown research vault.

Ambra is a repository-native research product built around AI agents. It helps you ingest raw material, rewrite it into readable briefs, extract reusable knowledge, synthesize higher-level wisdom, and surface next-step ideas — while keeping the whole process transparent in your own files.

This is not a black-box chatbot that forgets what it read. Ambra is designed for people who want their research process to compound over time inside a durable, inspectable vault.

---

## What Ambra gives you

- **Readable input, not just storage** — raw material becomes structured briefs instead of a pile of PDFs and highlights.
- **Reusable knowledge, not disposable summaries** — important concepts are extracted into atomic notes that can be merged and reused.
- **Higher-level synthesis** — Ambra can turn repeated patterns into wisdom notes, decision frameworks, and playbooks.
- **Next research directions** — Ambra can generate idea notes for your chosen directions and suggest adjacent topics worth exploring.
- **A visible change trail** — every downstream-complete run updates `changelog/` so you can see what changed and what new insight appeared.
- **Your language, your preferences** — `vault-language.txt` and `user.md` let the vault adapt to how you think and work.

---

## Who Ambra is for

Ambra is a strong fit if you:

- read a lot and do not want your notes to stay trapped in source documents
- want AI help, but still want transparent Markdown files you can inspect and keep
- care about building a long-term research vault rather than getting one-off summaries
- work in Obsidian-style knowledge environments and want agent workflows that stay repository-native

---

## Usage

**Use `SKILL/ambra/SKILL.md` as the main operating surface.** It exposes these canonical workflow labels:

| Workflow | Ask the agent to do this |
|---|---|
| `ambra:init` | create and bootstrap a new vault |
| `ambra:user` | create, refine, or audit `user.md` |
| `ambra:localize` | switch or clean up the vault's downstream language |
| `ambra:add-source` | register or extend a material source |
| `ambra:search` | search an existing source and ingest results |
| `ambra:import` | import local files such as PDFs or EPUBs |
| `ambra:run` | bring the vault fully up to date |
| `ambra:dream` | reorganize the vault, merge overlaps, and deepen synthesis |

These are **workflow names, not shell commands**. The user can invoke them directly or in natural language, for example:

```text
Use ambra:init to create a new Chinese vault in ~/vaults/investing.
Use ambra:user to help me shape this vault around quant research.
Use ambra:add-source to add a weekly magazine source and pull one recent item as a smoke test.
Use ambra:import to ingest these local EPUB files into Ambra.
Use ambra:run to update the whole vault and tell me what changed.
Use ambra:dream to merge overlapping knowledge and produce stronger wisdom.
```

If a workflow shapes source filtering, downstream emphasis, or idea generation, Ambra should consult `user.md`. If it writes downstream notes, it should follow `vault-language.txt`.

---

## What a full Ambra run produces

| Stage | What you start with | What you get |
|---|---|---|
| `material` | raw PDFs, EPUBs, webpages, source feeds, local files | source-faithful Markdown under `material/` |
| `brief` | raw material that is hard to scan | clear, user-language briefs that preserve important information |
| `knowledge` | document-level understanding | atomic, reusable knowledge notes |
| `wisdom` | many related knowledge notes | synthesis pieces, frameworks, and higher-level insight |
| `idea` | newly ready knowledge + your research directions | actionable idea notes and adjacent-topic recommendations |
| `changelog` | a completed downstream run | a linked brief showing what changed and why it matters |

---

## Quick Start

1. Make sure the local runtime is viable: `python3`, `sqlite3`, `pandoc`, and `pyyaml` are the important pieces.
2. Run `./scripts/init-db.sh` at the repository root to create the local `queue.db`.
3. Decide the vault's downstream language in `vault-language.txt`.
4. Create or refine `user.md` so Ambra knows your standing preferences.
5. Add a source with `ambra:add-source`, or import files with `ambra:import`.
6. Run `ambra:run` to push the vault through `brief -> knowledge -> wisdom / idea`.
7. Open `changelog/` to see what changed, then follow the linked notes.

> `queue.db` is local runtime state and is intentionally not committed.
>
> Git maintenance is opt-in. If you want Ambra to create commits for durable changes, enable that explicitly.

---

## What makes Ambra different

- **Vault-first, not SaaS-first** — the durable outputs are plain files in your repository.
- **Agentic, but inspectable** — the prompts and workflow contracts live alongside the content they govern.
- **Not summary-only** — Ambra is built to preserve signal, accumulate knowledge, and improve synthesis over time.
- **Language-aware** — downstream outputs, filenames, and tags can follow the user's working language.
- **Preference-aware** — `user.md` can guide source choices, emphasis, synthesis priorities, and idea generation.

---

## How Ambra works

```text
material -> brief -> knowledge -> wisdom
                             \-> idea (parallel to wisdom)
```

| Layer | Responsibility |
|---|---|
| **material** | fetch or import raw sources and convert them into clean Markdown |
| **brief** | restore the source in clearer language and structure without losing important information |
| **knowledge** | extract reusable concepts and merge overlaps |
| **wisdom** | synthesize multiple knowledge notes into stronger themes |
| **idea** | generate actionable ideas for user-defined directions and adjacent recommendations |

The technical orchestration is documented in `AGENTS.md`, while `SKILL/ambra/SKILL.md` is the main operating entrypoint for agents.

---

## Core operating concepts

### `user.md`

`user.md` is the vault's durable preference profile. Use it for stable source focus, exclusions, ranking, downstream emphasis, and idea-generation priorities. It can also decide whether Ambra should manage git automatically.

### `vault-language.txt`

`vault-language.txt` defines the canonical downstream output language for `brief/`, `knowledge/`, `wisdom/`, `idea/`, and `tags.md`. `material/` remains source-faithful.

### `changelog/`

Every completed downstream run should leave behind a linked update brief in `changelog/`, especially calling out changed wisdom, ideas, and the key new insight.

### Pipeline gate

Ambra uses a publish-unit and versioned-consumption gate so downstream work only runs on complete upstream outputs and can rerun safely when inputs change.

---

## Repository layout

```text
.
|- SKILL/ambra/            # Main operating skill
|- material/               # Source-faithful Markdown and source plugins
|- brief/                  # Readable reconstructions of source material
|- knowledge/              # Atomic reusable knowledge notes
|- wisdom/                 # Higher-level synthesis notes
|- idea/                   # User directions + reserved recommendations
|- changelog/              # Per-run update briefs
|- user.md                 # Durable user preference profile
|- vault-language.txt      # Canonical downstream output language
|- tags.md                 # Shared tag taxonomy
|- tag-dataview.md         # Tag-oriented cross-layer view
|- scripts/                # Database bootstrap and helpers
\- migrations/             # SQLite schema and migrations
```

---

## Extending Ambra

- Add a new research direction by creating a subdirectory under `idea/` with its own `AGENTS.md`.
- Add a new source plugin under `material/{source}/AGENTS.md`.
- Put reusable helpers under `material/skills/scripts/`.
- Start technical contract reading from `SKILL/ambra/SKILL.md` and root `AGENTS.md`.
