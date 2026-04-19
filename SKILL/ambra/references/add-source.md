# Workflow: `ambra:add-source`

Use this when the user wants to add or extend a material source plugin.

## Steps

1. Read `preflight.md`.
2. Read `user.md` if it exists.
3. Inspect existing sources before creating anything new.
4. Ask whether the requested source can:
   - merge into an existing source plugin
   - reuse the same acquisition pattern
   - reuse shared helper scripts
5. If reuse is possible, prefer extension over a redundant new plugin.
6. Use `user.md` to decide whether the source needs durable filtering or targeting guidance:
   - if the profile defines stable domain focus, exclusions, or ranking rules, encode the durable source-specific part in `material/{source}/AGENTS.md` or source helpers
   - do not bake one-off task instructions into the source contract
   - do not use `user.md` to reject a source the user explicitly asked to add
7. Create or update the source assets under `material/{source}/`:
   - `AGENTS.md`
   - source-specific skills if needed
   - source-specific helper scripts only when the logic is truly source-bound
   - optional `memory.md` if incremental bookkeeping is necessary
8. Make sure the source prompt defines:
   - source description
   - access method
   - incremental strategy
   - search behavior if supported
   - filtering/limits
   - output path pattern
   - ready-unit publication behavior
   - whether one fetched material item may contain multiple clearly independent subcontents that should become multipart briefs downstream
9. Prompt the user for a simple post-registration backfill so the new source can be smoke-tested immediately.
    - default: pull only the single most recent item
    - if `user.md` defines durable source filters, prefer the single most recent matching item
    - if the user wants a broader check, pull a few recent items
    - do not backfill full history unless explicitly requested
10. If the workflow pulls any new material, continue into downstream processing.
11. Before doing that downstream work, read `AGENTS.md`, the relevant layer contracts, and `references/update-changelog.md`.
12. If the workflow completed downstream processing and linked content changed, synchronize bidirectional links first.
13. If the workflow completed downstream processing, update `changelog/` with a linked summary.
14. If git maintenance is enabled or the user explicitly asks for a commit, commit durable source/plugin changes with an `ambra` marker in the subject.

## Checklist

- [ ] preflight passed
- [ ] `user.md` was consulted if present
- [ ] existing sources reviewed for merge/reuse opportunities
- [ ] source/plugin scope chosen
- [ ] durable source-side filtering or targeting guidance from `user.md`, if any, was handled intentionally
- [ ] source prompt defines access, incremental strategy, search, filters, and publication behavior
- [ ] source prompt clarifies whether bundled issues or digests should trigger multipart brief handling
- [ ] ready-unit publication is documented, not omitted
- [ ] user was guided to do a simple post-registration backfill
- [ ] default backfill behavior uses the single most recent item unless the user requested more
- [ ] root and downstream layer contracts were consulted before downstream processing
- [ ] downstream processing run if new material was ingested
- [ ] bidirectional links were synchronized before changelog generation when linked content changed
- [ ] `changelog/` was updated when new material completed downstream processing
- [ ] durable source/plugin changes were committed only when git maintenance was enabled or explicitly requested
