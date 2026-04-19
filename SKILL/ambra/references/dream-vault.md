# Workflow: `ambra:dream`

Use this when the user wants a global cleanup, consolidation, and deeper synthesis pass over an existing vault.

## Goal

Bring the vault into a more organized and more insightful state than a plain incremental run can achieve.

`ambra:dream` is the workflow for:

- merging overlapping or near-duplicate knowledge notes
- merging or rewriting overlapping wisdom notes
- normalizing tag branches and backlinks after consolidation
- discovering stronger cross-note combinations that justify new wisdom or new idea output

## Steps

1. Read `preflight.md`, `AGENTS.md`, `tags.md`, `tag-dataview.md`, the relevant layer contracts, and `user.md` if it exists.
2. If the vault is not up to date, run `ambra:run` logic first so dream works on the latest downstream state.
3. Scan the current downstream vault globally:
   - `knowledge/` for overlapping concepts, duplicate note names, and fractured tag branches
   - `wisdom/` for essays that cover the same theme with weak separation
   - `idea/` for ideas that should be merged, retired, or complemented by stronger cross-knowledge ideas
4. Consolidate `knowledge/`:
   - merge near-duplicates
   - preserve the stronger note path when possible
   - update backlinks, business rows, and publish-unit paths coherently
   - soft-delete superseded notes instead of leaving parallel duplicates behind
   - avoid splitting one concept into many thin notes
5. Consolidate `wisdom/`:
   - merge or rewrite overlapping essays
   - raise the synthesis level when several wisdom notes are really fragments of one theme
   - update backlinks, business rows, and publish-unit paths coherently
   - soft-delete superseded notes instead of leaving parallel duplicates behind
   - keep only meaningfully distinct wisdom notes
6. Revisit tags:
   - normalize branches to the canonical structure in `tags.md`
   - remove drift caused by one-off or mixed-purpose tags
   - confirm `tag-dataview.md` still presents a legible tag landscape
7. Use `user.md` to prioritize which mergers, synthesis rewrites, and new cross-note outputs are most valuable for this vault.
8. Generate new global outputs only when they are justified:
    - create new wisdom when several knowledge branches form a stronger synthesis than the current vault already captures
    - create new ideas under an existing user-created research direction whose `idea/{direction}/AGENTS.md` makes that synthesis a strong fit
    - also allow system-generated adjacent recommendations under `idea/recommend/` when the user's profile plus the current wisdom distribution strongly suggest a nearby topic the user may care about
    - if no existing research direction is a strong fit and there is no defensible adjacent recommendation, skip idea creation instead of inventing a new direction implicitly
9. Use sub-agents if supported for disjoint merge clusters or independent synthesis candidates, but keep global reconciliation in the main agent.
10. Synchronize bidirectional links.
11. Update `changelog/` with a linked summary of the dream pass.
12. If git maintenance is enabled or the user explicitly asks for a commit, make sure a git repository is active for the vault by reusing a parent repo or initializing a standalone repository if needed, then commit durable results with an `ambra` marker in the subject.

## Guardrails

- Do not mutate `material/`.
- Do not keep both the old and the new note when one clearly supersedes the other; merge cleanly.
- Do not create new wisdom or ideas just to increase output count.
- Do not leave tag branches half-migrated.
- Do not leave database rows, publish units, or backlinks pointing at superseded note paths.
- Keep note filenames, titles, tags, and prose aligned with `vault-language.txt`.

## Checklist

- [ ] preflight passed
- [ ] root and relevant layer contracts were consulted
- [ ] `user.md` was consulted if present
- [ ] current vault state was reviewed globally, not only incrementally
- [ ] outdated downstream state was refreshed before deep cleanup when needed
- [ ] overlapping knowledge notes were merged or intentionally preserved with a clear reason
- [ ] overlapping wisdom notes were merged, rewritten, or intentionally preserved with a clear reason
- [ ] database rows, publish units, and backlinks were updated coherently for consolidated notes
- [ ] tag branches were normalized to `tags.md`
- [ ] `tag-dataview.md` still gives a coherent cross-layer view
- [ ] new wisdom or idea outputs were created only when the synthesis was genuinely stronger and, for ideas, only inside an existing fitting research direction or the reserved `idea/recommend/` space
- [ ] `changelog/` was updated with a linked summary
- [ ] bidirectional links were checked
- [ ] durable changes were committed only when git maintenance was enabled or explicitly requested
