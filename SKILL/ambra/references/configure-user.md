# Workflow: `ambra:user`

Use this when the user wants to create, refine, or audit `user.md`.

## Goal

Turn vague user preferences into a durable vault profile that the rest of Ambra can reuse.

## Steps

1. Read the current `user.md` if it exists.
2. Read `vault-language.txt` and `tags.md` so language and taxonomy preferences stay compatible with the rest of the vault.
3. Ask targeted questions and separate:
   - hard constraints or exclusions
   - stable preferences and ranking rules
   - temporary task-specific requests that should **not** be baked into `user.md`
4. Capture only durable preferences that are likely to matter again, such as:
   - primary language and acceptable reading languages
   - core domains, recurring questions, and preferred evidence level
   - source preferences, exclusions, freshness bias, or result-count defaults
   - downstream preferences for brief, knowledge, wisdom, and idea outputs
   - preferred tag granularity or naming habits, as long as they still align with `tags.md`
5. Decide whether the workflow found a real durable change:
   - if yes, rewrite `user.md` into a concise operational profile instead of a diary
   - if no, treat the workflow as an audit and leave `user.md` unchanged
   - use the user's own language if that makes the profile easier for them to maintain
6. If the refined profile implies stable source-side behavior, point future source work toward updating the relevant `material/{source}/AGENTS.md` rather than overloading `user.md` with source-specific implementation detail.
7. Commit only when the workflow produced a durable change.

## Checklist

- [ ] existing `user.md` was read if present
- [ ] `vault-language.txt` and `tags.md` were read before validating language or taxonomy preferences
- [ ] durable preferences were separated from one-off requests
- [ ] hard constraints versus soft preferences were made explicit
- [ ] `user.md` stays concise and operational
- [ ] a no-change audit path was handled explicitly when no durable update was needed
- [ ] any tag or language preferences stay aligned with `tags.md` and `vault-language.txt`
- [ ] future source-specific behavior was routed toward source contracts when needed
- [ ] durable changes were committed to git when any existed
