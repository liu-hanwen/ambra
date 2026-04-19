# Recommended Topics - System Direction Spec

## Role

`idea/recommend/` is a reserved, system-managed recommendation space.

It exists for adjacent topics that the user has not explicitly subscribed to yet, but that Ambra can justify from the user's profile plus the current knowledge and wisdom landscape.

## Signals

Use signals such as:

- `user.md` domain preferences
- dominant topic or domain patterns in `wisdom/`
- repeated high-signal clusters in `knowledge/`
- gaps or adjacent topics suggested by the user's strongest wisdom branches

## Output shape

- Create one topic directory under `idea/recommend/` per candidate topic.
- Use the vault language for directory names and filenames.
- Inside each topic directory, write one or more concise idea-insight notes.
- Each note should link to the knowledge or wisdom notes that motivated the recommendation.

## Guardrails

- Recommend only adjacent, defensible topics; do not produce random novelty.
- Do not duplicate an existing user-created research direction.
- Use current wisdom distribution as a hint about user taste, not as absolute proof.
- Prefer a few high-signal topics over many weak candidates.
