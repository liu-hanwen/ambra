---
name: ambra
description: Operate, bootstrap, localize, personalize, or extend an Ambra vault. Use this skill whenever the user wants to initialize a new Ambra vault, configure or refine `user.md`, localize an existing vault, add a material source, search and ingest content, manually import files, run the full DIKW pipeline, or run a global reorganization pass over existing knowledge, wisdom, and idea outputs. Also use it when the user asks to wire a new upstream source into Ambra, pull recent historical content after source registration, ensure newly ingested material continues automatically through brief, knowledge, wisdom, and idea, or generate a linked changelog brief of what changed.
---

# Ambra

Use this skill to operate Ambra from a vault-wide perspective.

Ambra is a DIKW pipeline:

```text
material -> brief -> knowledge -> wisdom
                             \-> idea
```

This skill is an operating contract, not a passive reference. When the user asks for action, execute the workflow and use the relevant reference file(s) below to stay aligned with Ambra's rules.

## Command entrypoints

Expose these workflow labels to the user agent as the canonical entrypoints:

- `ambra:init` - create and bootstrap a fresh vault
- `ambra:user` - interactively create or refine `user.md`
- `ambra:localize` - localize an existing vault
- `ambra:add-source` - register or extend a material source plugin
- `ambra:search` - search an existing source and ingest results
- `ambra:import` - manually import local files and ingest them
- `ambra:run` - run the full DIKW pipeline now
- `ambra:dream` - reorganize and deepen the vault from a global perspective

These are workflow names, not shell commands. The user may trigger them indirectly in natural language.

## Progressive disclosure

Keep context lean:

1. Read `references/preflight.md` first for initialization, source work, ingestion, database work, or full-pipeline runs.
2. Identify the workflow.
3. Read only the workflow reference(s) that match the task.
4. Read `user.md` too when the workflow shapes source filters, ranking, downstream outputs, or idea generation and the file exists.
5. If the workflow will continue into brief, knowledge, wisdom, or idea, also read `AGENTS.md` plus the relevant layer `AGENTS.md` files before performing that downstream work.
6. If the workflow completes downstream processing or a dream pass, also read `references/update-changelog.md` before concluding.
7. If the request spans multiple workflows, execute them in dependency order.

## Universal rules

- Respect the pipeline gate. Never bypass `pipeline_units` or `pipeline_consumptions`.
- Use `./scripts/init-db.sh` before database work and `./scripts/sqlite.sh` for SQL.
- Read `vault-language.txt` before any downstream run. `brief`, `knowledge`, `wisdom`, `idea`, and `tags.md` must all follow that language unless the user explicitly asks for bilingual output, including downstream note filenames.
- Read `user.md` when it exists before shaping durable filters, source prompts, downstream selection, or idea generation. Treat explicit current user instructions as stronger than `user.md`, and treat repository invariants as stronger than both.
- If the host agent supports sub-agents, delegate boundary-clear work that benefits from parallelism or context isolation, but keep root orchestration, shared-state reconciliation, and final completion judgment in the main agent.
- Keep bidirectional links consistent.
- If any workflow ingests new material, continue into downstream processing before concluding.
- After any workflow that completes downstream processing or `ambra:dream`, update `changelog/` with a linked summary of what changed.
- Git maintenance is opt-in. Default to disabled unless the user or `user.md` explicitly enables it.
- If git maintenance is enabled, reuse the nearest parent git repository when one exists; only create a new repository when the user wants standalone git management and no parent repo is available.
- If Ambra creates an automatic commit, prefix the commit subject with an `ambra` marker such as `[ambra]`.
- Never commit `queue.db` or other generated runtime database files.
- Downstream layers may update upstream Markdown front matter when a layer spec requires backlink maintenance, but they must not mutate upstream business tables.

## Workflow router

| Workflow | Read this |
|---|---|
| `ambra:init` | `references/preflight.md`, `references/init-vault.md` |
| `ambra:user` | `references/configure-user.md` |
| `ambra:localize` | `references/localize-vault.md` |
| `ambra:add-source` | `references/preflight.md`, `references/add-source.md`, then `AGENTS.md` plus relevant layer `AGENTS.md` files if new material is ingested |
| `ambra:search` | `references/preflight.md`, `references/search-existing-source.md`, then `AGENTS.md` plus relevant layer `AGENTS.md` files |
| `ambra:import` | `references/preflight.md`, `references/import-files.md`, then `AGENTS.md` plus relevant layer `AGENTS.md` files |
| `ambra:run` | `references/preflight.md`, `references/run-pipeline.md`, then `AGENTS.md` plus relevant layer `AGENTS.md` files |
| `ambra:dream` | `references/preflight.md`, `references/dream-vault.md`, then `AGENTS.md` plus relevant layer `AGENTS.md` files |

## Completion rule

A workflow is complete only when:

1. its checklist in the relevant reference file is satisfied
2. downstream processing has been run if new material was ingested
3. sub-agent delegation, if used, stayed within clear boundaries and did not hide root-owned decisions
4. language and tag outputs remain consistent with `vault-language.txt`
5. `user.md`, if relevant to the workflow, was created, updated, or intentionally left unchanged with that choice reflected in the work
6. `changelog/` was updated when the workflow completed downstream processing or a dream pass
7. durable results were committed only when git maintenance was enabled or the user explicitly asked for a commit
8. the final report tells the user what changed and names the git commit if one was created

## Related files

- `README.md` - repository entrypoint
- `AGENTS.md` - root orchestration contract
- `material/AGENTS.md` - material-layer ingestion rules
- `brief/AGENTS.md`, `knowledge/AGENTS.md`, `wisdom/AGENTS.md`, `idea/AGENTS.md` - downstream layer contracts
